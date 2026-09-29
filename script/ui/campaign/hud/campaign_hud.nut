local CampaignHud = class (::EX.HudPane) {
    metrics = {
        paneHeight = 181,

        bgMidY = 52,

        tabY = 0, tabGap = 0,
        tabTextX = 0, tabTextY = 2,
        tabRound = 40,

        missionsX = 234, missionsY = 1,

        buildX = 251, buildY = 97,
        trainX = 159, trainY = 97,
        factionX = 290, factionY = 1,
        endTurnX = 64, endTurnY = 1,
        financeX = 76, financeY = 82,
        moneyX = 190, moneyY = 30, moneyGapY = 16,

        arrowX = 5, arrowUpY = 82, arrowDownY = 152,

        fontSize = 14, moneyFontSize = 14,
    }

    style = {
        bgLeftSprite  = "STRAT_HUD_LEFT",
        bgMidSprite   = "STRAT_HUD_MIDDLE",
        bgRightSprite = "STRAT_HUD_RIGHT",

        bgLeftScale  = 1.0,
        bgMidScale   = 1.0,
        bgRightScale = 1.0,

        tabPrefixM2  = "HUD_TAB_",
        tabPrefixRtw = "HUD_TEXT_TAB_",
        tabParts     = ["LEFT", "MID", "MID", "RIGHT"],

        tabArmy   = "SMT_ARMY",
        tabFleet  = "SMT_FLEET",
        tabAgents = "SMT_AGENTS",
        tabCity   = "SMT_CITY",
        tabTown   = "ST_TOWN",
        tabCastle = "ST_CASTLE",

        cityLevel = 3,

        tabLists = [::ui.StratList.armies, ::ui.StratList.settlements,
                    ::ui.StratList.characters, -1],

        buildSprite    = "BUILD_BUTTON_IMAGE",
        trainSprite    = "TRAIN_BUTTON_IMAGE",

        fieldSprite    = "FIELD_CONSTRUCTION_BUTTON_IMAGE",
        mercsSprite    = "HIRE_MERCS_BUTTON_IMAGE",

        disabledSprites = { build = "BUILD_BUTTON_IMAGE_DISABLED",
                            train = "TRAIN_BUTTON_IMAGE_DISABLED",
                            field = "FIELD_CONSTRUCTION_BUTTON_IMAGE_DISABLED",
                            mercs = "HIRE_MERCS_BUTTON_IMAGE_DISABLED" },
        endTurnSprite  = "END_TURN_BUTTON_IMAGE",
        financeSprite  = "FINANCE_BUTTON_IMAGE",
        missionsSprite = "MISSION_BUTTON",
        arrowUpSprite   = "UP_ARROW",
        arrowDownSprite = "DOWN_ARROW",

        imageFilter  = 0,
        disabledTint = 110,
        tabTextColour       = [245, 230, 175],
        tabTextColourActive = [0, 0, 0],
        tabTextColourDead   = [128, 119, 97],
        hoverAlpha   = 205,
        pressAlpha   = 150,
        bodyFont     = null,
        sdfText      = false,
        // [tip-rich] Faces from hud_pane.nut's ::EX.look, each falling back to bodyFont's face:
        //   tabFace   "display" (Constantine, as the settlement names and tooltip headings) or "title"
        //             (Montserrat SemiBold) or null for the body face, as before
        //   moneyFace "title" (SemiBold) or "display" or null
        tabFace      = "display",
        moneyFace    = "title",
        textShadow   = true,   // the tooltips' 1px shadow under the tab labels and the treasury

        maxStrikes   = 8,

        showBackground  = true,
        showButtons = true,
        showMoney   = true,
        fieldButtons = true,

        moneyTextColour     = [245, 230, 175],
        moneyTextColourUp   = [140, 220, 140],
        moneyTextColourDown = [225, 120, 120],

        deadTooltips = { build = ["SMT_NOTHING_TO_CONSTRUCT"],
                         train = ["SMT_NOTHING_TO_TRAIN"],
                         field = ["TMT_BUILD_FORT_OR_WATCHTOWER", "TMT_BUILD_WATCHTOWER"],
                         mercs = ["SMT_ONLY_FAMILY_CAN_RECRUIT_MERCENARIES"] },

        tooltips = { build = ["SMT_OPEN_CONSTRUCTION_WINDOW"],
                     train = ["SMT_OPEN_TRAINING_WINDOW"],
                     endTurn = ["SMT_END_TURN"],
                     faction = ["SMT_FACTION_BUTTON_TOOLTIP"],
                     finance = ["SMT_FINANCE_BUTTON", "SMT_OPEN_FINANCE_WINDOW"],
                     missions = ["SMT_MISSION_BUTTON"],
                     field = ["TMT_BUILD_FORT_OR_WATCHTOWER", "TMT_BUILD_WATCHTOWER"],
                     mercs = ["SMT_OPEN_MERCENARY_RECRUITMENT"] },

        deconstructTooltip = ["TMT_DECONSTRUCT_WATCHTOWER"],
        noMercsTooltip     = ["SMT_NO_MERCENARIES_AVAILABLE"],
    }

    feature = ::Enum.HdFeature.campaignHud
    art   = null
    font  = null
    frame = null
    tab   = 0
    crest = null
    crestFor = -1
    pendingTip = null   // [hd-tips] the hovered button's text, drawn after the HUD
    tabFont   = null     // [tip-rich] resolved in open()
    moneyFont = null
    state = { verified = false, down = false, strikes = 0 }

    function open() {
        this.openPaneFull()

        this.art = { left = ::UI.loadSprite(this.style.bgLeftSprite, ::UI.PAGE_STRATEGY),
                     middle = ::UI.loadSprite(this.style.bgMidSprite, ::UI.PAGE_STRATEGY),
                     right = ::UI.loadSprite(this.style.bgRightSprite, ::UI.PAGE_STRATEGY),
                     build = ::UI.loadSprite(this.style.buildSprite, ::UI.PAGE_STRATEGY),
                     train = ::UI.loadSprite(this.style.trainSprite, ::UI.PAGE_STRATEGY),
                     field = ::UI.loadSprite(this.style.fieldSprite, ::UI.PAGE_STRATEGY),
                     mercs = ::UI.loadSprite(this.style.mercsSprite, ::UI.PAGE_STRATEGY),
                     endTurn = ::UI.loadSprite(this.style.endTurnSprite, ::UI.PAGE_STRATEGY),
                     finance = ::UI.loadSprite(this.style.financeSprite, ::UI.PAGE_STRATEGY),
                     missions = ::UI.loadSprite(this.style.missionsSprite, ::UI.PAGE_STRATEGY),
                     arrowUp = ::UI.loadSprite(this.style.arrowUpSprite, ::UI.PAGE_SHARED),
                     arrowDown = ::UI.loadSprite(this.style.arrowDownSprite, ::UI.PAGE_SHARED),
                     tabs = [], dead = {} }
        foreach (id, name in this.style.disabledSprites) {
            this.art.dead[id] <- ::UI.loadSprite(name, ::UI.PAGE_STRATEGY)
        }
        local prefix = ("RTW" in getroottable()) ? this.style.tabPrefixRtw : this.style.tabPrefixM2
        foreach (part in this.style.tabParts) {
            this.art.tabs.append([::UI.loadSprite(prefix + part, ::UI.PAGE_STRATEGY),
                                  ::UI.loadSprite(prefix + part + "_SELECTED", ::UI.PAGE_STRATEGY)])
        }

        this.font = this.style.bodyFont != null ? this.style.bodyFont : ::EX.fonts.body
        this.tabFont = this.lookFace(this.style.tabFace)       // [tip-rich]
        this.moneyFont = this.lookFace(this.style.moneyFace)
    }

    // [tip-rich] "display" / "title" -> that face from hud_pane.nut's ::EX.look, else the body font.
    function lookFace(which) {
        local look = "look" in ::EX ? ::EX.look : null
        if (look != null && which == "display" && "tooltipTitleFace" in look && look.tooltipTitleFace != null) {
            return look.tooltipTitleFace
        }
        if (look != null && (which == "display" || which == "title") && "titleFace" in look && look.titleFace != null) {
            return look.titleFace
        }
        return this.font
    }

    // [tip-rich] The shadow style, when asked for and hud_pane.nut has it.
    function pushShadow() {
        if (!this.style.textShadow || !("tipTextShadow" in ::EX)) return false
        ::UI.pushStyle(::EX.tipTextShadow(::UI.dpiScale()))
        return true
    }

    function claimShortcuts() {
        ::UI.keyboard.shortcut("automerge_units", function (name) {
            if (!this.visible(::Enum.UiContext.campaignLive)) {
                return false
            }
            local army = ::ui.cardManager().selectedArmy
            if (army == null && this.frame != null && this.frame.settlement != null) {
                army = this.frame.settlement.army
            }
            return army != null ? army.mergeUnits() : false
        }.bindenv(this))
    }

    function update() {
        local mine = ::game.localFaction()
        if (mine != null && mine.id != this.crestFor) {
            this.crestFor = mine.id
            this.crest = ::UI.loadSpriteById(mine.logoId, ::UI.PAGE_STRATEGY)
        }

        local cards = ::ui.cardManager()
        local settlement = cards.selectedSettlement
        local fort = cards.selectedFort
        local army = cards.selectedArmy

        this.frame = { settlement = settlement,
                       character = cards.selectedCharacter,
                       canEndTurn = ::ui.canEndTurn(),
                       hdScrolls = ::options.hdFeature(::Enum.HdFeature.scrolls),
                       tabLive = [army != null || (settlement != null && settlement.army != null)
                                                || (fort != null && fort.army != null),
                                  settlement != null,
                                  (army != null && army.travellingAgents > 0)
                                      || (mine != null && settlement != null
                                          && settlement.visitingAgents(mine) > 0)
                                      || (mine != null && fort != null
                                          && fort.visitingAgents(mine) > 0),
                                  army != null && army.transportedArmy != null],
                       tabLabels = this.tabLabels(settlement, cards.selectedCharacter),
                       money = mine != null ? mine.money : 0,
                       income = mine != null ? mine.projectedIncome : 0,
                       fieldArmy = null,
                       fieldState = -1,
                       mercsReady = false,
                       mercsAllowed = false }

        if (this.style.fieldButtons && settlement == null && army != null) {
            this.frame.fieldArmy = army
            this.frame.fieldState = this.fieldConstructionState(army)
            this.frame.mercsReady = army.mercenariesAvailable
            this.frame.mercsAllowed = army.canRecruitMercenaries
        }

        if (!this.frame.tabLive[this.tab]) {
            foreach (i, live in this.frame.tabLive) {
                if (live) {
                    this.tab = i
                    break
                }
            }
        }
    }

    function button(id, art, mx, my, live) {
        local dead = !live && id != null && id in this.art.dead ? this.art.dead[id] : null
        if (dead != null && dead.img != 0) {
            art = dead
        }
        local size = this.scaledSize(art)   // [m2ex-hd-fix] was ::UI.imageSize (unscaled)
        if (size == null) {
            return null
        }
        local w = size[0]
        local h = size[1]
        local x = mx < 0 ? this.pane.x + this.pane.w + mx : this.pane.x + mx
        local y = this.pane.y + my
        local tint = live || (dead != null && dead.img != 0) ? 255 : this.style.disabledTint
        if (!live) {
            ::UI.image(art.img, w, h, x, y, tint, tint, tint, 255)
            return { x = x, y = y, w = w, h = h, clicked = false }
        }
        return ::UI.imageButton("##btn" + id, art, w, h, x, y)
    }

    function fieldConstructionState(army) {
        local ok = ::Enum.FieldConstruction.ok
        if (army.fieldConstructionTest(0) == ok || army.fieldConstructionTest(1) == ok) {
            return 0
        }
        return army.fieldConstructionTest(2) == ok ? 2 : -1
    }

    function dragging() {
        return "campaignCards" in ::EX && ::EX.campaignCards.dragLive()
    }

    function tooltipKeys(id, live) {
        if (id == "field" && live && this.frame.fieldState == 2) {
            return this.style.deconstructTooltip
        }
        if (id == "mercs" && !live && this.frame.mercsAllowed) {
            return this.style.noMercsTooltip
        }
        if (!live) {
            return (id in this.style.deadTooltips) ? this.style.deadTooltips[id] : []
        }
        return (id in this.style.tooltips) ? this.style.tooltips[id] : []
    }

    function text(keys) {
        foreach (key in keys) {
            local found = ::game.stratText(key)
            if (found != "") {
                return found
            }
        }
        return ""
    }

    function tabLabels(settlement, character) {
        local army = character != null ? character.army : null
        local navy = army != null && army.isNavy

        local seat = this.style.tabCity
        if (settlement != null) {
            seat = settlement.isCastle ? this.style.tabCastle
                 : settlement.level < this.style.cityLevel ? this.style.tabTown
                 : this.style.tabCity
        }

        return [::game.stratText(navy ? this.style.tabFleet : this.style.tabArmy),
                this.sharedOrStratText(seat),
                ::game.stratText(this.style.tabAgents),
                navy ? ::game.stratText(this.style.tabArmy) : ""]
    }

    function sharedOrStratText(key) {
        local found = ::scripting.textTable(key, ::Enum.StringTable.shared)
        return found != "" ? found : ::game.stratText(key)
    }

    function runCommand(id) {
        if (id == "build" && this.frame.settlement != null) {
            ::ui.showConstruction(this.frame.settlement)
        } else if (id == "train" && this.frame.settlement != null) {
            ::ui.showRecruitment(this.frame.settlement)
        } else if (id == "field" && this.frame.fieldArmy != null) {
            ::ui.showFieldConstruction(this.frame.fieldArmy)
        } else if (id == "mercs" && this.frame.character != null) {
            ::ui.showCharacter(this.frame.character)
        } else if (id == "endTurn") {
            ::ui.endTurn()
        } else if (id == "faction") {
            ::ui.showFaction()
        } else if (id == "finance") {
            ::ui.showFinance()
        } else if (id == "missions") {
            ::ui.showMissions()
        }
    }

    function centreX(w) {
        return this.pane.x + (this.pane.w - w) / 2
    }

    function renderBackground() {
        // [m2ex-hd-fix] sizes follow the pane scale
        local left = this.scaledSize(this.art.left, this.style.bgLeftScale)
        local mid = this.scaledSize(this.art.middle, this.style.bgMidScale)
        local right = this.scaledSize(this.art.right, this.style.bgRightScale)
        if (left == null || mid == null || right == null) {
            return
        }

        local leftW = left[0]
        local leftH = left[1]
        local rightW = right[0]
        local rightH = right[1]
        local midH = mid[1]
        local midW = this.pane.w - leftW - rightW
        local bottom = this.pane.y + this.pane.h

        ::UI.imageButton("##bgLeft", this.art.left, leftW, leftH, this.pane.x, bottom - leftH)
        ::UI.imageButton("##bgRight", this.art.right, rightW, rightH,
                         this.pane.x + this.pane.w - rightW, bottom - rightH)

        if (midW <= 0) {
            return
        }
        local midX = this.pane.x + leftW
        local midY = this.pane.y + this.px.bgMidY
        local halfW = midW / 2
        ::UI.imageButton("##bgMid0", this.art.middle, halfW, midH, midX, midY)
        ::UI.imageButton("##bgMid1", this.art.middle, midW - halfW, midH, midX + halfW, midY)
    }

    function tabRunWidth() {
        local total = 0
        foreach (i, pair in this.art.tabs) {
            local art = this.tab == i ? pair[1] : pair[0]
            local size = this.scaledSize(art)   // [m2ex-hd-fix]
            if (size != null) {
                total += size[0] + this.px.tabGap
            }
        }
        return total > 0 ? total - this.px.tabGap : 0
    }

    function renderTabs() {
        local x = this.centreX(this.tabRunWidth()) - this.pane.x
        ::UI.pushStyle({ [::UI.Metric.pressOffset] = 0,
                         [::UI.Metric.hoverLighten] = 0,
                         [::UI.Metric.pressDarken] = 0,
                         [::UI.Metric.disabledAlpha] = 255,
                         [::UI.Colour.textDisabled] = this.style.tabTextColourDead })

        foreach (i, pair in this.art.tabs) {
            local live = this.frame.tabLive[i]
            local art = live && this.tab == i ? pair[1] : pair[0]
            local size = this.scaledSize(art)   // [m2ex-hd-fix]
            if (size == null) {
                continue
            }
            local w = size[0]
            local h = size[1]
            local bx = this.pane.x + x
            local by = this.pane.y + this.px.tabY
            local r = this.px.tabRound

            local cx = i == 0 ? bx : bx - r
            local cw = w + (i == 0 ? 0 : r) + (i == this.art.tabs.len() - 1 ? 0 : r)
            ::UI.pushRoundedClip(cx, by, cw, h + r, r)
            ::UI.image(art, w, h, bx, by)
            ::UI.popRoundedClip()

            local hit = ::UI.hitRect(bx, by, w, h)
            local label = this.frame.tabLabels[i]
            if (label != "") {
                local colour = this.tab == i ? this.style.tabTextColourActive : this.style.tabTextColour
                local face = this.tabFont != null ? this.tabFont : this.font   // [tip-rich]
                // No shadow on the selected tab: its label is dark on the lit art.
                local shadowed = live && this.tab != i && this.pushShadow()
                ::UI.pushFont(face, this.style.sdfText, this.px.fontSize)
                local m = ::UI.textSize(label, face, this.px.fontSize)
                ::UI.layoutAt(bx + (w - m[0]) / 2 + this.px.tabTextX,
                              by + (h - m[1]) / 2 + this.px.tabTextY)
                if (live) { ::UI.textColoured(label, colour[0], colour[1], colour[2], 255) }
                else { ::UI.textDisabled(label) }
                ::UI.popFont()
                if (shadowed) ::UI.popStyle()
            }

            if (hit.clicked && live && !this.dragging()) {
                this.tab = i
            }
            if (hit.heldRight && ::UI.mouse.clicked(::UI.mouse.right)
                && this.style.tabLists[i] >= 0) {
                ::ui.toggleList(this.style.tabLists[i])
            }
            x += w + this.px.tabGap
        }
        ::UI.popStyle()
    }

    function verify() {
        if (this.pane == null || this.px == null || this.font == null) {
            return false
        }
        foreach (key, value in this.metrics) {
            if (typeof(value) == "integer" && !(key in this.px)) {
                return false
            }
        }
        if (this.art == null || this.art.tabs == null || this.art.dead == null) {
            return false
        }
        foreach (id in ["left", "middle", "right", "build", "train", "field", "mercs", "endTurn",
                        "finance", "missions", "arrowUp", "arrowDown"]) {
            if (!(id in this.art) || this.art[id] == null) {
                return false
            }
        }
        if (this.art.dead.len() != this.style.disabledSprites.len()) {
            return false
        }
        if (this.art.tabs.len() != this.style.tabParts.len()) {
            return false
        }
        foreach (pair in this.art.tabs) {
            if (pair == null || pair.len() != 2 || pair[0] == null || pair[1] == null) {
                return false
            }
        }
        local labels = this.tabLabels(null, null)
        if (labels.len() < this.art.tabs.len()
            || this.style.tabLists.len() < this.art.tabs.len()) {
            return false
        }
        if (this.tab < 0 || this.tab >= this.art.tabs.len()) {
            return false
        }
        foreach (colour in [this.style.tabTextColour, this.style.tabTextColourActive, this.style.tabTextColourDead,
                         this.style.moneyTextColour, this.style.moneyTextColourUp, this.style.moneyTextColourDown]) {
            if (colour == null || colour.len() < 3) {
                return false
            }
        }
        if (::UI.textSize("M", this.font, this.px.fontSize) == null) {
            return false
        }
        if (::UI.loadSpriteById == null || ::UI.pushRoundedClip == null) {
            return false
        }
        if (::ui.cardManager == null) {
            return false
        }
        if (::ui.canEndTurn == null || ::ui.endTurn == null || ::ui.toggleList == null) {
            return false
        }
        if (::ui.showConstruction == null || ::ui.showRecruitment == null
            || ::ui.showFieldConstruction == null || ::ui.showCharacter == null
            || ::ui.showFaction == null || ::ui.showFinance == null || ::ui.showMissions == null) {
            return false
        }
        return ::game.localFaction != null && ::game.stratText != null
               && ::scripting.textTable != null
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

                ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter,
                                 [::UI.Metric.hoverLighten] = 0,
                                 [::UI.Metric.pressDarken] = 0,
                                 [::UI.Metric.pressOffset] = 0 })
                ::UI.pushHitMode(::UI.Hit.alpha)

                if (this.style.showBackground) {
                    this.renderBackground()
                }
                ::UI.popStyle()

                if (this.style.showButtons) {
                    ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter })
                    this.renderTabs()
                    this.renderButtons()
                    this.renderArrows()
                    if (this.style.showMoney) {
                        this.renderMoney()
                    }
                    ::UI.popStyle()
                }
                ::UI.popHitMode()
                this.drawPendingTip()   // [hd-tips]
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
            println("squi: campaign hud STOOD DOWN - " + fault)
        }
    }

    function renderButtons() {
        local hasSettlement = this.frame.settlement != null
        local inField = this.frame.fieldArmy != null
        local buildId = inField ? "field" : "build"
        local trainId = inField ? "mercs" : "train"
        local buildArt = inField ? this.art.field : this.art.build
        local trainArt = inField ? this.art.mercs : this.art.train
        local buildLive = inField ? this.frame.fieldState >= 0 : hasSettlement
        local trainLive = inField ? (this.frame.mercsReady && this.frame.mercsAllowed) : hasSettlement
        foreach (row in [[buildId, buildArt, -this.px.buildX, this.px.buildY, buildLive],
                         [trainId, trainArt, -this.px.trainX, this.px.trainY, trainLive],
                         ["finance", this.art.finance, -this.px.financeX, this.px.financeY, true],
                         ["missions", this.art.missions, this.px.missionsX, this.px.missionsY, true],
                         ["faction", this.crest, -this.px.factionX, this.px.factionY, true],
                         ["endTurn", this.art.endTurn, -this.px.endTurnX, this.px.endTurnY,
                          this.frame.canEndTurn]]) {
            local hit = this.button(row[0], row[1], row[2], row[3], row[4])
            if (hit != null) {
                local tip = this.text(this.tooltipKeys(row[0], row[4]))
                if (tip != "") {
                    // [hd-tips] Raised invisibly, as the map tooltips do; the visible box is drawn with
                    // ::EX.drawTip once the HUD is done, in the map tooltips' font and colours.
                    if ("drawTip" in ::EX && "ghostStyle" in ::EX) {
                        ::UI.pushStyle(::EX.ghostStyle())
                        ::UI.tooltipAt(hit.x, hit.y, hit.w, hit.h)
                        ::UI.tooltip(0, tip)
                        ::UI.popStyle()
                        local m = ::UI.mouse.pos()
                        if (m[0] >= hit.x && m[0] < hit.x + hit.w && m[1] >= hit.y && m[1] < hit.y + hit.h) {
                            this.pendingTip = tip
                        }
                    } else {
                        ::UI.tooltipAt(hit.x, hit.y, hit.w, hit.h)
                        ::UI.tooltip(0, tip)
                    }
                }
                if (hit.clicked && !this.dragging()) {
                    this.runCommand(row[0])
                }
            }
        }
    }

    // [hd-tips] The hovered button's tooltip in the campaign map tooltip's box, font and colours.
    function drawPendingTip() {
        local text = this.pendingTip
        this.pendingTip = null
        if (text == null || this.dragging() || !("drawTip" in ::EX)) {
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
            println("squi: [hd-tips] button tooltip failed - " + e)
        }
    }

    function renderArrows() {
        local rack = ("campaignCards" in ::EX) ? ::EX.campaignCards : null
        if (rack == null) {
            return
        }
        local over = rack.maxScroll()
        if (over <= 0) {
            return
        }
        local arrowX = this.centreX(rack.px.w) - this.pane.x + rack.px.w + this.px.arrowX
        if (rack.scrollRow > 0) {
            local up = this.button("arrowUp", this.art.arrowUp, arrowX, this.px.arrowUpY, true)
            if (up != null && up.clicked && !this.dragging()) {
                rack.scrollBy(-1)
            }
        }
        if (rack.scrollRow < over) {
            local down = this.button("arrowDown", this.art.arrowDown, arrowX, this.px.arrowDownY, true)
            if (down != null && down.clicked && !this.dragging()) {
                rack.scrollBy(1)
            }
        }
    }

    function renderMoney() {
        local x = this.pane.x + this.pane.w - this.px.moneyX
        local y = this.pane.y + this.px.moneyY
        local colour = this.style.moneyTextColour

        local shadowed = this.pushShadow()   // [tip-rich]
        ::UI.pushFont(this.moneyFont != null ? this.moneyFont : this.font, this.style.sdfText, this.px.moneyFontSize)
        ::UI.layoutAt(x, y)
        ::UI.textColoured(this.frame.money.tostring(), colour[0], colour[1], colour[2], 255)

        local income = this.frame.income
        local delta = income > 0 ? this.style.moneyTextColourUp
                    : income < 0 ? this.style.moneyTextColourDown
                                 : colour
        ::UI.layoutAt(x, y + this.px.moneyGapY)
        ::UI.textColoured((income > 0 ? "+" : "") + income.tostring(),
                          delta[0], delta[1], delta[2], 255)
        ::UI.popFont()
        if (shadowed) ::UI.popStyle()
    }
}

local campaignHud = CampaignHud()
campaignHud.open()

local campaignHudCanvas = ::UI.canvas("##campaign_hudcanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(campaignHudCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.setWidgetStyle(campaignHudCanvas, ::UI.Cap.autoScale, 0)
::UI.onDraw(campaignHudCanvas, function() { campaignHud.render() })
::UI.widgetUnderlay(campaignHudCanvas, true)

campaignHud.claimShortcuts()

::UI.onResize(function(w, h) { campaignHud.open() })

::EX.campaignHud <- campaignHud
