local CampaignCards = class (::EX.CardRack) {
    // 1080p units, scaled by UI.dpiScale(); perRow, rows and buildPerRow are counts. [m2ex-hd-fix]
    metrics = {
        paneHeight = 181,

        // Twenty 64x64 cards to a row is 1280 wide and 128 tall.
        y = 54, w = 1280,
        cardW = 64, cardH = 64,
        perRow = 20, rows = 2,

        // The portrait fills the card.
        portraitX = 0, portraitY = 0, portraitW = 64, portraitH = 64,

        // A building card is the 112x84 art at the unit card's height: 85 wide, 15 to a row.
        buildW = 85, buildPerRow = 15,

        numberX = 2, numberY = 2,
        frameThick = 2,
        dragFan = 4,
        dropZoneAbove = 40, dropZoneSide = 60, dropZoneBelow = 60,
        fontSize = 10,
    }

    style = {
        backgroundSprite = "STRAT_CARD_BACKGROUND",
        selectedSprite   = "STRAT_CARD_SELECTED_BACKGROUND",

        imageFilter  = 2,
        bodyFont     = null,
        sdfText      = false,
        numberColour = [0, 0, 0],
        groupFrame   = [255, 205, 90],

        showNumbers = true,
        selectedLift = 125,

        maxStrikes = 8,
    }

    buildings = false
    agents    = false
    tab       = -1
    hoverIndex = -1
    pressSelected = false
    anchor    = -1
    feature   = ::Enum.HdFeature.campaignHud
    art       = null
    font      = null
    scrollRow = 0
    portraits = null
    pendingTip = null   // [hd-tips] the hovered card's text, drawn once the cards are done
    state     = { verified = false, down = false, strikes = 0 }

    function open() {
        this.openPaneFull({ perRow = true, rows = true, buildPerRow = true })   // [m2ex-hd-fix]
        this.px.left <- this.pane.x + (this.pane.w - this.px.w) / 2
        this.px.top <- this.pane.y + this.px.y

        this.art = { background = ::UI.loadSprite(this.style.backgroundSprite, ::UI.PAGE_SHARED),
                     selected = ::UI.loadSprite(this.style.selectedSprite, ::UI.PAGE_SHARED) }

        this.font = this.style.bodyFont != null ? this.style.bodyFont : ::EX.fonts.body
        this.portraits = {}
        this.rack = []
    }

    // The rack follows the HUD's tab: the units of whatever is selected, or a settlement's buildings.
    function update() {
        local cards = ::ui.cardManager()
        local settlement = cards.selectedSettlement
        this.rack = []
        // The HUD's current tab, once that module has loaded.
        local tab = ("campaignHud" in ::EX) ? ::EX.campaignHud.tab : 0
        // A drag left latched over a rack that moved on claims the pointer every frame and deafens the game.
        if (tab != this.tab || (this.dragUnit != null && !::UI.mouse.down(::UI.mouse.left)
                                                      && !::UI.mouse.released(::UI.mouse.left))) {
            this.dragCancel()
        }
        // The anchor is a rack index, so it means nothing once the rack is a different list.
        if (tab != this.tab) {
            this.anchor = -1
        }
        this.tab = tab
        this.buildings = tab == 1
        this.agents = tab == 2

        if (this.buildings) {
            if (settlement == null || settlement.owner == null) {
                return
            }
            local culture = settlement.owner.cultureId
            for (local i = 0; i < settlement.buildingCount; i++) {
                local building = settlement.building(i)
                if (building == null || building.type == null) {
                    continue
                }
                local level = ::buildings.level(building.type, building.level)
                if (level != null) {
                    local shown = ::buildings.levelText(level, settlement.owner.id, 0)
                    this.rack.append({ path = ::buildings.levelImage(level, culture, 0),
                                       name = shown != "" ? shown : building.levelName,
                                       ref = building })
                }
            }
            return
        }

        // The CHARACTERS with the stack or in the residence, generals excluded, as the native tab does.
        if (tab == 2) {
            local stack = cards.selectedArmy
            if (stack != null) {
                for (local i = 0; i < stack.characterCount; i++) {
                    local agent = stack.character(i)
                    if (agent != null && !agent.isGeneral()) { this.rack.append(agent) }
                }
            }
            // A fort spells the same getter `characterAt`, and asking one for `character` raises.
            local fort = settlement == null ? cards.selectedFort : null
            local host = settlement != null ? settlement : fort
            if (host != null) {
                for (local i = 0; i < host.characterCount; i++) {
                    local agent = fort != null ? host.characterAt(i) : host.character(i)
                    if (agent != null && !agent.isGeneral()) { this.rack.append(agent) }
                }
            }
            return
        }

        // selectedArmy is the stack the selection is IN, which is what the native rack fills from.
        local army = cards.selectedArmy

        // The passengers tab racks what a selected fleet carries and NOTHING else.
        if (tab == 3) {
            if (army != null) {
                army = army.transportedArmy
            }
            if (army != null) {
                for (local i = 0; i < army.unitCount; i++) {
                    local unit = army.unit(i)
                    if (unit != null) {
                        this.rack.append(unit)
                    }
                }
            }
            return
        }

        if (army == null && settlement != null) {
            army = settlement.army
        }
        if (army == null) {
            local fort = cards.selectedFort
            if (fort != null) {
                army = fort.army
            }
        }
        if (army == null) {
            return
        }
        for (local i = 0; i < army.unitCount; i++) {
            local unit = army.unit(i)
            if (unit != null) {
                this.rack.append(unit)
            }
        }
    }

    // A building card is a picture and nothing else - no selection, no count, no group.
    function renderBuilding(entry, rect, index) {
        if (entry.path == null || entry.path.len() == 0) {
            return
        }
        if (!(entry.path in this.portraits)) {
            this.portraits[entry.path] <- ::UI.loadTexture(entry.path)
        }
        local face = this.portraits[entry.path]
        if (face != null && face.img != 0) {
            ::UI.image(face.img, rect.w, rect.h, rect.x, rect.y)
        }
        if (index == this.hoverIndex) {
            this.raiseTip(rect, entry.name)   // [hd-tips]
        }
    }

    // An agent's card is its portrait and its type - no selection, no count, no group.
    function renderAgent(agent, rect, index) {
        local art = this.art.background
        if (art != null && art.img != 0) {
            ::UI.image(art.img, rect.w, rect.h, rect.x, rect.y)
        }
        local record = agent.record
        local path = record != null ? record.cardPath : ""
        if (index == this.hoverIndex) {
            this.raiseTip(rect, record != null ? record.displayName : agent.typeName)   // [hd-tips]
        }
        if (path == "") {
            return
        }
        if (!(path in this.portraits)) {
            this.portraits[path] <- ::UI.loadTexture(path)
        }
        local face = this.portraits[path]
        if (face != null && face.img != 0) {
            ::UI.pushStyle({ [::UI.Colour.imageGlow] = [this.style.selectedLift, this.style.selectedLift,
                                                        this.style.selectedLift,
                                                        agent.isCardSelected ? 255 : 0] })
            ::UI.image(face.img, this.px.portraitW, this.px.portraitH,
                       rect.x + this.px.portraitX, rect.y + this.px.portraitY)
            ::UI.popStyle()
        }
    }

    // How many rows the rack needs for everything in it.
    function rowCount() {
        local perRow = this.slotsPerRow()
        return (this.rack.len() + perRow - 1) / perRow
    }

    function maxScroll() {
        local over = this.rowCount() - this.metrics.rows
        return over > 0 ? over : 0
    }

    function scrollBy(rows) {
        this.scrollRow += rows
        if (this.scrollRow > this.maxScroll()) { this.scrollRow = this.maxScroll() }
        if (this.scrollRow < 0) { this.scrollRow = 0 }
    }

    // Card n, laid left to right from the top row down, minus whatever is scrolled away.
    // Buildings are a wider card than units, and fewer fit in a row.
    function slotW() { return this.buildings ? this.px.buildW : this.px.cardW }
    function slotsPerRow() { return this.buildings ? this.px.buildPerRow : this.px.perRow }

    function cardRect(index) {
        local perRow = this.slotsPerRow()
        local w = this.slotW()
        local col = index % perRow
        local row = index / perRow - this.scrollRow
        return { x = this.px.left + col * w,
                 y = this.px.top + row * this.px.cardH,
                 w = w, h = this.px.cardH }
    }

    // The run from the anchor to the clicked card, REPLACING the selection - so shift-clicking
    // back towards the anchor shortens the run instead of leaving the far end selected.
    function selectRange(from, to) {
        local lo = from < to ? from : to
        local hi = from < to ? to : from
        local mode = ::Enum.SelectMode.replace
        for (local i = lo; i <= hi; i++) {
            if (this.slotUsable(i) && this.rack[i] != null) {
                this.pick(this.rack[i], mode)
                mode = ::Enum.SelectMode.add
            }
        }
    }

    // unit.select makes the card when the engine has none, so a garrison unit selects like any other.
    function pick(unit, mode) {
        if (unit.select(mode)) {
            return
        }
        local host = ::ui.cardManager().selectedSettlement
        if (host != null) {
            host.select()
            unit.select(mode)
        }
    }

    // A row scrolled out of the strip is clipped from the draw, so it is not a target either.
    function slotUsable(index) {
        local r = this.cardRect(index)
        return r.y >= this.px.top && r.y < this.px.top + this.px.cardH * this.metrics.rows
    }

    // Only a unit card is ever picked; a building or an agent entry has no selection to ask about.
    function cardPicked(entry) {
        return !this.buildings && !this.agents && entry.isSelected
    }

    // The whole card: frame, portrait, the group numeral and the soldier count.
    function renderCard(unit, rect, index) {
        local lit = unit.isSelected || unit == this.dragUnit
        local art = lit ? this.art.selected : this.art.background
        if (art != null && art.img != 0) {
            ::UI.image(art.img, rect.w, rect.h, rect.x, rect.y)
        }

        local path = unit.cardPath
        if (!(path in this.portraits)) {
            this.portraits[path] <- ::UI.loadTexture(path)
        }
        local face = this.portraits[path]
        if (face != null && face.img != 0) {
            // The native card redraws the face under a 2x colour scale; an additive pass matches it.
            ::UI.pushStyle({ [::UI.Colour.imageGlow] = [this.style.selectedLift, this.style.selectedLift,
                                                        this.style.selectedLift, lit ? 255 : 0] })
            ::UI.image(face.img, this.px.portraitW, this.px.portraitH,
                       rect.x + this.px.portraitX, rect.y + this.px.portraitY)
            ::UI.popStyle()
        }

        local group = unit.groupId
        if (group >= 0) {
            local edge = this.style.groupFrame
            ::UI.drawRect(rect.x, rect.y, rect.w, this.px.frameThick, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(rect.x, rect.y + rect.h - this.px.frameThick, rect.w, this.px.frameThick,
                          edge[0], edge[1], edge[2], 255)
        }

        if (this.style.showNumbers) {
            local ink = this.style.numberColour
            ::UI.pushFont(this.font, this.style.sdfText, this.px.fontSize)
            ::UI.layoutAt(rect.x + this.px.numberX, rect.y + this.px.numberY)
            ::UI.textColoured(unit.displayedSoldiers.tostring(), ink[0], ink[1], ink[2], 255)
            ::UI.popFont()
        }

        // Only the card under the cursor needs its text built, and never the one riding it.
        if (index >= 0 && index == this.hoverIndex) {
            this.raiseTip(rect, this.cardText(unit))   // [hd-tips]
        }
    }

    // [hd-tips] A card's tooltip in the same box and font as the campaign map's (::EX.drawTip), not
    // the engine's own, which draws in the game's legacy face. The engine tooltip is still raised,
    // invisibly (::EX.ghostStyle), so hovering behaves as before; the visible box is drawn after the
    // cards, once the strip's clip is off, so it is never cut to the strip.
    function raiseTip(rect, text) {
        if (text == null || text == "") {
            return
        }
        if ("drawTip" in ::EX && "ghostStyle" in ::EX) {
            ::UI.pushStyle(::EX.ghostStyle())
            ::UI.tooltipAt(rect.x, rect.y, rect.w, rect.h)
            ::UI.tooltip(0, text)
            ::UI.popStyle()
            this.pendingTip = text
            return
        }
        ::UI.tooltipAt(rect.x, rect.y, rect.w, rect.h)
        ::UI.tooltip(0, text)
    }

    // [hd-tips] The campaign map tooltip's colours, so every tooltip on the map looks alike.
    function drawPendingTip() {
        local text = this.pendingTip
        this.pendingTip = null
        if (text == null || !("drawTip" in ::EX)) {
            return
        }
        local look = ("stratTooltips" in ::EX && ::EX.stratTooltips != null) ? ::EX.stratTooltips.style : null
        local bg = look != null && "background" in look ? look.background : [0, 0, 0, 160]
        local edge = look != null && "border" in look ? look.border : [255, 245, 139, 255]
        local ink = look != null && "ink" in look ? look.ink : [255, 245, 139, 255]
        try {
            ::EX.drawTip(text, bg, edge, ink)
        }
        catch (e) {
            println("squi: [hd-tips] card tooltip failed - " + e)
        }
    }

    // What the native card says: who commands it, what it is, and whatever name it was given.
    function cardText(unit) {
        local kind = unit.type != null ? unit.type.displayName : ""
        local record = unit.general != null ? unit.general.record : null
        local text = record != null ? record.displayName + ": " + kind : kind
        if (unit.isFreeUpkeep) {
            text += "\n" + ::scripting.textTable("SMT_FREE_UPKEEP", ::Enum.StringTable.strat)
        }
        if (unit.name != "") {
            text += "\n" + unit.name
        }
        return text
    }

    // Click selects, ctrl toggles, shift adds, a drag reorders or merges; right-click raises the scroll.
    function handleMouse() {
        local m = ::UI.mouse.pos()
        local over = -1
        for (local i = 0; i < this.rack.len(); i++) {
            local r = this.cardRect(i)
            if (r.y < this.px.top || r.y >= this.px.top + this.px.cardH * this.metrics.rows) {
                continue   // scrolled out of the strip: clipped from the draw, so not clickable either
            }
            if (m[0] >= r.x && m[0] < r.x + r.w && m[1] >= r.y && m[1] < r.y + r.h) {
                over = i
            }
        }
        this.hoverIndex = over
        if (over < 0 && this.dragUnit == null) {
            if (::UI.mouse.clicked(::UI.mouse.left) && !this.buildings
                && !(::UI.keyboard.mods() & (::UI.Mod.shift | ::UI.Mod.ctrl))
                && m[0] >= this.px.left && m[0] < this.px.left + this.px.w
                && m[1] >= this.px.top && m[1] < this.px.top + this.px.cardH * this.metrics.rows) {
                ::ui.cardManager().selectedUnitCount = 0
            }
            return
        }
        if (over >= 0 || this.dragLive()) {
            ::UI.mouse.capture()
        }

        local entry = over >= 0 ? this.rack[over] : null

        if (this.buildings) {
            if (entry != null && ::UI.mouse.clicked(::UI.mouse.right)) {
                entry.ref.showInfoScroll()
            }
            return
        }

        // An agent card raises its character and nothing else - it is not a unit to select or drag.
        if (this.agents) {
            if (entry == null) {
                return
            }
            if (::UI.mouse.clicked(::UI.mouse.right)) {
                ::ui.showCharacter(entry)
            }
            else if (::UI.mouse.clicked(::UI.mouse.left)) {
                entry.selectCard(this.clickMode())
            }
            return
        }

        // A bodyguard raises its character, anything else its own scroll, a fogged card nothing.
        if (entry != null && ::UI.mouse.clicked(::UI.mouse.right)) {
            if (!entry.infoVisibleTo(::game.localFaction(), ::Enum.SpyInfo.type)) {
                return
            }
            local general = entry.general
            if (general != null) { ::ui.showCharacter(general) }
            else { entry.showInfoScroll() }
            return
        }

        // The native rack commits an unmodified click on the press and leaves the rest to the release.
        if (entry != null && ::UI.mouse.clicked(::UI.mouse.left)) {
            this.dragPress(entry, over)
            this.pressSelected = entry.isSelected
            if ((::UI.keyboard.mods() & ::UI.Mod.shift) && this.anchor >= 0) {
                this.selectRange(this.anchor, over)
                return
            }
            this.anchor = over
            if (!entry.isSelected && this.clickMode() == ::Enum.SelectMode.replace) {
                this.pick(entry, ::Enum.SelectMode.replace)
            }
            return
        }

        // The block that travels is the selection, and an unselected card becomes it first.
        if (this.dragUnit != null && ::UI.mouse.dragging(::UI.mouse.left)) {
            if (this.dragBlock == null && !this.dragUnit.isSelected) {
                this.pick(this.dragUnit, this.clickMode())
            }
            this.dragTrack(m[0], m[1])
        }

        if (!::UI.mouse.released(::UI.mouse.left)) {
            return
        }

        local drop = this.dragRelease(m[0], m[1])
        local unit = drop.unit
        if (unit == null) {
            return
        }

        if (drop.moved[0] != 0 || drop.moved[1] != 0) {
            // Reading the army off a unit that has none raises, and this runs inside a canvas draw.
            local army = unit.army
            if (army == null) {
                return
            }
            local slot = drop.slot
            local units = []
            if (drop.block != null) {
                foreach (moving in drop.block) { units.append(moving) }
            }
            if (units.len() == 0) {
                return
            }

            // Inside the strip the drop reorders or merges; only one clear of the HUD reaches the map.
            if (m[0] >= this.pane.x && m[0] < this.pane.x + this.pane.w
                && m[1] >= this.pane.y && m[1] < this.pane.y + this.pane.h) {
                if (slot != null) {
                    local target = this.rack[slot.index]
                    local tr = this.cardRect(slot.index)
                    // A merge needs the cursor ON the card; the drop zone around it only reorders.
                    local onCard = m[0] >= tr.x && m[0] < tr.x + tr.w
                                && m[1] >= tr.y && m[1] < tr.y + tr.h
                    if (units.len() == 1 && onCard && target.canMergeWith(unit)) {
                        target.mergeWith(unit)
                    } else {
                        army.moveUnit(units, slot.before ? slot.index : slot.index + 1)
                    }
                }
                return
            }

            local tile = ::stratMap.hoveredTile()
            if (tile != null) {
                local mine = ::game.localFactionId()
                local foe = tile.character
                local enemy = foe != null && foe.faction != null && foe.faction.id != mine
                if (!enemy && tile.settlement != null && tile.settlement.owner != null) {
                    enemy = tile.settlement.owner.id != mine
                }
                if (enemy) { army.attackWith(units, tile.x, tile.y) }
                else if (army.faction != null) { army.faction.splitArmy(units, tile.x, tile.y) }
            }
            return
        }

        if (::UI.keyboard.mods() & ::UI.Mod.shift) {
            return
        }

        // The press already committed a plain click; only a modifier or an already-selected
        // card still has something to do here, which is what the native rack does.
        if (this.clickMode() != ::Enum.SelectMode.replace || this.pressSelected) {
            this.pick(unit, this.clickMode())
        }
    }

    function verify() {
        if (this.pane == null || this.px == null || this.art == null || this.portraits == null
            || this.rack == null || this.font == null) {
            return false
        }
        foreach (key in ["left", "top", "w", "cardW", "cardH", "perRow", "buildW", "buildPerRow",
                         "portraitX", "portraitY", "portraitW", "portraitH", "numberX", "numberY",
                         "frameThick", "dragFan", "fontSize", "dropZoneAbove", "dropZoneSide",
                         "dropZoneBelow"]) {
            if (!(key in this.px)) {
                return false
            }
        }
        if (this.px.cardH <= 0 || this.px.perRow <= 0 || this.px.buildPerRow <= 0
            || this.metrics.rows <= 0) {
            return false
        }
        if (!("background" in this.art) || !("selected" in this.art)) {
            return false
        }
        if (this.feature != ::Enum.HdFeature.campaignHud) {
            return false
        }
        return ::ui.cardManager != null && ::ui.showCharacter != null && ::buildings != null
               && ::game.localFactionId != null && ::scripting.textTable != null
               && ::stratMap.hoveredTile != null
    }

    function render() {
        if (this.state.down) {
            return
        }

        if (!this.visible(::Enum.UiContext.campaignLive)) {
            return
        }

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

        this.pendingTip = null
        if (fault == "") {
            try {
                this.update()
                this.scrollBy(0)   // a shorter rack must not stay scrolled past its own end
                if (this.rack.len() > 0) {
                    this.handleMouse()

                    ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter })
                    ::UI.pushClip(this.px.left, this.px.top, this.px.w, this.px.cardH * this.metrics.rows)

                    // From the insertion point on the cards slide half a card aside; the block is not drawn here.
                    for (local i = 0; i < this.rack.len(); i++) {
                        if (!this.slotUsable(i)) {
                            continue
                        }
                        if (this.buildings) {
                            this.renderBuilding(this.rack[i], this.cardRect(i), i)
                            continue
                        }
                        if (this.agents) {
                            this.renderAgent(this.rack[i], this.cardRect(i), i)
                            continue
                        }
                        local unit = this.rack[i]
                        if (this.dragLive() && this.cardPicked(unit)) {
                            continue
                        }
                        this.renderCard(unit, this.dragSlide(this.cardRect(i), i), i)
                    }

                    ::UI.popClip()

                    // The block rides the cursor, fanned back with the grabbed card on top.
                    if (this.dragLive()) {
                        local m = ::UI.mouse.pos()
                        for (local i = this.dragBlock.len() - 1; i >= 0; i--) {
                            this.renderCard(this.dragBlock[i],
                                            { x = m[0] - this.px.cardW / 2 - i * this.px.dragFan,
                                              y = m[1] - this.px.cardH / 2 - i * this.px.dragFan,
                                              w = this.px.cardW, h = this.px.cardH }, -1)
                        }
                    }

                    ::UI.popStyle()

                    // [hd-tips] No tooltip while a block is being dragged, as the engine's hid it.
                    if (this.dragLive()) {
                        this.pendingTip = null
                    }
                    this.drawPendingTip()
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
            ::options.failHdFeature(::Enum.HdFeature.campaignHud)
            println("squi: campaign cards STOOD DOWN - " + fault)
        }
    }
}

local campaignCards = CampaignCards()
campaignCards.open()

local campaignCardsCanvas = ::UI.canvas("##campaigncardscanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(campaignCardsCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(campaignCardsCanvas, function() { campaignCards.render() })
::UI.widgetUnderlay(campaignCardsCanvas, true)

::UI.onResize(function(w, h) { campaignCards.open() })

::EX.campaignCards <- campaignCards
