// native_tooltips.nut - HD tooltips for the game's own (native) windows.
//
// The game's scrolls are not M2EX widgets, but ::ui.element("strat_ui") exposes their layout:
// every piece reports its rect and whether the mouse is over it. Each frame this module follows
// the hovered chain from the root down to the piece under the cursor, works out what it is
// (a trait row, an ancillary, the piety line...), switches the game's own tooltip off, and draws
// ours with ::EX.drawTip, reading the text straight from the game objects. No mod files are read.
//
// Covered now: the character windows (own and enemy): traits, ancillaries, command / chivalry /
// loyalty / piety. More windows are added in resolve().

local NativeTooltips = class {
    style = {
        enabled        = true,
        ghostNative    = true,    // raise an invisible engine tooltip at the cursor, which keeps the
                                  // game's own tooltip hidden (what the campaign cards do)
        ghostPad       = 2,       // half-size of that invisible hover box, in pixels
        muteNative     = false,   // also flip the showToolTips option through Lua (did not work on the map)
        probeNative    = false,   // log what ::UI.tooltipContent gives for each new native piece hovered
        buttons        = false,   // buttons, tabs and gadgets keep the game's own tooltip
        slots          = false,   // recruitment / construction cards: off - M2EX gives no way to
                                  // tell which unit a card is, nor any building names
        quietNavigation = true,   // unmapped tabs / nav buttons show no tooltip instead of the old one
        ghostOnButtons = true,    // hide the game's tooltip on buttons too (turn off if a button stops
                                  // taking clicks; the game's own tooltip then shows there instead)
        gapSnap        = 4,       // px: the cursor in the gap between two rows counts as the nearer row
        graceFrames    = 10,      // keep our tooltip (and the game's hidden) this many frames after the
                                  // cursor leaves a piece, so moving between rows never lets it through
        delayFrames    = 8,       // frames the cursor rests on a piece before our tooltip shows
        showStatSources = false,  // stat tooltips also list the traits / ancillaries that affect them
        debug          = false,   // log each new target and the text it resolved to
    }

    // Stat rows in character windows are named character_info_<stat>_points. For each stat:
    // the label shown as the title, and the words that mark an effect on it in a trait's or
    // ancillary's effects text. Unlisted stats still work, titled from their name.
    statInfo = {
        command    = { label = "Command",    words = ["command"] },
        chivalry   = { label = "Chivalry",   words = ["chivalry", "dread"] },
        loyalty    = { label = "Loyalty",    words = ["loyalty"] },
        piety      = { label = "Piety",      words = ["piety"] },
        influence  = { label = "Influence",  words = ["influence"] },
        subterfuge = { label = "Subterfuge", words = ["subterfuge"] },
        finance    = { label = "Finance",    words = ["finance", "trade"] },
        charm      = { label = "Charm",      words = ["charm"] },
        magic      = { label = "Magic",      words = ["magic"] },
        authority  = { label = "Authority",  words = ["authority"] },
    }

    state = { down = false, strikes = 0, lastKey = "", still = 0, muted = false, loggedMismatch = false,
              probeKey = "", probeCount = 0, probeErrors = {},
              grace = 0, lastText = null, loggedBuildingTable = false,
              loggedStat = {}, loggedList = {}, loggedRows = {}, loggedMiss = {}, loggedGeo = {} }
    scrollChar = null     // the character whose scroll was opened (captured on ScrollOpened)
    tipText = null
    hitActive = false     // a native piece we replace is under the cursor this frame

    // ------------------------------------------------------------------
    // Native element helpers
    // ------------------------------------------------------------------
    function nameOf(e) {
        try { return e.name } catch (err) { return "" }
    }

    function kids(e) {
        try { return e.childCount } catch (err) { return 0 }
    }

    function childOf(e, i) {
        try { return e.child(i) } catch (err) { return null }
    }

    function isHovered(e) {
        try { return e != null && e.hovered } catch (err) { return false }
    }

    function root() {
        local e = null
        try { e = ::ui.element("strat_ui") } catch (err) { return null }
        try { if (e == null || !e.valid) return null } catch (err) { return null }
        return e
    }

    // The chain of hovered pieces from the root down: [{ e, index }], root first.
    function hoveredChain(rootEl) {
        local chain = [{ e = rootEl, index = -1 }]
        local cur = rootEl
        for (local depth = 0; depth < 16; depth++) {
            local found = null
            local foundIdx = -1
            for (local i = this.kids(cur) - 1; i >= 0; i--) {
                local ch = this.childOf(cur, i)
                if (this.isHovered(ch)) { found = ch; foundIdx = i; break }
            }
            if (found == null && depth >= 2) {
                local snap = this.nearestChild(cur)
                if (snap != null) { found = snap[0]; foundIdx = snap[1] }
            }
            if (found == null) break
            chain.append({ e = found, index = foundIdx })
            cur = found
        }
        return chain
    }

    // No child reports the hover (the cursor sits in the thin gap between two rows): the child
    // whose screen rect is within gapSnap pixels of the cursor, nearest first. Leaves only.
    function nearestChild(e) {
        local m = null
        try { m = ::UI.mouse.pos() } catch (err) { return null }
        local pad = this.style.gapSnap
        local best = null
        local bestD = pad + 1
        for (local i = 0; i < this.kids(e); i++) {
            local ch = this.childOf(e, i)
            if (ch == null || this.kids(ch) != 0) continue
            local x = 0; local y = 0; local w = 0; local h = 0
            try { x = ch.screenX; y = ch.screenY; w = ch.screenWidth; h = ch.screenHeight } catch (err) { continue }
            if (w <= 0 || h <= 0 || m[0] < x || m[0] >= x + w) continue
            local d = 0
            if (m[1] < y) d = y - m[1]
            else if (m[1] >= y + h) d = m[1] - (y + h - 1)
            if (d < bestD) { bestD = d; best = [ch, i] }
        }
        return best
    }

    // Looks a few levels into a window for a piece whose name contains one of the given words.
    function findNamed(e, words, depth) {
        local n = this.nameOf(e)
        if (n != null && n != "") {
            foreach (w in words) {
                if (n.indexof(w) != null) return n
            }
        }
        if (depth <= 0) return null
        for (local i = 0; i < this.kids(e); i++) {
            local hit = this.findNamed(this.childOf(e, i), words, depth - 1)
            if (hit != null) return hit
        }
        return null
    }

    // ------------------------------------------------------------------
    // Whose scroll is it
    // ------------------------------------------------------------------
    function captureCharacter() {
        local cm = null
        try { cm = ::ui.cardManager() } catch (err) { return }
        local pick = null
        foreach (k in ["hoveredCharacter", "selectedEnemyCharacter", "selectedCharacter"]) {
            local c = null
            try { c = cm[k] } catch (err) {}
            if (c != null) { pick = c; break }
        }
        if (pick != null) this.scrollChar = pick
    }

    // Every character the open window could be about, most likely first.
    function candidates(windowKind) {
        local out = []
        local seen = {}
        local add = function(c) {
            if (c == null) return
            local rec = null
            try { rec = c.record } catch (err) { rec = null }
            if (rec == null) { try { if (c.traitCount != null) rec = c } catch (err) {} }
            if (rec == null) return
            local id = ""
            try { id = rec.displayName + "#" + rec.index } catch (err) { id = "" + rec }
            if (id in seen) return
            seen[id] <- true
            out.append(rec)
        }
        local cm = null
        try { cm = ::ui.cardManager() } catch (err) {}
        // Own windows follow the selection first, so the prev / next arrows keep it right.
        if (windowKind == "own" && cm != null) { try { add(cm.selectedCharacter) } catch (err) {} }
        add(this.scrollChar)
        if (cm != null) {
            foreach (k in ["selectedCharacter", "selectedEnemyCharacter", "hoveredCharacter"]) {
                try { add(cm[k]) } catch (err) {}
            }
            // A general picked from a unit card (a character opened from inside a settlement)
            try {
                local u = cm.selectedUnit
                if (u != null) {
                    foreach (f in ["character", "general", "generalCharacter"]) { try { add(u[f]) } catch (err) {} }
                }
            } catch (err) {}
        }
        // Everyone in the settlement or fort whose window is open
        local places = []
        try { local ss = ::ui.settlementScroll(); if (ss != null) places.append(ss.settlement) } catch (err) {}
        if (cm != null) {
            foreach (k in ["selectedSettlement", "selectedEnemySettlement", "hoveredSettlement", "selectedFort", "selectedEnemyFort"]) {
                try { local pl = cm[k]; if (pl != null) places.append(pl) } catch (err) {}
            }
        }
        foreach (pl in places) {
            try { add(pl.governor) } catch (err) {}
            local n = 0
            try { n = pl.characterCount } catch (err) {}
            for (local i = 0; i < n; i++) {
                foreach (f in ["getCharacter", "character", "characterAt"]) {
                    try { add(pl[f].call(pl, i)); break } catch (err) {}
                }
            }
            try { add(pl.army.leader) } catch (err) {}
            try { add(pl.army.general) } catch (err) {}
        }
        return out
    }

    // In a character window: the trait column's row count and the retinue column's slot count,
    // or null when the two columns are not found.
    function columnCounts(e, depth) {
        if (e == null || depth < 0) return null
        if (this.kids(e) == 2) {
            local a = this.childOf(e, 0)
            local t = this.childOf(e, 1)
            local ok = a != null && t != null
            local tw = 0; local aw = 0
            try { tw = t.width; aw = a.width } catch (err) { ok = false }
            if (ok && tw > 150 && aw > 150) {
                local rowsOk = true
                for (local i = 0; i < this.kids(t); i++) {
                    local r = this.childOf(t, i)
                    local h = 0
                    try { h = r.height } catch (err) {}
                    if (h <= 0 || h >= 20 || this.kids(r) != 0) { rowsOk = false; break }
                }
                if (rowsOk && this.kids(t) + this.kids(a) > 0) return [this.kids(t), this.kids(a)]
            }
        }
        for (local i = 0; i < this.kids(e); i++) {
            local hit = this.columnCounts(this.childOf(e, i), depth - 1)
            if (hit != null) return hit
        }
        return null
    }

    // The window's character: the candidate whose visible traits and retinue match the window's
    // rows. Remembered per window until a scroll opens or closes.
    pickCache = null
    function characterFor(windowKind, win) {
        local list = this.candidates(windowKind)
        if (list.len() == 0) {
            if (this.lastPickName != "<none>") {
                this.lastPickName = "<none>"
                if (this.style.debug) println("squi: [native-tips] window character: no candidates")
            }
            return null
        }
        local counts = this.columnCounts(win, 6)
        if (counts == null) {
            local first = "?"
            try { first = list[0].displayName } catch (err) {}
            if (first != this.lastPickName) {
                this.lastPickName = first
                if (this.style.debug) println("squi: [native-tips] window character: " + first + " (no trait columns found, "
                        + list.len() + " candidates)")
            }
            return list[0]
        }
        local best = null
        local bestScore = -1
        foreach (rec in list) {
            local score = 0
            local anc = -1
            try { anc = rec.ancillaryCount } catch (err) {}
            if (this.visibleTraits(rec).len() == counts[0]) score += 2
            else if (this.traitsForRowsQuiet(rec, counts[0])) score += 2   // [trait-rows] a looser reading fits
            if (anc == counts[1]) score += 1
            if (score > bestScore) { best = rec; bestScore = score }
        }
        local name = "?"
        try { name = best.displayName } catch (err) {}
        if (name != this.lastPickName) {
            this.lastPickName = name
            if (this.style.debug) println("squi: [native-tips] window character: " + name + " (score " + bestScore + " of 3, "
                    + list.len() + " candidates, window rows " + counts[0] + " traits / " + counts[1] + " retinue)")
        }
        return best
    }
    lastPickName = ""

    // ------------------------------------------------------------------
    // Text builders
    // ------------------------------------------------------------------
    function visibleTraits(rec) {
        local out = []
        local n = 0
        try { n = rec.traitCount } catch (err) { return out }
        for (local i = 0; i < n; i++) {
            local t = null
            try { t = rec.getTrait(i) } catch (err) { continue }
            if (t == null) continue
            local hidden = false
            try { hidden = t.traitType.isHidden } catch (err) {}
            local shown = ""
            try { shown = t.levelEntry.name } catch (err) {}
            if (hidden || shown == null || shown == "") continue
            out.append(t)
        }
        return out
    }

    // [trait-rows] The traits in the order the window lists them, for a column of `rows` rows.
    // The window does not always agree with visibleTraits: a trait flagged hidden can still be
    // listed (SSHIP's Courtier, and traits a script adds as the window opens), which left the last
    // row unmatched and every row after the odd one out shifted by one. So the looser readings are
    // tried in turn and the first whose count matches the rows is used:
    //   1. visible traits (not hidden, with a shown name) - as before
    //   2. every trait with a shown name, hidden flag or not
    //   3. every trait
    // With no match, reading 1 is kept and rows past its end are left to the game.
    function traitsForRows(rec, rows) {
        local strict = this.visibleTraits(rec)
        if (strict.len() == rows) return strict
        local named = []
        local all = []
        local n = 0
        try { n = rec.traitCount } catch (err) { return strict }
        for (local i = 0; i < n; i++) {
            local t = null
            try { t = rec.getTrait(i) } catch (err) { continue }
            if (t == null) continue
            all.append(t)
            local shown = ""
            try { shown = t.levelEntry.name } catch (err) {}
            if (shown != null && shown != "") named.append(t)
        }
        // 4. not flagged hidden, named or not (some mods list a trait whose level has no name)
        local open = []
        foreach (t in all) {
            local hidden = false
            try { hidden = t.traitType.isHidden } catch (err) {}
            if (!hidden) open.append(t)
        }
        local pick = named.len() == rows ? named : (all.len() == rows ? all : (open.len() == rows ? open : null))
        local key = rec.displayName + ":" + rows
        if (!(key in this.state.loggedRows)) {
            this.state.loggedRows[key] <- true
            if (this.style.debug) println("squi: [native-tips] trait rows " + rows + " for " + rec.displayName + ": visible " + strict.len()
                    + ", named " + named.len() + ", not hidden " + open.len() + ", all " + all.len() + " -> "
                    + (pick == null ? "no count matches - rows are matched by their text where the window gives it"
                                    : (pick == named ? "named" : (pick == all ? "all" : "not hidden"))))
            if (pick == null) {
                // what each trait is, so the window's rule can be worked out
                local list = ""
                foreach (t in all) {
                    local nm = ""; local hid = false
                    try { nm = t.levelEntry.name } catch (err) {}
                    try { hid = t.traitType.isHidden } catch (err) {}
                    list += " [" + (nm != null && nm != "" ? nm : "<no name>") + (hid ? " hidden" : "") + "]"
                }
                if (this.style.debug) println("squi: [native-tips]   traits:" + list)
            }
        }
        this.lastRowsExact = pick != null
        return pick != null ? pick : strict
    }

    // [trait-rows] Whether a looser reading (named / all traits) has exactly `rows` traits.
    function traitsForRowsQuiet(rec, rows) {
        local named = 0
        local all = 0
        local n = 0
        try { n = rec.traitCount } catch (err) { return false }
        for (local i = 0; i < n; i++) {
            local t = null
            try { t = rec.getTrait(i) } catch (err) { continue }
            if (t == null) continue
            all++
            local shown = ""
            try { shown = t.levelEntry.name } catch (err) {}
            if (shown != null && shown != "") named++
        }
        local open = 0
        for (local i = 0; i < n; i++) {
            local t = null
            try { t = rec.getTrait(i) } catch (err) { continue }
            if (t == null) continue
            local hidden = false
            try { hidden = t.traitType.isHidden } catch (err) {}
            if (!hidden) open++
        }
        return named == rows || all == rows || open == rows
    }
    lastRowsExact = true

    // [trait-rows] The text a window row carries, if M2EX exposes it: [field, text] or null. Tried
    // once per field name; the first time a row gives text, which field it was is logged.
    rowFields = ["text", "label", "caption", "string", "title", "tooltip", "tooltipText"]
    rowFieldLogged = false
    function rowText(e) {
        foreach (f in this.rowFields) {
            local v = null
            try { v = e[f] } catch (err) { v = null }
            if (typeof v == "string" && this.trim(v) != "") {
                if (!this.rowFieldLogged) {
                    this.rowFieldLogged = true
                    if (this.style.debug) println("squi: [native-tips] window rows carry text in ." + f + ": \"" + v + "\"")
                }
                return [f, this.trim(v)]
            }
        }
        if (!this.rowFieldLogged) {
            this.rowFieldLogged = true
            local have = ""
            try { foreach (k, v in e) have += " " + k } catch (err) {}
            if (this.style.debug) println("squi: [native-tips] window rows carry no text we can read" + (have != "" ? "; fields:" + have : ""))
        }
        return null
    }

    // [trait-rows] The trait a row names, found by its text; null when the row has no readable text
    // or no trait carries that name.
    function traitByRowText(rec, e) {
        local got = this.rowText(e)
        if (got == null) return null
        local want = got[1]
        local n = 0
        try { n = rec.traitCount } catch (err) { return null }
        for (local i = 0; i < n; i++) {
            local t = null
            try { t = rec.getTrait(i) } catch (err) { continue }
            if (t == null) continue
            local nm = ""
            try { nm = t.levelEntry.name } catch (err) {}
            if (nm != null && this.trim(nm) == want) return t
        }
        return null
    }

    function traitText(t) {
        local lv = t.levelEntry
        local text = lv.name
        local desc = ""
        try { desc = lv.description } catch (err) {}
        if (desc != null && desc != "") text += "\n" + desc
        local fx = ""
        try { fx = lv.effectsDescription } catch (err) {}
        if (fx != null && fx != "") text += "\nEffects: " + fx
        try {
            if (t.hasEpithet && lv.epithetDescription != "") text += "\nEpithet: " + lv.epithetDescription
        } catch (err) {}
        return text
    }

    function ancillaryText(a) {
        local text = a.displayName
        local desc = ""
        try { desc = a.description } catch (err) {}
        if (desc != null && desc != "") text += "\n" + desc
        local fx = ""
        try { fx = a.effectsDescription } catch (err) {}
        if (fx != null && fx != "") text += "\nEffects: " + fx
        return text
    }

    function trim(s) {
        local a = 0
        local b = s.len()
        while (a < b && (s[a] == ' ' || s[a] == '\t' || s[a] == '\n' || s[a] == '\r')) a++
        while (b > a && (s[b - 1] == ' ' || s[b - 1] == '\t' || s[b - 1] == '\n' || s[b - 1] == '\r')) b--
        return s.slice(a, b)
    }

    // The effect clauses in an effects text that mention one of the words.
    function matchingEffects(fx, words) {
        local out = []
        if (fx == null || fx == "") return out
        foreach (part in fx.split(",")) {
            local clause = this.trim(part)
            local low = clause.tolower()
            foreach (w in words) {
                if (low.indexof(w) != null) { out.append(clause); break }
            }
        }
        return out
    }

    // The game's own text, from its loaded string tables (tooltips.txt lives in one of them).
    // Which table holds the TMT_ keys is found once and remembered. null when not found.
    function gameText(key) {
        local table = key.indexof("SMT_") == 0 ? "strat" : key.indexof("ST_") == 0 ? "shared" : "tooltips"
        local id = null
        try { if (table in ::Enum.StringTable) id = ::Enum.StringTable[table] } catch (err) {}
        if (id == null) {
            if (!(table in this.missingTables)) {
                this.missingTables[table] <- true
                local have = ""
                try { foreach (k, v in ::Enum.StringTable) have += k + " " } catch (err) {}
                println("squi: [native-tips] no string table '" + table + "'; tables: " + have)
            }
            return null
        }
        local out = null
        try { out = ::scripting.textTable(key, id) } catch (err) { return null }
        if (out == null || out == "" || out == key) return null
        return this.trim(out)
    }
    missingTables = {}

    // The same, from the first of several tables that holds the key (for tables whose name
    // may differ between game versions, such as the building names).
    function gameTextIn(key, tables) {
        foreach (t in tables) {
            local id = null
            try { if (t in ::Enum.StringTable) id = ::Enum.StringTable[t] } catch (err) {}
            if (id == null) continue
            local out = null
            try { out = ::scripting.textTable(key, id) } catch (err) { continue }
            if (out != null && out != "" && out != key) return this.trim(out)
        }
        return null
    }

    // "%d florins" + 850 -> "850 florins"
    function fmtD(text, n) {
        if (text == null) return null
        local at = text.indexof("%d")
        if (at == null) return text
        return text.slice(0, at) + n + text.slice(at + 2)
    }

    // "character_info_piety_points" -> "piety"
    function statFromName(name) {
        local pre = "character_info_"
        local post = "_points"
        if (name == null || name.len() <= pre.len() + post.len()) return null
        if (name.slice(0, pre.len()) != pre || name.slice(name.len() - post.len()) != post) return null
        return name.slice(pre.len(), name.len() - post.len())
    }

    function statText(rec, stat) {
        local info = stat in this.statInfo ? this.statInfo[stat]
                   : { label = stat.slice(0, 1).toupper() + stat.slice(1), words = [stat] }
        local value = null
        try { value = rec[stat].tointeger() } catch (err) {}
        // A "dread" row (EB II shows one as Confidence) is chivalry read the other way.
        if (stat == "dread") {
            local ch = null
            try { ch = rec.chivalry.tointeger() } catch (err) {}
            if (ch != null) {
                local lv = ch < 0 ? -ch : 0
                if (lv > 10) lv = 10
                local title = this.gameText("ST_DREAD")
                local text = title != null ? title : "Dread"
                local line = this.gameText("TMT_DREAD_LEVEL_" + lv)
                if (line != null) text += "\n" + line
                return text
            }
        }

        // Title and the game's own line for this level
        local label = info.label
        local keys = []
        local upper = stat.toupper()
        if (value != null) {
            local mag = value < 0 ? -value : value
            if (mag > 10) mag = 10
            if (stat == "chivalry" && value < 0) {
                label = "Dread"
                keys = ["TMT_DREAD_LEVEL_" + mag, "TMT_NEGATIVE_CHIVALRY", "TMT_CHIVALRY_LEVEL_0"]
            } else if (value < 0) {
                keys = ["TMT_NEGATIVE_" + upper, "TMT_" + upper + "_LEVEL_0"]
            } else {
                keys = ["TMT_" + upper + "_LEVEL_" + mag]
                if (stat == "chivalry") keys.append("TMT_DREAD_LEVEL_" + mag)
            }
        }
        // The title as this mod names the stat (EB II calls chivalry "Confidence", for one):
        // the tooltip title, else the stat's own name from the shared text, else our label.
        local title = null
        if (label == "Dread") title = this.gameText("ST_DREAD")
        else {
            title = this.gameText("TMT_" + upper + "_TITLE")
            if (title == null) title = this.gameText("ST_" + upper)
        }
        if (title != null) label = title
        local text = label
        local line = null
        foreach (k in keys) {
            line = this.gameText(k)
            if (line != null && line.indexof("DO NOT TRANSLATE") == null) break
            line = null
        }
        if (line != null) text += "\n" + line
        else if (!(stat in this.state.loggedStat)) {
            this.state.loggedStat[stat] <- true
            local tried = ""
            foreach (k in keys) tried += k + " "
            if (this.style.debug) println("squi: [native-tips] no level text for " + stat + " = " + value + "; tried " + tried)
        }
        if (!this.style.showStatSources) return text

        // What raises or lowers it: "+1 Piety (Tutor)"
        local sources = []
        foreach (t in this.visibleTraits(rec)) {
            local fx = ""
            try { fx = t.levelEntry.effectsDescription } catch (err) {}
            foreach (clause in this.matchingEffects(fx, info.words)) sources.append(clause + " (" + t.levelEntry.name + ")")
        }
        local n = 0
        try { n = rec.ancillaryCount } catch (err) {}
        for (local i = 0; i < n; i++) {
            local a = null
            try { a = rec.getAncillary(i) } catch (err) { continue }
            if (a == null) continue
            local fx = ""
            try { fx = a.effectsDescription } catch (err) {}
            foreach (clause in this.matchingEffects(fx, info.words)) sources.append(clause + " (" + a.displayName + ")")
        }
        if (sources.len() > 0) {
            text += "\n"
            foreach (src in sources) text += "\n" + src
        }
        return text
    }

    // ------------------------------------------------------------------
    // Buttons, tabs and gadgets: element name -> text key. Only while they are enabled: a
    // disabled button's native tooltip says why it is disabled, which we cannot know, so the
    // game's own tooltip is left to show it.
    // ------------------------------------------------------------------
    buttonKeys = {
        // settlement scroll
        decrease_taxation_gadget          = "TMT_DECREASE_TAXATION",
        increase_taxation_gadget          = "TMT_INCREASE_TAXATION",
        settlement_stats_button           = "SMT_SHOW_SETTLEMENT_STATS",
        building_browser_button           = "SMT_SHOW_TECH_TREE",
        garrison_info_zoom_to_button      = "SMT_ZOOM_TO_SETTLEMENT",
        settlement_info_construction_tab  = "SMT_SHOW_NEW_BUILDINGS",
        settlement_info_recruitment_tab   = "SMT_SET_TO_RECRUIT_MODE",
        settlement_info_repair_tab        = "SMT_SHOW_REPAIRABLE_BUILDINGS",
        settlement_info_retrain_tab       = "SMT_SET_TO_RETRAIN_MODE",
        // settlement details
        zoom_to_settlement_button         = "SMT_ZOOM_TO_SETTLEMENT",
        advanced_stats_show_trade_button  = "SMT_SHOW_TRADE_SUMMARY",
        advanced_stats_set_as_capital_button = "SMT_SET_AS_CAPITAL",
        // building / unit info
        destroy_building_button           = "SMT_DESTROY_BUILDING",
        unit_info_zoom_to_button          = "SMT_ZOOM_TO_UNIT",
        disband_unit_button               = "SMT_DISBAND",
        // character windows
        character_info_prev_item_cycle    = "SMT_PREV_CHARACTER",
        character_info_next_item_cycle    = "SMT_NEXT_CHARACTER",
        hire_mercenaries_button           = "SMT_OPEN_MERCENARY_RECRUITMENT",
        show_bodygaurd_unit_button        = "TMT_SHOW_GENERAL_UNIT_DETAILS",
        join_crusade_button               = "TMT_JOIN_CRUSADE",
        // faction overview
        family_tree_button                = "SMT_SHOW_FAMILY_TREE",
        faction_ranking_button            = "SMT_SHOW_FACTION_RANKINGS",
        show_college_of_cardinals_button  = "SMT_SHOW_COLLEGE_OF_CARDINALS",
        call_crusade_btn                  = "TMT_CALL_CRUSADE",
        set_heir_button                   = "SMT_SET_HEIR",
    }

    function isEnabled(e) {
        try { return e.enabled } catch (err) { return true }
    }

    // Named buttons, plus the two unnamed ones every scroll has: the close seal (58x65,
    // bottom right) and the help button (42x42, top right).
    function resolveButton(chain) {
        if (!this.style.buttons) return null
        local leafLink = chain[chain.len() - 1]
        local leaf = leafLink.e
        if (this.kids(leaf) != 0 || !this.isEnabled(leaf)) return null
        local name = this.nameOf(leaf)
        if (name != null && name in this.buttonKeys) {
            local key = this.buttonKeys[name]
            // the advice button asks about buildings or units, whichever tab is showing
            local text = this.gameText(key)
            return text != null ? ["btn:" + name, text] : null
        }
        if (name == "show_construction_advice_button") {
            local recruiting = false
            try {
                local win = chain[1].e
                local tab = this.findElement(win, "settlement_info_recruitment_tab", 6)
                recruiting = tab != null && tab.selected
            } catch (err) {}
            local text = this.gameText(recruiting ? "SMT_RECRUITMENT_ADVICE" : "SMT_BUILDING_ADVICE")
            return text != null ? ["btn:advice:" + recruiting, text] : null
        }
        if (name != null && name != "" && name != "null") {
            // Navigation buttons and tabs we have no text for: no tooltip at all rather than
            // the game's old one.
            if (this.style.quietNavigation) {
                foreach (suffix in ["_tab", "_cycle", "_button", "_btn"]) {
                    if (name.len() > suffix.len() && name.slice(name.len() - suffix.len()) == suffix)
                        return ["btn:quiet:" + name, null]
                }
            }
            return null
        }
        if (chain.len() != 3) return null     // directly under a top-level window
        local win = chain[1].e
        local rx = 0; local ry = 0; local w = 0; local h = 0; local ww = 0
        try { rx = leaf.x - win.x; ry = leaf.y - win.y; w = leaf.width; h = leaf.height; ww = win.width } catch (err) { return null }
        if (w == 58 && h == 65 && rx > ww - 80) {
            local text = this.gameText("ST_CLOSE_SCROLL")
            return text != null ? ["btn:close", text] : null
        }
        if (w == 42 && h == 42 && ry < 20 && rx > ww - 60) {
            local text = this.gameText("ST_SHOW_SCROLL_HELP")
            return text != null ? ["btn:help", text] : null
        }
        return null
    }

    // ------------------------------------------------------------------
    // Settlement scroll: construction options, construction queue, population growth row
    // ------------------------------------------------------------------
    function openSettlement() {
        try { local ss = ::ui.settlementScroll(); if (ss != null) return ss.settlement } catch (err) {}
        return null
    }

    // A building level's name as the game shows it: "<level>_<culture>" first, then "<level>".
    function buildingName(opt, settlement) {
        local levelName = opt.levelName
        local culture = null
        try { culture = ::game.cultureName(settlement.owner.cultureId) } catch (err) {}
        local keys = culture != null ? [levelName + "_" + culture, levelName] : [levelName]
        // 1. a string table that holds the building names, if this build has one
        foreach (k in keys) {
            local name = this.gameTextIn(k, ["buildings", "export_buildings", "building"])
            if (name != null) return name
        }
        // 2. the game's own text lookups
        foreach (k in keys) {
            foreach (fn in ["text", "stratText"]) {
                local out = null
                try { out = ::game[fn](k) } catch (err) {}
                if (out != null && typeof out == "string" && out != "" && out != k) return this.trim(out)
            }
        }
        // 3. the building type object
        local bt = null
        try { bt = opt.buildingType } catch (err) {}
        if (bt != null) {
            foreach (f in ["displayName", "localisedName", "levelDisplayName"]) {
                local v = null
                try { v = bt[f] } catch (err) { continue }
                local vt = typeof v
                if (vt == "string" && v != "") return v
                if (vt == "function" || vt == "native function") {
                    foreach (arg in [opt.level, levelName]) {
                        try { local r = v.call(bt, arg); if (typeof r == "string" && r != "") return r } catch (err) {}
                    }
                }
            }
        }
        if (!this.state.loggedBuildingTable) {
            this.state.loggedBuildingTable = true
            local fns = ""
            local props = ""
            try { foreach (k, v in bt) { local vt = typeof v; if (vt == "function" || vt == "native function") fns += k + " " } } catch (err) {}
            try { foreach (k, v in bt.__getTable) props += k + " " } catch (err) {}
            if (this.style.debug) println("squi: [native-tips] no building name for " + levelName + " (culture " + culture + ")")
            if (this.style.debug) println("squi: [native-tips]   BuildingType functions: " + fns)
            if (this.style.debug) println("squi: [native-tips]   BuildingType properties: " + props)
        }
        return null
    }

    function resolveSettlement(chain) {
        if (chain.len() < 3) return null
        local leaf = chain[chain.len() - 1]
        local s = null

        // The slot is the child of the named list, whatever is drawn inside it
        local parentName = ""
        local slot = null
        for (local j = chain.len() - 2; j >= 1; j--) {
            local n = this.nameOf(chain[j].e)
            if (n == "available_construction_options" || n == "construction_queue"
                || n == "available_training_options" || n == "recruitment_queue") {
                parentName = n
                slot = chain[j + 1]
                break
            }
        }
        if (slot != null) {
            s = this.openSettlement()
            if (s == null) {
                this.logList(parentName, null, chain, null)
                return null
            }
            // Only on the tab the list belongs to: the same list shows repair / retrain cards.
            local win = chain[1].e
            local recruiting = parentName == "available_training_options" || parentName == "recruitment_queue"
            local tab = this.findElement(win, recruiting ? "settlement_info_recruitment_tab" : "settlement_info_construction_tab", 7)
            local onTab = false
            try { onTab = tab != null && tab.selected } catch (err) {}
            if (!onTab) return null
            // One card per option, in order. The list can hold more cells than options (blank
            // cells, cards the game adds); then the order cannot be trusted and the game's own
            // tooltip is left in place.
            local count = -1
            try {
                if (parentName == "available_training_options") count = s.recruitmentOptions().count
                else if (parentName == "recruitment_queue") count = s.recruitmentQueueCount
                else if (parentName == "available_construction_options") count = s.constructionOptions().count
                else count = s.constructionQueueCount
            } catch (err) {}
            local listEl = null
            for (local j = chain.len() - 2; j >= 1; j--) { if (this.nameOf(chain[j].e) == parentName) { listEl = chain[j].e; break } }
            local cells = listEl != null ? this.kids(listEl) : -1
            if (count < 0 || cells != count) {
                this.logList(parentName, s, chain, listEl, count)
                return null
            }
            if (recruiting)
                return this.recruitText(s, parentName == "recruitment_queue", slot.index)
            local queued = parentName == "construction_queue"
            local opt = null
            try { opt = queued ? s.queuedConstruction(slot.index) : s.constructionOption(slot.index) } catch (err) { return null }
            if (opt == null) return null
            local name = null
            try { name = this.buildingName(opt, s) } catch (err) {}
            if (name == null) return null
            local text = name
            if (queued) {
                local left = this.fmtD(this.gameText("SMT_X_TURNS_REMAINING"), opt.turnsRemaining)
                if (left != null) text += "\n" + left
                local help = this.gameText("TMT_CONSTRUCTION_REMOVE_HELP")
                if (help != null) text += "\n" + help
            } else {
                local t = this.gameText("SMT_CONSTRUCTION_TIME")
                local turns = this.fmtD(this.gameText("SMT_X_TURNS"), opt.turnsRemaining)
                if (t != null && turns != null) text += "\n" + t + " " + turns
                local c = this.gameText("SMT_CONSTRUCTION_COST")
                local money = this.fmtD(this.gameText("ST_X_DENARI"), opt.cost)
                if (c != null && money != null) text += "\n" + c + " " + money
                local help = this.gameText("TMT_CONSTRUCTION_HELP")
                if (help != null) text += "\n" + help
            }
            return [(queued ? "queue:" : "build:") + slot.index + ":" + opt.levelName, text]
        }

        // The stats grid (4 rows x 3 columns: income, public order, population, growth).
        // Only the growth row for now: its text depends on the growth sign alone.
        if (this.kids(leaf.e) != 0) return null
        local grid = chain[chain.len() - 2].e
        if (this.kids(grid) == 13 && this.findNamed(chain[1].e, ["taxation_gadget"], 6) != null) {
            local row = (leaf.index / 3).tointeger()
            if (row != 3) return null
            s = this.openSettlement()
            if (s == null) return null
            local g = 0.0
            try { g = s.stats().populationGrowth } catch (err) { return null }
            local key = g > 0.0001 ? "TMT_GROWTH_TOOLTIP_GROWTH" : (g < -0.0001 ? "TMT_GROWTH_TOOLTIP_DECLINING" : "TMT_GROWTH_TOOLTIP_STATIC")
            local text = this.gameText(key)
            return text != null ? ["growth:" + key, text] : null
        }
        return null
    }

    // Logs a slot list's cells once, so the cell-to-option order can be worked out.
    function logList(name, s, chain, listEl, count = -1) {
        local where = (s == null ? "no settlement" : "settlement") + ":" + name
        if (where in this.state.loggedList) return
        this.state.loggedList[where] <- true
        if (s == null) {
            // A general's mercenary list: what does his army offer?
            local army = null
            try { army = this.pickCache.rec.character.army } catch (err) {}
            local info = ""
            try { info += " mercenariesAvailable=" + army.mercenariesAvailable + " (" + typeof army.mercenariesAvailable + ")" } catch (err) {}
            try { info += " canRecruitMercenaries=" + army.canRecruitMercenaries } catch (err) {}
            if (this.style.debug) println("squi: [native-tips] " + name + " without a settlement (mercenaries?)" + info)
            return
        }
        if (this.style.debug) println("squi: [native-tips] " + name + ": " + (listEl != null ? this.kids(listEl) : -1) + " cells, " + count + " options - left to the game")
        if (listEl == null) return
        for (local i = 0; i < this.kids(listEl); i++) {
            local c = this.childOf(listEl, i)
            local r = ""
            try { r = c.x + "," + c.y + " " + c.width + "x" + c.height + (c.enabled ? "" : " disabled") + " kids=" + this.kids(c) } catch (err) {}
            if (this.style.debug) println("squi: [native-tips]   cell " + i + " [" + r + "]")
        }
        for (local i = 0; i < count && i < 30; i++) {
            local n = "?"
            try {
                local o = name == "available_training_options" ? s.recruitmentOption(i)
                        : name == "recruitment_queue" ? s.queuedRecruitment(i)
                        : name == "available_construction_options" ? s.constructionOption(i) : s.queuedConstruction(i)
                if ("unitType" in o && o.unitType != null) n = o.unitType.displayName
                else if ("levelName" in o) n = o.levelName
                else if ("agentType" in o) n = "agent " + o.agentType
            } catch (err) {}
            if (this.style.debug) println("squi: [native-tips]   option " + i + " = " + n)
        }
    }

    // Agent recruitment options have no unit type: their name comes from the agent type.
    agentKeys = { [0] = "ST_SPY", [1] = "ST_ASSASSIN", [2] = "ST_DIPLOMAT", [3] = "ST_ADMIRAL", [4] = "ST_MERCHANT",
                  [5] = "ST_PRIEST", [8] = "ST_PRINCESS", [9] = "ST_HERETIC", [10] = "ST_WITCH", [11] = "ST_INQUISITOR" }

    function recruitText(s, queued, index) {
        local opt = null
        try { opt = queued ? s.queuedRecruitment(index) : s.recruitmentOption(index) } catch (err) { return null }
        if (opt == null) return null
        local name = null
        try { if (opt.unitType != null) name = opt.unitType.displayName } catch (err) {}
        if (name == null) {
            local at = -1
            try { at = opt.agentType } catch (err) {}
            if (at in this.agentKeys) name = this.gameText(this.agentKeys[at])
        }
        if (name == null || name == "") return null
        local text = name
        if (queued) {
            local left = 0
            try { left = opt.recruitTime - opt.turnsTrained } catch (err) {}
            local rem = this.fmtD(this.gameText("SMT_X_TURNS_REMAINING"), left)
            if (rem != null) text += "\n" + rem
            local help = this.gameText("TMT_CONSTRUCTION_REMOVE_HELP")
            if (help != null) text += "\n" + help
        } else {
            local c = this.gameText("SMT_RECRUITMENT_COST")
            local money = this.fmtD(this.gameText("ST_X_DENARI"), opt.cost)
            if (c != null && money != null) text += "\n" + c + " " + money
            local t = this.gameText("SMT_RECRUITMENT_TIME")
            local turns = this.fmtD(this.gameText("SMT_X_TURNS"), opt.recruitTime)
            if (t != null && turns != null) text += "\n" + t + " " + turns
            local help = this.gameText("TMT_CONSTRUCTION_HELP")
            if (help != null) text += "\n" + help
        }
        return [(queued ? "rqueue:" : "recruit:") + index + ":" + name, text]
    }

    function findElement(e, wanted, depth) {
        if (e == null) return null
        if (this.nameOf(e) == wanted) return e
        if (depth <= 0) return null
        for (local i = 0; i < this.kids(e); i++) {
            local hit = this.findElement(this.childOf(e, i), wanted, depth - 1)
            if (hit != null) return hit
        }
        return null
    }

    // ------------------------------------------------------------------
    // What is under the cursor -> [key, text] or null
    // ------------------------------------------------------------------
    function resolve(chain) {
        if (chain.len() < 2) return null
        local btn = this.resolveButton(chain)
        if (btn != null) return btn
        if (this.style.slots) {
            local place = null
            try { place = this.resolveSettlement(chain) } catch (err) {}
            if (place != null) return place
        }
        local win = chain[1].e
        local panel = this.findNamed(win, ["character_panel", "character_info_"], 5)
        if (panel == null) return null
        local kind = panel.indexof("own_") == 0 ? "own" : "other"
        local rec = null
        local winKey = win.x + "," + win.y + "," + win.width
        if (this.pickCache != null && this.pickCache.win == winKey && this.pickCache.age < 20) {
            this.pickCache.age++
            rec = this.pickCache.rec
        } else {
            // re-checked every 20 frames, so the prev / next arrows switch it too
            rec = this.characterFor(kind, win)
            this.pickCache = { win = winKey, rec = rec, age = 0 }
        }
        if (rec == null) return null

        local leaf = chain[chain.len() - 1]
        local leafName = this.nameOf(leaf.e)

        // Stat rows are named
        local stat = this.statFromName(leafName)
        if (stat == null && (leafName == null || leafName == "" || leafName == "null") && chain.len() >= 2) {
            // the unnamed label just before a named stat row: "Confidence", "Piety"...
            local next = this.childOf(chain[chain.len() - 2].e, leaf.index + 1)
            if (next != null) stat = this.statFromName(this.nameOf(next))
        }
        if (stat != null) return ["stat:" + stat, this.statText(rec, stat)]

        // [trait-rows] A long trait list overflows its column: rows past the column's own box are
        // not reported as hovered, so the hovered chain stops at the column or the box around it.
        // Then the row is found by position: the trait column under the cursor, and its row whose
        // rect holds the mouse (a list that scrolls moves its rows' rects with it).
        local geo = this.traitRowByPosition(leaf.e, chain, rec)
        if (geo != null) {
            local traits = this.traitsForRows(rec, geo.rows)
            local t = null
            if (!this.lastRowsExact) t = this.traitByRowText(rec, geo.row)
            if (t == null && geo.index < traits.len()) t = traits[geo.index]
            if (t != null) return ["trait:" + geo.index, this.traitText(t)]
            this.traitMiss("row " + geo.index + " of " + traits.len() + " traits (by position)", chain)
            return null
        }

        // Traits and ancillaries: two columns under one container.
        // leaf = row, parent = column, grandparent = container with the two columns.
        if (chain.len() < 4) { this.traitMiss("chain " + chain.len(), chain); return null }
        local column = chain[chain.len() - 2]
        local container = chain[chain.len() - 3].e
        if (this.kids(leaf.e) != 0) { this.traitMiss("leaf has " + this.kids(leaf.e) + " children", chain); return null }
        local rowH = 0
        try { rowH = leaf.e.height } catch (err) {}
        // [trait-rows] A long list gets a scroll bar, which can sit in the container beside the two
        // columns: so the trait column is known by its rows (short, childless), not by the
        // container having exactly two children or the column being child 1.
        local traitCol = rowH > 0 && rowH < 20 && this.kids(column.e) > 0 && this.kids(container) >= 2
                         && this.rowsFitTraits(rec, this.kids(column.e))
        if (!traitCol && this.kids(container) != 2) { this.traitMiss("container has " + this.kids(container) + " children", chain); return null }

        if ((column.index == 1 || traitCol) && rowH > 0 && rowH < 20 && this.rowsFitTraits(rec, this.kids(column.e))) {
            local traits = this.traitsForRows(rec, this.kids(column.e))   // [trait-rows]
            // No reading of his traits has the window's row count: the rows are matched by name
            // where the window gives its row text, as the order cannot be trusted either.
            if (!this.lastRowsExact) {
                local t = this.traitByRowText(rec, leaf.e)
                if (t != null) return ["trait:" + leaf.index, this.traitText(t)]
            }
            if (leaf.index < traits.len()) return ["trait:" + leaf.index, this.traitText(traits[leaf.index])]
            this.traitMiss("row " + leaf.index + " of " + traits.len() + " traits", chain)
            return null
        }
        if (rowH >= 20 && rowH < 30) this.traitMiss("row height " + rowH, chain)
        if (column.index == 0 && rowH >= 30) {
            local n = 0
            try { n = rec.ancillaryCount } catch (err) {}
            if (leaf.index < n) {
                local a = null
                try { a = rec.getAncillary(leaf.index) } catch (err) {}
                if (a != null) return ["anc:" + leaf.index, this.ancillaryText(a)]
            }
        }
        return null
    }

    // [trait-rows] Whether a list of `rows` rows can be this character's traits: no fewer than his
    // visible traits, no more than all of them - so a stats grid of short rows is not taken for it.
    function rowsFitTraits(rec, rows) {
        local all = 0
        try { all = rec.traitCount } catch (err) { return false }
        return rows >= this.visibleTraits(rec).len() && rows <= all
    }

    // [trait-rows] The trait column: a child list of short (< 20), childless rows. Looks at e itself
    // and a few levels under it.
    function isTraitColumn(e) {
        local n = this.kids(e)
        if (n < 1) return false
        for (local i = 0; i < n; i++) {
            local r = this.childOf(e, i)
            local h = 0
            try { h = r.height } catch (err) {}
            if (h <= 0 || h >= 20 || this.kids(r) != 0) return false
        }
        return true
    }

    function findTraitColumn(e, depth) {
        if (e == null || depth < 0) return null
        if (this.isTraitColumn(e) && this.kids(e) >= 3) return e
        for (local i = 0; i < this.kids(e); i++) {
            local hit = this.findTraitColumn(this.childOf(e, i), depth - 1)
            if (hit != null) return hit
        }
        return null
    }

    // When the chain stops at the trait column or a box holding it (not at a row): the row under
    // the mouse by its screen rect -> { index, row, rows }, or null.
    function traitRowByPosition(leafEl, chain, rec) {
        if (this.kids(leafEl) == 0) return null          // the chain reached a row: the normal path
        local col = this.findTraitColumn(leafEl, 3)
        if (col == null || !this.rowsFitTraits(rec, this.kids(col))) return null
        local m = null
        try { m = ::UI.mouse.pos() } catch (err) { return null }
        local cx = 0; local cw = 0
        try { cx = col.screenX; cw = col.screenWidth } catch (err) { return null }
        if (m[0] < cx || m[0] >= cx + cw) return null
        local n = this.kids(col)
        local found = null
        local firstY = null; local lastY = null
        for (local i = 0; i < n; i++) {
            local r = this.childOf(col, i)
            local y = 0; local h = 0
            try { y = r.screenY; h = r.screenHeight } catch (err) { continue }
            if (i == 0) firstY = y
            lastY = y + h
            if (found == null && m[1] >= y && m[1] < y + h) found = { index = i, row = r, rows = n }
        }
        this.logRowGeometry(col, n, firstY, lastY, m, found)
        return found
    }

    // Once per window size: where the trait column and its rows are, against the mouse.
    function logRowGeometry(col, n, firstY, lastY, m, found) {
        if (!this.style.debug) return
        local key = n + ":" + firstY + ":" + lastY
        if (key in this.state.loggedGeo || this.state.loggedGeo.len() > 6) return
        this.state.loggedGeo[key] <- true
        local r = "?"
        try { r = col.screenX + "," + col.screenY + " " + col.screenWidth + "x" + col.screenHeight } catch (err) {}
        if (this.style.debug) println("squi: [native-tips] trait column " + n + " rows @ " + r + ", rows span y " + firstY + ".." + lastY
                + ", mouse " + m[0] + "," + m[1] + " -> " + (found != null ? "row " + found.index : "no row"))
    }

    // [trait-rows] Why a hovered piece of a character window got no tooltip - logged once per reason
    // and place, with the rects involved, so a window that lays its rows out differently shows up.
    function traitMiss(reason, chain) {
        if (!this.style.debug) return
        local path = ""
        foreach (i, link in chain) { if (i > 0) path += "." + link.index }
        local key = reason + "@" + path
        if (key in this.state.loggedMiss || this.state.loggedMiss.len() > 30) return
        this.state.loggedMiss[key] <- true
        local rects = ""
        for (local i = chain.len() - 1; i >= 1 && i >= chain.len() - 3; i--) {
            local e = chain[i].e
            local r = "?"
            try { r = e.screenX + "," + e.screenY + " " + e.screenWidth + "x" + e.screenHeight } catch (err) {}
            rects += " [" + this.nameOf(e) + " #" + chain[i].index + " kids " + this.kids(e) + " @ " + r + "]"
        }
        local m = [0, 0]
        try { m = ::UI.mouse.pos() } catch (err) {}
        if (this.style.debug) println("squi: [native-tips] no tooltip (" + reason + ") at " + path + ", mouse " + m[0] + "," + m[1] + ":" + rects)
    }

    // ------------------------------------------------------------------
    // Diagnostic: can M2EX hand us the game's own tooltip text? Logged once per new piece.
    // ------------------------------------------------------------------
    function probe(chain) {
        if (!this.style.debug) return
        if (!this.style.probeNative || this.state.probeCount >= 60 || chain.len() < 2) return
        local path = "root"
        foreach (i, link in chain) { if (i > 0) path += "." + link.index }
        if (path == this.state.probeKey) return
        this.state.probeKey = path
        this.state.probeCount++
        local leaf = chain[chain.len() - 1].e
        local r = ""
        try { r = leaf.x + "," + leaf.y + " " + leaf.width + "x" + leaf.height } catch (err) {}
        if (this.style.debug) println("squi: [native-tips] probe " + path + " \"" + this.nameOf(leaf) + "\" [" + r + "]")
        local f = null
        try { f = ::UI.tooltipContent } catch (err) {}
        if (f == null) return
        local tries = [["()", []], ["(leaf)", [leaf]], ["(\"\")", [""]], ["(0)", [0]]]
        foreach (t in tries) {
            local label = t[0]
            local args = t[1]
            try {
                local out = args.len() == 0 ? f.call(::UI) : f.call(::UI, args[0])
                if (this.style.debug) println("squi: [native-tips]   tooltipContent" + label + " = " + (typeof out) + " " + out)
            } catch (err) {
                local msg = "" + err
                if (!(label in this.state.probeErrors)) {
                    this.state.probeErrors[label] <- true
                    if (this.style.debug) println("squi: [native-tips]   tooltipContent" + label + " failed: " + msg)
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // The game's own tooltip on / off (same switch as the battle tooltips)
    // ------------------------------------------------------------------
    function muteNative(on) {
        if (!this.style.muteNative || on == this.state.muted) return
        local lua = @"
local want = " + (on ? "false" : "true") + @"
for _, name in ipairs({'getOptions1', 'getOptions2'}) do
  local get = M2TWEOP and M2TWEOP[name]
  local o = get and get()
  if o ~= nil then
    local ok, cur = pcall(function() return o.showToolTips end)
    if ok and cur ~= nil then
      if type(cur) == 'boolean' then o.showToolTips = want else o.showToolTips = want and 1 or 0 end
      return 'native-tips set ' .. name
    end
  end
end
return 'native-tips none'
"
        local out = ""
        try { out = "" + ::UI.eval("lua", lua) } catch (err) { out = "error " + err }
        if (out.indexof("none") != null || out.indexof("rror") != null) {
            println("squi: [native-tips] could not switch the game's tooltips (" + out + "); muteNative off")
            this.style.muteNative = false
            this.state.muted = false
            return
        }
        this.state.muted = on
    }

    // ------------------------------------------------------------------
    // Per frame
    // ------------------------------------------------------------------
    function update() {
        this.tipText = null
        this.hitActive = false
        if (!this.style.enabled) { this.muteNative(false); return }

        local over = false
        try { over = ::UI.cursorOverGameUi() } catch (err) {}
        local rootEl = over ? this.root() : null
        if (rootEl == null) {
            this.state.lastKey = ""
            this.state.still = 0
            this.muteNative(false)
            return
        }

        local chain = this.hoveredChain(rootEl)
        try { this.probe(chain) } catch (err) {}
        local hit = this.resolve(chain)
        if (hit == null) {
            if (this.state.grace > 0 && chain.len() >= 2) {
                this.state.grace--
                this.hitActive = true
                this.tipText = this.state.lastText
                return
            }
            this.state.lastKey = ""
            this.state.lastText = null
            this.state.still = 0
            this.muteNative(false)
            return
        }
        this.state.grace = this.style.graceFrames

        this.hitActive = true
        this.muteNative(true)
        if (hit[0] != this.state.lastKey) {
            this.state.lastKey = hit[0]
            this.state.still = 0
            if (this.style.debug) println("squi: [native-tips] " + hit[0] + " -> " + hit[1])
        }
        this.state.still++
        if (this.state.still >= this.style.delayFrames) {
            this.tipText = hit[1]
            this.state.lastText = hit[1]
        }
    }

    function render() {
        if (this.state.down) return
        try {
            this.update()
            local onButton = this.state.lastKey.indexof("btn:") == 0
            if (onButton && !this.style.ghostOnButtons) {
                this.tipText = null
            } else if (this.hitActive && this.style.ghostNative && "ghostStyle" in ::EX) {
                local m = ::UI.mouse.pos()
                local pad = this.style.ghostPad
                ::UI.pushStyle(::EX.ghostStyle())
                ::UI.tooltipAt(m[0] - pad, m[1] - pad, pad * 2 + 1, pad * 2 + 1)
                ::UI.tooltip(0, " ")
                ::UI.popStyle()
            }
            if (this.tipText != null && "drawTip" in ::EX) {
                local look = ("stratTooltips" in ::EX && ::EX.stratTooltips != null) ? ::EX.stratTooltips.style : null
                local bg = look != null && "background" in look ? look.background : [0, 0, 0, 160]
                local edge = look != null && "border" in look ? look.border : [255, 245, 139, 255]
                local ink = look != null && "ink" in look ? look.ink : [255, 245, 139, 255]
                ::EX.drawTip(this.tipText, bg, edge, ink)
            }
            this.state.strikes = 0
        } catch (err) {
            this.state.strikes++
            if (this.state.strikes >= 8) {
                this.state.down = true
                try { this.muteNative(false) } catch (e2) {}
                println("squi: [native-tips] STOOD DOWN - " + err)
            }
        }
    }
}

local nativeTooltips = NativeTooltips()

::events.on("ScrollOpened", function(p) { nativeTooltips.pickCache = null; nativeTooltips.captureCharacter() })
::events.on("ScrollClosed", function(p) { nativeTooltips.pickCache = null })

local nativeTooltipsCanvas = ::UI.canvas("##native_tooltips_canvas", 0, 0, 4, 4)
::UI.setWidgetStyle(nativeTooltipsCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(nativeTooltipsCanvas, function() { nativeTooltips.render() })

::EX.nativeTooltips <- nativeTooltips
