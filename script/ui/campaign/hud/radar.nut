local CampaignRadar = class (::EX.HudPane) {
    // 1080p units, offset from the full-width pane's left edge, scaled by UI.dpiScale(). [m2ex-hd-fix]
    metrics = {
        paneHeight = 181,

        x = 0, y = 50, w = 250, h = 125,

        viewThick = 1,
    }

    style = {
        imageFilter = 2,

        showBackdrop = true,
        showOverlay  = true,
        showStars    = true,
        showView     = true,

        starSprite = "GENERALS_GOLD_STAR",
        colourView = [255, 0, 0],

        maxStrikes = 8,
    }

    feature = ::Enum.HdFeature.campaignHud
    map     = null
    star    = null
    handle  = -1
    frame   = null
    state   = { verified = false, down = false, strikes = 0 }

    function open() {
        this.openPaneFull()
        this.px.left <- this.pane.x + this.px.x
        this.px.top <- this.pane.y + this.px.y

        this.map = null
        this.handle = -1
        this.frame = null
        this.star = ::UI.loadSprite(this.style.starSprite, ::UI.PAGE_SHARED)
    }

    // A re-bake hands back a different texture, so re-adopt whenever the handle moves.
    function adopt() {
        local c = ::Campaign.current()
        if (c == null || !c.isOpen || !c.radarReady) {
            return false
        }
        if (this.map == null || this.handle != c.radarTexture
            || ::UI.imageSize(this.map.img) == null) {
            this.handle = c.radarTexture
            this.map = ::UI.imageFromTexture(this.handle)
        }
        return this.map != null && this.map.img != 0 && ::UI.imageSize(this.map.img) != null
    }

    // Tiles run left-to-right, bottom-to-top; screen y runs the other way.
    function tileToPx(x, y) {
        return [this.px.left + ((x.tofloat() / this.frame.tilesX) * this.px.w).tointeger(),
                this.px.top + ((1.0 - y.tofloat() / this.frame.tilesY) * this.px.h).tointeger()]
    }

    function pxToTile(sx, sy) {
        return [((sx - this.px.left).tofloat() / this.px.w) * this.frame.tilesX,
                (1.0 - (sy - this.px.top).tofloat() / this.px.h) * this.frame.tilesY]
    }

    // Asks the engine to flush its overlay, and reads back the frame it painted.
    function update() {
        local c = ::Campaign.current()
        c.radarBake()

        this.frame = { tilesX = ::stratMap.width().tofloat(),
                       tilesY = ::stratMap.height().tofloat(),
                       overlay = c.radarOverlayTexture,
                       overlayRect = c.radarOverlayRect(),
                       view = ::stratMap.viewCorners() }
    }

    // The one thing the overlay cannot show: a horde or homeless faction has no territory to colour.
    function renderStars() {
        local c = ::Campaign.current()
        local mine = ::game.localFactionId()
        for (local i = 0; i < c.factionCount; i++) {
            local faction = c.factionByOrder(i)
            if (faction == null || faction.id == mine || faction.status != 0
                || !(faction.isHorde || faction.isHomeless)) {
                continue
            }
            local record = faction.leader
            if (record == null || !record.isAlive || record.isOffMap()) {
                continue
            }
            local leader = record.character
            if (leader == null || !leader.fowVisible) {
                continue
            }
            local size = this.scaledSize(this.star)   // [m2ex-hd-fix]
            if (size == null) {
                continue
            }
            local at = this.tileToPx(leader.x, leader.y)
            ::UI.image(this.star.img, size[0], size[1],
                       at[0] - size[0] / 2, at[1] - size[1] / 2)
        }
    }

    // The quad of map the player can actually see.
    function renderView() {
        local view = this.frame.view
        local ink = this.style.colourView
        foreach (pair in [[0, 1], [1, 3], [3, 2], [2, 0]]) {
            local a = this.tileToPx(view[pair[0]].x, view[pair[0]].y)
            local b = this.tileToPx(view[pair[1]].x, view[pair[1]].y)
            ::UI.drawLine(a[0], a[1], b[0], b[1], this.px.viewThick, ink[0], ink[1], ink[2], 255)
        }
    }

    // Left-click walks the camera there; right-click is the map's own, so it is left alone.
    function handleMouse() {
        local m = ::UI.mouse.pos()
        if (m[0] < this.px.left || m[0] >= this.px.left + this.px.w
            || m[1] < this.px.top || m[1] >= this.px.top + this.px.h) {
            return
        }
        ::UI.mouse.capture()

        if (::UI.mouse.released(::UI.mouse.left)) {
            local at = this.pxToTile(m[0], m[1])
            ::stratMap.jumpCamera(at[0].tointeger(), at[1].tointeger())
        }
    }

    function verify() {
        if (this.pane == null || this.px == null) {
            return false
        }
        foreach (key in ["left", "top", "x", "y", "w", "h", "viewThick"]) {
            if (!(key in this.px)) {
                return false
            }
        }
        if (this.px.w <= 0 || this.px.h <= 0) {
            return false
        }
        if (this.star == null) {
            return false
        }
        if (this.style.colourView == null || this.style.colourView.len() < 3) {
            return false
        }
        if (::Campaign.current == null || ::stratMap.width == null || ::stratMap.height == null
            || ::stratMap.jumpCamera == null || ::stratMap.viewCorners == null) {
            return false
        }
        if (::UI.imageFromTexture == null || ::UI.textureRect == null || ::UI.drawLine == null
            || ::UI.imageSize == null) {
            return false
        }
        return ::game.localFactionId != null && ::options.failHdFeature != null
    }

    function render() {
        if (this.state.down) {
            return
        }
        if (!this.visible(::Enum.UiContext.campaignLive)) {
            return
        }
        local c = ::Campaign.current()
        if (c == null || !c.isOpen) {
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
                local backdrop = this.adopt()

                this.update()

                ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter })
                ::UI.pushClip(this.px.left, this.px.top, this.px.w, this.px.h)

                if (this.style.showBackdrop && backdrop) {
                    ::UI.image(this.map.img, this.px.w, this.px.h, this.px.left, this.px.top)
                }

                // The overlay is a sub-rect of a shared atlas, drawn by texel rect.
                if (this.style.showOverlay && this.frame.overlay >= 0 && this.frame.overlayRect != null) {
                    local r = this.frame.overlayRect
                    ::UI.textureRect(this.frame.overlay, this.px.w, this.px.h, this.px.left, this.px.top,
                                     r.x, r.y, r.w, r.h)
                }

                if (this.style.showStars && this.star != null && this.star.img != 0) {
                    this.renderStars()
                }
                if (this.style.showView && this.frame.view != null) {
                    this.renderView()
                }

                ::UI.popClip()
                ::UI.popStyle()

                this.handleMouse()
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
            println("squi: campaign radar STOOD DOWN - " + fault)
        }
    }
}

local campaignRadar = CampaignRadar()
campaignRadar.open()

local campaignRadarCanvas = ::UI.canvas("##campaignradarcanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(campaignRadarCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(campaignRadarCanvas, function() { campaignRadar.render() })
::UI.widgetUnderlay(campaignRadarCanvas, true)

::UI.onResize(function(w, h) { campaignRadar.open() })

::EX.campaignRadar <- campaignRadar
