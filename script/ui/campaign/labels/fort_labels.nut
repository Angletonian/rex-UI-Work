local FortLabels = class {
    metrics = {
        labelOffsetX   = 0,
        labelOffsetY   = 0,
        rowHeight      = 36,
        plateWidth     = 0,
        plateHeight    = 0,
        platePadLeft   = 0,
        platePadRight  = 0,
        platePadTop    = 0,
        platePadBottom = 0,
        plateOffsetX   = 0,
        plateOffsetY   = 0,

        contentPadLeft  = 12,
        contentPadRight = 12,

        countOffsetX  = 0,
        countOffsetY  = 0,
        countGapAfter = 12,

        siegeIconWidth   = 24,
        siegeIconHeight  = 24,
        siegeIconOffsetX = 0,
        siegeIconOffsetY = 0,

        fontSize = 18,
        textShadowOffsetX = 1,
        textShadowOffsetY = 1,
        textShadowSpread  = 0,
    }

    style = {
        anchorTileOffsetX = 0.5,
        anchorTileOffsetY = -0.25,
        plateAlpha        = 150,

        siegeSprite = "STATUS_UNDER_SIEGE",

        bodyFont = "constantine.regular.ttf",   // [ui-font] fort name, matches settlement names (was "roboto.regular.ttf")
        sdfText  = false,

        textShadow         = false,
        textShadowColour   = [0, 0, 0],
        textShadowAlpha    = 160,
        textShadowSoftness = 100,

        contrastThreshold = 140,
        textOnDarkPlate   = [255, 245, 139],
        textOnLightPlate  = [0, 0, 0],

        defaultIconTint    = [255, 255, 255],
        unknownFactionFill = [90, 90, 100],
        imageFilter        = 0,

        maxStrikes = 8,

        showAllKey        = null,
    }

    state = { tick = 0, hover = null, capturing = false, lastClickKey = "",
              verified = false, down = false, strikes = 0 }

    px       = null
    scope    = null
    frame    = null
    font     = null
    siegeArt = null
    rect     = null
    name     = ""
    besieged = false

    function hovered() { return this.state.hover }

    // Metrics are 1080p units, scaled by screen height alone.
    // [ui-font] Roboto for the labels, the same styles as the battle card and campaign tooltips.
    // A bare file name is looked for in fontFolder (relative to Medieval II Total War\data\).
    // Each file is loaded once, when this script starts - fonts loaded mid-game can draw nothing.
    // A file that will not load or will not measure falls back to the hud_pane.nut face,
    // then ::EX.fonts.body, and says so in the console.
    fontFolder = "fonts/"
    faces = null
    function lookFont(wanted, fallbackName) {
        if (this.faces == null) {
            this.faces = {}
        }
        local fallback = "look" in ::EX && "face" in ::EX.look && ::EX.look.face != null
                         ? ::EX.look.face : ::EX.fonts[fallbackName]
        if (wanted == null) {
            return fallback
        }
        if (typeof(wanted) != "string" || wanted.tolower().indexof(".ttf") == null) {
            return wanted   // a handle, or an engine face name such as "tnr"
        }
        if (!(wanted in this.faces)) {
            local path = wanted.indexof("/") == null && wanted.indexof("\\") == null
                         ? this.fontFolder + wanted : wanted
            local handle = null
            try { handle = ::UI.loadFont(path) } catch (e) { handle = null }
            // No test-measure: open() first runs while the scripts start up, before the font
            // system can measure anything.
            local works = handle != null && handle != 0
            println("squi: [ui-font] fort labels" + (works ? " loaded " : " could not use ") + path)
            this.faces[wanted] <- works ? handle : null
        }
        local face = this.faces[wanted]
        return face != null ? face : fallback
    }

    // [ui-look] Label size against M2EX's own: labelScale from hud_pane.nut, or 0.75 until that
    // file has loaded. Read here rather than trusted to load order.
    lookK = -1.0
    function lookScale() {
        return "look" in ::EX && "labelScale" in ::EX.look && ::EX.look.labelScale > 0
               ? ::EX.look.labelScale : 0.75
    }

    function open() {
        this.lookK = this.lookScale()
        local scale = ::UI.dpiScale() * this.lookK   // [ui-look] was ::UI.dpiScale()
        local fontSize = (this.metrics.fontSize * scale + 0.5).tointeger()
        local rowHeight = (this.metrics.rowHeight * scale).tointeger()

        this.px = {}
        foreach (key, value in this.metrics) {
            this.px[key] <- (value * scale).tointeger()
        }
        this.px.fontSize = fontSize
        this.px.rowHeight = rowHeight

        this.font = this.lookFont(this.style.bodyFont, "body")   // [ui-font]
        this.siegeArt = ::UI.loadSprite(this.style.siegeSprite, ::UI.PAGE_STRATEGY)

        local info = ::UI.fontInfo(this.font, fontSize)
        local textHeight = info != null ? info.ascent + info.descent : fontSize
        this.px.nameY <- (rowHeight - textHeight) / 2 + this.px.countOffsetY
        this.px.siegeIconY <- (rowHeight - this.px.siegeIconHeight) / 2 + this.px.siegeIconOffsetY
    }

    // The engine state that changes under us, sampled once so every label sees one answer.
    function update() {
        local mouse = ::UI.mouse.pos()

        this.frame = {
            mouseX = mouse[0], mouseY = mouse[1],
            cursorBlocked = ::UI.overlayAt(mouse[0], mouse[1]) || ::UI.cursorOverGameUi(),
            hoveredFort = ::ui.cardManager().hoveredFort,
            showAll = this.style.showAllKey != null && ::UI.keyboard.down(this.style.showAllKey),
            localFactionId = ::game.localFactionId(),
        }

        local shadow = this.style.textShadowColour
        this.scope = {
            [::UI.Metric.imageFilter]        = this.style.imageFilter,
            [::UI.Cap.textShadow]            = this.style.textShadow ? 1 : 0,
            [::UI.Colour.textShadow]         = [shadow[0], shadow[1], shadow[2], this.style.textShadowAlpha],
            [::UI.Metric.textShadowX]        = this.px.textShadowOffsetX,
            [::UI.Metric.textShadowY]        = this.px.textShadowOffsetY,
            [::UI.Metric.textShadowSpread]   = this.px.textShadowSpread,
            [::UI.Metric.textShadowSoftness] = this.style.textShadowSoftness,
            [::UI.Metric.contrastThreshold]  = this.style.contrastThreshold,
            [::UI.Colour.contrastInkLight]   = this.style.textOnDarkPlate,
            [::UI.Colour.contrastInkDark]    = this.style.textOnLightPlate,
        }
    }

    // Takes the fort this label is about to show and answers whether it shows at all.
    function initialise(fort) {
        this.name = ""
        this.besieged = false

        if (!fort.fowVisible) {
            return false
        }
        if (this.frame.hoveredFort != fort && !this.frame.showAll) {
            return false
        }

        this.name = fort.displayName
        this.besieged = fort.siegeCount > 0
        return true
    }

    // The label's whole geometry, in one place: contents box, plate box, and where each item sits.
    function positionChildren(fort) {
        this.rect = null

        local anchor = ::UI.tileToScreen(fort.x + this.style.anchorTileOffsetX,
                                         fort.y + this.style.anchorTileOffsetY)
        if (!anchor[2]) {
            return false
        }

        local nameWidth = ::UI.textSize(this.name, this.font, this.px.fontSize)[0]
        local width = this.px.contentPadLeft + nameWidth + this.px.contentPadRight
        if (this.besieged) {
            width += this.px.countGapAfter + this.px.siegeIconWidth
        }

        local x = anchor[0] - width / 2 + this.px.labelOffsetX
        local y = anchor[1] + this.px.labelOffsetY

        local plateW = this.px.plateWidth > 0 ? this.px.plateWidth
                                              : width + this.px.platePadLeft + this.px.platePadRight
        local plateH = this.px.plateHeight > 0 ? this.px.plateHeight
                                               : this.px.rowHeight + this.px.platePadTop + this.px.platePadBottom

        this.rect = {
            x = x + (width - plateW) / 2 + this.px.plateOffsetX,
            y = y + (this.px.rowHeight - plateH) / 2 + this.px.plateOffsetY,
            w = plateW,
            h = plateH,
            nameX = x + this.px.contentPadLeft + this.px.countOffsetX,
            nameY = y + this.px.nameY,
            siegeX = x + this.px.contentPadLeft + nameWidth + this.px.countGapAfter + this.px.siegeIconOffsetX,
            siegeY = y + this.px.siegeIconY,
        }
        return true
    }

    // The plate under the cursor becomes this frame's hover, for handleMouse to act on.
    function claimHover(fort) {
        if (this.frame.cursorBlocked) {
            return
        }
        if (this.frame.mouseX < this.rect.x || this.frame.mouseX >= this.rect.x + this.rect.w) {
            return
        }
        if (this.frame.mouseY < this.rect.y || this.frame.mouseY >= this.rect.y + this.rect.h) {
            return
        }

        this.state.hover = { tileX = fort.x, tileY = fort.y, fort = fort,
                             x = this.rect.x, y = this.rect.y, w = this.rect.w, h = this.rect.h }
    }

    // Draws what the three above prepared. Reads no game data and computes no geometry.
    function renderLabel(fill) {
        ::UI.pushStyle(this.scope)
        local ink = ::UI.contrastText(fill[0], fill[1], fill[2])

        ::UI.drawRect(this.rect.x, this.rect.y, this.rect.w, this.rect.h,
                      fill[0], fill[1], fill[2], this.style.plateAlpha)

        ::UI.pushFont(this.font, this.style.sdfText, this.px.fontSize)
        ::UI.layoutAt(this.rect.nameX, this.rect.nameY)
        ::UI.textColoured(this.name, ink[0], ink[1], ink[2], 255)
        ::UI.popFont()

        if (this.besieged) {
            local tint = this.style.defaultIconTint
            ::UI.image(this.siegeArt, this.px.siegeIconWidth, this.px.siegeIconHeight,
                       this.rect.siegeX, this.rect.siegeY, tint[0], tint[1], tint[2], 255)
        }
        ::UI.popStyle()
    }

    // Points the game's own cursor at the fort's tile, so its tooltip and selection work off the plate.
    function handleMouse() {
        local hover = this.state.hover
        if (hover == null) {
            this.state.capturing = false
            return
        }
        if (!this.state.capturing && ::UI.cursorOverGameUi()) {
            this.state.capturing = false
            return
        }
        this.state.capturing = true

        ::UI.hoverTile(hover.tileX, hover.tileY)
        ::UI.mouse.capture()

        if (::UI.mouse.clicked(::UI.mouse.left)) {
            local clickKey = hover.tileX + "_" + hover.tileY
            // The player's own double-click speed, which is what the settlement itself tests
            // against; counting frames made the window shrink as the framerate rose.
            local doubleClick = this.state.lastClickKey == clickKey
                             && ::UI.mouse.clickedCount(::UI.mouse.left) >= 2

            ::UI.clickStratItem(hover.tileX, hover.tileY, 0, doubleClick)
            this.state.lastClickKey = clickKey
        } else if (::UI.mouse.clicked(::UI.mouse.right)) {
            ::UI.clickStratItem(hover.tileX, hover.tileY, 1, false)
        }
    }

    // One fort, start to finish.
    function renderFort(fort, fill) {
        if (!this.initialise(fort)) {
            return
        }
        if (!this.positionChildren(fort)) {
            return
        }
        this.claimHover(fort)
        this.renderLabel(fill)
    }

    function verify() {
        if (this.px == null || this.font == null || this.siegeArt == null) {
            return false
        }
        foreach (key, value in this.metrics) {
            if (!(key in this.px)) {
                return false
            }
        }
        if (!("nameY" in this.px) || !("siegeIconY" in this.px)) {
            return false
        }
        if (this.px.fontSize <= 0 || this.px.rowHeight <= 0) {
            return false
        }
        if (this.style.textShadowColour.len() != 3 || this.style.unknownFactionFill.len() != 3) {
            return false
        }
        if (this.style.defaultIconTint.len() != 3 || this.style.textOnDarkPlate.len() != 3
            || this.style.textOnLightPlate.len() != 3) {
            return false
        }
        if (::ui.cardManager == null) {
            return false
        }
        return ::game.factionCount != null && ::game.faction != null
            && ::UI.tileToScreen != null && ::UI.clickStratItem != null
    }

    function render() {
        if (this.state.down) {
            return
        }
        if (this.lookScale() != this.lookK) {
            this.open()   // [ui-look] the size setting arrived or changed since open()
        }

        this.state.hover = null
        if (!(::UI.context() & ::Enum.UiContext.campaignLive)) {
            return
        }
        if (!::options.hdFeature(::Enum.HdFeature.labels)) {
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
                this.state.tick += 1
                this.update()

                // Without the show-all key only the hovered fort can label, so only its owner is visited.
                local hovered = this.frame.showAll ? null : this.frame.hoveredFort
                local factions = []
                if (hovered != null) {
                    local owner = hovered.owner
                    if (owner != null) {
                        factions.append(owner)
                    }
                } else if (this.frame.showAll) {
                    local factionCount = ::game.factionCount()
                    for (local fi = 0; fi < factionCount; fi += 1) {
                        local faction = ::game.faction(fi)
                        if (faction != null) {
                            factions.append(faction)
                        }
                    }
                }

                foreach (faction in factions) {
                    local record = faction.record
                    local fill = record != null ? [record.primaryRed, record.primaryGreen, record.primaryBlue]
                                                : this.style.unknownFactionFill
                    if (hovered != null) {
                        this.renderFort(hovered, fill)
                        continue
                    }
                    local fortCount = faction.fortCount
                    for (local i = 0; i < fortCount; i += 1) {
                        local fort = faction.fort(i)
                        if (fort == null) {
                            continue
                        }
                        this.renderFort(fort, fill)
                    }
                }

                this.handleMouse()
                this.state.strikes = 0
            }
            catch (e) {
                this.state.hover = null
                this.state.capturing = false
                this.state.strikes += 1
                if (this.state.strikes >= this.style.maxStrikes) {
                    fault = "" + e
                }
            }
        }

        if (fault != "") {
            this.state.down = true
            this.state.hover = null
            this.state.capturing = false
            ::options.failHdFeature(::Enum.HdFeature.labels)
            println("squi: fort labels STOOD DOWN - " + fault)
        }
    }
}

local fortLabels = FortLabels()
fortLabels.style.showAllKey = ::UI.Key.leftAlt
fortLabels.open()

local fortCanvas = ::UI.canvas("##fort_labelscanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(fortCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(fortCanvas, function() { fortLabels.render() })
::UI.widgetUnderlay(fortCanvas, true)

::UI.onResize(function(w, h) { fortLabels.open() })

::EX.fortLabels <- fortLabels
