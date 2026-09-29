// ============================================================================================
// [ui-look] Font and size of the HD map labels and tooltips. The HUD itself is NOT resized.
// ============================================================================================

// [montserrat] The UI font, from data/fonts, loaded here while the scripts start up (a font first
// loaded mid-game can come back as a handle that draws nothing). Each weight tries its files in
// order and takes the first that loads; the console says which it got. No test-measure here:
// the font system is not ready this early, and a measure now fails for every font.
local lookLoad = function (files, last) {
    foreach (file in files) {
        local f = null
        try { f = ::UI.loadFont("fonts/" + file) } catch (e) { f = null }
        local ok = f != null && f != 0
        if (ok) return f
    }
    return last
}
local lookFace  = lookLoad(["Montserrat-Regular.ttf", "roboto.regular.ttf"], "tnr")
local lookTitle = lookLoad(["Montserrat-SemiBold.ttf", "roboto.medium.ttf"], lookFace)
// [tip-rich] Descriptions in italic, tooltip headings in the settlement-name face. Either one
// missing just falls back (italic -> regular, heading -> SemiBold); the console says which loaded.
local lookItalic  = lookLoad(["Montserrat-Italic.ttf", "Montserrat-LightItalic.ttf", "roboto.italic.ttf"], lookFace)
local lookDisplay = lookLoad(["constantine.regular.ttf"], lookTitle)

::EX.look <- {
    // Face for labels, HUD text and tooltips. "tnr" gives the plain face the character name
    // plates showed before (the game resolves it to Verdana). null = leave M2EX's fonts alone.
    face = lookFace,   // Montserrat Regular (was "tnr", then Roboto Regular)

    // [montserrat] Headings (::EX.fonts.title, the event scroll's title) and the bold parts of
    // the campaign tooltips. null = the face above.
    titleFace = lookTitle,   // Montserrat SemiBold

    // Campaign tooltips: the first line (the name) in titleFace when the tooltip has more than one
    // line, and a short "Label:" at the start of a line in titleFace with the value after it.
    tooltipBoldTitle  = true,
    tooltipBoldLabels = true,

    // Settlement, character and fort labels, against M2EX's size (1.0). 0.75 = three quarters.
    labelScale = 0.75,

    // Tooltips (campaign map and battle), against the text size below (1.0).
    tooltipScale = 0.8,
    // [tip-battle-size] Battle tooltips only (HUD buttons, the plain unit box, the hover label),
    // against tooltipScale: 1.0 = the same size as the campaign's. Set from the X menu in battle, so
    // resizing them there no longer changes the campaign map's tooltips.
    battleTooltipScale = 1.0,

    // Tooltip layout in 1080p units; the screen resolution and tooltipScale are applied on top.
    tooltipFontSize = 15,   // [montserrat] was 16; Montserrat runs about a tenth wider than Roboto
    tooltipPad      = 6,
    tooltipBorder   = 1,
    tooltipLineGap  = 2,
    tooltipOffsetX  = 24,   // below-right placement (the old default, and the fallback near the top edge)
    tooltipOffsetY  = 30,

    // [tip-place] Where the tooltip sits against the cursor. true = above and to the right, so it
    // stays clear of the labels under and beside what is hovered; false = the old below-right.
    tooltipAbove    = true,
    // [tip-place] Above-right: the gap from the cursor's point to the box's lower-left corner.
    tooltipAboveX   = 18,
    tooltipAboveY   = 14,

    // Longest tooltip line in 1080p units before it wraps onto the next line (0 = never wrap).
    // M2EX's own battle tooltips wrap at 280; the campaign map's long resource text needs more.
    tooltipWrapWidth = 420,

    // ---------------------------------------------------------------------------------------
    // [tip-rich] The styled tooltip: a heading per entry, italic descriptions, a rule between
    // entries, muted click hints, and a framed, shadowed box. false = the old plain box.
    tooltipRich = true,

    italicFace       = lookItalic,    // descriptions and subtitles
    tooltipTitleFace = lookDisplay,   // entry headings (Constantine, as the settlement names)

    // Sizes against tooltipFontSize, and spacing in 1080p units.
    tooltipTitleScale = 1.2,
    tooltipHintScale  = 0.9,
    tooltipPadX       = 11,
    tooltipPadY       = 8,
    tooltipTitleGap   = 3,    // heading -> its first line
    tooltipSectionGap = 10,   // between entries; the rule sits in the middle of it

    // Colours [r, g, b] or [r, g, b, a].
    tipBgTop     = [38, 30, 20, 238],     // the box fades from this at the top...
    tipBgBottom  = [12, 10, 8, 238],      // ...to this at the bottom
    tipHeader    = [201, 164, 88, 30],    // wash behind the first heading
    tipEdge      = [201, 164, 88, 255],   // outer frame
    tipEdgeInner = [201, 164, 88, 70],    // the thin inner frame, a few px inside
    tipCorner    = [255, 222, 140, 255],  // corner brackets
    tipRule      = [201, 164, 88, 110],   // rule between entries
    tipTitle     = [255, 214, 120],       // headings
    tipBody      = [236, 226, 200],       // plain lines
    tipDesc      = [208, 196, 168],       // italic descriptions
    tipLabel     = [255, 214, 120],       // the "Label:" part of a "Label: value" line
    tipWarn      = [238, 118, 90],        // siege countdowns, blockades
    tipHint      = [168, 158, 132],       // "Left-click to select"

    // The diplomatic stance after a heading, coloured by how things stand.
    tipStance = { allied = [120, 205, 110], suspicious = [228, 200, 90], neutral = [190, 184, 168],
                  hostile = [238, 150, 60], war = [232, 78, 60] },

    // [tip-tone] Trait and ancillary effects: each value in the text ("+1", "-3", "10%") drawn
    // green when it helps the holder and red when it hurts; the rest of the line stays tipBody.
    // See ::EX.effectTone for the rules.
    tipTone       = true,                 // false = effect lines drawn as before
    tipGood       = [128, 204, 104],
    tipBad        = [226, 98, 82],
    // [tip-fx] The effects block: a gap above "Effects:", and when there is more than one effect,
    // each on its own line under it, in line with "Effects:".
    tipEffectsGap = 6,                    // 1080p units, above "Effects:"
    // [tip-epithet] "Epithet: the Wise" is set apart below the effects: a gap, "Epithet:" in gold,
    // and the epithet capitalised on its own line beneath ("The Wise") in the heading face.
    // The label words it is found by, lowercase (add a mod's own language here).
    tipEpithetWords = ["epithet"],
    tipEpithetGap   = 8,                  // 1080p units, above "Epithet:"
    // [tip-title] A one-line tooltip up to this many characters, not ending in a full stop, is a
    // name and gets the heading face (unit names with their "(men/max)" count run long).
    tipTitleMaxLen  = 64,

    // Effects.
    tipShadow      = true,   // soft drop shadow under the box
    tipShadowSize  = 5,
    tipGradient    = true,   // top-to-bottom fade (tipBgTop -> tipBgBottom); false = tipBgBottom flat
    tipInnerFrame  = true,
    tipCorners     = true,   // gold brackets at the corners
    tipCornerSize  = 9,
    tipTextShadow  = true,   // a 1px dark shadow under all tooltip text

    // ---------------------------------------------------------------------------------------
    // [hud-scale] Size of the MINIMAL battle HUD (command bar, formations, radar column).
    // The game lays it out on a 1024x768 screen stretched to yours in width and height apart, so on
    // a wide screen everything is a third wider than tall, and on a 4K screen very large. With a
    // scale set it is sized from the screen height alone (no stretch), times this; the bar stays
    // centred along the top and the radar column in the top-right corner.
    //   0.75 = three quarters of the game's height   1.0 = the game's height, unstretched
    //   0    = the game's own stretched layout, as before
    battleMinimalScale = 0.75,
    // [hud-full] Size of the FULL battle HUD in its compact restyle: the radar, speed controls and
    // strength bar gathered into one gilded block in the bottom-left corner, the command ring into
    // another in the bottom-right, and the unit cards moved in beside the radar - all sized from
    // the screen height, times this.
    //   0.75 = three quarters of M2EX's full HUD   1.0 = its own size, still compact
    //   0    = M2EX's own full layout, exactly as before
    battleFullScale = 0.75,

    // [radar-size] The radar (map and its controls) against the HUD it sits in, on both HUDs:
    // 1.0 = in step with the HUD size above, 1.2 = a fifth larger. Also in the X menu.
    battleRadarScale = 1.0,

    // [mini-layout] Where the MINIMAL HUD's parts sit (restyle on; with it off, the game's places):
    battleMiniBar       = "bottomRight",   // command bar: "bottomRight" corner, or "top" centre (the game's)
    battleMiniRadar     = "bottomRight",   // radar: "bottomRight", stacked above the command bar, or "top"
    battleRadarControls = "below",         // radar controls: "below" the map, or "left" of it (the game's)
    battleMiniMargin    = 4,               // 1080p units the corner blocks keep from the screen edges

    // [restyle] false = the battle HUD, radar, unit cards and unit tooltip drawn as the mod draws
    // them (its button art, M2EX's own layouts, the game's tooltips). Switched in battle from the X
    // menu, which remembers the choice.
    restyle = true,
}

// [restyle] Whether the battle restyle is on.
::EX.restyled <- function() {
    return !("look" in ::EX) || !("restyle" in ::EX.look) || ::EX.look.restyle
}

// [tip-battle-size] The tooltip size factor right now: tooltipScale, times battleTooltipScale
// while a battle is on screen.
::EX.tipScale <- function() {
    local look = ::EX.look
    local k = look.tooltipScale
    try {
        if ("battleTooltipScale" in look
            && (::UI.context() & (::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded))) {
            k = k * look.battleTooltipScale
        }
    } catch (e) {}
    return k
}

// The size multiplier a label module applies on top of the screen-resolution scale.
::EX.labelScale <- function() {
    return "look" in ::EX && ::EX.look.labelScale > 0 ? ::EX.look.labelScale : 1.0
}

// Points M2EX's shared font table at the chosen face; every label and HUD module reads it.
::EX.applyLook <- function() {
    local face = ::EX.look.face
    if (face == null || !("fonts" in ::EX)) {
        return
    }
    local title = "titleFace" in ::EX.look && ::EX.look.titleFace != null ? ::EX.look.titleFace : face
    foreach (key in ["body", "title", "petrock"]) {
        if (key in ::EX.fonts) {
            try { ::EX.fonts[key] = key == "title" ? title : face } catch (e) {}
        }
    }
}

// [montserrat] "Income: 1,200" -> ["Income:", " 1,200"]; only a short label at the start of a line
// counts, so sentences with a colon in them are left whole.
::EX.splitLabel <- function(text) {
    local at = text.indexof(": ")
    // [tip-fx] a short label alone on its line ("Effects:") counts too, with nothing after it
    if (at == null && text.len() >= 3 && text.len() <= 21 && text[text.len() - 1] == ':') return [text, ""]
    if (at == null || at < 2 || at > 20) return null
    return [text.slice(0, at + 1), text.slice(at + 1)]
}

// Breaks one line into lines no wider than maxW, at spaces. A line's leading indent is kept on
// every piece it wraps into, so indented lists stay indented. A single word wider than maxW
// is left whole rather than cut.
::EX.wrapLine <- function(line, face, size, maxW) {
    if (maxW <= 0 || line == "") return [line]
    local whole = ::UI.textSize(line, face, size)
    if (whole == null || whole[0] <= maxW) return [line]

    local indent = ""
    while (indent.len() < line.len() && line[indent.len()] == ' ') indent += " "
    local out = []
    local current = indent
    foreach (word in line.slice(indent.len()).split(" ")) {
        if (word == "") continue
        local trial = current == indent ? indent + word : current + " " + word
        local m = ::UI.textSize(trial, face, size)
        if (m != null && m[0] > maxW && current != indent) {
            out.append(current)
            current = indent + word
        } else {
            current = trial
        }
    }
    out.append(current)
    return out
}

// A style that makes the engine's own tooltip draw nothing at all. The tooltip modules still
// raise it at the cursor with this pushed: while an HD tooltip is up the game keeps its native
// tooltip hidden, so skipping the call entirely let the native unit tooltip show beside ours.
::EX.ghostStyle <- function() {
    return { [::UI.Surface.tooltip]       = [0, 0, 0, 0],
             [::UI.Colour.tooltipText]    = [0, 0, 0, 0],
             [::UI.Colour.tooltipBorder]  = [0, 0, 0, 0],
             [::UI.Metric.borderTooltip]  = 0 }
}

// [tip-place] Where a boxW x boxH tooltip goes: above and right of the cursor by default
// (look.tooltipAbove), else below and right; flipped to the other side of the cursor when it
// would run off the screen, and never left hanging off it. Returns [x, y].
::EX.tipPlaceWith <- null   // [tip-place] a module's own placement, function(boxW, boxH, k) -> [x, y] or null
::EX.tipPlace <- function(boxW, boxH, k) {
    if (::EX.tipPlaceWith != null) {
        local own = null
        try { own = ::EX.tipPlaceWith(boxW, boxH, k) } catch (e) { own = null }
        if (own != null) return own
    }
    local look = ::EX.look
    local mouse = ::UI.mouse.pos()
    local screen = ::UI.screenSize()
    local offX = (look.tooltipOffsetX * k + 0.5).tointeger()
    local offY = (look.tooltipOffsetY * k + 0.5).tointeger()
    local x = 0
    local y = 0
    if ("tooltipAbove" in look && look.tooltipAbove) {
        local upX = ((("tooltipAboveX" in look) ? look.tooltipAboveX : 18) * k + 0.5).tointeger()
        local upY = ((("tooltipAboveY" in look) ? look.tooltipAboveY : 14) * k + 0.5).tointeger()
        x = mouse[0] + upX
        y = mouse[1] - upY - boxH
        if (x + boxW > screen[0]) x = mouse[0] - upX - boxW   // too far right: go left of the cursor
        if (y < 0) y = mouse[1] + offY                        // too near the top: drop below it
    } else {
        x = mouse[0] + offX
        y = mouse[1] + offY
        if (x + boxW > screen[0]) x = mouse[0] - offX - boxW
        if (y + boxH > screen[1]) y = mouse[1] - boxH - offY / 4
    }
    if (x + boxW > screen[0]) x = screen[0] - boxW
    if (y + boxH > screen[1]) y = screen[1] - boxH
    if (x < 0) x = 0
    if (y < 0) y = 0
    return [x, y]
}

// ============================================================================================
// [tip-rich] The styled tooltip.
//
// A tooltip is a list of ENTRIES (sections), one per thing under the cursor - a settlement, a
// resource, a road, the click hints - each drawn as a heading and its lines, with a rule and a
// gap between entries:
//   { title = "Quarry" or null,
//     tag   = { text = "At War", stance = "war" } or null,     // coloured, after the heading
//     lines = [ { text = "...", kind = "desc" }, ... ] }
// Line kinds: "body" plain, "desc" italic description, "sub" italic subtitle, "label" a
// "Label: value" line with the label in gold SemiBold, "warn" a warning in red, "hint" a muted
// click hint in a smaller italic.
// ============================================================================================

// A colour as [r, g, b, a], whichever length it was given in.
::EX.tipRgba <- function(c, alpha = 255) {
    return c.len() > 3 ? c : [c[0], c[1], c[2], alpha]
}

// Plain tooltip text as entries, for callers that only have a string (the HUD buttons, the unit
// cards): the first line is the heading when there are several, "Name - description" splits into
// heading and italic description, "Label: value" lines keep a gold label, and lines that talk
// about clicking become hints in an entry of their own.
// [tip-rich] "Name - description" or "Name: description" -> [name, description], split at the
// earliest of those within the first 40 characters; null when there is none, or nothing after it.
::EX.tipSplitName <- function(text) {
    local best = null
    local cut = 0
    foreach (sep in [" - ", ": "]) {
        local at = text.indexof(sep)
        if (at != null && at > 0 && at < 40 && (best == null || at < best)) {
            best = at
            cut = sep.len()
        }
    }
    if (best == null) return null
    local rest = text.slice(best + cut)
    while (rest.len() > 0 && rest[0] == ' ') rest = rest.slice(1)
    return rest != "" ? [text.slice(0, best), rest] : null
}

// [tip-tone] Which numbers in a trait or ancillary effect help or hurt the holder, so the tooltip
// can colour each one green or red in the text itself. A line is cut into clauses at "," ";" "."
// and each number is judged on its own, so "+1 to Law, -1 from popularity" gets one of each.
// Mod-agnostic: a signed number ("+1", "-3") is judged by its sign, in any language. An unsigned
// percentage ("3% bonus on trade income") is judged by the words of its clause, and a "less is
// better" stat flips the result ("-5% unrest" is good). Words inside "(...)" are ignored, so
// "(reduces public order)" does not decide anything. The word lists are English; add a mod's
// own words to them as needed.
local EffectTone = class {
    // Stats where a lower number helps the holder. Matched lowercase, before any "(...)".
    lowerIsBetter = ["unrest", "corruption", "squalor", "cost", "upkeep", "disease",
                     "plague", "revolt", "unhappiness", "chance of death"]

    // Decide an unsigned percentage ("Bonus of 10% on Tax Income").
    goodWords = ["bonus", "increase", "improve", "extra"]
    badWords  = ["penalty", "malus", "decrease", "reduce", "loss", "lose"]

    function isDigit(c) {
        return c >= '0' && c <= '9'
    }

    function wordSign(lower) {
        foreach (w in this.goodWords) if (lower.indexof(w) != null) return 1
        foreach (w in this.badWords)  if (lower.indexof(w) != null) return -1
        return 0
    }

    // The number inside one word: "+1", "-3,", "(+2", "10%" -> { a, b, sign } marking the part to
    // colour (sign 0 for an unsigned percentage), or null. A bare "1" or a year is not a value.
    function numberCore(w) {
        local n = w.len()
        local i = 0
        while (i < n && w[i] == '(') i++
        if (i >= n) return null
        local st = i
        local sign = 0
        if ((w[i] == '+' || w[i] == '-') && i + 1 < n && this.isDigit(w[i + 1])) {
            sign = w[i] == '+' ? 1 : -1
            i++
        }
        if (!this.isDigit(w[i])) return null
        local nonzero = false
        while (i < n && (this.isDigit(w[i]) || w[i] == '.')) {
            if (w[i] != '0' && w[i] != '.') nonzero = true
            i++
        }
        while (i > st && w[i - 1] == '.') i--          // "+2." -> "+2"
        local pct = i < n && w[i] == '%'
        if (pct) i++
        if (!nonzero || (sign == 0 && !pct)) return null
        return { a = st, b = i, sign = sign, tone = null }
    }

    function endsClause(w) {
        local c = w[w.len() - 1]
        return c == ',' || c == ';' || c == '.'
    }

    // Judges the numbers in words[i..j], one clause.
    function judge(words, i, j) {
        local head = ""
        for (local q = i; q <= j; q++) {
            if (words[q].text[0] == '(') break
            head += " " + words[q].text
        }
        local lower = head.tolower()
        local flip = 1
        foreach (w in this.lowerIsBetter) {
            if (lower.indexof(w) != null) { flip = -1; break }
        }
        local ws = this.wordSign(lower)
        for (local q = i; q <= j; q++) {
            local c = words[q].core
            if (c == null) continue
            local s = c.sign != 0 ? c.sign : ws
            if (s != 0) c.tone = s * flip > 0 ? "good" : "bad"
        }
    }

    // One line as words: [{ text, core }], core.tone "good" / "bad" / null for each number.
    function words(text) {
        local out = []
        foreach (t in text.split(" ")) {
            if (t != "") out.append({ text = t, core = this.numberCore(t) })
        }
        local i = 0
        while (i < out.len()) {
            local j = i
            while (j < out.len() - 1 && !this.endsClause(out[j].text)) j++
            this.judge(out, i, j)
            i = j + 1
        }
        return out
    }

    function hasTone(text) {
        foreach (w in this.words(text)) {
            if (w.core != null && w.core.tone != null) return true
        }
        return false
    }

    // Words that share a row, as text spans: [{ text, tone }], neighbours of one colour merged.
    function segments(group) {
        local out = []
        foreach (wi, w in group) {
            local parts = []
            if (wi > 0) parts.append({ text = " ", tone = null })
            local c = w.core
            if (c == null || c.tone == null) {
                parts.append({ text = w.text, tone = null })
            } else {
                if (c.a > 0) parts.append({ text = w.text.slice(0, c.a), tone = null })
                parts.append({ text = w.text.slice(c.a, c.b), tone = c.tone })
                if (c.b < w.text.len()) parts.append({ text = w.text.slice(c.b), tone = null })
            }
            foreach (p in parts) {
                local last = out.len() > 0 ? out[out.len() - 1] : null
                if (last != null && last.tone == p.tone) last.text += p.text
                else out.append(p)
            }
        }
        return out
    }

    // [tip-fx] The separate effects in one line: split at commas and semicolons outside "(...)",
    // but only where the piece after the split carries a value of its own - so "+1 Loyalty, +1 Law,
    // -5% malus on tax income" is three effects while a sentence with a comma in it stays whole.
    function items(text) {
        local pieces = []
        local depth = 0
        local start = 0
        local n = text.len()
        for (local i = 0; i < n; i++) {
            local c = text[i]
            if (c == '(') depth++
            else if (c == ')' && depth > 0) depth--
            else if ((c == ',' || c == ';') && depth == 0 && i + 1 < n && text[i + 1] == ' ') {
                pieces.append(text.slice(start, i))
                start = i + 2
            }
        }
        pieces.append(text.slice(start))
        local out = []
        foreach (raw in pieces) {
            local p = this.trim(raw)
            if (p == "") continue
            if (out.len() > 0 && !this.hasTone(p)) out[out.len() - 1] += ", " + p
            else out.append(p)
        }
        // "+1 Command." -> "+1 Command": a value's full stop is dropped, a sentence keeps its own
        foreach (i, p in out) {
            if (p.len() > 1 && p[p.len() - 1] == '.' && this.hasTone(p) && p.indexof(". ") == null) {
                out[i] = p.slice(0, p.len() - 1)
            }
        }
        return out
    }

    // Leading and trailing spaces, and a trailing comma or semicolon, removed.
    function trim(text) {
        local t = text
        local again = true
        while (again) {
            again = false
            while (t.len() > 0 && (t[0] == ' ' || t[0] == '\t')) t = t.slice(1)
            // the mod's own bullet ("* ", "- ", or a UTF-8 bullet or middle dot) - each effect has its own line instead
            if (t.len() > 1 && (t[0] == '*' || t[0] == '-') && t[1] == ' ') { t = t.slice(2); again = true }
            else if (t.len() >= 3 && (t[0] & 0xFF) == 0xE2 && (t[1] & 0xFF) == 0x80 && (t[2] & 0xFF) == 0xA2) { t = t.slice(3); again = true }
            else if (t.len() >= 2 && (t[0] & 0xFF) == 0xC2 && (t[1] & 0xFF) == 0xB7) { t = t.slice(2); again = true }
        }
        while (t.len() > 0) {
            local c = t[t.len() - 1]
            if (c != ' ' && c != '\t' && c != ',' && c != ';') break
            t = t.slice(0, t.len() - 1)
        }
        return t
    }

    // Which lines of a tooltip are effect lines, in order. With a labelled line ("Effects:", in
    // whatever language), it and the lines after it; without one (SSHIP's "5% bonus on all trade
    // income, +2 to law"), any line with a value to colour - so plain descriptions stay plain.
    function effectLines(lines) {
        local labelled = false
        foreach (raw in lines) {
            if (::EX.splitLabel(raw) != null) { labelled = true; break }
        }
        local out = []
        local inEffects = false
        foreach (raw in lines) {
            if (!labelled) {
                out.append(this.hasTone(raw))
                continue
            }
            if (!inEffects && ::EX.splitLabel(raw) != null) inEffects = true
            out.append(inEffects)
        }
        return out
    }
}
::EX.effectTone <- EffectTone()

// [tip-epithet] "Epithet: the Wise" -> the epithet line { text, kind = "epithet", label, value =
// "The Wise" }, or null for any other line.
::EX.tipEpithet <- function(raw) {
    local look = ::EX.look
    if (!("tipEpithetWords" in look)) return null
    local cut = ::EX.splitLabel(raw)
    if (cut == null) return null
    local label = cut[0].tolower()
    local hit = false
    foreach (w in look.tipEpithetWords) {
        if (label.indexof(w) == 0) hit = true
    }
    if (!hit) return null
    local value = cut[1]
    while (value.len() > 0 && value[0] == ' ') value = value.slice(1)
    if (value == "") return null
    if (value[0] >= 'a' && value[0] <= 'z') value = value.slice(0, 1).toupper() + value.slice(1)
    return { text = raw, kind = "epithet", label = cut[0], value = value }
}

::EX.tipSectionsFromText <- function(text) {
    local raws = text.split("\n")
    local main = { title = null, tag = null, lines = [] }
    local hints = { title = null, tag = null, lines = [] }
    foreach (raw in raws) {
        if (raw == "") continue
        if (raw.tolower().indexof("click") != null) {
            hints.lines.append({ text = raw, kind = "hint" })
            continue
        }
        if (main.title == null && main.lines.len() == 0) {
            // [tip-rich] "Double Line: Units organised..." / "Quarry - This area..." -> the name as the
            // heading, the rest as an italic description, however long the line is - so every
            // tooltip of one kind reads the same way. The earliest separator in the first 40 wins.
            local parts = ::EX.tipSplitName(raw)
            if (parts != null) {
                main.title = parts[0]
                main.lines.append({ text = parts[1], kind = "desc" })
                continue
            }
            // A short name alone ("Halt"), or the first of several lines, is the heading. [tip-title]
            // A lone line up to tipTitleMaxLen that is not a sentence counts as a name too, so a long
            // unit name ("Foot Knights of Santiago (102/103)", 34) heads its box like a short one -
            // it was 32, so those fell through as plain body text.
            local maxLen = "tipTitleMaxLen" in ::EX.look ? ::EX.look.tipTitleMaxLen : 32
            local sentence = raw.len() > 0 && raw[raw.len() - 1] == '.'
            if (raws.len() > 1 || raw.len() <= 32 || (raw.len() <= maxLen && !sentence)) {
                main.title = raw
                continue
            }
        }
        local epithet = ::EX.tipEpithet(raw)   // [tip-epithet]
        if (epithet != null) {
            main.lines.append(epithet)
            continue
        }
        main.lines.append({ text = raw, kind = ::EX.splitLabel(raw) != null ? "label" : "body" })
    }
    // [tip-tone] [tip-fx] The effect lines become one "effects" line: its label ("Effects:", or
    // null when the mod writes none) and its separate effects, whose values drawTipRichNow colours
    // green or red. Any fault here only costs the formatting, never the tooltip.
    if ("effectTone" in ::EX && "tipTone" in ::EX.look && ::EX.look.tipTone) {
        try {
            local tone = ::EX.effectTone
            // [tip-epithet] the epithet is never an effect, and its own "Epithet:" label must not
            // count as the effects label either - so it is left out of the scan
            local texts = []
            local scanAt = []
            foreach (line in main.lines) {
                scanAt.append(line.kind == "epithet" ? -1 : texts.len())
                if (line.kind != "epithet") texts.append(line.text)
            }
            local scanned = tone.effectLines(texts)
            local flags = []
            foreach (at in scanAt) flags.append(at >= 0 ? scanned[at] : false)
            local lines = []
            local block = null
            foreach (i, line in main.lines) {
                if (!flags[i]) {
                    block = null
                    lines.append(line)
                    continue
                }
                local rest = line.text
                if (block == null) {
                    block = { text = line.text, kind = "effects", label = null, items = [] }
                    local cut = ::EX.splitLabel(line.text)
                    if (cut != null) {
                        block.label = cut[0]
                        rest = cut[1]
                    }
                    lines.append(block)
                } else {
                    block.text += "\n" + line.text
                }
                foreach (item in tone.items(rest)) block.items.append(item)
            }
            main.lines = lines
        } catch (e) {
            println("squi: [tip-fx] effect formatting failed - " + e)
        }
    }
    local out = []
    if (main.title != null || main.lines.len() > 0) out.append(main)
    if (hints.lines.len() > 0) out.append(hints)
    return out
}

// Entries back to plain text (for the engine's hidden tooltip, and the plain fallback box).
::EX.tipSectionsToText <- function(sections) {
    local text = ""
    foreach (s in sections) {
        local head = s.title != null ? s.title : ""
        if (s.tag != null && s.tag.text != "") head += (head != "" ? " (" : "(") + s.tag.text + ")"
        if (head != "") text += (text != "" ? "\n" : "") + head
        foreach (line in s.lines) {
            if (line.text != "") text += (text != "" ? "\n" : "") + line.text
        }
    }
    return text
}

// Helpers for drawTipRich, kept top-level (no closures over its locals).
::EX.tipPx <- function(v, k) { return (v * k + 0.5).tointeger() }
::EX.tipLineH <- function(f, s) {
    local info = ::UI.fontInfo(f, s)
    return info != null ? info.ascent + info.descent : s
}
::EX.tipWidth <- function(t, f, s) {
    local m = ::UI.textSize(t, f, s)
    return m != null ? m[0] : 0
}

// [tip-rich] The styled box in parts, so other modules (the battle unit card, the HUDs) can frame
// themselves the same way and put their own art between the backing and the frame.

// Soft drop shadow and the dark bronze-to-black fade (look.tipShadow / tipGradient).
::EX.tipBack <- function(x, y, w, h, k) {
    local look = ::EX.look
    if (look.tipShadow) {
        local sh = ::EX.tipPx(look.tipShadowSize, k)
        for (local i = 3; i >= 0; i--) {
            local grow = i * sh / 3
            ::UI.drawRect(x + sh / 2 - grow, y + sh - grow, w + grow * 2, h + grow * 2,
                          0, 0, 0, 34 + (3 - i) * 22)
        }
    }
    local bgTop = ::EX.tipRgba(look.tipBgTop)
    local bgBot = ::EX.tipRgba(look.tipBgBottom)
    if (look.tipGradient) {
        local bands = 12
        for (local i = 0; i < bands; i++) {
            local t = (i + 0.5) / bands
            local y0 = y + h * i / bands
            local y1 = y + h * (i + 1) / bands
            ::UI.drawRect(x, y0, w, y1 - y0,
                          (bgTop[0] + (bgBot[0] - bgTop[0]) * t).tointeger(),
                          (bgTop[1] + (bgBot[1] - bgTop[1]) * t).tointeger(),
                          (bgTop[2] + (bgBot[2] - bgTop[2]) * t).tointeger(),
                          (bgTop[3] + (bgBot[3] - bgTop[3]) * t).tointeger())
        }
    } else {
        ::UI.drawRect(x, y, w, h, bgBot[0], bgBot[1], bgBot[2], bgBot[3])
    }
}

::EX.tipInnerInk <- null   // [tip-enemy] set around one drawTip call to tint that box's inner frame

// The gold frame, the thin inner frame and the corner brackets (look.tipEdge / tipInnerFrame /
// tipCorners). edgeInk overrides the outer frame's colour - the battle card passes its faction's.
::EX.tipFrame <- function(x, y, w, h, k, edgeInk = null) {
    local look = ::EX.look
    local rule = ::EX.tipPx(look.tooltipBorder, k)
    if (rule < 1) rule = 1
    local edge = ::EX.tipRgba(edgeInk != null ? edgeInk : look.tipEdge)
    ::UI.drawRect(x, y, w, rule, edge[0], edge[1], edge[2], edge[3])
    ::UI.drawRect(x, y + h - rule, w, rule, edge[0], edge[1], edge[2], edge[3])
    ::UI.drawRect(x, y, rule, h, edge[0], edge[1], edge[2], edge[3])
    ::UI.drawRect(x + w - rule, y, rule, h, edge[0], edge[1], edge[2], edge[3])
    if (look.tipInnerFrame || ::EX.tipInnerInk != null) {
        local g = rule + ::EX.tipPx(2, k)
        local e2 = ::EX.tipRgba(look.tipEdgeInner, 70)
        // [tip-enemy] a module can tint the inner frame for one box (the battle tooltips mark an
        // enemy unit's box with a fine red inner frame)
        if (::EX.tipInnerInk != null) {
            e2 = ::EX.tipRgba(::EX.tipInnerInk)
            local t = ::EX.tipPx(0.5, k)   // a fine line: half a 1080p pixel, never less than 1
            if (t < 1) t = 1
            ::UI.drawRect(x + g, y + g, w - g * 2, t, e2[0], e2[1], e2[2], e2[3])
            ::UI.drawRect(x + g, y + h - g - t, w - g * 2, t, e2[0], e2[1], e2[2], e2[3])
            ::UI.drawRect(x + g, y + g, t, h - g * 2, e2[0], e2[1], e2[2], e2[3])
            ::UI.drawRect(x + w - g - t, y + g, t, h - g * 2, e2[0], e2[1], e2[2], e2[3])
        }
        ::UI.drawRect(x + g, y + g, w - g * 2, 1, e2[0], e2[1], e2[2], e2[3])
        ::UI.drawRect(x + g, y + h - g - 1, w - g * 2, 1, e2[0], e2[1], e2[2], e2[3])
        ::UI.drawRect(x + g, y + g, 1, h - g * 2, e2[0], e2[1], e2[2], e2[3])
        ::UI.drawRect(x + w - g - 1, y + g, 1, h - g * 2, e2[0], e2[1], e2[2], e2[3])
    }
    if (look.tipCorners) {
        local c = ::EX.tipRgba(look.tipCorner)
        local len = ::EX.tipPx(look.tipCornerSize, k)
        local t = rule + 1
        foreach (corner in [[x, y, 1, 1], [x + w, y, -1, 1], [x, y + h, 1, -1], [x + w, y + h, -1, -1]]) {
            local cx = corner[2] > 0 ? corner[0] : corner[0] - len
            local cy = corner[3] > 0 ? corner[1] : corner[1] - t
            ::UI.drawRect(cx, cy, len, t, c[0], c[1], c[2], c[3])
            cx = corner[2] > 0 ? corner[0] : corner[0] - t
            cy = corner[3] > 0 ? corner[1] : corner[1] - len
            ::UI.drawRect(cx, cy, t, len, c[0], c[1], c[2], c[3])
        }
    }
}

// A 1px rule w wide, brighter across its middle quarter (look.tipRule, then look.tipEdge).
::EX.tipRule <- function(x, y, w) {
    local look = ::EX.look
    local ink = ::EX.tipRgba(look.tipRule, 110)
    local edge = ::EX.tipRgba(look.tipEdge)
    ::UI.drawRect(x, y, w, 1, ink[0], ink[1], ink[2], ink[3])
    ::UI.drawRect(x + w * 3 / 8, y, w / 4, 1, edge[0], edge[1], edge[2], 200)
}

// The 1px dark text shadow all styled text uses, as a style table for UI.pushStyle.
::EX.tipTextShadow <- function(k) {
    local s = ::EX.tipPx(1, k)
    if (s < 1) s = 1
    return { [::UI.Cap.textShadow]            = 1,
             [::UI.Colour.textShadow]         = [0, 0, 0, 210],
             [::UI.Metric.textShadowX]        = s,
             [::UI.Metric.textShadowY]        = s,
             [::UI.Metric.textShadowSpread]   = 0,
             [::UI.Metric.textShadowSoftness] = 100 }
}

// ============================================================================================
// [tip-layer] The tooltip layer. Each module draws inside its own canvas, and those canvases are
// underlays drawn one after another - so a tooltip drawn by the battle HUD went UNDER the radar
// drawn after it. Tooltips are instead queued here (::EX.onTop) and drawn by one canvas of their
// own that is not an underlay and is raised above the rest, so they are always on top.
//
// If that canvas ever stops drawing (a context where it is not updated), the queue is bypassed and
// tooltips draw in place again, as before - see ::EX.tipLayerLive.
// ============================================================================================
::EX.tipQueue <- []
::EX.tipTick <- 0          // counts frames (UI.onFrame)
::EX.tipLayerTick <- -100  // the frame the layer last drew in

::EX.tipLayerLive <- function() {
    return "tipLayer" in ::EX && ::EX.tipLayer != null && ::EX.tipTick - ::EX.tipLayerTick <= 3
}

// Runs fn on the tooltip layer this frame (or the next, whichever the layer draws in first); when
// the layer is not drawing, runs it now.
::EX.tipDrawing <- false   // true while the layer runs its queue: a tooltip asked for then draws at once
::EX.onTop <- function(fn) {
    if (!::EX.tipDrawing && ::EX.tipLayerLive()) {
        ::EX.tipQueue.append(fn)
        return
    }
    fn()
}

::EX.drawTipRich <- function(sections) {
    if (sections == null || sections.len() == 0) {
        return
    }
    ::EX.onTop(function() { ::EX.drawTipRichNow(sections) })
}

// [tip-fx] One effect laid out as rows starting x0 in, wrapped a word at a time within maxW, its
// values green or red: [{ runs, w }]. Top-level, like the other helpers drawTipRichNow uses.
::EX.tipValueRows <- function(text, f, s2, ink, x0, maxW, k) {
    local look = ::EX.look
    local avail = 0
    if (maxW > 0) {
        avail = maxW - x0
        local least = ::EX.tipPx(120, k)
        if (avail < least) avail = least
    }
    local groups = []
    local cur = []
    local curText = ""
    foreach (w in ::EX.effectTone.words(text)) {
        local trial = curText == "" ? w.text : curText + " " + w.text
        if (avail > 0 && cur.len() > 0 && ::EX.tipWidth(trial, f, s2) > avail) {
            groups.append(cur)
            cur = [w]
            curText = w.text
        } else {
            cur.append(w)
            curText = trial
        }
    }
    if (cur.len() > 0) groups.append(cur)
    local out = []
    foreach (group in groups) {
        local runs = []
        local so = ""
        foreach (sg in ::EX.effectTone.segments(group)) {
            local sink = sg.tone == "good" ? look.tipGood : sg.tone == "bad" ? look.tipBad : ink
            runs.append({ text = sg.text, face = f, size = s2, ink = sink, dx = x0 + ::EX.tipWidth(so, f, s2) })
            so += sg.text
        }
        out.append({ runs = runs, w = x0 + ::EX.tipWidth(so, f, s2) })
    }
    return out
}

::EX.drawTipRichNow <- function(sections) {
    if (sections == null || sections.len() == 0) {
        return
    }
    local look = ::EX.look
    local k = ::UI.dpiScale() * ::EX.tipScale()   // [tip-battle-size]
    local px = ::EX.tipPx
    local lineH = ::EX.tipLineH
    local width = ::EX.tipWidth

    local face    = look.face != null ? look.face : ::EX.fonts.body
    local bold    = "titleFace" in look && look.titleFace != null ? look.titleFace : face
    local italic  = "italicFace" in look && look.italicFace != null ? look.italicFace : face
    local heading = "tooltipTitleFace" in look && look.tooltipTitleFace != null ? look.tooltipTitleFace : bold

    local size      = px(look.tooltipFontSize, k)
    local titleSize = px(look.tooltipFontSize * look.tooltipTitleScale, k)
    local hintSize  = px(look.tooltipFontSize * look.tooltipHintScale, k)
    local padX      = px(look.tooltipPadX, k)
    local padY      = px(look.tooltipPadY, k)
    local lineGap   = px(look.tooltipLineGap, k)
    local titleGap  = px(look.tooltipTitleGap, k)
    local sectGap   = px(look.tooltipSectionGap, k)
    local wrapW     = px(look.tooltipWrapWidth, k)
    local rule      = px(look.tooltipBorder, k)
    if (rule < 1) rule = 1

    // Lay every entry out as rows; a row is one or more runs of text on a line.
    // row: { runs = [{ text, face, size, ink, dx }], h, w, before, rule, header }
    local rows = []
    local firstTitleRows = 0
    foreach (si, s in sections) {
        local startRow = rows.len()
        if (s.title != null && s.title != "") {
            local pieces = ::EX.wrapLine(s.title, heading, titleSize, wrapW)
            foreach (piece in pieces) {
                local w = width(piece, heading, titleSize)
                rows.append({ runs = [{ text = piece, face = heading, size = titleSize, ink = look.tipTitle, dx = 0 }],
                              h = lineH(heading, titleSize), w = w, before = lineGap, rule = false, header = si == 0 })
            }
            // the stance rides on the heading's last row when it fits, else gets its own
            if (s.tag != null && s.tag.text != "") {
                local ink = "stance" in s.tag && s.tag.stance in look.tipStance ? look.tipStance[s.tag.stance] : look.tipDesc
                local tw = width(s.tag.text, italic, size)
                local last = rows[rows.len() - 1]
                local space = width("  ", italic, size)
                if (last.w + space + tw <= wrapW || wrapW <= 0) {
                    last.runs.append({ text = s.tag.text, face = italic, size = size, ink = ink, dx = last.w + space,
                                       lift = lineH(heading, titleSize) - lineH(italic, size) })
                    last.w += space + tw
                } else {
                    rows.append({ runs = [{ text = s.tag.text, face = italic, size = size, ink = ink, dx = 0 }],
                                  h = lineH(italic, size), w = tw, before = lineGap, rule = false, header = si == 0 })
                }
            }
            if (si == 0) firstTitleRows = rows.len()
        }
        foreach (li, line in s.lines) {
            if (line.text == "") continue
            local kind = line.kind
            local f = face
            local s2 = size
            local ink = look.tipBody
            if (kind == "desc" || kind == "sub") { f = italic; ink = look.tipDesc }
            else if (kind == "warn") { ink = look.tipWarn }
            else if (kind == "hint") { f = italic; s2 = hintSize; ink = look.tipHint }

            local first = rows.len() == startRow ? 0 : (li == 0 && rows.len() > startRow ? titleGap : lineGap)
            local cut = kind == "label" ? ::EX.splitLabel(line.text) : null

            // [tip-fx] The effects block. One effect sits beside "Effects:", wrapping under itself:
            //   Effects: Less likely to fall ill. Ageing will take
            //            him a bit later.
            // More than one go on their own lines below it, in line with it:
            //   Effects:
            //   +1 Loyalty
            //   -5% malus on tax income
            if (kind == "effects") {
                local before = rows.len() > startRow ? first + px(look.tipEffectsGap, k) : first
                local lead = null
                local labelW = 0
                if (line.label != null) {
                    lead = { text = line.label, face = bold, size = size, ink = look.tipLabel, dx = 0 }
                    labelW = width(line.label, bold, size) + width(" ", face, size)
                }
                if (line.items.len() <= 1) {
                    local vrows = ::EX.tipValueRows(line.items.len() > 0 ? line.items[0] : "", f, s2, ink, labelW, wrapW, k)
                    if (vrows.len() == 0) vrows = [{ runs = [], w = labelW }]
                    foreach (pi, vr in vrows) {
                        local runs = vr.runs
                        if (pi == 0 && lead != null) runs.insert(0, lead)
                        rows.append({ runs = runs, h = lineH(f, s2), w = vr.w,
                                      before = pi == 0 ? before : lineGap, rule = false, header = false })
                    }
                    continue
                }
                if (lead != null) {
                    rows.append({ runs = [lead], h = lineH(f, s2), w = labelW - width(" ", face, size),
                                  before = before, rule = false, header = false })
                    before = lineGap
                }
                foreach (ii, item in line.items) {
                    foreach (pi, vr in ::EX.tipValueRows(item, f, s2, ink, 0, wrapW, k)) {
                        rows.append({ runs = vr.runs, h = lineH(f, s2), w = vr.w,
                                      before = ii == 0 && pi == 0 ? before : lineGap, rule = false, header = false })
                    }
                }
                continue
            }

            // [tip-epithet] a gap, "Epithet:" in gold, and the epithet on its own line below it
            if (kind == "epithet") {
                local gapE = "tipEpithetGap" in look ? look.tipEpithetGap : look.tipEffectsGap
                local before = rows.len() > startRow ? first + px(gapE, k) : first
                rows.append({ runs = [{ text = line.label, face = bold, size = size, ink = look.tipLabel, dx = 0 }],
                              h = lineH(bold, size), w = width(line.label, bold, size),
                              before = before, rule = false, header = false })
                local eSize = px(look.tooltipFontSize * 1.1, k)
                foreach (pi, piece in ::EX.wrapLine(line.value, heading, eSize, wrapW)) {
                    rows.append({ runs = [{ text = piece, face = heading, size = eSize, ink = look.tipTitle, dx = 0 }],
                                  h = lineH(heading, eSize), w = width(piece, heading, eSize),
                                  before = lineGap, rule = false, header = false })
                }
                continue
            }

            if (cut != null) {
                local lw = width(cut[0], bold, size)
                local vw = width(cut[1], face, size)
                if (wrapW <= 0 || lw + vw <= wrapW) {
                    rows.append({ runs = [{ text = cut[0], face = bold, size = size, ink = look.tipLabel, dx = 0 },
                                          { text = cut[1], face = face, size = size, ink = look.tipBody, dx = lw }],
                                  h = lineH(face, size), w = lw + vw, before = first, rule = false, header = false })
                    continue
                }
            }
            foreach (pi, piece in ::EX.wrapLine(line.text, f, s2, wrapW)) {
                rows.append({ runs = [{ text = piece, face = f, size = s2, ink = ink, dx = 0 }],
                              h = lineH(f, s2), w = width(piece, f, s2),
                              before = pi == 0 ? first : lineGap, rule = false, header = false })
            }
        }
        if (si > 0 && rows.len() > startRow) {
            rows[startRow].before = sectGap
            rows[startRow].rule = true
        }
    }
    if (rows.len() == 0) {
        return
    }
    rows[0].before = 0

    local textW = 0
    local textH = 0
    foreach (r in rows) {
        if (r.w > textW) textW = r.w
        textH += r.before + r.h
    }
    local boxW = textW + padX * 2
    local boxH = textH + padY * 2
    local at = ::EX.tipPlace(boxW, boxH, k)
    local x = at[0]
    local y = at[1]

    // --- the box -------------------------------------------------------------------------
    ::EX.tipBack(x, y, boxW, boxH, k)
    // the first heading sits on a faint gold wash when more follows it
    if (firstTitleRows > 0 && firstTitleRows < rows.len()) {
        local hh = padY
        for (local i = 0; i < firstTitleRows; i++) hh += rows[i].before + rows[i].h
        hh += (rows[firstTitleRows].rule ? rows[firstTitleRows].before : titleGap) / 2
        local w = ::EX.tipRgba(look.tipHeader, 30)
        ::UI.drawRect(x + rule, y + rule, boxW - rule * 2, hh - rule, w[0], w[1], w[2], w[3])
    }
    ::EX.tipFrame(x, y, boxW, boxH, k)

    // --- the text ------------------------------------------------------------------------
    local shadowed = look.tipTextShadow
    if (shadowed) ::UI.pushStyle(::EX.tipTextShadow(k))
    local ly = y + padY
    foreach (r in rows) {
        if (r.rule) {
            ::EX.tipRule(x + padX, ly + r.before / 2, boxW - padX * 2)
        }
        ly += r.before
        foreach (run in r.runs) {
            local ink = ::EX.tipRgba(run.ink)
            local lift = "lift" in run && run.lift > 0 ? run.lift - px(1, k) : 0
            ::UI.pushFont(run.face, false, run.size)
            ::UI.layoutAt(x + padX + run.dx, ly + lift)
            ::UI.textColoured(run.text, ink[0], ink[1], ink[2], ink[3])
            ::UI.popFont()
        }
        ly += r.h
    }
    if (shadowed) {
        ::UI.popStyle()
    }
}

// Draws a tooltip box at the cursor with the same text path the labels use (UI.pushFont), so
// it takes the chosen face and size. bg / edge / ink are [r, g, b, a].
// [tip-rich] With look.tooltipRich on, plain text is parsed into entries and drawn styled, so
// the HUD button and unit card tooltips match the campaign map's; bg / edge / ink then unused.
::EX.drawTip <- function(text, bg, edge, ink) {
    if (text == null || text == "") {
        return
    }
    local look = ::EX.look
    if ("tooltipRich" in look && look.tooltipRich) {
        ::EX.drawTipRich(::EX.tipSectionsFromText(text))
        return
    }
    local k = ::UI.dpiScale() * ::EX.tipScale()   // [tip-battle-size]
    local face = look.face != null ? look.face : ::EX.fonts.body
    local size = (look.tooltipFontSize * k + 0.5).tointeger()
    local pad = (look.tooltipPad * k + 0.5).tointeger()
    local gap = (look.tooltipLineGap * k + 0.5).tointeger()
    local rule = (look.tooltipBorder * k + 0.5).tointeger()
    if (rule < 1) rule = 1

    local info = ::UI.fontInfo(face, size)
    local lineH = info != null ? info.ascent + info.descent : size
    local wrapW = (look.tooltipWrapWidth * k + 0.5).tointeger()
    // [montserrat] Each line is { text, font, cut }: cut is [label, value, labelW] when the line is
    // drawn as a bold label and a regular value.
    local bold = "titleFace" in look && look.titleFace != null ? look.titleFace : null
    local raws = text.split("\n")
    local lines = []
    foreach (n, raw in raws) {
        local lineFont = bold != null && look.tooltipBoldTitle && n == 0 && raws.len() > 1 ? bold : face
        local pieces = ::EX.wrapLine(raw, lineFont, size, wrapW)
        local cut = null
        if (bold != null && look.tooltipBoldLabels && lineFont == face && pieces.len() == 1) {
            cut = ::EX.splitLabel(raw)
            if (cut != null) {
                local lw = ::UI.textSize(cut[0], bold, size)
                local vw = ::UI.textSize(cut[1], face, size)
                if (lw == null || vw == null || (wrapW > 0 && lw[0] + vw[0] > wrapW)) cut = null
                else cut.append(lw[0])
            }
        }
        foreach (piece in pieces) lines.append({ text = piece, font = lineFont, cut = cut })
    }
    local textW = 0
    foreach (line in lines) {
        if (line.text == "") continue
        local w = 0
        if (line.cut != null) {
            w = line.cut[2] + ::UI.textSize(line.cut[1], face, size)[0]
        } else {
            local m = ::UI.textSize(line.text, line.font, size)
            w = m != null ? m[0] : 0
        }
        if (w > textW) textW = w
    }
    local boxW = textW + pad * 2
    local boxH = lines.len() * lineH + (lines.len() - 1) * gap + pad * 2

    local at = ::EX.tipPlace(boxW, boxH, k)   // [tip-place]
    local x = at[0]
    local y = at[1]

    ::UI.drawRect(x, y, boxW, boxH, bg[0], bg[1], bg[2], bg[3])
    local a = edge.len() > 3 ? edge[3] : 255
    ::UI.drawRect(x, y, boxW, rule, edge[0], edge[1], edge[2], a)
    ::UI.drawRect(x, y + boxH - rule, boxW, rule, edge[0], edge[1], edge[2], a)
    ::UI.drawRect(x, y, rule, boxH, edge[0], edge[1], edge[2], a)
    ::UI.drawRect(x + boxW - rule, y, rule, boxH, edge[0], edge[1], edge[2], a)

    local alpha = ink.len() > 3 ? ink[3] : 255
    foreach (i, line in lines) {
        if (line.text == "") continue
        local ly = y + pad + i * (lineH + gap)
        if (line.cut != null) {
            ::UI.pushFont(bold, false, size)
            ::UI.layoutAt(x + pad, ly)
            ::UI.textColoured(line.cut[0], ink[0], ink[1], ink[2], alpha)
            ::UI.popFont()
            ::UI.pushFont(face, false, size)
            ::UI.layoutAt(x + pad + line.cut[2], ly)
            ::UI.textColoured(line.cut[1], ink[0], ink[1], ink[2], alpha)
            ::UI.popFont()
        } else {
            ::UI.pushFont(line.font, false, size)
            ::UI.layoutAt(x + pad, ly)
            ::UI.textColoured(line.text, ink[0], ink[1], ink[2], alpha)
            ::UI.popFont()
        }
    }
}

try { ::EX.applyLook() } catch (e) { println("squi: [ui-look] apply failed - " + e) }

// Modules can load before or after this file, so on the first frame the fonts are applied again
// and every label and tooltip module rebuilds its sizes, whatever the load order was.
::EX.lookRefreshId <- ::UI.onFrame(function() {
    ::UI.offFrame(::EX.lookRefreshId)
    try { ::EX.applyLook() } catch (e) { println("squi: [ui-look] apply failed - " + e) }
    // [tip-layer] every module's canvas exists by now; put the tooltip layer above them all
    if (::EX.tipLayer != null) {
        try { ::UI.raise(::EX.tipLayer) } catch (e) { println("squi: [tip-layer] raise failed - " + e) }
    }
    foreach (name in ["labels", "characterLabels", "fortLabels", "stratTooltips", "battleTooltips",
                      "campaignHud", "campaignCards", "campaignRadar", "eventIcons", "eventScroll",
                      "battleHud", "battleRadar", "battleCards"]) {   // [hud-scale] the battle HUD too
        if (name in ::EX && ::EX[name] != null) {
            try { ::EX[name].open() } catch (e) { println("squi: [ui-look] " + name + ".open failed - " + e) }
        }
    }
})

// [hud-scale] The minimal battle HUD's 1024x768 layout on this screen. A rect { x, y, w, h } in
// the game's virtual units goes to screen pixels: stretched as the game does when
// look.battleMinimalScale is 0, else scaled from the screen height and anchored - to the top
// centre (anchor "centre"), or to the top-right corner (anchor "right") for the radar column.
::EX.miniScale <- function() {
    local look = "look" in ::EX ? ::EX.look : null
    local k = look != null && "battleMinimalScale" in look ? look.battleMinimalScale : 0
    if (k <= 0 || !::EX.restyled()) return null   // [restyle] off: the game's own layout
    return ::UI.screenSize()[1] / 768.0 * k
}

// [mini-layout] Where the minimal HUD's two blocks go on this screen, or null to leave them where
// the game has them: { bar = [dx, dy] or null, col = { raw, x, y, f } or null }. The command bar is
// the game's 308..716 x 0..80 block (anchor "centre"); the radar column everything anchored "right"
// (850..1024 x 0..226 with the controls below the map, 796..1024 x 0..200 beside it).
::EX.miniShifts <- function() {
    if (!::EX.restyled()) return null
    local look = ::EX.look
    local screen = ::UI.screenSize()
    local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
    local m = ((("battleMiniMargin" in look) ? look.battleMiniMargin : 4) * k + 0.5).tointeger()
    local out = { bar = null, col = null, barTop = null }
    local bar = ::EX.miniRectRaw(308, 0, 408, 80, "centre")
    if (!("battleMiniBar" in look) || look.battleMiniBar == "bottomRight") {
        out.bar = [screen[0] - m - (bar.x + bar.w), screen[1] - m - (bar.y + bar.h)]
        out.barTop = screen[1] - m - bar.h
    }
    local below = !("battleRadarControls" in look) || look.battleRadarControls == "below"
    local col = below ? ::EX.miniRectRaw(850, 0, 174, 226, "right") : ::EX.miniRectRaw(796, 0, 228, 200, "right")
    local f = "battleRadarScale" in look && look.battleRadarScale > 0 ? look.battleRadarScale : 1.0
    local toBottom = (!("battleMiniRadar" in look) || look.battleMiniRadar == "bottomRight") && out.barTop != null
    local y = col.y
    if (toBottom) {
        // above the command bar with room for both plates between them; shrunk if it will not fit
        local gap = (14 * k + 0.5).tointeger()
        local room = out.barTop - gap - m
        if (col.h * f > room && col.h > 0) f = room.tofloat() / col.h
        y = out.barTop - gap - (col.h * f).tointeger()
    } else {
        local room = screen[1] - m - (out.barTop != null ? screen[1] - out.barTop + (14 * k).tointeger() : 0)
        if (col.h * f > room && col.h > 0) f = room.tofloat() / col.h
    }
    out.col = { raw = col, f = f, x = screen[0] - (col.w * f).tointeger(), y = y }
    return out
}

::EX.miniRect <- function(x, y, w, h, anchor) {
    local r = ::EX.miniRectRaw(x, y, w, h, anchor)
    local sh = ::EX.miniShifts()
    if (sh == null) return r
    if (anchor == "centre" && sh.bar != null) {
        r.x += sh.bar[0]
        r.y += sh.bar[1]
    } else if (anchor == "right" && sh.col != null) {
        local c = sh.col
        r = { x = (c.x + (r.x - c.raw.x) * c.f).tointeger(), y = (c.y + (r.y - c.raw.y) * c.f).tointeger(),
              w = (r.w * c.f + 0.5).tointeger(), h = (r.h * c.f + 0.5).tointeger() }
    }
    return r
}

::EX.miniRectRaw <- function(x, y, w, h, anchor) {
    local s = ::EX.miniScale()
    if (s == null) {
        local virt = ::UI.virtualScale()
        return { x = (x * virt[0]).tointeger(), y = (y * virt[1]).tointeger(),
                 w = (w * virt[0]).tointeger(), h = (h * virt[1]).tointeger() }
    }
    local screen = ::UI.screenSize()
    local sx = anchor == "right" ? screen[0] - (1024 - x) * s : screen[0] / 2.0 + (x - 512) * s
    return { x = sx.tointeger(), y = (y * s).tointeger(), w = (w * s + 0.5).tointeger(), h = (h * s + 0.5).tointeger() }
}

// [hud-full] The compact full battle HUD, on this screen: null when look.battleFullScale is 0,
// else a table of screen rects shared by battle_hud.nut, radar.nut, ui_cards.nut and the unit card,
// so every module agrees on it whatever order they load in. Layout units are 1080p; k is their
// size on this screen (screen height / 1080 x battleFullScale).
::EX.fullScale <- function() {
    local look = "look" in ::EX ? ::EX.look : null
    local f = look != null && "battleFullScale" in look ? look.battleFullScale : 0
    if (f <= 0 || !::EX.restyled()) return null   // [restyle] off: M2EX's own layout
    return ::UI.screenSize()[1] / 1080.0 * f
}

::EX.fullLayout <- function() {
    local k = ::EX.fullScale()
    if (k == null) return null
    local P = function (v) { return (v * k + 0.5).tointeger() }
    local screen = ::UI.screenSize()
    local H = screen[1]
    local m = P(8)
    local gap = P(6)
    // [radar-size] the map at its own size; the controls beside it and the slider above follow
    local rf = "battleRadarScale" in ::EX.look && ::EX.look.battleRadarScale > 0 ? ::EX.look.battleRadarScale : 1.0
    local rs = P(220 * rf)
    local radar = { x = m, y = H - m - rs, w = rs, h = rs }
    local colX = radar.x + radar.w + gap
    local colW = P(44)
    local sliderY = radar.y - gap - P(20)
    local top = sliderY - gap
    local L = {
        k = k,
        radar = radar,
        time      = { x = colX + P(2), y = radar.y, w = P(40), h = P(40) },
        speedText = { x = colX + P(6), y = radar.y + P(50), size = P(16) },
        timeSlow  = { x = colX + P(2), y = radar.y + P(86), w = P(19), h = P(28) },
        timeSpeed = { x = colX + P(23), y = radar.y + P(86), w = P(19), h = P(28) },
        playPause = { x = colX + P(2), y = radar.y + radar.h - P(40), w = P(40), h = P(40) },
        slider    = { x = m, y = sliderY, w = radar.w, h = P(20) },
        power     = { x = colX, y = sliderY + P(5), w = colW, h = P(10) },
        zoomOut   = { x = radar.x + P(26), y = radar.y + P(4), w = P(18), h = P(18) },
        zoomIn    = { x = radar.x + P(4), y = radar.y + P(4), w = P(18), h = P(18) },
        // the block the radar, controls and slider share, flush with the bottom-left corner
        left      = { x = 0, y = top, w = colX + colW + gap, h = H - top },
    }
    L.cardsLeft <- L.left.w + P(10)
    return L
}

// [tip-layer] The canvas that draws queued tooltips, above every module's underlay canvas.
::EX.tipLayer <- null
try {
    ::EX.tipLayer = ::UI.canvas("##tip_layer", 0, 0, 4, 4)
    ::UI.setWidgetStyle(::EX.tipLayer, ::UI.Cap.autoScaleCanvas, 0)
    ::UI.onDraw(::EX.tipLayer, function() {
        ::EX.tipLayerTick = ::EX.tipTick
        local queue = ::EX.tipQueue
        ::EX.tipQueue = []
        ::EX.tipDrawing = true
        foreach (fn in queue) {
            try { fn() } catch (e) { println("squi: [tip-layer] tooltip failed - " + e) }
        }
        ::EX.tipDrawing = false
    })
    // Not an underlay: drawn over them. Raised again once every module has made its canvas.
    ::UI.widgetUnderlay(::EX.tipLayer, false)
}
catch (e) {
    ::EX.tipLayer = null
    println("squi: [tip-layer] could not make the tooltip layer, tooltips draw in place - " + e)
}
::UI.onFrame(function() { ::EX.tipTick += 1 })

// The strip every HUD module draws into, and the gate that decides whether it draws at all.
::EX.HudPane <- class {
    metrics = null
    style   = null
    feature = null

    pane = null
    px   = null

    // Fills this.pane and this.px and hands back the scale; authored draws the strip at its own size rather than stretching it.
    function openPane(authored, notPixels, forceScale = null) {
        local screen = ::UI.screenSize()
        local scale = ::UI.dpiScale()
        if (forceScale != null) {
            scale = forceScale
        }
        else if (!authored) {
            local band = screen[0] < screen[1] * 16.0 / 9.0 ? screen[0].tofloat()
                                                            : screen[1] * 16.0 / 9.0
            scale = band / this.metrics.paneWidth.tofloat()
        }
        local width = this.metrics.paneWidth * scale
        local height = this.metrics.paneHeight * scale

        this.pane = { x = (screen[0] - width) / 2, y = screen[1] - height, w = width, h = height }

        this.px = { scale = scale }
        foreach (key, value in this.metrics) {
            if (typeof(value) == "integer" && !(key in notPixels)) {
                this.px[key] <- (value * scale + 0.5).tointeger()
            }
        }
        return scale
    }

    // The full screen width at the bottom. Metrics are 1080p units, scaled by UI.dpiScale()
    // (screen height / 1080) so the strip keeps its proportions at 1440p and 4K.
    // `notPixels` names integer metrics that are COUNTS (cards per row, rows) and must not scale.
    // [m2ex-hd-fix] was: every metric taken as raw screen pixels, so 4K drew it at half size.
    function openPaneFull(notPixels = null) {
        local screen = ::UI.screenSize()
        local scale = ::UI.dpiScale()
        if (scale <= 0) {
            scale = 1.0
        }
        local height = (this.metrics.paneHeight * scale + 0.5).tointeger()

        this.pane = { x = 0, y = screen[1] - height, w = screen[0], h = height }

        this.px = { scale = scale }
        foreach (key, value in this.metrics) {
            if (typeof(value) == "integer") {
                local count = notPixels != null && (key in notPixels)
                this.px[key] <- count ? value : (value * scale + (value < 0 ? -0.5 : 0.5)).tointeger()
            }
        }
        return scale
    }

    // A sprite's natural size in texels, scaled to match the pane; null when it has none.
    function scaledSize(art, factor = 1.0) {
        local size = art != null ? ::UI.imageSize(art.img) : null
        if (size == null) {
            return null
        }
        local k = factor * (this.px != null && "scale" in this.px ? this.px.scale : 1.0)
        return [(size[0] * k + 0.5).tointeger(), (size[1] * k + 0.5).tointeger()]
    }

    // Live only in the right context, with the feature on, and not while the player has hidden the UI.
    function visible(context) {
        if (!(::UI.context() & context)) {
            return false
        }
        if (!::options.hdFeature(this.feature)) {
            return false
        }
        if (this.feature != ::Enum.HdFeature.battleHud) {
            return true
        }
        return !("battleShortcuts" in ::EX && ::EX.battleShortcuts.hidden)
    }
}

// A strip of unit cards and the drag that reorders them, over a rack's own `rack` and cardRect.
::EX.CardRack <- class (::EX.HudPane) {
    rack      = null
    dragUnit  = null
    dragFrom  = -1
    dragBlock = null
    dropAt    = -1
    dropAfter = false

    // Whether slot `index` can be drawn on and dropped at - a scrolled-away row cannot.
    function slotUsable(index) {
        return true
    }

    // Whether this card is one the drag carries.
    function cardPicked(entry) {
        return false
    }

    // What a click means: ctrl flips this card, shift adds it, anything else replaces the selection.
    function clickMode() {
        local mods = ::UI.keyboard.mods()
        if (mods & ::UI.Mod.ctrl) {
            return ::Enum.SelectMode.toggle
        }
        return (mods & ::UI.Mod.shift) ? ::Enum.SelectMode.add : ::Enum.SelectMode.replace
    }

    // Where a drop lands: the nearest card scored row first, inside a generous zone around it.
    function dropSlot(x, y) {
        local best = -1
        local bestRow = 0
        local bestCol = 0
        for (local i = 0; i < this.rack.len(); i++) {
            if (!this.slotUsable(i) || (this.dragBlock != null && this.cardPicked(this.rack[i]))) {
                continue
            }
            local r = this.cardRect(i)
            local row = y < r.y ? r.y - y : (y >= r.y + r.h ? y - (r.y + r.h) : 0)
            local col = x < r.x ? r.x - x : (x >= r.x + r.w ? x - (r.x + r.w) : 0)
            if (best < 0 || row < bestRow || (row == bestRow && col < bestCol)) {
                best = i
                bestRow = row
                bestCol = col
            }
        }
        if (best < 0) {
            return null
        }

        local r = this.cardRect(best)
        if (y < r.y - this.px.dropZoneAbove || y >= r.y + r.h + this.px.dropZoneBelow
            || x < r.x - this.px.dropZoneSide || x >= r.x + r.w + this.px.dropZoneSide) {
            return null
        }
        return { index = best, before = x < r.x + r.w / 2 }
    }

    // The press edge: what the drag would carry, from a clean state.
    function dragPress(entry, index) {
        this.dragUnit = entry
        this.dragFrom = index
        this.dragBlock = null
        this.dropAt = -1
    }

    // The first dragging frame latches the block; every frame after it tracks where the drop would go.
    function dragTrack(x, y) {
        if (this.dragBlock == null) {
            this.dragBlock = [this.dragUnit]
            for (local i = 0; i < this.rack.len(); i++) {
                if (i != this.dragFrom && this.cardPicked(this.rack[i])) {
                    this.dragBlock.append(this.rack[i])
                }
            }
        }
        local slot = this.dropSlot(x, y)
        this.dropAt = slot != null ? slot.index : -1
        this.dropAfter = slot != null && !slot.before
    }

    // Drops what the drag carried without acting on it - for a rack that changed under the cursor.
    function dragCancel() {
        this.dragUnit = null
        this.dragFrom = -1
        this.dragBlock = null
        this.dropAt = -1
    }

    // The release: hands back what was carried and where it landed, and clears the drag.
    function dragRelease(x, y) {
        local out = { unit = this.dragUnit, from = this.dragFrom, block = this.dragBlock,
                      slot = this.dragUnit != null ? this.dropSlot(x, y) : null,
                      moved = ::UI.mouse.dragDelta(::UI.mouse.left) }
        this.dragCancel()
        return out
    }

    // True while the cards are actually riding the cursor.
    function dragLive() {
        return this.dragBlock != null && ::UI.mouse.down(::UI.mouse.left)
    }

    // The half-card gap the rack opens at the insertion point.
    function dragSlide(rect, index) {
        if (this.dragLive() && this.dropAt >= 0 && index >= this.dropAt + (this.dropAfter ? 1 : 0)) {
            rect.x += this.px.cardW / 2
        }
        return rect
    }
}
