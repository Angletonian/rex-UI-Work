local Theme = class {
    // Authored at 1080p; the engine scales every length metric by UI.dpiScale() when it resolves it.
    metrics = {
        tooltipPadX    = 4,
        tooltipPadY    = 2,
        tooltipCorner  = 0,
        tooltipBorder  = 2,
        tooltipOffsetX = 24,
        tooltipOffsetY = 34,
    }

    style = {
        tooltipDelayMs    = 0,
        tooltipBackground = [0, 0, 0, 160],
        tooltipBorderInk  = [255, 245, 139, 255],
        tooltipInk        = [255, 245, 139, 255],
    }

    // Writes the overlay's default faces and tooltip look into the global style.
    function open() {
        // Without these every widget falls through to the engine's own baked face, which only
        // resolves once the font database has parsed and never honours a pixel size.
        ::UI.setStyle(::UI.Font.body, ::EX.fonts.body)
        ::UI.setStyle(::UI.Font.heading, ::EX.fonts.title)

        ::UI.setStyle(::UI.Surface.tooltip, this.style.tooltipBackground)
        ::UI.setStyle(::UI.Colour.tooltipBorder, this.style.tooltipBorderInk)
        ::UI.setStyle(::UI.Colour.tooltipText, this.style.tooltipInk)
        ::UI.setStyle(::UI.Metric.tooltipDelay, this.style.tooltipDelayMs)
        ::UI.setStyle(::UI.Metric.tooltipPadX, this.metrics.tooltipPadX)
        ::UI.setStyle(::UI.Metric.tooltipPadY, this.metrics.tooltipPadY)
        ::UI.setStyle(::UI.Metric.roundTooltip, this.metrics.tooltipCorner)
        ::UI.setStyle(::UI.Metric.borderTooltip, this.metrics.tooltipBorder)
        ::UI.setStyle(::UI.Metric.tooltipOffX, this.metrics.tooltipOffsetX)
        ::UI.setStyle(::UI.Metric.tooltipOffY, this.metrics.tooltipOffsetY)
    }
}

local theme = Theme()
theme.open()

::UI.onResize(function(w, h) { theme.open() })

::EX.theme <- theme
