local StratTooltips = class {
    metrics = {
        cursorPad   = 6,
        padX        = 4,
        padY        = 2,
        corner      = 0,
        borderWidth = 2,
        offsetX     = 24,
        offsetY     = 34,
    }

    style = {
        clickHints = true,
        delayMs    = 0,
        background = [0, 0, 0, 160],
        border     = [255, 245, 139, 255],
        ink        = [255, 245, 139, 255],
        maxStrikes = 8,
    }

    state = { text = "", sections = [], verified = false, down = false, strikes = 0 }   // [tip-rich] sections

    px         = null
    scope      = null
    frame      = null
    tile       = null
    rect       = null
    restricted = false

    // Metrics are 1080p units, scaled by screen height alone.
    function open() {
        local scale = ::UI.dpiScale()

        this.px = {}
        foreach (key, value in this.metrics) {
            this.px[key] <- (value * scale).tointeger()
        }

        local bg = this.style.background
        local edge = this.style.border
        local ink = this.style.ink
        this.scope = {
            [::UI.Surface.tooltip]      = [bg[0], bg[1], bg[2], bg[3]],
            [::UI.Colour.tooltipBorder] = [edge[0], edge[1], edge[2], edge[3]],
            [::UI.Colour.tooltipText]   = [ink[0], ink[1], ink[2], ink[3]],
            [::UI.Metric.tooltipDelay]  = this.style.delayMs,
            [::UI.Metric.tooltipPadX]   = this.px.padX,
            [::UI.Metric.tooltipPadY]   = this.px.padY,
            [::UI.Metric.roundTooltip]  = this.px.corner,
            [::UI.Metric.borderTooltip] = this.px.borderWidth,
            [::UI.Metric.tooltipOffX]   = this.px.offsetX,
            [::UI.Metric.tooltipOffY]   = this.px.offsetY,
        }
    }

    // The screen box a tile's column covers, from the ground up to `height` world units.
    function columnRect(tileX, tileY, height) {
        local minX = null
        local minY = null
        local maxX = null
        local maxY = null

        for (local c = 0; c < 8; c += 1) {
            local at = ::game.camera.worldToScreen(tileX + (c & 1), tileY + ((c >> 1) & 1),
                                                   (c & 4) != 0 ? height : 0.0)
            if (at == null) continue

            if (minX == null || at.x < minX) minX = at.x
            if (maxX == null || at.x > maxX) maxX = at.x
            if (minY == null || at.y < minY) minY = at.y
            if (maxY == null || at.y > maxY) maxY = at.y
        }

        if (minX == null) return null

        local w = (maxX - minX).tointeger()
        local h = (maxY - minY).tointeger()
        return (w > 0 && h > 0) ? [minX.tointeger(), minY.tointeger(), w, h] : null
    }

    // A retained window covers the map, and so does the hud strip - an underlay overlayAt cannot see.
    function coveredAt(x, y) {
        if (::UI.overlayAt(x, y)) {
            return true
        }
        if (!("campaignHud" in ::EX)) {
            return false
        }
        local pane = ::EX.campaignHud.pane
        return pane != null && x >= pane.x && x < pane.x + pane.w
                            && y >= pane.y && y < pane.y + pane.h
    }

    function update() {
        local tile = ::stratMap.hoveredTile()
        local viewer = ::game.localFaction()
        local mouse = ::UI.mouse.pos()

        local seen = 0
        if (tile != null && viewer != null) {
            local level = viewer.tileVisibility(tile.x, tile.y)
            if (level != null) seen = level
        }

        this.frame = {
            tileX = tile != null ? tile.x : -1000,
            tileY = tile != null ? tile.y : -1000,
            seen = seen,
            mouseX = mouse[0], mouseY = mouse[1],
            cursorBlocked = this.coveredAt(mouse[0], mouse[1]) || ::UI.cursorOverGameUi(),
            hoveredFort = ::ui.cardManager().hoveredFort,
            hoveredSettlement = ::ui.cardManager().hoveredSettlement,
            hoveredCharacter = ::ui.cardManager().hoveredCharacter,
            localFaction = viewer,
            selected = ::ui.cardManager().selectedCharacter,
            hotseat = ::game.options.hotseatMode() != 0,
        }
    }

    // EMT_ keys are built from the faction's internal descr_sm_factions name, uppercased.
    function factionKey(faction) {
        return faction != null ? faction.name.toupper() : ""
    }

    // [tip-rich] The diplomatic stance, for everyone but your own faction, as the tag an entry's
    // heading carries: { text = "At War", stance = "war" }, or null. drawTipRich colours it by
    // stance; the plain box shows it in brackets.
    function stanceTag(faction) {
        if (faction == null) return null

        local viewer = this.frame.localFaction
        if (viewer == null || faction.id == viewer.id) return null

        local diplomacy = ::game.campaign().diplomacyWith(viewer.id, faction.id)
        if (diplomacy == null) return null

        local stance = diplomacy.state
        local key  = "SMT_AT_WAR"
        local kind = "war"
        if (stance <= ::Enum.DiplomaticStance.allied)          { key = "SMT_ALLIES";     kind = "allied" }
        else if (stance <= ::Enum.DiplomaticStance.suspicious) { key = "SMT_SUSPICIOUS"; kind = "suspicious" }
        else if (stance <= ::Enum.DiplomaticStance.neutral)    { key = "SMT_NEUTRAL";    kind = "neutral" }
        else if (stance <= ::Enum.DiplomaticStance.hostile)    { key = "SMT_HOSTILE";    kind = "hostile" }

        local word = ::game.stratText(key)
        if (word == "") return null

        if (this.frame.hotseat) {
            local who = ::game.stratText(::game.campaign().isPlayerFaction(faction.id) ? "SMT_HUMAN" : "SMT_AI")
            if (who != "") word = who + ", " + word
        }
        return { text = word, stance = kind }
    }

    // [tip-rich] Entry builders. An entry is { title, tag, lines = [{ text, kind }] } - see
    // hud_pane.nut's drawTipRich for the kinds.
    function entry(title, tag = null) {
        return { title = title, tag = tag, lines = [] }
    }

    function addLines(section, text, kind) {
        if (text == null || text == "") return
        foreach (raw in text.split("\n")) {
            if (raw != "") section.lines.append({ text = raw, kind = kind })
        }
    }

    // Appends one entry list to another (plain loop: no Squirrel 3 array methods relied on).
    function join(into, more) {
        foreach (item in more) into.append(item)
        return into
    }

    // Engine text whose first line is the name and the rest a subtitle - "Nobilis\n(Romani Heir)".
    function entryFromNamed(text, tag = null) {
        local lines = text.split("\n")
        local out = this.entry(lines.len() > 0 ? lines[0] : text, tag)
        for (local i = 1; i < lines.len(); i++) {
            if (lines[i] != "") out.lines.append({ text = lines[i], kind = "sub" })
        }
        return out
    }

    // Whoever the player last saw here, which is who the engine names on a remembered tile.
    function apparentOwner(tile, realOwner) {
        local remembered = tile.rememberedOwner
        return remembered != null ? remembered : realOwner
    }

    function settlementKey(settlement, owner) {
        local stem = "EMT_" + this.factionKey(owner) + "_"
        if (settlement.isCapital) return stem + "CAPITAL"

        local castle = settlement.isCastle
        local level = settlement.level
        if (level <= ::Enum.SettlementLevel.village)    return stem + (castle ? "WOODEN_CASTLE" : "VILLAGE")
        if (level == ::Enum.SettlementLevel.town)       return stem + (castle ? "STONE_KEEP" : "TOWN")
        if (level == ::Enum.SettlementLevel.largeTown) return stem + (castle ? "CASTLE" : "LARGE_TOWN")
        if (level == ::Enum.SettlementLevel.city)       return stem + (castle ? "LARGE_CASTLE" : "CITY")
        if (level == ::Enum.SettlementLevel.largeCity) return stem + (castle ? "FORTRESS" : "LARGE_CITY")
        return stem + (castle ? "STAR_FORT" : "HUGE_CITY")
    }

    // The agent's own word for what it is, branched on by name so both ports read the same.
    function characterKey(character) {
        local record = character.record
        local stem = "EMT_" + this.factionKey(character.faction) + "_"

        if (record != null && record.isLeader()) return stem + "FACTION_LEADER"
        if (record != null && record.isHeir()) return stem + "FACTION_HEIR"

        local kind = character.typeName
        if (kind == "heretic")    return "EMT_HERETIC"
        if (kind == "witch")      return "EMT_WITCH"
        if (kind == "inquisitor") return "EMT_INQUISITOR"

        if (kind == "named character" || kind == "named_character" || kind == "family") {
            return stem + (record != null && record.isFamilyMember ? "NAMED_CHARACTER" : "NAMED_GENERAL")
        }

        local key = stem + kind.toupper()
        local level = record != null ? record.level : 0
        return level > 0 ? key + "_" + level : key
    }

    // The localised name of a rebel entry, read off the rebels table.
    function rebelSuffix(entry) {
        if (entry == null) return ""
        local name = ::rebels.displayName(entry)
        return name != "" ? " (" + name + ")" : ""
    }

    // [tip-rich] Each tooltipFrom* now returns its entries as an array (empty when there is nothing
    // to say) rather than a string, so each thing under the cursor keeps its own heading.

    function tooltipFromSettlement(tile, settlement) {
        local owner = this.apparentOwner(tile, settlement.owner)

        local text = ::game.text(this.settlementKey(settlement, owner))
        if (text == "") return []

        local out = this.entryFromNamed(text + this.rebelSuffix(settlement.rebelEntry), this.stanceTag(owner))

        if (settlement.siegeCount > 0) {
            local immune = settlement.capability(::Enum.BuildingCapability.siegeImmune)
            if (immune != null && immune.value > 0) {
                this.addLines(out, ::game.stratText("SMT_SIEGE_INDEFINITE"), "warn")
            } else {
                this.addLines(out, ::game.stratText("SMT_TURNS_UNTIL_SURRENDER") + " " + settlement.siegeTurnsRemaining, "warn")
            }
        }

        return [out]
    }

    function tooltipFromFort(tile, fort) {
        local owner = this.apparentOwner(tile, fort.owner)

        local text = ::game.text("EMT_" + this.factionKey(owner) + "_FORT")
        if (text == "") return []

        local out = this.entryFromNamed(text + this.rebelSuffix(fort.rebelEntry), this.stanceTag(owner))

        if (fort.siegeCount > 0) {
            this.addLines(out, ::game.stratText("SMT_TURNS_UNTIL_SURRENDER") + " " + fort.siegeTurnsRemaining, "warn")
        }

        return [out]
    }

    function tooltipFromCharacter(character) {
        local text = ::game.text(this.characterKey(character))
        if (text == "") return []

        local army = character.army
        local rebel = this.rebelSuffix(army != null ? army.rebelEntry : null)
        local out = this.entryFromNamed(text, this.stanceTag(character.faction))
        if (rebel != "") out.title += rebel
        return [out]
    }

    function tooltipFromWatchtower(tile, watchtower) {
        local owner = this.apparentOwner(tile, watchtower.owner)

        local text = ::game.text("EMT_" + this.factionKey(owner) + "_WATCHTOWER")
        return text != "" ? [this.entryFromNamed(text, this.stanceTag(owner))] : []
    }

    function tooltipFromPort(tile, port) {
        local owner = this.apparentOwner(tile, port.owner)
        local stem = "EMT_" + this.factionKey(owner) + "_"

        local text = ::game.text(stem + (port.level == ::Enum.PortLevel.fishingVillage ? "FISHING_VILLAGE" : "PORT"))
        if (text == "") return []

        local out = this.entryFromNamed(text, this.stanceTag(owner))
        if (port.isBlockaded) this.addLines(out, ::game.stratText("SMT_BLOCKADED"), "warn")
        return [out]
    }

    function tooltipFromBattleSite(site) {
        local out = this.entry(::game.stratText("SMT_FAMOUS_BATTLE_SITE"))
        this.addLines(out, ::game.stratText("SMT_BATTLE_YEAR") + ": " + site.year, "label")
        this.addLines(out, ::game.stratText("SMT_VICTOR") + ": " + site.victor + " (" + site.victorFaction + ")", "label")
        this.addLines(out, ::game.stratText("SMT_LOSER") + ": " + site.loser + " (" + site.loserFaction + ")", "label")
        return [out]
    }

    // [tip-rich] A resource's name and description. Mods write these two ways -
    // "Quarry - This area..." and "Marble: A valuable trade resource" - so the earliest of
    // those separators within the first 40 characters splits them. Returns
    // [name, description], or null when there is no name to take.
    function splitName(text) {
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
        return [text.slice(0, best), rest]
    }

    // "Quarry - This area has a rock quarry..." / "Marble: A valuable trade resource"
    // -> heading "Quarry" / "Marble", the rest an italic description.
    function tooltipFromResource(resource) {
        local text = resource.tooltip
        if (text == null || text == "") return []

        local lines = text.split("\n")
        local parts = this.splitName(lines[0])
        local out = this.entry(parts != null ? parts[0] : null)
        this.addLines(out, parts != null ? parts[1] : lines[0], "desc")
        for (local i = 1; i < lines.len(); i++) this.addLines(out, lines[i], "desc")
        return [out]
    }

    function tooltipFromRallyPoint(tile) {
        local viewer = this.frame.localFaction
        if (viewer == null) return []

        local count = tile.rallyPointCount(viewer)
        if (count <= 0) return []

        local text = ::game.stratText(count > 1 ? "SMT_RALLY_POINTS" : "SMT_RALLY_POINT")
        return text != "" ? [this.entry(text)] : []
    }

    // "Road: Allows armies to march further\nAlso adds..." -> heading "Road", then the lines.
    function tooltipFromRoad(tile) {
        local level = tile.roadLevel
        if (level < 1 || level > 3) return []

        local key = level == 1 ? "TMT_ROADS_TOOLTIP"
                  : level == 2 ? "TMT_PAVED_ROADS_TOOLTIP"
                  : "TMT_HIGHWAYS_TOOLTIP"

        local text = ::scripting.textTable(key, ::Enum.StringTable.tooltips)
        if (text == "") return []

        local lines = text.split("\n")
        local cut = ::EX.splitLabel(lines[0])
        local out = null
        if (cut != null) {
            out = this.entry(cut[0].slice(0, cut[0].len() - 1))       // "Road:" -> "Road"
            local rest = cut[1]
            while (rest.len() > 0 && rest[0] == ' ') rest = rest.slice(1)
            this.addLines(out, rest, "body")
        } else {
            out = this.entry(null)
            this.addLines(out, lines[0], "body")
        }
        for (local i = 1; i < lines.len(); i++) this.addLines(out, lines[i], "body")
        return [out]
    }

    function tooltipFromLandmark(tile) {
        local name = tile.landmarkName
        if (name == "") return []

        local owner = tile.landmarkOwner
        local viewer = this.frame.localFaction
        local foreign = owner != null && viewer != null && owner.id != viewer.id

        local out = this.entry(name, foreign ? this.stanceTag(owner) : null)
        this.addLines(out, tile.landmarkText, "desc")
        if (foreign) {
            this.addLines(out, ::game.stratText("SMT_OWNED_BY") + " " + owner.displayName, "body")
        }
        return [out]
    }

    // What clicking here would do, as an entry of its own under whatever the tile said.
    // The action line reads plain; the "Left-click to ..." lines as muted hints.
    function cursorHint(tile) {
        if (!this.style.clickHints) return []

        local action = tile.cursorAction(this.frame.selected)
        if (action == null) return []

        local out = this.entry(null)
        if (action.tooltip != "") {
            foreach (raw in action.tooltip.split("\n")) {
                if (raw == "") continue
                out.lines.append({ text = raw, kind = raw.tolower().indexof("click") != null ? "hint" : "body" })
            }
        }
        this.addLines(out, action.clickHint, "hint")
        return out.lines.len() > 0 ? [out] : []
    }

    // The entries for whatever furniture the tile carries, in the engine's own precedence order.
    function tooltipFromTile(tile) {
        local fort = this.frame.hoveredFort
        if (fort != null) return this.tooltipFromFort(tile, fort)

        local settlement = this.frame.hoveredSettlement
        if (settlement != null) return this.tooltipFromSettlement(tile, settlement)

        local character = this.frame.hoveredCharacter
        if (character != null) return this.tooltipFromCharacter(character)

        local out = this.tooltipFromLandmark(tile)

        local watchtower = tile.watchtower
        local port = tile.port
        if (watchtower != null) out = this.tooltipFromWatchtower(tile, watchtower)
        else if (port != null) out = this.tooltipFromPort(tile, port)

        if (this.frame.seen < 3) return out

        local site = tile.battleSite
        if (site != null) out = this.tooltipFromBattleSite(site)

        local resource = tile.resource
        if (resource != null) {
            this.join(out, this.tooltipFromResource(resource))
        } else {
            local rally = this.tooltipFromRallyPoint(tile)
            if (rally.len() > 0) out = rally
        }

        if (port == null) {
            this.join(out, this.tooltipFromRoad(tile))
        }

        return out
    }

    // The label plate under the cursor, if one of our own label modules published one.
    function labelHover() {
        foreach (name in ["characterLabels", "labels", "fortLabels"]) {
            if (!(name in ::EX)) continue

            local labels = ::EX[name]
            if (labels == null || !("hovered" in labels)) continue

            local hover = labels.hovered()
            if (hover == null) continue
            if (!("w" in hover) || !("h" in hover)) continue
            if (hover.w == null || hover.h == null || hover.w <= 0 || hover.h <= 0) continue

            if (this.frame.mouseX < hover.x || this.frame.mouseX >= hover.x + hover.w) continue
            if (this.frame.mouseY < hover.y || this.frame.mouseY >= hover.y + hover.h) continue

            return hover
        }
        return null
    }

    // Picks what the cursor is on - one of our own label plates, or the tile - and builds its text.
    function initialise() {
        this.state.text = ""
        this.state.sections = []
        this.tile = null
        this.restricted = false

        local hover = this.labelHover()
        if (hover != null) {
            this.tile = ::stratMap.tile(hover.tileX, hover.tileY)
            if (this.tile == null) return false

            if ("character" in hover && hover.character != null) {
                this.state.sections = this.tooltipFromCharacter(hover.character)
            } else if ("sett" in hover && hover.sett != null) {
                this.state.sections = this.tooltipFromSettlement(this.tile, hover.sett)
            } else if ("fort" in hover && hover.fort != null) {
                this.state.sections = this.tooltipFromFort(this.tile, hover.fort)
            }
            this.rect = [hover.x, hover.y, hover.w, hover.h]
            return this.appendCursorHint()
        }

        if (this.frame.tileX <= -1000) return false

        this.tile = ::stratMap.tile(this.frame.tileX, this.frame.tileY)
        if (this.tile == null) return false

        this.restricted = this.tile.isCursorRestricted
        if (this.restricted) {
            local text = ::scripting.textTable("TMT_RESTRICTED_AREA", ::Enum.StringTable.tooltips)
            this.state.sections = text != "" ? [this.entry(text)] : []
        } else {
            this.state.sections = this.tooltipFromTile(this.tile)
        }
        this.rect = null
        return this.appendCursorHint()
    }

    // Adds what clicking here would do as the last entry, and builds the plain text from the
    // entries (the engine's hidden tooltip still needs a string).
    function appendCursorHint() {
        if (!this.restricted) {
            this.join(this.state.sections, this.cursorHint(this.tile))
        }
        this.state.text = this.sectionsText(this.state.sections)
        return this.state.text != ""
    }

    // The entries as plain text: hud_pane.nut's helper when it has loaded, else the same by hand.
    function sectionsText(sections) {
        if ("tipSectionsToText" in ::EX) return ::EX.tipSectionsToText(sections)
        local text = ""
        foreach (s in sections) {
            local head = s.title != null ? s.title : ""
            if (s.tag != null) head += " (" + s.tag.text + ")"
            if (head != "") text += (text != "" ? "\n" : "") + head
            foreach (line in s.lines) text += (text != "" ? "\n" : "") + line.text
        }
        return text
    }

    // The screen box the tooltip points at: the tile's column, or a small box on the cursor.
    function positionChildren() {
        if (this.rect != null) return true

        local onObject = this.frame.hoveredCharacter != null
                      || this.frame.hoveredSettlement != null
                      || this.frame.hoveredFort != null
        if (onObject) {
            local pad = this.px.cursorPad
            this.rect = [this.frame.mouseX - pad, this.frame.mouseY - pad, pad * 2, pad * 2]
            return true
        }

        this.rect = this.columnRect(this.frame.tileX, this.frame.tileY, 0.0)
        return this.rect != null
    }

    // Draws what the two above prepared.
    function renderTooltip() {
        // [ui-look] Drawn with the label text path, so it takes the face and size from hud_pane.nut.
        if ("drawTip" in ::EX) {
            // The engine tooltip is still raised, invisibly, so the game keeps its native one hidden.
            ::UI.pushStyle(this.scope)
            ::UI.pushStyle(::EX.ghostStyle())
            ::UI.tooltipAt(this.rect[0], this.rect[1], this.rect[2], this.rect[3])
            ::UI.tooltip(0, this.state.text)
            ::UI.popStyle()
            ::UI.popStyle()
            // [tip-rich] The styled box, drawn from the entries, when hud_pane.nut has it switched on.
            if ("drawTipRich" in ::EX && "tooltipRich" in ::EX.look && ::EX.look.tooltipRich) {
                ::EX.drawTipRich(this.state.sections)
                return
            }
            ::EX.drawTip(this.state.text, this.style.background, this.style.border, this.style.ink)
            return
        }
        ::UI.pushStyle(this.scope)
        ::UI.tooltipAt(this.rect[0], this.rect[1], this.rect[2], this.rect[3])
        ::UI.tooltip(0, this.state.text)
        ::UI.popStyle()
    }

    function verify() {
        if (this.px == null || this.scope == null) {
            return false
        }
        if (this.px.len() != this.metrics.len() || !("cursorPad" in this.px)) {
            return false
        }
        if (!(::UI.Surface.tooltip in this.scope) || !(::UI.Colour.tooltipText in this.scope)
            || !(::UI.Metric.tooltipDelay in this.scope) || !(::UI.Metric.tooltipOffX in this.scope)) {
            return false
        }
        if (::stratMap.hoveredTile == null || ::UI.tooltipAt == null || ::UI.tooltip == null
            || ::UI.overlayAt == null || ::UI.cursorOverGameUi == null) {
            return false
        }
        if (::stratMap.tile == null || ::rebels.displayName == null || ::scripting.textTable == null) {
            return false
        }
        if (::game.localFaction == null || ::game.text == null || ::game.stratText == null
            || ::game.campaign == null || ::game.camera.worldToScreen == null
            || ::game.options.hotseatMode == null) {
            return false
        }
        return ::ui.cardManager != null && ::options.failHdFeature != null
    }

    function render() {
        if (this.state.down) {
            return
        }

        this.state.text = ""
        if (!(::UI.context() & ::Enum.UiContext.campaignLive)) return
        if (!::options.hdFeature(::Enum.HdFeature.tooltips)) return

        local fault = ""
        if (!this.state.verified) {
            this.state.verified = true
            try {
                if (!this.verify()) {
                    fault = "verify() rejected the widget tree"
                }
            }
            catch (e) {
                fault = "verify() threw - " + e
            }
        }

        if (fault == "") {
            try {
                this.update()

                local ready = !this.frame.cursorBlocked && this.initialise() && this.positionChildren()
                if (ready) {
                    this.renderTooltip()
                }
                this.state.strikes = 0
            }
            catch (e) {
                this.state.strikes += 1
                if (this.state.strikes >= this.style.maxStrikes) {
                    fault = "" + e
                }
            }
        }

        if (fault != "") {
            this.state.down = true
            ::options.failHdFeature(::Enum.HdFeature.tooltips)
            println("squi: strat tooltips STOOD DOWN - " + fault)
        }
    }
}

local stratTooltips = StratTooltips()
stratTooltips.open()

local tooltipCanvas = ::UI.canvas("##strat_tooltipscanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(tooltipCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(tooltipCanvas, function() { stratTooltips.render() })
::UI.widgetUnderlay(tooltipCanvas, true)

::UI.onResize(function(w, h) { stratTooltips.open() })

::EX.stratTooltips <- stratTooltips
