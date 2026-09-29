// Double-click an EMPTY campaign tile to snap the camera onto it.

local CameraSnap = class {
    function occupied(tile) {
        return tile.hasSettlement || tile.hasFort || tile.hasPort
            || tile.hasWatchtower || tile.hasArmy || tile.hasNavy
    }

    function render() {
        if (!::UI.mouse.doubleClicked(::UI.mouse.left)) return
        if (::UI.cursorOverGameUi()) return
        if (::UI.mouse.captured()) return
        local tile = ::stratMap.hoveredTile()
        if (tile == null) return
        if (this.occupied(tile)) return
        ::stratMap.jumpCamera(tile.x, tile.y)
    }
}

::EX.cameraSnap <- CameraSnap()

::UI.onFrame(function() { ::EX.cameraSnap.render() })
