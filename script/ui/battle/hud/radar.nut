local math = require("math")

local BattleRadar = class (::EX.HudPane) {
    // Pixels against the 1920x540 pane at 1080p, scaled once by pane.w / paneWidth.
    metrics = {
        paneWidth  = 1920,
        paneHeight = 540,

        w      = 220,
        h      = 220,
        gap    = 0,   // from the pane's left edge
        bottom = 0,   // from the pane's bottom edge

        bakeResolution = 1024,   // one high bake, drawn to fit - no re-bake on zoom

        minimal = { x = 856, y = 0, w = 168, h = 168 },

        blipSize        = 6,
        blipSizeGeneral = 7,
        blipOutline     = 2,
        coneLength      = 60,
        cameraMarker    = 5,
        outlineThick    = 2,
    }

    style = {
        imageFilter = 2,

        zoomMin  = 1.0,
        zoomMax  = 8.0,
        zoomStep = 0.5,

        // Vanilla's own marker rows, for a port or mod where battle.markerColours() answers null.
        markerColours = { us           = { primary = [0, 64, 0],   secondary = [0, 255, 0] },
                          allied       = { primary = [0, 0, 64],   secondary = [0, 0, 255] },
                          enemy        = { primary = [64, 0, 0],   secondary = [255, 0, 0] },
                          nonCombatant = { primary = [64, 64, 64], secondary = [255, 255, 255] } },
        colourSelected     = [0, 255, 0],
        colourCamera       = [255, 255, 255],
        colourCone         = [255, 255, 255, 40],
        // [hud-restyle] With the frame on (minimal HUD): the camera in warm gold instead.
        colourCameraFramed = [255, 222, 140],
        colourConeFramed   = [255, 214, 120, 46],
        colourDeployment   = [255, 220, 120],   // fallback for a faction with no record to read

        showBlips      = true,
        showCamera     = true,
        showDeployment = true,

        // [hud-restyle] The map in the campaign tooltips' frame (hud_pane.nut's gold double frame and
        // corner brackets), with a soft shadow inside the edge so it sits into the plate.
        // "minimal": on the minimal HUD and the compact full HUD (hud_pane.nut's battleFullScale);
        // M2EX's own full layout keeps the mod's look (the default);
        // true: on both; false: the bare map, as before.
        showFrame      = "minimal",
        innerShadow    = 70,    // alpha at the very edge (0 = off)
        innerShadowW   = 10,    // 1080p units the shadow reaches in
        // The camera leash clamps a click back to your own units; clearing it makes the click travel.
        freeCameraClick = false,

        maxStrikes = 8,
    }

    feature    = ::Enum.HdFeature.battleHud
    map        = null
    art        = null
    markers    = null
    generation = -1
    texture    = 0
    zoom       = 1.0
    panX       = 0
    panY       = 0
    panned     = false
    frame      = null
    blips      = null
    minimalUi  = false
    state      = { verified = false, down = false, strikes = 0 }

    function open() {
        this.minimalUi = !::options.isNormalHud()

        local scale = this.openPane(false, { paneWidth = true, paneHeight = true })
        if (this.minimalUi) {
            local virt = ::UI.virtualScale()
            local mini = this.metrics.minimal
            if ("miniRect" in ::EX) {   // [mini-layout] hud_pane.nut places (and sizes) the radar column
                // [hud-scale] hud_pane.nut's scaled layout, anchored to the top-right corner,
                // so the map stays square and in step with the HUD's radar column
                local at = ::EX.miniRect(mini.x, mini.y, mini.w, mini.h, "right")
                this.px.w = at.w
                this.px.h = at.h
                this.px.x <- at.x
                this.px.y <- at.y
            } else {
                this.px.w = (mini.w * virt[0]).tointeger()
                this.px.h = (mini.h * virt[1]).tointeger()
                this.px.x <- (mini.x * virt[0]).tointeger()
                this.px.y <- (mini.y * virt[1]).tointeger()
            }
        } else if ("fullLayout" in ::EX && ::EX.fullScale() != null) {
            // [hud-full] the compact full HUD's radar block, bottom-left (hud_pane.nut)
            local r = ::EX.fullLayout().radar
            this.px.w = r.w
            this.px.h = r.h
            this.px.x <- r.x
            this.px.y <- r.y
        } else {
            this.px.w = (this.metrics.w * scale).tointeger()
            this.px.h = (this.metrics.h * scale).tointeger()
            this.px.x <- (this.pane.x + this.metrics.gap * scale).tointeger()
            this.px.y <- (this.pane.y + this.pane.h - this.metrics.bottom * scale
                          - this.metrics.h * scale).tointeger()
        }

        this.art = { dot = ::UI.loadSprite("RADAR_DOT", ::UI.PAGE_RADAR),
                     dotGeneral = ::UI.loadSprite("RADAR_DOT_GENERAL", ::UI.PAGE_RADAR) }
        local live = ::battle.markerColours()
        this.markers = live != null ? live : this.style.markerColours

        this.map = null
        this.generation = -1
        this.texture = 0
        this.zoom = 1.0
        this.panX = 0
        this.panY = 0
        this.frame = null
    }

    // A re-bake destroys the old texture handle, so re-adopt whenever the generation moves.
    function adopt() {
        local b = ::battle.current()
        if (b == null || !b.radarReady) {
            return false
        }
        if (b.radarResolution != this.metrics.bakeResolution) {
            b.radarResolution = this.metrics.bakeResolution
        }
        // A resolution change swaps the texture underneath without moving the generation, so the
        // handle is checked too - otherwise the old, freed one is kept and nothing draws.
        if (this.map == null || this.generation != b.radarGeneration || this.texture != b.radarTexture) {
            this.map = ::UI.imageFromTexture(b.radarTexture)
            this.generation = b.radarGeneration
            this.texture = b.radarTexture
        }
        return this.map != null && this.map.img != 0
    }

    // The world is a square centred on the origin; z runs the opposite way to screen y.
    function worldToPx(x, z) {
        local size = this.frame.worldSize
        return [this.px.x + this.panX + ((x / size + 0.5) * this.px.w * this.zoom).tointeger(),
                this.px.y + this.panY + ((0.5 - z / size) * this.px.h * this.zoom).tointeger()]
    }

    function pxToWorld(sx, sy) {
        local size = this.frame.worldSize
        return [(((sx - this.px.x - this.panX).tofloat() / (this.px.w * this.zoom)) - 0.5) * size,
                (0.5 - ((sy - this.px.y - this.panY).tofloat() / (this.px.h * this.zoom))) * size]
    }

    // The engine state the whole frame reads, sampled once: which enemies are visible, and who is us.
    function update() {
        local b = ::battle.current()
        local side = b.localSide

        this.frame = { worldSize = b.radarWorldSize.tofloat(),
                       phase = b.phase,
                       factionColours = ::options.radarFactionColours(),
                       localAlliance = side != null ? side.index : -1,
                       visible = {},
                       playerArmies = {} }

        for (local i = 0; i < b.playerArmyCount; i++) {
            local army = b.playerArmy(i)
            if (army != null) {
                this.frame.playerArmies[army.index] <- true
            }
        }

        local ai = side != null ? side.ai : null
        if (ai != null) {
            for (local i = 0; i < ai.visibleEnemyCount; i++) {
                local seen = ai.visibleEnemy(i)
                if (seen != null) {
                    this.frame.visible[seen.id] <- true
                }
            }
        }
    }

    // Us, allied, enemy or neither - the alignment the native marker colours by.
    function alignment(army) {
        if (army.index in this.frame.playerArmies) {
            return "us"
        }
        if (army.battleAlliance == this.frame.localAlliance) {
            return "allied"
        }
        if (army.battleAlliance < 0) {
            return "nonCombatant"
        }
        return "enemy"
    }

    // Primary fills the dot, secondary rings it - the faction's own pair when faction colours are on.
    function blipInk(army, secondary) {
        if (this.frame.factionColours) {
            local record = army.faction != null ? army.faction.record : null
            if (record != null) {
                return secondary ? [record.secondaryRed, record.secondaryGreen, record.secondaryBlue]
                                 : [record.primaryRed, record.primaryGreen, record.primaryBlue]
            }
        }
        local pair = this.markers[this.alignment(army)]
        return secondary ? pair.secondary : pair.primary
    }

    // 6px at 1x zoom and twice that from 4x up, generals a pixel larger - the native marker's ladder.
    function blipSize(unit) {
        local dot = unit.isGeneralUnit ? this.px.blipSizeGeneral : this.px.blipSize
        local size = (dot * math.sqrt(this.zoom) + 0.5).tointeger()
        if (size > dot * 2) {
            return dot * 2
        }
        return size < dot ? dot : size
    }

    // One blip, the ring pass drawn a little larger than the fill pass it sits under.
    function renderBlip(blip, outline) {
        local size = blip.size + (outline ? this.px.blipOutline : 0)
        local ink = outline ? blip.ring : blip.fill
        ::UI.image(blip.art.img, size, size, blip.x - size / 2, blip.y - size / 2,
                   ink[0], ink[1], ink[2], 255)
    }

    // One dot per unit, enemies only where seen; every ring first, so none lands on a neighbour's dot.
    function renderBlips() {
        this.collectBlips()
        foreach (blip in this.blips) {
            this.renderBlip(blip, true)
        }
        foreach (blip in this.blips) {
            this.renderBlip(blip, false)
        }
    }

    // Everything both passes draw with, read once: the walk is side x army x unit.
    function collectBlips() {
        this.blips = []
        local b = ::battle.current()
        for (local s = 0; s < b.sideCount; s++) {
            local side = b.side(s)
            if (side == null) {
                continue
            }
            local own = side.index == this.frame.localAlliance
            for (local a = 0; a < side.armyCount; a++) {
                local slot = side.armySlot(a)
                local army = slot != null ? slot.army : null
                if (army == null) {
                    continue
                }
                local ring = this.blipInk(army, true)
                local fill = this.blipInk(army, false)
                for (local u = 0; u < army.unitCount; u++) {
                    local unit = army.unit(u)
                    if (unit == null || unit.isDead) {
                        continue
                    }
                    if (!own && !(unit.id in this.frame.visible)) {
                        continue
                    }
                    local art = unit.isGeneralUnit ? this.art.dotGeneral : this.art.dot
                    if (art == null || art.img == 0) {
                        continue
                    }
                    local at = this.worldToPx(unit.x, unit.z)
                    this.blips.append({ x = at[0], y = at[1], art = art,
                                        size = this.blipSize(unit), ring = ring,
                                        fill = unit.isSelected ? this.style.colourSelected : fill })
                }
            }
        }
    }

    // Where the camera is and roughly what it can see - a wedge of cameraFov about cameraYaw.
    function renderCamera() {
        local b = ::battle.current()
        local at = this.worldToPx(b.cameraX, b.cameraZ)
        local half = b.cameraFov * 0.5
        local reach = this.px.coneLength * this.zoom

        local leftX = at[0] + (math.sin(b.cameraYaw - half) * reach).tointeger()
        local leftY = at[1] - (math.cos(b.cameraYaw - half) * reach).tointeger()
        local rightX = at[0] + (math.sin(b.cameraYaw + half) * reach).tointeger()
        local rightY = at[1] - (math.cos(b.cameraYaw + half) * reach).tointeger()

        local cone = this.framed() ? this.style.colourConeFramed : this.style.colourCone
        ::UI.drawTriangle(at[0], at[1], leftX, leftY, rightX, rightY,
                          cone[0], cone[1], cone[2], cone[3])

        local ink = this.framed() ? this.style.colourCameraFramed : this.style.colourCamera
        ::UI.drawRect(at[0] - this.px.cameraMarker / 2, at[1] - this.px.cameraMarker / 2,
                      this.px.cameraMarker, this.px.cameraMarker, ink[0], ink[1], ink[2], 255)
    }

    // One area's outer edge and then every span cut out of it.
    function renderArea(area, ink) {
        for (local i = 0; i < area.pointCount; i++) {
            local a = area.point(i)
            local b = area.point((i + 1) % area.pointCount)
            if (a != null && b != null) {
                local p = this.worldToPx(a.x, a.y)
                local q = this.worldToPx(b.x, b.y)
                ::UI.drawLine(p[0], p[1], q[0], q[1], this.px.outlineThick, ink[0], ink[1], ink[2], 255)
            }
        }
        for (local s = 0; s < area.spanCount; s++) {
            local count = area.spanPointCount(s)
            for (local i = 0; i < count; i++) {
                local a = area.spanPoint(s, i)
                local b = area.spanPoint(s, (i + 1) % count)
                if (a != null && b != null) {
                    local p = this.worldToPx(a.x, a.y)
                    local q = this.worldToPx(b.x, b.y)
                    ::UI.drawLine(p[0], p[1], q[0], q[1], this.px.outlineThick, ink[0], ink[1], ink[2], 255)
                }
            }
        }
    }

    // Every army's own zones, each in its owner's colour, exactly as the native radar walks them.
    function renderDeployment() {
        local b = ::battle.current()
        for (local s = 0; s < b.sideCount; s++) {
            local side = b.side(s)
            if (side == null) {
                continue
            }
            for (local a = 0; a < side.armyCount; a++) {
                local slot = side.armySlot(a)
                local army = slot != null ? slot.army : null
                local faction = army != null ? army.faction : null
                local record = faction != null ? faction.record : null
                local ink = record != null ? [record.primaryRed, record.primaryGreen, record.primaryBlue]
                                           : this.style.colourDeployment
                if (slot == null) {
                    continue
                }
                for (local i = 0; i < slot.deploymentAreaCount; i++) {
                    local area = slot.deploymentAreaAt(i)
                    if (area != null) {
                        this.renderArea(area, ink)
                    }
                }
            }
        }
    }

    // Wheel zooms, drag pans, right-click orders the selection, a click takes the camera there.
    function handleMouse() {
        // The overlay's own hit pass, so a window drawn over the radar takes the click instead of this.
        local hit = ::UI.hitRect(this.px.x, this.px.y, this.px.w, this.px.h)
        if (!hit.hovered) {
            if (::UI.mouse.released(::UI.mouse.left)) { this.panned = false }
            return
        }
        local m = ::UI.mouse.pos()

        local wheel = ::UI.mouse.wheel()
        if (wheel != 0) {
            ::UI.mouse.captureWheel()
            this.zoom += wheel > 0 ? this.style.zoomStep : -this.style.zoomStep
            if (this.zoom < this.style.zoomMin) { this.zoom = this.style.zoomMin }
            if (this.zoom > this.style.zoomMax) { this.zoom = this.style.zoomMax }
            this.clampPan()
        }

        if (hit.held && ::UI.mouse.dragging(::UI.mouse.left)) {
            local moved = ::UI.mouse.dragDelta(::UI.mouse.left)
            if (moved[0] != 0 || moved[1] != 0) { this.panned = true }
            this.panX += moved[0]
            this.panY += moved[1]
            ::UI.mouse.dragReset(::UI.mouse.left)
            this.clampPan()
            return
        }

        if (hit.clicked) {
            if (!this.panned) {
                local b = ::battle.current()
                if (this.style.freeCameraClick && b.cameraRestrict) {
                    b.cameraRestrict = false
                }
                local at = this.pxToWorld(m[0], m[1])
                b.cameraMoveTo(at[0], at[1])
            }
            this.panned = false
            return
        }

        if (hit.clickedRight) {
            local at = this.pxToWorld(m[0], m[1])
            local height = ::battle.current().groundHeightAt(at[0], at[1])
            if (height == null) {
                return
            }
            local platform = ::battle.current().platformAt(at[0], at[1])
            if (::battle.selection.canReach(at[0], height, at[1], platform)) {
                ::battle.selection.move(at[0], height, at[1],
                                        ::UI.mouse.clickedCount(::UI.mouse.right) >= 2, platform)
            }
        }
    }

    // [hud-restyle] Whether the map is framed on the HUD in use.
    function framed() {
        if ("restyled" in ::EX && !::EX.restyled()) return false   // [restyle] the bare map, as the mod has it
        local v = this.style.showFrame
        return v == true || (v == "minimal" && (this.minimalUi
               || ("fullScale" in ::EX && ::EX.fullScale() != null)))   // [hud-full] the compact full HUD too
    }

    // [hud-restyle] A shadow that fades in from the map's four edges.
    function renderEdge() {
        local a = this.style.innerShadow
        if (!this.framed() || a <= 0) {
            return
        }
        local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
        local reach = (this.style.innerShadowW * k + 0.5).tointeger()
        if (reach < 2) reach = 2
        local x = this.px.x
        local y = this.px.y
        local w = this.px.w
        local h = this.px.h
        for (local i = 0; i < reach; i++) {
            local alpha = (a * (reach - i) / reach).tointeger()
            ::UI.drawRect(x, y + i, w, 1, 0, 0, 0, alpha)
            ::UI.drawRect(x, y + h - 1 - i, w, 1, 0, 0, 0, alpha)
            ::UI.drawRect(x + i, y, 1, h, 0, 0, 0, alpha)
            ::UI.drawRect(x + w - 1 - i, y, 1, h, 0, 0, 0, alpha)
        }
    }

    // Keep the zoomed image covering the frame, so no empty band shows at an edge.
    function clampPan() {
        local slackX = (this.px.w * this.zoom).tointeger() - this.px.w
        local slackY = (this.px.h * this.zoom).tointeger() - this.px.h
        if (this.panX > 0) { this.panX = 0 }
        if (this.panY > 0) { this.panY = 0 }
        if (this.panX < -slackX) { this.panX = -slackX }
        if (this.panY < -slackY) { this.panY = -slackY }
    }

    function verify() {
        if (this.px == null) {
            return false
        }
        foreach (key in ["x", "y", "w", "h", "blipSize", "blipSizeGeneral", "blipOutline",
                         "coneLength", "cameraMarker", "outlineThick"]) {
            if (!(key in this.px)) {
                return false
            }
        }
        if (this.px.w <= 0 || this.px.h <= 0) {
            return false
        }
        if (this.art == null || !("dot" in this.art) || !("dotGeneral" in this.art)) {
            return false
        }
        if (this.markers == null) {
            return false
        }
        foreach (key in ["us", "allied", "enemy", "nonCombatant"]) {
            if (!(key in this.markers)) {
                return false
            }
            local pair = this.markers[key]
            if (pair == null || !("primary" in pair) || !("secondary" in pair)) {
                return false
            }
        }
        if (!("deploymentPlayer2" in ::Enum.BattleState)) {
            return false
        }
        return ::battle.selection != null && ::options.radarFactionColours != null
    }

    function render() {
        if (this.state.down) {
            return
        }
        if (!this.visible(::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded)) {
            return
        }
        // [hud-toggles] the radar toggle key
        if ("battleShortcuts" in ::EX && "isHidden" in ::EX.battleShortcuts
            && ::EX.battleShortcuts.isHidden("radar")) {
            return
        }
        if (!this.adopt()) {
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
                this.update()

                ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter })
                ::UI.pushClip(this.px.x, this.px.y, this.px.w, this.px.h)

                ::UI.image(this.map.img, (this.px.w * this.zoom).tointeger(),
                           (this.px.h * this.zoom).tointeger(),
                           this.px.x + this.panX, this.px.y + this.panY)

                if (this.style.showDeployment && this.frame.phase <= ::Enum.BattleState.deploymentPlayer2) {
                    this.renderDeployment()
                }
                if (this.style.showBlips) {
                    this.renderBlips()
                }
                if (this.style.showCamera) {
                    this.renderCamera()
                }
                this.renderEdge()   // [hud-restyle] inner shadow, still inside the clip

                ::UI.popClip()
                if (this.framed() && "tipFrame" in ::EX) {
                    ::EX.tipFrame(this.px.x, this.px.y, this.px.w, this.px.h,
                                  ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0)   // [hud-restyle]
                }
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
            ::options.failHdFeature(::Enum.HdFeature.battleHud)
            println("squi: battle radar STOOD DOWN - " + fault)
        }
    }
}

local battleRadar = BattleRadar()
battleRadar.open()

local battleRadarCanvas = ::UI.canvas("##battleradarcanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(battleRadarCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(battleRadarCanvas, function() { battleRadar.render() })
::UI.widgetUnderlay(battleRadarCanvas, true)

::UI.onResize(function(w, h) { battleRadar.open() })

::EX.battleRadar <- battleRadar
