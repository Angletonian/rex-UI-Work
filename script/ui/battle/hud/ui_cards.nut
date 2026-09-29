local BattleCards = class (::EX.CardRack) {
    // Pixels against the 1920x540 pane at 1080p, scaled once by pane.w / paneWidth; overlay positions are the card's own space, 0,0 top-left.
    metrics = {
        paneWidth  = 1920,
        paneHeight = 540,

        cardW  = 64,
        cardH  = 100,
        left   = 320,   // from the pane's left edge; -1 centres the row instead
        gapX   = 0,
        gapY   = 4,
        perRow = 20,
        perRowFull = 20,
        rows = 2,          // how many rows the strip has; cards fill the top one first and overflow down

        minimal = { left = 4, bottom = 4, perRow = 20, rows = 2 },
        groupFrameThick = 2,
        dropZoneAbove = 75, dropZoneSide = 100, dropZoneBelow = 100,
        reloadY = 95, reloadH = 3,
        bottom = 8,

        numberX = 2,
        numberY = 2,
        fontSize = 14,

        starX = 2,   starY = 13,  starW = 16,  starH = 16,
        weaponX = 1, weaponY = 53, weaponW = 14, weaponH = 14,
        armourX = 3, armourY = 66, armourW = 14, armourH = 15,
        // 0 = the sprite's own size, which differs between the ports (M2's chevrons are 10x10, Rome's 9x8).
        xpX = 3,     xpY = 28,     xpW = 0,      xpH = 0,   xpStep = 0,

        // Same inset ratio as the campaign card: 13% down, sitting flush on the card's bottom edge.
        portraitX = 0, portraitY = 12, portraitW = 64, portraitH = 88,

        crusadeX = 40, crusadeY = 0, crusadeW = 0, crusadeH = 0,

        ammoX = 18, ammoY = 89, ammoW = 39, ammoH = 5, ammoInset = 1,

        statusW = 0, statusH = 0,   // 0 = the sprite's own size, as above

        // Each slot shows ONE icon, swapping to the next set bit every cycleSeconds, in the engine's n_unit_state_icon_ids bit order.
        statusSlots = [
            { x = 23, y = 1, bits = [[::Enum.BattleStatus.running, "CARD_RUN"],
                                     [::Enum.BattleStatus.walking, "CARD_WALK"]] },
            { x = 0, y = 0, bits = [[::Enum.BattleStatus.underMissileAttack, "CARD_UNDER_ATTACK_MISSILE"],
                                    [::Enum.BattleStatus.routing, "CARD_PANICKING"],
                                    [::Enum.BattleStatus.hiding, "CARD_HIDING"],
                                    [::Enum.BattleStatus.attackingMelee, "CARD_ATTACKING"],
                                    [::Enum.BattleStatus.attackingMissile, "CARD_ATTACKING_MISSILE"],
                                    [::Enum.BattleStatus.hasLadders, "BUILD_LADDERS"],
                                    [::Enum.BattleStatus.hasRam, "BUILD_RAMS"],
                                    [::Enum.BattleStatus.sapping, "BUILD_SAPPING"],
                                    [::Enum.BattleStatus.hasSiegeTower, "BUILD_TOWERS"],
                                    [::Enum.BattleStatus.aiLinked, "UNIT_LINKED_STATUS_ICON"],
                                    [::Enum.BattleStatus.runningAmok, "CARD_RUNNING_AMOK"],
                                    [::Enum.BattleStatus.fightingToTheDeath, "CARD_FIGHTING_TO_DEATH"],
                                    [::Enum.BattleStatus.withdrawing, "CARD_PANICKING"],
                                    [::Enum.BattleStatus.berserk, "BERSERK_STATUS_ICON"],
                                    [::Enum.BattleStatus.swimming, "SWIMMING_STATUS_ICON"],
                                    [::Enum.BattleStatus.infighting, "CARD_INFIGHTING"]] },
        ]
    }

    style = {
        backgroundSprite = "BATTLE_CARD_BACKGROUND",
        selectedSprite   = "BATTLE_CARD_SELECTED_BACKGROUND",
        goldStarSprite   = "GENERALS_GOLD_STAR",
        silverStarSprite = "GENERALS_SILVER_STAR",
        weaponSprites    = ["MELEE_UPGRADE_BRONZE", "MELEE_UPGRADE_SILVER", "MELEE_UPGRADE_GOLD"],
        armourSprites    = ["ARMOUR_UPGRADE_BRONZE", "ARMOUR_UPGRADE_SILVER", "ARMOUR_UPGRADE_GOLD"],
        xpSprites        = ["XP_CHEVRON_BRONZE", "XP_CHEVRON_SILVER", "XP_CHEVRON_GOLD"],
        // [crusading, abandoning a crusade, on jihad, abandoning a jihad]; Rome defines none of these.
        crusadeSprites   = ["CRUSADE_UNIT_LOGO", "CRUSADE_ABANDON_UNIT_LOGO",
                            "JIHAD_UNIT_LOGO", "JIHAD_ABANDON_UNIT_LOGO"],

        imageFilter  = 2,
        bodyFont     = null,
        sdfText      = false,
        numberColour = [0, 0, 0],
        dyingColour  = [200, 0, 0],
        countOutline = [203, 192, 189],   // the native card outlines a named general's soldier count in this
        dyingRate    = 0.01,   // deaths per second above which the count turns red, as the card does

        cycleSeconds  = 3.0,    // how long each status icon holds before the next set bit
        flashRate     = 1.0,    // deaths per second above which the count blinks at all
        flashFastRate = 1.5,    // ...and above which it blinks twice as fast
        flashSlow     = 0.250,  // seconds per blink in the 1.0-1.5 band
        flashFast     = 0.125,  // seconds per blink above that

        ammoColour      = [0, 50, 200],
        ammoCowColour   = [40, 170, 40],
        cowCarcassShot  = 3,               // Enum.ProjectileType.cowCarcass; Rome's arm of that table does not define it
        reloadColour    = [230, 190, 60],   // the reload bar drawn under the ammo bar
        enteringAlpha   = 0.5,              // reinforcements still marching on are drawn faded
        groupFrame      = [255, 205, 90],
        groupFrameAi    = [255, 150, 40],   // the native frame turns orange for an AI-run group
        showGroupFrames = true,
        ammoEmptyColour = [174, 166, 155],
        showAmmoBar     = true,
        followHudPreference = true,   // narrow the rack to perRowFull when the player is on the full battle HUD, as the native rack does
        captureMouse    = false,   // OFF: claiming the cursor upsets the game's own handling

        // [hud-restyle] A bronze plate with the gold double frame (hud_pane.nut) behind the cards.
        //   "minimal": on the minimal HUD only, where the cards float over the field (the default);
        //   true: on both HUDs; false: never. The plate only draws - it takes no clicks.
        plate    = "minimal",
        platePad = 6,   // 1080p units the plate reaches past the cards

        freeUpkeepTint = [140, 235, 140],   // campaign only - the native battle card never tints
        selectedLift   = 125,                // 0.49 of 255, the native selected-portrait lift

        maxStrikes     = 8,
    }

    feature   = ::Enum.HdFeature.battleHud
    art       = null
    font      = null
    portraits = null
    hovered   = null
    pressSelected = false
    minimalUi = false
    // One clock for the whole rack; 60 is a whole multiple of every period above, so wrapping there stays phase-continuous.
    clock     = 0.0
    pendingTip = null   // [hd-tips] the hovered status icon's text, drawn once the cards are done
    plateRect  = null   // [dock] the box around the rack this frame (the plate's, when it draws)
    state     = { verified = false, down = false, strikes = 0 }

    function open() {
        local scale = this.openPane(false, { paneWidth = true, paneHeight = true,
                                            perRow = true, perRowFull = true, rows = true })
        this.minimalUi = !::options.isNormalHud()
        this.px.minimalLeft <- (this.metrics.minimal.left * scale + 0.5).tointeger()
        this.px.minimalBottom <- (this.metrics.minimal.bottom * scale + 0.5).tointeger()
        // [hud-full] The compact full HUD: the strip starts just right of the radar block.
        if (!this.minimalUi && "fullLayout" in ::EX && ::EX.fullScale() != null) {
            this.px.left = (::EX.fullLayout().cardsLeft - this.pane.x).tointeger()
        }
        this.px.perRow <- this.minimalUi ? this.metrics.minimal.perRow
                        : this.style.followHudPreference ? this.metrics.perRowFull
                        : this.metrics.perRow
        // The native card is 48 wide and our offsets are its x1.25, so a sprite drawn at its own size uses this.
        this.px.spriteK <- this.metrics.cardW / 48.0 * scale

        this.px.statusSlots <- []
        foreach (slot in this.metrics.statusSlots) {
            this.px.statusSlots.append({ x = (slot.x * scale + 0.5).tointeger(),
                                         y = (slot.y * scale + 0.5).tointeger(),
                                         bits = slot.bits })
        }

        this.art = {
            background = ::UI.loadSprite(this.style.backgroundSprite, ::UI.PAGE_BATTLE),
            selected = ::UI.loadSprite(this.style.selectedSprite, ::UI.PAGE_BATTLE),
            goldStar = ::UI.loadSprite(this.style.goldStarSprite, ::UI.PAGE_SHARED),
            silverStar = ::UI.loadSprite(this.style.silverStarSprite, ::UI.PAGE_SHARED),
            weapon = [], armour = [], xp = [], crusade = [], status = {}
        }
        foreach (name in this.style.weaponSprites) {
            this.art.weapon.append(::UI.loadSprite(name, ::UI.PAGE_SHARED))
        }
        foreach (name in this.style.armourSprites) {
            this.art.armour.append(::UI.loadSprite(name, ::UI.PAGE_SHARED))
        }
        foreach (name in this.style.xpSprites) {
            this.art.xp.append(::UI.loadSprite(name, ::UI.PAGE_SHARED))
        }
        foreach (name in this.style.crusadeSprites) {
            this.art.crusade.append(::UI.loadSprite(name, ::UI.PAGE_SHARED))
        }
        foreach (slot in this.metrics.statusSlots) {
            foreach (pair in slot.bits) {
                if (!(pair[1] in this.art.status)) {
                    this.art.status[pair[1]] <- ::UI.loadSprite(pair[1], ::UI.PAGE_SHARED)
                }
            }
        }

        this.font = this.style.bodyFont != null ? this.style.bodyFont : ::EX.fonts.body

        // loadTexture dedups by path, but with a linear walk of every image the overlay has loaded.
        this.portraits = {}
    }

    // The rack follows ARMY::m_units, skipping any unit that is dead or has left the field.
    function update() {
        local cards = ::ui.cardManager()
        local seed = cards.unitCardCount > 0 ? cards.unitAt(0) : null
        local army = seed != null ? seed.army : null
        local total = army != null && army.unitCount <= cards.unitCardCount ? army.unitCount
                                                                           : cards.unitCardCount

        this.rack = []
        for (local i = 0; i < total; i++) {
            local unit = army != null ? army.unit(i) : cards.unitAt(i)
            if (unit == null) {
                continue
            }
            local state = unit.actionStatus
            if (state == ::Enum.UnitActionStatus.dead || state == ::Enum.UnitActionStatus.leavingBattle
                || state == ::Enum.UnitActionStatus.leftBattle) {
                continue
            }
            this.rack.append(unit)
        }
        // A drag left latched over a rack that moved on claims the pointer every frame and deafens the game.
        if (this.dragUnit != null && !::UI.mouse.down(::UI.mouse.left)
                                  && !::UI.mouse.released(::UI.mouse.left)) {
            this.dragCancel()
        }
        this.hovered = null
    }

    function rackCount() {
        return this.rack == null ? 0 : this.rack.len()
    }

    function rackUnit(index) {
        return this.rack != null && index >= 0 && index < this.rack.len() ? this.rack[index] : null
    }

    // Card n, laid left to right from the TOP row down, so a full army fills the upper row first.
    function cardRect(index) {
        if (this.minimalUi) {
            local used = (this.rackCount() + this.px.perRow - 1) / this.px.perRow
            if (used < 1) { used = 1 }
            if (used > this.metrics.minimal.rows) { used = this.metrics.minimal.rows }
            local fromBottom = used - 1 - index / this.px.perRow
            if (fromBottom < 0) { fromBottom = 0 }
            return { x = (this.px.minimalLeft
                          + index % this.px.perRow * (this.px.cardW + this.px.gapX)).tointeger(),
                     y = (this.pane.y + this.pane.h - this.px.minimalBottom - this.px.cardH
                          - fromBottom * (this.px.cardH + this.px.gapY)).tointeger(),
                     w = this.px.cardW, h = this.px.cardH }
        }
        local rowW = (this.px.cardW + this.px.gapX) * this.px.perRow - this.px.gapX
        local fromBottom = this.metrics.rows - 1 - index / this.px.perRow
        local left = this.metrics.left >= 0 ? this.px.left : (this.pane.w - rowW) / 2
        return { x = (this.pane.x + left
                      + index % this.px.perRow * (this.px.cardW + this.px.gapX)).tointeger(),
                 y = (this.pane.y + this.pane.h - this.px.bottom - this.px.cardH
                      - fromBottom * (this.px.cardH + this.px.gapY)).tointeger(),
                 w = this.px.cardW, h = this.px.cardH }
    }

    function cardPicked(entry) {
        return entry.isSelected
    }

    // The card grown by half of each gutter it shares with a neighbour.
    function cardAt(x, y) {
        local halfX = this.px.gapX / 2
        local halfY = this.px.gapY / 2
        for (local i = 0; i < this.rackCount(); i++) {
            local r = this.cardRect(i)
            local col = i % this.px.perRow
            local left = col > 0 ? halfX : 0
            local right = col < this.px.perRow - 1 && i + 1 < this.rackCount() ? this.px.gapX - halfX : 0
            local up = i >= this.px.perRow ? halfY : 0
            local down = i + this.px.perRow < this.rackCount() ? this.px.gapY - halfY : 0
            if (x >= r.x - left && x < r.x + r.w + right && y >= r.y - up && y < r.y + r.h + down) {
                return i
            }
        }
        return -1
    }

    // The whole card: frame, portrait, general's star, upgrades, chevrons, status, ammo, crusade, soldier count.
    function renderCard(unit, rect, armTips = true) {
        local entering = unit.actionStatus == ::Enum.UnitActionStatus.enteringBattle
        if (entering) {
            ::UI.pushOpacity(this.style.enteringAlpha)
        }

        local lit = unit.isSelected || unit == this.dragUnit
        local art = lit ? this.art.selected : this.art.background
        if (art.img != 0) { ::UI.image(art.img, rect.w, rect.h, rect.x, rect.y) }

        local path = unit.cardPath
        if (!(path in this.portraits)) {
            this.portraits[path] <- ::UI.loadTexture(path)
        }
        art = this.portraits[path]
        if (art != null && art.img != 0) {
            // The native card redraws the face at 190 under a 2x colour scale, so an additive 0.49 pass matches it.
            ::UI.pushStyle({ [::UI.Colour.imageGlow] = [this.style.selectedLift, this.style.selectedLift,
                                                        this.style.selectedLift, lit ? 255 : 0] })
            ::UI.image(art.img, this.px.portraitW, this.px.portraitH,
                       rect.x + this.px.portraitX, rect.y + this.px.portraitY)
            ::UI.popStyle()
        }

        if (unit.isGeneralUnit) {
            art = unit.commandingGeneralPresent ? this.art.goldStar : this.art.silverStar
            if (art.img != 0) {
                ::UI.image(art.img, this.px.starW, this.px.starH,
                           rect.x + this.px.starX, rect.y + this.px.starY)
            }
        }

        if (unit.weaponLevel > 0 && unit.weaponLevel <= this.art.weapon.len()) {
            art = this.art.weapon[unit.weaponLevel - 1]
            if (art.img != 0) {
                ::UI.image(art.img, this.px.weaponW, this.px.weaponH,
                           rect.x + this.px.weaponX, rect.y + this.px.weaponY)
            }
        }

        if (unit.armourLevel > 0 && unit.armourLevel <= this.art.armour.len()) {
            art = this.art.armour[unit.armourLevel - 1]
            if (art.img != 0) {
                ::UI.image(art.img, this.px.armourW, this.px.armourH,
                           rect.x + this.px.armourX, rect.y + this.px.armourY)
            }
        }

        // Each tier carries three chevrons: the tier picks the sprite, the remainder how many to stack, each overlapping the one above.
        if (unit.experience > 0) {
            art = this.art.xp[(unit.experience - 1) / 3 > 2 ? 2 : (unit.experience - 1) / 3]
            local w = this.px.xpW > 0 ? this.px.xpW : (art.w * this.px.spriteK + 0.5).tointeger()
            local h = this.px.xpH > 0 ? this.px.xpH : (art.h * this.px.spriteK + 0.5).tointeger()
            local y = this.px.xpY
            for (local n = unit.experience % 3 == 0 ? 3 : unit.experience % 3; n > 0; n--) {
                if (art.img != 0) { ::UI.image(art.img, w, h, rect.x + this.px.xpX, rect.y + y) }
                y += this.px.xpStep > 0 ? this.px.xpStep : (h + 1) / 2
            }
        }

        // One icon per slot, cycling through whichever bits are set, as the engine's STATE_CHANGER does.
        local status = unit.battleStatus
        foreach (slot in this.px.statusSlots) {
            local active = []
            foreach (pair in slot.bits) {
                if (status & pair[0]) { active.append(pair[1]) }
            }
            if (active.len() > 0) {
                local nth = (this.clock / this.style.cycleSeconds).tointeger() % active.len()
                art = this.art.status[active[nth]]
                if (art != null && art.img != 0) {
                    local w = this.px.statusW > 0 ? this.px.statusW : (art.w * this.px.spriteK + 0.5).tointeger()
                    local h = this.px.statusH > 0 ? this.px.statusH : (art.h * this.px.spriteK + 0.5).tointeger()
                    ::UI.image(art.img, w, h, rect.x + slot.x, rect.y + slot.y)
                    if (armTips && unit == this.hovered) {
                        this.raiseTip(rect.x + slot.x, rect.y + slot.y, w, h, unit.actionStatusName)   // [hd-tips]
                    }
                }
            }
        }

        // A missile unit shows how much ammo is left and how far through its reload it is.
        local reload = unit.missileReloadFraction
        if (::options.showReload() && reload >= 0.0 && reload < 1.0) {
            local ink = this.style.reloadColour
            local run = ((this.px.ammoW - this.px.ammoInset * 2) * reload).tointeger()
            ::UI.drawRect(rect.x + this.px.ammoX, rect.y + this.px.reloadY, this.px.ammoW, this.px.reloadH,
                          this.style.ammoEmptyColour[0], this.style.ammoEmptyColour[1],
                          this.style.ammoEmptyColour[2], 255)
            if (run > 0) {
                ::UI.drawRect(rect.x + this.px.ammoX + this.px.ammoInset, rect.y + this.px.reloadY,
                              run, this.px.reloadH, ink[0], ink[1], ink[2], 255)
            }
        }

        local fraction = unit.hasExpendableAmmo && unit.currentAmmoMax > 0
                       ? unit.currentAmmo.tofloat() / unit.currentAmmoMax : -1.0
        if (this.style.showAmmoBar && fraction >= 0.0) {
            local ink = unit.firingProjectileType == this.style.cowCarcassShot
                      ? this.style.ammoCowColour : this.style.ammoColour
            ::UI.drawRect(rect.x + this.px.ammoX, rect.y + this.px.ammoY, this.px.ammoW, this.px.ammoH,
                          this.style.ammoEmptyColour[0], this.style.ammoEmptyColour[1],
                          this.style.ammoEmptyColour[2], 255)

            local filled = ((this.px.ammoW - this.px.ammoInset * 2) * fraction).tointeger()
            if (filled > 0) {
                ::UI.drawRect(rect.x + this.px.ammoX + this.px.ammoInset,
                              rect.y + this.px.ammoY + this.px.ammoInset,
                              filled, this.px.ammoH - this.px.ammoInset * 2, ink[0], ink[1], ink[2], 255)
            }
        }

        // crusadeState is the native gate: 0 none, >0 on one, <0 abandoning; a null `crusade` means jihad.
        if (unit.crusadeState != 0) {
            art = this.art.crusade[(unit.crusade != null ? 0 : 2) + (unit.crusadeState > 0 ? 0 : 1)]
            if (art != null && art.img != 0) {
                ::UI.image(art.img,
                           this.px.crusadeW > 0 ? this.px.crusadeW : (art.w * this.px.spriteK + 0.5).tointeger(),
                           this.px.crusadeH > 0 ? this.px.crusadeH : (art.h * this.px.spriteK + 0.5).tointeger(),
                           rect.x + this.px.crusadeX, rect.y + this.px.crusadeY)
            }
        }

        // Above a man a second the native count blinks hard on and off, twice as fast again above 1.5.
        local blinkedOut = unit.mortalityRate > this.style.flashRate
                        && (this.clock / ((unit.mortalityRate > this.style.flashFastRate
                                           ? this.style.flashFast : this.style.flashSlow)
                                          * 0.5)).tointeger() % 2 != 0

        // A card in a control group wears its group's frame, orange while the AI is running it.
        if (this.style.showGroupFrames && unit.group != null) {
            local edge = unit.group.isAutomated ? this.style.groupFrameAi : this.style.groupFrame
            ::UI.drawRect(rect.x, rect.y, rect.w, this.px.groupFrameThick, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(rect.x, rect.y + rect.h - this.px.groupFrameThick, rect.w,
                          this.px.groupFrameThick, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(rect.x, rect.y, this.px.groupFrameThick, rect.h, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(rect.x + rect.w - this.px.groupFrameThick, rect.y, this.px.groupFrameThick,
                          rect.h, edge[0], edge[1], edge[2], 255)
        }

        if (entering) {
            ::UI.popOpacity()
        }

        if (blinkedOut) {
            return
        }

        local ink = unit.mortalityRate > this.style.dyingRate ? this.style.dyingColour : this.style.numberColour
        ::UI.pushStyle({ [::UI.Cap.textOutline] = unit.general != null ? 1 : 0,
                         [::UI.Colour.textOutline] = this.style.countOutline,
                         [::UI.Metric.textOutlineWidth] = 1 })
        ::UI.pushFont(this.font, this.style.sdfText, this.px.fontSize)
        ::UI.layoutAt(rect.x + this.px.numberX, rect.y + this.px.numberY)
        ::UI.textColoured(unit.displayedSoldiers.tostring(), ink[0], ink[1], ink[2], 255)
        ::UI.popFont()
        ::UI.popStyle()
    }

    // [hud-restyle] The plate behind the rack: the box every card (and the support-army row above
    // them) sits in, grown by platePad; where it meets a screen edge it runs off it.
    function renderPlate() {
        this.plateRect = null
        if (this.rackCount() == 0) {
            return
        }
        local v = this.style.plate
        local compact = !this.minimalUi && "fullScale" in ::EX && ::EX.fullScale() != null   // [hud-full]
        local drawn = (v == true || (v == "minimal" && (this.minimalUi || compact))) && "tipBack" in ::EX && "tipFrame" in ::EX
                    && (!("restyled" in ::EX) || ::EX.restyled())   // [restyle]
        local x0 = null
        local y0 = null
        local x1 = null
        local y1 = null
        local cards = ::ui.cardManager()
        local support = cards != null ? cards.supportArmyCardCount : 0
        for (local i = 0; i < this.rackCount(); i++) {
            local r = this.cardRect(i)
            if (x0 == null || r.x < x0) x0 = r.x
            if (y0 == null || r.y < y0) y0 = r.y
            if (x1 == null || r.x + r.w > x1) x1 = r.x + r.w
            if (y1 == null || r.y + r.h > y1) y1 = r.y + r.h
            if (i < support) {
                local up = r.y - this.px.cardH - this.px.gapY
                if (up < y0) y0 = up
            }
        }
        local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
        local pad = (this.style.platePad * k + 0.5).tointeger()
        local screen = ::UI.screenSize()
        x0 -= pad
        y0 -= pad
        x1 += pad
        y1 += pad
        if (x0 < pad) x0 = -pad
        if (y1 > screen[1] - pad) y1 = screen[1] + pad
        // [dock] battle_tooltips.nut docks the unit card on top of this box, aligned to its left
        this.plateRect = { x = x0, y = y0, w = x1 - x0, h = y1 - y0, drawn = drawn }
        if (drawn) {
            ::EX.tipBack(x0, y0, x1 - x0, y1 - y0, k)
            ::EX.tipFrame(x0, y0, x1 - x0, y1 - y0, k)
        }
    }

    // [hd-tips] The status icon's tooltip in the campaign tooltips' styled box (hud_pane.nut), not the
    // engine's own in the legacy face. The engine tooltip is still raised, invisibly, over the same
    // rect, so hovering behaves as before; the box is drawn after the cards. Without hud_pane.nut:
    // the engine's, as before.
    function raiseTip(x, y, w, h, text) {
        if (text == null || text == "") {
            return
        }
        if (!("drawTip" in ::EX) || !("ghostStyle" in ::EX) || ("restyled" in ::EX && !::EX.restyled())) {   // [restyle]
            ::UI.tooltipAt(x, y, w, h)
            ::UI.tooltip(0, text)
            return
        }
        ::UI.pushStyle(::EX.ghostStyle())
        ::UI.tooltipAt(x, y, w, h)
        ::UI.tooltip(0, text)
        ::UI.popStyle()
        local m = ::UI.mouse.pos()
        if (m[0] >= x && m[0] < x + w && m[1] >= y && m[1] < y + h) {
            this.pendingTip = text
        }
    }

    function drawPendingTip() {
        local text = this.pendingTip
        this.pendingTip = null
        if (text == null || this.dragLive() || !("drawTip" in ::EX)) {
            return
        }
        try {
            ::EX.drawTip(text, [0, 0, 0, 160], [255, 245, 139, 255], [255, 245, 139, 255])
        }
        catch (e) {
            println("squi: [hd-tips] battle card tooltip failed - " + e)
        }
    }

    // An unmodified click on an unselected card commits on the press; ctrl, shift and the drag land on the release.
    function handleMouse() {
        local m = ::UI.mouse.pos()
        local over = this.cardAt(m[0], m[1])
        local unitOver = over >= 0 ? this.rackUnit(over) : null
        this.hovered = unitOver

        // The delay phase is the multiplayer wait before deployment, where the native rack ignores clicks.
        if (::battle.current().phase == ::Enum.BattleState.delay) {
            return
        }

        if (this.dragLive() || (over >= 0 && this.style.captureMouse)) {
            ::UI.mouse.capture()
        }

        // Amok, infighting and pool-retired units refuse selection; the native rack asks before it acts.
        local overCard = over >= 0
        if (unitOver != null && !unitOver.canBeSelected) {
            unitOver = null
            over = -1
        }

        // Right-click opens the info scroll, which is a toggle, so only on the press edge.
        if (::UI.mouse.clicked(::UI.mouse.right) && unitOver != null) {
            unitOver.showInfoScroll()
            return
        }

        // The native rack commits an unmodified click on the press and leaves the rest to the release.
        if (::UI.mouse.clicked(::UI.mouse.left)) {
            this.dragPress(unitOver, over)
            this.pressSelected = unitOver != null && unitOver.isSelected
            if (unitOver != null && (::UI.keyboard.mods() & ::UI.Mod.shift)) {
                local anchor = -1
                for (local i = 0; i < this.rackCount(); i++) {
                    local other = this.rackUnit(i)
                    if (anchor < 0 && other != null && other.isSelected) { anchor = i }
                }
                if (anchor >= 0) {
                    for (local i = anchor < over ? anchor : over; i <= (anchor < over ? over : anchor); i++) {
                        local other = this.rackUnit(i)
                        if (other != null) { other.select(::Enum.SelectMode.add) }
                    }
                    return
                }
            }
            if (unitOver != null && !unitOver.isSelected
                && this.clickMode() == ::Enum.SelectMode.replace) {
                unitOver.select(::Enum.SelectMode.replace)
            }
            return
        }

        // An unselected card becomes the selection first, and the selection is the block that moves.
        if (this.dragUnit != null && ::UI.mouse.dragging(::UI.mouse.left)) {
            if (this.dragBlock == null && !this.dragUnit.isSelected) {
                this.dragUnit.select(this.clickMode())
            }
            this.dragTrack(m[0], m[1])
        }

        if (!::UI.mouse.released(::UI.mouse.left)) {
            return
        }

        local drop = this.dragRelease(m[0], m[1])
        local unit = drop.unit
        local from = drop.from

        // A double click on the strip clear of any card selects the whole army, or clears it when everything is already selected.
        if (unit == null) {
            local first = this.cardRect(0)
            local rowW = (this.px.cardW + this.px.gapX) * this.px.perRow - this.px.gapX
            local inStrip = !overCard
                         && m[0] >= first.x && m[0] < first.x + rowW
                         && m[1] >= first.y && m[1] < this.pane.y + this.pane.h - this.px.bottom
            if (inStrip) {
                if (::UI.mouse.clickedCount(::UI.mouse.left) >= 2) {
                    if (::ui.cardManager().selectedUnitCount >= this.rackCount()) { ::battle.selection.clear() }
                    else { ::battle.selection.selectAll() }
                }
                else if (!(::UI.keyboard.mods() & (::UI.Mod.shift | ::UI.Mod.ctrl))) {
                    ::battle.selection.clear()
                }
            }
            return
        }

        if (drop.moved[0] != 0 || drop.moved[1] != 0) {
            if (drop.slot != null && drop.slot.index != from && drop.block != null) {
                local army = unit.army
                if (army != null) {
                    army.moveUnit(drop.block, drop.slot.before ? drop.slot.index
                                                               : drop.slot.index + 1)
                }
            }
            return
        }

        if (::UI.mouse.clickedCount(::UI.mouse.left) >= 2) {
            if (::UI.keyboard.mods() & ::UI.Mod.ctrl) { unit.selectSameType() }
            else { unit.zoomTo() }
            return
        }

        // The press already committed a plain click; only a modifier or an already-selected
        // card still has something to do here, which is what the native rack does.
        if (::UI.keyboard.mods() & ::UI.Mod.shift) {
            return
        }
        if (this.clickMode() != ::Enum.SelectMode.replace || this.pressSelected) {
            unit.select(this.clickMode())
        }
    }

    function verify() {
        if (this.pane == null || this.px == null) {
            return false
        }
        if (!("cardW" in this.px) || !("cardH" in this.px) || !("gapX" in this.px)
            || !("gapY" in this.px) || !("perRow" in this.px) || !("left" in this.px)
            || !("bottom" in this.px) || !("fontSize" in this.px) || !("spriteK" in this.px)
            || !("statusSlots" in this.px)) {
            return false
        }
        if (this.px.perRow <= 0 || this.px.cardW <= 0 || this.px.cardH <= 0) {
            return false
        }
        if (this.art == null || this.font == null || this.portraits == null) {
            return false
        }
        if (this.art.weapon.len() != this.style.weaponSprites.len()
            || this.art.armour.len() != this.style.armourSprites.len()
            || this.art.xp.len() != this.style.xpSprites.len()
            || this.art.crusade.len() != this.style.crusadeSprites.len()) {
            return false
        }
        if (this.px.statusSlots.len() != this.metrics.statusSlots.len()) {
            return false
        }
        foreach (slot in this.px.statusSlots) {
            foreach (pair in slot.bits) {
                if (!(pair[1] in this.art.status)) {
                    return false
                }
            }
        }
        return ::ui.cardManager != null && ::battle.current != null
               && ::battle.selection != null && ::options.showReload != null
    }

    function render() {
        if (this.state.down) {
            return
        }

        if (!this.visible(::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded)) {
            return
        }
        // [hud-toggles] the unit-cards toggle key
        if ("battleShortcuts" in ::EX && "isHidden" in ::EX.battleShortcuts
            && ::EX.battleShortcuts.isHidden("cards")) {
            this.hovered = null
            this.plateRect = null   // [dock]
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

        if (fault == "") {
            try {
                local minimal = !::options.isNormalHud()
                if (minimal != this.minimalUi) {
                    this.open()
                }

                this.clock += ::UI.time.delta()
                while (this.clock >= 60.0) { this.clock -= 60.0 }

                this.update()
                this.handleMouse()
                this.pendingTip = null   // [hd-tips]
                this.renderPlate()       // [hud-restyle] behind the cards

                ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter })

                // While a drag is live the cards from the insertion point on slide half a card aside, opening the gap it would land in.
                for (local i = 0; i < this.rackCount(); i++) {
                    local unit = this.rackUnit(i)
                    if (unit != null && !(this.dragLive() && this.cardPicked(unit))) {
                        this.renderCard(unit, this.dragSlide(this.cardRect(i), i))
                    }
                    // [card-click] Claim the pointer over each card, as the HUD chrome does, so a
                    // click on a card is not ALSO a click on the battlefield behind it (which can
                    // deselect or re-select units under the card and undo the card's selection).
                    if (unit != null) {
                        local hit = this.cardRect(i)
                        ::UI.hitRect(hit.x, hit.y, hit.w, hit.h)
                    }
                }

                // The allied AI armies fighting alongside the player get their own row above the rack.
                local cards = ::ui.cardManager()
                for (local i = 0; i < cards.supportArmyCardCount; i++) {
                    local army = cards.supportArmyCard(i)
                    if (army == null || army.faction == null || army.faction.record == null) {
                        continue
                    }
                    local rect = this.cardRect(i)
                    rect.y -= this.px.cardH + this.px.gapY
                    local record = army.faction.record
                    ::UI.drawRect(rect.x, rect.y, rect.w, rect.h,
                                  record.primaryRed, record.primaryGreen, record.primaryBlue,
                                  army.isSelected ? 255 : 180)
                }

                // The whole block rides the cursor, fanned back with the grabbed card on top.
                if (this.dragLive()) {
                    local m = ::UI.mouse.pos()
                    for (local i = this.dragBlock.len() - 1; i >= 0; i--) {
                        local unit = this.dragBlock[i]
                        if (unit != null) {
                            this.renderCard(unit, { x = m[0] - this.px.cardW / 2 - i * this.px.gapX,
                                                    y = m[1] - this.px.cardH / 2 - i * this.px.gapY,
                                                    w = this.px.cardW, h = this.px.cardH }, false)
                        }
                    }
                }

                ::UI.popStyle()
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
            ::options.failHdFeature(::Enum.HdFeature.battleHud)
            println("squi: battle cards STOOD DOWN - " + fault)
        }
    }
}

local battleCards = BattleCards()
battleCards.open()

local battleCardsCanvas = ::UI.canvas("##battlecardscanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(battleCardsCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(battleCardsCanvas, function() { battleCards.render() })
::UI.widgetUnderlay(battleCardsCanvas, true)

::UI.onResize(function(w, h) { battleCards.open() })

::EX.battleCards <- battleCards
