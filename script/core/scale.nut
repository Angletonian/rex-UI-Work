if (!("EX" in getroottable())) { ::EX <- {} }
if (!("shared" in ::EX)) { ::EX.shared <- {} }

// authored 1920x1080 units in, widgetRect units out; virtual stretches x with the screen's width
::EX.shared.scaler <- function (virtual) {
    local d = ::UI.dpiScale()
    if (d <= 0.0) { d = 1.0 }
    local s = ::UI.screenSize()
    local fx = (virtual && s != null && s.len() >= 2 && s[0] > 0) ? (s[0] / 1920.0) / d : 1.0
    return { x = function (v) { return (v * fx + (v < 0 ? -0.5 : 0.5)).tointeger() },
             y = function (v) { return v } }
}
