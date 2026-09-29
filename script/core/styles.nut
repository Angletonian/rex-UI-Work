if (!("EX" in getroottable())) { ::EX <- {} }
if (!("shared" in ::EX)) { ::EX.shared <- {} }

// the game's normal tooltip style, applied to a window so its tooltips inherit it
::EX.shared.tooltips <- {
    [::UI.Surface.tooltip]      = [0, 0, 0, 160],
    [::UI.Colour.tooltipBorder] = [255, 245, 139, 255],
    [::UI.Colour.tooltipText]   = [255, 245, 139, 255],
    [::UI.Metric.tooltipDelay]  = 0,
    [::UI.Metric.tooltipPadX]   = 4,
    [::UI.Metric.tooltipPadY]   = 2,
    [::UI.Metric.roundTooltip]  = 0,
    [::UI.Metric.borderTooltip] = 2,
    [::UI.Metric.tooltipOffX]   = 24,
    [::UI.Metric.tooltipOffY]   = 34,
}
