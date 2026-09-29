local EventIcons = class {
    metrics = {
        iconWidth  = 0,
        iconHeight = 0,
        stackGap   = 0,
        offsetX    = 0,
        offsetY    = 0,
    }

    style = {
        suppressNative = true,
        showTooltips   = true,
        fadeIn         = true,
        alertPulse     = true,
        alertPeriod    = 1.5,
        alertLift      = 96,
        unreadTint     = [255, 255, 255],
        readTint       = [255, 255, 255],
        hoverTint      = [255, 255, 255],
        hoverLift      = 40,
        pixelHitTest   = true,
        imageFilter    = 0,
        maxStrikes     = 8,
    }

    state = { claimed = false, hover = 0, clock = 0.0, verified = false, down = false, strikes = 0 }

    px      = null
    sprites = null
    frame   = null
    scope   = null
    pendingTip = null   // [hd-tips] the hovered icon's title, drawn after the icons

    function open() {
        local scale = ::UI.dpiScale()
        this.px = {}
        foreach (key, value in this.metrics) {
            this.px[key] <- (value * scale + (value < 0 ? -0.5 : 0.5)).tointeger()
        }
        this.sprites = {}
        this.scope = { [::UI.Metric.imageFilter] = this.style.imageFilter }
    }

    function live() {
        return ::options.hdFeature(::Enum.HdFeature.events)
    }

    function claim() {
        local want = this.style.suppressNative && this.live()
        if (want == this.state.claimed) { return }
        ::ui.events.nativeIconsSet(!want)
        this.state.claimed = want
    }

    function sprite(kind, read) {
        local key = kind * 2 + (read ? 1 : 0)
        if (key in this.sprites) { return this.sprites[key] }
        local id = ::ui.events.iconSprite(kind, read)
        local image = id >= 0 ? ::UI.loadSpriteById(id, ::UI.PAGE_SHARED) : null
        this.sprites[key] <- image
        return image
    }

    function update() {
        local mouse = ::UI.mouse.pos()
        this.frame = {
            mouseX = mouse[0],
            mouseY = mouse[1],
            blocked = ::UI.overlayAt(mouse[0], mouse[1]),
            messages = ::ui.events.list(),
        }
    }

    function rectOf(message, image) {
        local natural = ::UI.imageSize(image.img)
        local w = this.px.iconWidth > 0 ? this.px.iconWidth
                : natural != null ? natural[0] : message.width
        local h = this.px.iconHeight > 0 ? this.px.iconHeight
                : natural != null ? natural[1] : message.height
        local x = message.x + (message.width - w) / 2 + this.px.offsetX
        local y = message.y + (message.height - h) / 2 + this.px.offsetY
        return [x, y, w, h]
    }

    function over(message, image, rect) {
        if (this.frame.blocked) { return false }
        local mx = this.frame.mouseX
        local my = this.frame.mouseY
        if (mx < rect[0] || my < rect[1] || mx >= rect[0] + rect[2] || my >= rect[1] + rect[3]) {
            return false
        }
        if (!this.style.pixelHitTest || image == null || image.img == 0) { return true }
        return ::UI.imageHitTest(image.img, rect[0], rect[1], rect[2], rect[3], mx, my)
    }

    function tintOf(message, hovered) {
        local rgb = message.unread ? this.style.unreadTint : this.style.readTint
        local lift = 0
        if (hovered) {
            rgb = this.style.hoverTint
            lift = this.style.hoverLift
        }
        if (this.style.alertPulse && message.needsInput && this.style.alertPeriod > 0.0) {
            local phase = this.state.clock / this.style.alertPeriod
            local wave = phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0
            lift = lift + (this.style.alertLift * wave).tointeger()
        }
        local alpha = this.style.fadeIn ? message.alpha : 255
        return [this.clamp(rgb[0] + lift), this.clamp(rgb[1] + lift), this.clamp(rgb[2] + lift), alpha]
    }

    function clamp(value) {
        return value < 0 ? 0 : (value > 255 ? 255 : value)
    }

    function act(message, hovered) {
        if (!hovered) { return }
        this.state.hover = message.id
        if (::UI.mouse.clicked(::UI.mouse.left)) {
            if (message.open) { ::ui.events.close(message.id) }
            else { ::ui.events.open(message.id) }
        }
        else if (::UI.mouse.clicked(::UI.mouse.right)) {
            ::ui.events.dismiss(message.id)
        }
    }

    function draw(message) {
        local image = this.sprite(message.kind, !message.unread)
        if (image == null || image.img == 0) { return }
        local rect = this.rectOf(message, image)
        local hovered = this.over(message, image, rect)
        local tint = this.tintOf(message, hovered)
        ::UI.image(image.img, rect[2], rect[3], rect[0], rect[1], tint[0], tint[1], tint[2], tint[3])
        if (this.style.showTooltips && message.title != "") {
            // [hd-tips] The engine tooltip is raised invisibly, as the map tooltips do, and the
            // title is drawn with ::EX.drawTip in their font and colours once the icons are done.
            if ("drawTip" in ::EX && "ghostStyle" in ::EX) {
                if (hovered) {
                    ::UI.pushStyle(::EX.ghostStyle())
                    ::UI.tooltipAt(rect[0], rect[1], rect[2], rect[3])
                    ::UI.tooltip(0, message.title)
                    ::UI.popStyle()
                    this.pendingTip = message.title
                }
            } else {
                ::UI.tooltipAt(rect[0], rect[1], rect[2], rect[3])
                ::UI.tooltip(0, message.title)
            }
        }
        this.act(message, hovered)
    }

    // [hd-tips] The hovered icon's title in the campaign map tooltip's box, font and colours.
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
            println("squi: [hd-tips] event icon tooltip failed - " + e)
        }
    }

    function verify() {
        if (this.px == null || this.sprites == null || this.scope == null) {
            return false
        }
        if (!("iconWidth" in this.px) || !("iconHeight" in this.px)
            || !("offsetX" in this.px) || !("offsetY" in this.px)) {
            return false
        }
        if (this.style.unreadTint.len() < 3 || this.style.readTint.len() < 3
            || this.style.hoverTint.len() < 3) {
            return false
        }
        if (::UI.imageSize == null || ::UI.imageHitTest == null || ::UI.overlayAt == null
            || ::UI.tooltipAt == null) {
            return false
        }
        if (::ui.events.iconSprite == null || ::ui.events.open == null
            || ::ui.events.close == null || ::ui.events.dismiss == null) {
            return false
        }
        if (::options.failHdFeature == null) {
            return false
        }
        return ::ui.events.list != null
    }

    function render() {
        if (this.state.down) {
            return
        }

        this.claim()
        if (!this.state.claimed) { return }

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
                this.state.clock += ::UI.time.delta()
                while (this.style.alertPeriod > 0.0 && this.state.clock >= this.style.alertPeriod) {
                    this.state.clock -= this.style.alertPeriod
                }
                this.update()
                this.state.hover = 0
                this.pendingTip = null
                ::UI.pushStyle(this.scope)
                foreach (message in this.frame.messages) {
                    this.draw(message)
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
            ::options.failHdFeature(::Enum.HdFeature.events)
            println("squi: event icons STOOD DOWN - " + fault)
        }
    }
}

local eventIcons = EventIcons()
eventIcons.open()

local eventCanvas = ::UI.canvas("##event_icons_canvas", 0, 0, 4, 4)
::UI.setWidgetStyle(eventCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(eventCanvas, function() { eventIcons.render() })
::UI.widgetUnderlay(eventCanvas, true)

::UI.onResize(function(w, h) { eventIcons.open() })

::EX.eventIcons <- eventIcons
