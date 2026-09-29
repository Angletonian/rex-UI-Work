local math = require("math")

local EXPERIENCE_ATTACK = [0, 1, 1, 1, 2, 2, 2, 3, 3, 3]
local EXPERIENCE_DEFENCE = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

local ROWS = [
    { key = "meleeAttack",    text = "Melee Attack" },
    { key = "missileAttack",  text = "Missile Attack" },
    { key = "buildingDamage", text = "Att vs. Buildings" },
    { key = "chargeBonus",    text = "Charge Bonus" },
    { key = "totalDefence",   text = "Total Defence" },
    { key = "armour",         text = "Armour" },
    { key = "defence",        text = "Defence Skill" },
    { key = "shield",         text = "Shield" },
    { key = "health",         text = "Health" },
    { key = "morale",         text = "Morale" },
    // Parked until the number is confirmed against the native card.
    // { key = "speed",          text = "Speed" },
    { key = "missileRange",   text = "Missile Range" },
    { key = "artilleryRange", text = "Range" },
    { key = "ammunition",     text = "Ammunition" },
]

local UnitStatsSidebar = class {
    metrics = {
        windowWidth   = 340,
        edgeMargin    = 10,
        rowHeight     = 20,
        headerHeight  = 26,
        labelWidth    = 164,
        valueWidth    = 44,
        barHeight     = 11,
        rowGap        = 2,
        chevronWidth  = 11,
        chevronHeight = 11,
        chevronStep   = 6,
        countWidth    = 84,
        anchorHeight  = 230,
        liftY         = 100,
    }

    style = {
        windowFlags = [::UI.WindowFlag.hideTitleBar, ::UI.WindowFlag.notDraggable,
                       ::UI.WindowFlag.fixedSize, ::UI.WindowFlag.stackVertical,
                       ::UI.WindowFlag.noScrollBodyY, ::UI.WindowFlag.autoResizeY,
                       ::UI.WindowFlag.noAutoRaise],
        rowFlags    = [::UI.PanelFlag.stackHorizontal, ::UI.PanelFlag.borderless,
                       ::UI.PanelFlag.transparent, ::UI.PanelFlag.noScrollBodyY,
                       ::UI.PanelFlag.hideScrollBars],

        titleInk = [255, 245, 139, 255],
        labelInk = [214, 208, 186, 255],
        valueInk = [255, 255, 255, 255],
        barFill  = [188, 150, 64, 255],
        barOver  = [152, 176, 72, 255],
        barUnder = [148, 68, 58, 200],
        barTrack = [32, 30, 26, 255],

        xpSprites   = ["XP_CHEVRON_BRONZE", "XP_CHEVRON_SILVER", "XP_CHEVRON_GOLD"],
        maxChevrons = 3,

        weaponUpgradeStep = 3,
        armourUpgradeStep = 2,

        barCurve = 0.8,

        maxStrikes = 8,

        maxima = {
            meleeAttack    = 50,
            chargeBonus    = 50,
            totalDefence   = 50,
            armour         = 20,
            defence        = 50,
            shield         = 20,
            health         = 10,
            morale         = 50,
            // speed          = 125,
            missileRange   = 300,
            artilleryRange = 500,
            ammunition     = 40,
            missileAttack  = 50,
            buildingDamage = 150,
        },
    }

    window     = null
    title      = null
    header     = null
    countLabel = null
    killsLabel = null
    chevrons   = null
    rows       = null
    art        = null
    frame      = null
    values     = null
    bases      = null
    state      = { verified = false, down = false, strikes = 0 }

    function buildOnce() {
        if (this.window != null) {
            return
        }

        this.chevrons = []
        this.rows = []
        this.art = []

        this.window = ::UI.window("##unitstats", this.metrics.windowWidth, 0,
                                  this.metrics.edgeMargin, 0, this.style.windowFlags)
        this.title = ::UI.label("")
        ::UI.addChild(this.window, this.title); ::UI.align(this.title, ::UI.Align.center); ::UI.setWidgetStyle(this.title, ::UI.Colour.text, this.style.titleInk)

        local rule = ::UI.separator("##unitstatsrule")
        ::UI.addChild(this.window, rule)

        this.header = ::UI.panel("##unitstatshead")
        ::UI.setFlags(this.header, this.style.rowFlags); ::UI.addChild(this.window, this.header); ::UI.widgetRect(this.header, 0, 0, 0, this.metrics.headerHeight)

        this.countLabel = ::UI.label("")
        ::UI.addChild(this.header, this.countLabel); ::UI.widgetRect(this.countLabel, 0, 0, this.metrics.countWidth, 0); ::UI.setWidgetStyle(this.countLabel, ::UI.Colour.text, this.style.valueInk)

        this.killsLabel = ::UI.label("")
        ::UI.addChild(this.header, this.killsLabel); ::UI.flexGrow(this.killsLabel, 1); ::UI.setWidgetStyle(this.killsLabel, ::UI.Colour.text, this.style.valueInk)

        foreach (spriteName in this.style.xpSprites) {
            this.art.append(::UI.loadSprite(spriteName, ::UI.PAGE_SHARED))
        }
        for (local i = 0; i < this.style.maxChevrons; i += 1) {
            local pip = ::UI.image("##unitstatsxp" + i)
            ::UI.addChild(this.window, pip); ::UI.placeAbsolute(pip)
            this.chevrons.append(pip)
        }

        foreach (row in ROWS) {
            local panel = ::UI.panel("##unitstatsrow" + row.key)
            ::UI.setFlags(panel, this.style.rowFlags); ::UI.addChild(this.window, panel); ::UI.widgetRect(panel, 0, 0, 0, this.metrics.rowHeight)
            ::UI.setWidgetStyle(panel, ::UI.Metric.gap, this.metrics.rowGap)

            local name = ::UI.label(row.text)
            ::UI.addChild(panel, name); ::UI.widgetRect(name, 0, 0, this.metrics.labelWidth, 0); ::UI.setWidgetStyle(name, ::UI.Colour.text, this.style.labelInk)

            local value = ::UI.label("")
            ::UI.addChild(panel, value); ::UI.widgetRect(value, 0, 0, this.metrics.valueWidth, 0); ::UI.setWidgetStyle(value, ::UI.Colour.text, this.style.valueInk)

            local bar = ::UI.progress("##unitstatsbar" + row.key)
            ::UI.addChild(panel, bar); ::UI.flexGrow(bar, 1); ::UI.align(bar, ::UI.Align.center); ::UI.widgetRect(bar, 0, 0, 0, this.metrics.barHeight)
            ::UI.setWidgetStyle(bar, ::UI.Colour.accent, this.style.barFill); ::UI.setWidgetStyle(bar, ::UI.Surface.progressTrack, this.style.barTrack)
            ::UI.progressMax(bar, 1.0)

            this.rows.append({ key = row.key, panel = panel, value = value, bar = bar })
        }

        ::UI.setParent(0)
        ::UI.widgetVisible(this.window, false)
    }

    // The script card racks replace the native cards, so the unit under the cursor is asked of them
    // first - the same way battle_tooltips.nut does. The native rects only answer with the racks off.
    function scriptHover() {
        if (this.frame.battle) {
            if (!("battleCards" in ::EX) || !::options.hdFeature(::Enum.HdFeature.battleHud)) {
                return null
            }
            return ::EX.battleCards.hovered
        }
        if (!("campaignCards" in ::EX) || !::options.hdFeature(::Enum.HdFeature.campaignHud)) {
            return null
        }
        local rack = ::EX.campaignCards
        // Building and agent tabs rack things that are not units.
        if (rack.buildings || rack.agents || rack.rack == null) {
            return null
        }
        local i = rack.hoverIndex
        return i >= 0 && i < rack.rack.len() ? rack.rack[i] : null
    }

    function nativeHover(cards) {
        local scripted = this.scriptHover()
        if (scripted != null) {
            return scripted
        }

        local mouse = ::UI.mouse.pos()
        local count = cards.unitCardCount

        for (local i = 0; i < count; i += 1) {
            local rect = cards.unitCardRect(i)
            if (rect == null) {
                continue
            }
            if (mouse[0] < rect[0] || mouse[0] >= rect[0] + rect[2]) {
                continue
            }
            if (mouse[1] < rect[1] || mouse[1] >= rect[1] + rect[3]) {
                continue
            }
            return cards.unitAt(i)
        }

        return null
    }

    function firstSelected(cards) {
        local count = cards.unitCardCount

        for (local i = 0; i < count; i += 1) {
            local unit = cards.unitAt(i)
            if (unit != null && unit.isSelected) {
                return unit
            }
        }
        if (cards.selectedUnitCount > 0) {
            return cards.selectedUnit(0)
        }

        return null
    }

    function update() {
        local context = ::UI.context()
        local live = context & (::Enum.UiContext.battleLive | ::Enum.UiContext.campaignLive)

        this.frame = { battle = (context & ::Enum.UiContext.battleLive) != 0, unit = null }
        if (!live) {
            return
        }

        local cards = ::ui.cardManager()
        if (cards == null) {
            return
        }

        local unit = this.nativeHover(cards)
        if (unit == null) {
            unit = this.firstSelected(cards)
        }
        this.frame.unit = unit
    }

    function initialise(unit) {
        this.values = null
        this.bases = null

        if (unit == null) {
            return false
        }
        local unitType = unit.type
        if (unitType == null) {
            return false
        }

        local experience = unit.experience < 0 ? 0 : (unit.experience > 9 ? 9 : unit.experience)
        local slot = unitType.isMissile(0) == true ? 1 : 0
        local artillery = unitType.isMissile(3) == true && unitType.hasProjectile(3) == true

        local weaponBonus = unit.attackInBattle - (unitType.attack(0) ?? 0)
        local weaponFloor = unit.weaponLevel * this.style.weaponUpgradeStep
        if (weaponBonus < weaponFloor) {
            weaponBonus = weaponFloor
        }

        local armour = unit.armourInBattle
        local armourFloor = (unitType.armour(0) ?? 0) + unit.armourLevel * this.style.armourUpgradeStep
        if (armour < armourFloor) {
            armour = armourFloor
        }

        local defence = (unitType.defence(0) ?? 0) + EXPERIENCE_DEFENCE[experience]
        local shield = unitType.shield(0) ?? 0

        this.values = {
            meleeAttack  = (unitType.attack(slot) ?? 0) + weaponBonus + EXPERIENCE_ATTACK[experience],
            chargeBonus  = artillery ? 0 : (unitType.charge(slot) ?? 0),
            totalDefence = armour + defence + shield,
            armour       = armour,
            defence      = defence,
            shield       = shield,
            health       = unitType.health ?? 0,
            morale       = unitType.morale ?? 0,
        }

        local baseArmour = unitType.armour(0) ?? 0
        local baseDefence = unitType.defence(0) ?? 0
        this.bases = {
            meleeAttack  = unitType.attack(slot) ?? 0,
            totalDefence = baseArmour + baseDefence + shield,
            armour       = baseArmour,
            defence      = baseDefence,
        }

        if (artillery) {
            this.values.artilleryRange <- unitType.range(3) ?? 0
            this.values.buildingDamage <- unitType.projectileDamage(3) ?? 0
            this.values.missileAttack <- unitType.attack(3) ?? 0
            this.values.ammunition <- unitType.ammo(3) ?? 0
        } else if (unitType.isMissile(0) == true) {
            this.values.missileRange <- unitType.range(0) ?? 0
            this.values.ammunition <- unitType.ammo(0) ?? 0
            this.values.missileAttack <- unitType.attack(0) ?? 0
        }

        return true
    }

    function positionChildren() {
        if (this.window == null) {
            return
        }

        local screen = ::UI.screenSize()
        local scale = ::UI.dpiScale() <= 0 ? 1.0 : ::UI.dpiScale()

        local y = ((screen[1] / scale - this.metrics.anchorHeight) / 2).tointeger() - this.metrics.liftY
        if (y < 0) {
            y = 0
        }
        ::UI.widgetRect(this.window, this.metrics.edgeMargin, y, this.metrics.windowWidth, 0)
    }

    function renderHeader(unit) {
        ::UI.textSet(this.title, unit.type.displayName)
        ::UI.textSet(this.countLabel, "" + unit.soldiersMax + " (" + unit.displayedSoldiers + ")")

        local kills = ""
        if (this.frame.battle) {
            local tally = unit.battleStats()
            if (tally != null) {
                kills = "" + tally.killed
            }
        }
        ::UI.textSet(this.killsLabel, kills)

        local experience = unit.experience
        local tier = experience < 1 ? 0 : (experience - 1) / 3
        if (tier > 2) {
            tier = 2
        }
        local pips = experience < 1 ? 0 : (experience % 3 == 0 ? 3 : experience % 3)

        local head = ::UI.widgetRectGet(this.header, true)
        local pipX = head != null ? head[0] + head[2] - this.metrics.chevronWidth : 0
        foreach (index, pip in this.chevrons) {
            local on = head != null && index < pips && this.art[tier].img != 0
            ::UI.widgetVisible(pip, on)
            if (on) {
                ::UI.imageSet(pip, this.art[tier])
                ::UI.widgetRect(pip, pipX, head[1] + index * this.metrics.chevronStep,
                                this.metrics.chevronWidth, this.metrics.chevronHeight)
            }
        }
    }

    function renderRows() {
        foreach (row in this.rows) {
            local shown = row.key in this.values
            ::UI.widgetVisible(row.panel, shown)
            if (!shown) {
                continue
            }

            local value = this.values[row.key]
            local baseValue = (row.key in this.bases) ? this.bases[row.key] : value
            local limit = this.style.maxima[row.key]
            if (limit <= 0) {
                limit = 1
            }

            local low = value < baseValue ? value : baseValue
            local high = value > baseValue ? value : baseValue
            if (low < 0) {
                low = 0
            }
            if (high > limit) {
                high = limit
            }
            if (low > high) {
                low = high
            }

            local fLow = low.tofloat() / limit
            local fHigh = high.tofloat() / limit
            if (this.style.barCurve != 1.0) {
                fLow = math.pow(fLow, this.style.barCurve)
                fHigh = math.pow(fHigh, this.style.barCurve)
            }

            local parts = [{ value = fLow, colour = this.style.barFill }]
            if (fHigh > fLow) {
                parts.append({ value = fHigh - fLow,
                               colour = value > baseValue ? this.style.barOver : this.style.barUnder })
            }

            ::UI.textSet(row.value, "" + value); ::UI.progressValue(row.bar, fHigh); ::UI.progressParts(row.bar, parts)
        }
    }

    function verify() {
        if (this.window == null || !::UI.alive(this.window)) {
            return false
        }
        if (this.title == null || this.header == null || this.countLabel == null
            || this.killsLabel == null) {
            return false
        }
        if (this.rows == null || this.rows.len() != ROWS.len()) {
            return false
        }
        foreach (row in this.rows) {
            if (!::UI.alive(row.panel) || !::UI.alive(row.value) || !::UI.alive(row.bar)) {
                return false
            }
            if (!(row.key in this.style.maxima)) {
                return false
            }
        }
        if (this.chevrons == null || this.chevrons.len() != this.style.maxChevrons) {
            return false
        }
        if (this.art == null || this.art.len() != this.style.xpSprites.len()) {
            return false
        }
        return ::ui.cardManager != null
    }

    function render() {
        if (this.state.down) {
            return
        }

        this.buildOnce()

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
                local unit = this.frame.unit
                local shown = unit != null && this.initialise(unit)
                if (shown) {
                    this.positionChildren()
                    this.renderHeader(unit)
                    this.renderRows()
                }
                ::UI.widgetVisible(this.window, shown)
                this.state.strikes = 0
            }
            catch (e) {
                ::UI.widgetVisible(this.window, false)
                this.state.strikes += 1
                if (this.state.strikes >= this.style.maxStrikes) {
                    fault = "" + e
                }
            }
        }

        if (fault != "") {
            this.state.down = true
            ::UI.widgetVisible(this.window, false)
            println("squi: unit stats sidebar STOOD DOWN - " + fault)
        }
    }
}

local unitStatsSidebar = UnitStatsSidebar()

::UI.onFrame(function() { unitStatsSidebar.render() })
::UI.onResize(function(w, h) { unitStatsSidebar.positionChildren() })

::EX.unitStats <- unitStatsSidebar
