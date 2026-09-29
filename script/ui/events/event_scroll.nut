local EventScroll = class {
    metrics = {
        width = 640,
        minHeight = 200,
        maxHeight = 700,
        screenMargin = 16,
        padX = 46,
        padTop = 54,
        padBottom = 54,
        titleGap = 14,
        rowGap = 6,
        lineGap = 2,
        imageMax = 360,
        sealX = 42,
        sealY = 44,
        sealW = 48,
        sealH = 52,
        titleSize = 22,
        bodySize = 16,
        cellGap = 10,
        buttonH = 26,
        buttonGap = 24,
    }

    style = {
        suppressNative = true,
        titleInk = [245, 230, 175],
        bodyInk  = [232, 220, 190],
        ruleInk  = [120, 104, 74],
        buttonInk = [245, 230, 175],
        buttonHoverInk = [255, 255, 255],
        acceptText = "SMT_ACCEPT",
        declineText = "SMT_DECLINE",
        sliceScale = 141,
        titleFont = null,
        bodyFont  = null,
        sdfText   = false,
        imageFilter = 0,
        maxStrikes = 8,
    }

    state = { claimed = false, openId = 0, verified = false, down = false, strikes = 0 }

    px    = null
    art   = null
    font  = null
    frame = null

    function open() {
        local scale = ::UI.dpiScale()
        this.px = {}
        foreach (key, value in this.metrics) {
            this.px[key] <- (value * scale + (value < 0 ? -0.5 : 0.5)).tointeger()
        }
        this.font = this.style.bodyFont != null ? this.style.bodyFont : ::EX.fonts.body
        this.art = { scroll = ::EX.shared.images.tileable_scroll,
                     seal = ::EX.shared.images.seal,
                     pics = {} }
    }

    function live() {
        return ::options.hdFeature(::Enum.HdFeature.events)
    }

    function picture(path) {
        if (path == "") { return null }
        if (path in this.art.pics) { return this.art.pics[path] }
        local img = ::UI.loadTexture(path)
        this.art.pics[path] <- img
        return img
    }

    function chosen() {
        foreach (message in ::ui.events.list()) {
            if (message.open) { return message }
        }
        return null
    }

    function claim(wanted) {
        local want = this.style.suppressNative && wanted
        if (want == this.state.claimed) { return }
        ::ui.events.nativePanelSet(!want)
        this.state.claimed = want
    }

    // Height a grid row will actually occupy, using the same wrapping as drawGrid().
    function gridHeight(row, inner) {
        local columns = row.columns > 0 ? row.columns : 1
        local colW = (inner - this.px.cellGap * (columns - 1)) / columns
        local lineH = 0
        local used = 0
        foreach (i, cell in row.cells) {
            local col = i % columns
            local m = ::UI.textSize(cell, this.font, this.px.bodySize, colW)
            if (m[1] > lineH) { lineH = m[1] }
            if (col == columns - 1) {
                used += lineH + this.px.lineGap
                lineH = 0
            }
        }
        if (lineH > 0) { used += lineH }
        return used
    }

    // Height of a non-button content row. Measuring and drawing both use this.
    function rowHeight(row, inner) {
        if (row.family == ::Enum.MessageRow.text) {
            return ::UI.textSize(row.text, this.font, this.px.bodySize, inner)[1]
        }
        if (row.family == ::Enum.MessageRow.rule) { return row.height }
        if (row.family == ::Enum.MessageRow.image) {
            local img = this.picture(row.image)
            return img != null && img.img != 0 ? this.imageHeight(img, inner) : 0
        }
        if (row.family == ::Enum.MessageRow.grid) { return this.gridHeight(row, inner) }
        return 0
    }

    function measure(rows, inner, cap) {
        local h = this.px.padTop + this.px.padBottom
        local hasButtons = false
        foreach (row in rows) {
            if (row.family == ::Enum.MessageRow.button) {
                hasButtons = true
                continue
            }
            h += this.rowHeight(row, inner) + this.px.rowGap
        }
        if (hasButtons) { h += this.px.buttonH + this.px.rowGap }
        if (h < this.px.minHeight) { h = this.px.minHeight }
        if (h > cap) { h = cap }
        return h
    }

    function imageHeight(img, inner) {
        local size = ::UI.imageSize(img.img)
        if (size == null || size[0] <= 0) { return 0 }
        local w = size[0] > inner ? inner : size[0]
        if (w > this.px.imageMax) { w = this.px.imageMax }
        return (size[1] * w) / size[0]
    }

    function drawText(row, x, y, inner) {
        ::UI.pushFont(this.font, this.style.sdfText, this.px.bodySize)
        local m = ::UI.textSize(row.text, this.font, this.px.bodySize, inner)
        local tx = row.justify == 1 ? x + (inner - m[0]) / 2
                 : row.justify == 2 ? x + inner - m[0] : x
        ::UI.layoutAt(tx, y)
        ::UI.pushStyle({ [::UI.Colour.text] = [row.r, row.g, row.b, row.a] })
        ::UI.textWrapped(row.text, inner)
        ::UI.popStyle()
        ::UI.popFont()
        return m[1]
    }

    function drawRule(row, x, y, inner) {
        if (row.a > 0 && row.height > 0) {
            local w = row.width > 0 && row.width < inner ? row.width : inner
            ::UI.drawRect(x + (inner - w) / 2, y, w, row.height, row.r, row.g, row.b, row.a)
        }
        return row.height
    }

    function drawImage(row, x, y, inner) {
        local img = this.picture(row.image)
        if (img == null || img.img == 0) { return 0 }
        local size = ::UI.imageSize(img.img)
        if (size == null || size[0] <= 0) { return 0 }
        local w = size[0] > inner ? inner : size[0]
        if (w > this.px.imageMax) { w = this.px.imageMax }
        local h = (size[1] * w) / size[0]
        ::UI.image(img.img, w, h, x + (inner - w) / 2, y)
        return h
    }

    function drawGrid(row, x, y, inner) {
        local columns = row.columns > 0 ? row.columns : 1
        local colW = (inner - this.px.cellGap * (columns - 1)) / columns
        local lineH = 0
        local used = 0
        ::UI.pushFont(this.font, this.style.sdfText, this.px.bodySize)
        ::UI.pushStyle({ [::UI.Colour.text] = [row.r, row.g, row.b, row.a] })
        foreach (i, cell in row.cells) {
            local col = i % columns
            local m = ::UI.textSize(cell, this.font, this.px.bodySize, colW)
            ::UI.layoutAt(x + col * (colW + this.px.cellGap), y + used)
            ::UI.textWrapped(cell, colW)
            if (m[1] > lineH) { lineH = m[1] }
            if (col == columns - 1) {
                used += lineH + this.px.lineGap
                lineH = 0
            }
        }
        if (lineH > 0) { used += lineH }
        ::UI.popStyle()
        ::UI.popFont()
        return used
    }

    function drawButton(row, message, x, y, inner) {
        local label = ::game.stratText(row.accept ? this.style.acceptText : this.style.declineText)
        if (label == "") { label = row.accept ? "Accept" : "Decline" }
        ::UI.pushFont(this.font, this.style.sdfText, this.px.bodySize)
        local m = ::UI.textSize(label, this.font, this.px.bodySize)
        local bw = m[0] + this.px.buttonGap
        local bx = row.accept ? x + inner / 2 - bw - this.px.buttonGap / 2
                              : x + inner / 2 + this.px.buttonGap / 2
        local hit = ::UI.hitRect(bx, y, bw, this.px.buttonH)
        local ink = hit.hovered ? this.style.buttonHoverInk : this.style.buttonInk
        ::UI.layoutAt(bx + (bw - m[0]) / 2, y + (this.px.buttonH - m[1]) / 2)
        ::UI.textColoured(label, ink[0], ink[1], ink[2], 255)
        ::UI.popFont()
        if (hit.clicked) {
            if (row.accept) { ::ui.events.accept(message.id) }
            else { ::ui.events.decline(message.id) }
        }
        return this.px.buttonH
    }

    function drawRow(row, message, x, y, inner) {
        if (row.family == ::Enum.MessageRow.text) { return this.drawText(row, x, y, inner) }
        if (row.family == ::Enum.MessageRow.rule) { return this.drawRule(row, x, y, inner) }
        if (row.family == ::Enum.MessageRow.image) { return this.drawImage(row, x, y, inner) }
        if (row.family == ::Enum.MessageRow.grid) { return this.drawGrid(row, x, y, inner) }
        if (row.family == ::Enum.MessageRow.button) { return this.drawButton(row, message, x, y, inner) }
        return 0
    }

    function verify() {
        if (this.px == null || this.art == null || this.font == null) {
            return false
        }
        foreach (key, value in this.metrics) {
            if (!(key in this.px)) {
                return false
            }
        }
        if (this.art.pics == null || this.art.seal == null || this.art.seal == 0) {
            return false
        }
        if (this.art.scroll == null || this.art.scroll.len() != 9) {
            return false
        }
        foreach (part in this.art.scroll) {
            if (part == 0) {
                return false
            }
        }
        if (this.style.titleInk.len() < 3 || this.style.buttonInk.len() < 3
            || this.style.buttonHoverInk.len() < 3) {
            return false
        }
        if (!("text" in ::Enum.MessageRow) || !("rule" in ::Enum.MessageRow)
            || !("image" in ::Enum.MessageRow) || !("grid" in ::Enum.MessageRow)
            || !("button" in ::Enum.MessageRow)) {
            return false
        }
        if (::UI.drawImageNine == null || ::UI.imageButton == null || ::UI.hitRect == null
            || ::UI.textSize == null || ::UI.layoutAt == null || ::UI.imageSize == null) {
            return false
        }
        if (::ui.events.body == null || ::ui.events.bodyDrawable == null
            || ::ui.events.needsAnswer == null || ::ui.events.nativePanelSet == null
            || ::ui.events.accept == null || ::ui.events.decline == null
            || ::ui.events.close == null) {
            return false
        }
        if (::options.failHdFeature == null || ::game.stratText == null) {
            return false
        }
        return ::ui.events.list != null
    }

    function render() {
        if (this.state.down) {
            return
        }

        local message = this.live() ? this.chosen() : null
        local drawable = message != null && ::ui.events.bodyDrawable(message.id)
        this.claim(drawable)
        if (!this.state.claimed || !drawable) { return }

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
                local rows = ::ui.events.body(message.id)
                local screen = ::UI.screenSize()
                local margin = this.px.screenMargin

                // Fit the scroll inside the window, not just inside maxHeight/width.
                local w = this.px.width
                if (w > screen[0] - margin * 2) { w = screen[0] - margin * 2 }
                local inner = w - this.px.padX * 2
                local cap = this.px.maxHeight
                if (cap > screen[1] - margin * 2) { cap = screen[1] - margin * 2 }

                local h = this.measure(rows, inner, cap)
                local x = (screen[0] - w) / 2
                local y = (screen[1] - h) / 2
                if (x < 0) { x = 0 }
                if (y < 0) { y = 0 }

                ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter,
                                 [::UI.Metric.sliceBorderScale] = this.style.sliceScale })
                ::UI.drawImageNine(this.art.scroll, x, y, w, h)

                local ink = this.style.titleInk
                ::UI.pushFont(this.font, this.style.sdfText, this.px.titleSize)
                local tm = ::UI.textSize(message.title, this.font, this.px.titleSize)
                ::UI.layoutAt(x + (w - tm[0]) / 2, y + this.px.padTop - tm[1] - this.px.titleGap)
                ::UI.textColoured(message.title, ink[0], ink[1], ink[2], 255)
                ::UI.popFont()

                // Buttons are pulled out and always drawn, so an event that needs an
                // answer can never have them cut off by overflowing content.
                local buttons = []
                foreach (row in rows) {
                    if (row.family == ::Enum.MessageRow.button) { buttons.append(row) }
                }

                local cursor = y + this.px.padTop
                local limit = y + h - this.px.padBottom
                if (buttons.len() > 0) { limit -= this.px.buttonH + this.px.rowGap }

                foreach (row in rows) {
                    if (row.family == ::Enum.MessageRow.button) { continue }
                    local rh = this.rowHeight(row, inner)
                    if (cursor + rh > limit) { break }
                    this.drawRow(row, message, x + this.px.padX, cursor, inner)
                    cursor += rh + this.px.rowGap
                }

                foreach (row in buttons) {
                    this.drawButton(row, message, x + this.px.padX, cursor, inner)
                }

                if (!::ui.events.needsAnswer(message.id)) {
                    local seal = ::UI.imageButton("##event_scroll_seal", this.art.seal,
                                                  this.px.sealW, this.px.sealH,
                                                  x + w - this.px.sealX - this.px.sealW,
                                                  y + h - this.px.sealY - this.px.sealH)
                    if (seal.clicked) { ::ui.events.close(message.id) }
                }
                ::UI.popStyle()
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
            println("squi: event scroll STOOD DOWN - " + fault)
            this.claim(false)
        }
    }
}

local eventScroll = EventScroll()
eventScroll.open()

local eventScrollCanvas = ::UI.canvas("##event_scroll_canvas", 0, 0, 4, 4)
::UI.setWidgetStyle(eventScrollCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(eventScrollCanvas, function() { eventScroll.render() })

::UI.onResize(function(w, h) { eventScroll.open() })

::EX.eventScroll <- eventScroll
