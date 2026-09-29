local SettlementLabels = class {
    metrics = {
        labelOffsetX   = 0,
        labelOffsetY   = 0,
        rowHeight      = 36,
        rowGap         = -10,
        plateWidth     = 0,
        plateHeight    = 0,
        platePadLeft   = 12,
        platePadRight  = 12,
        platePadTop    = 0,
        platePadBottom = 0,
        plateOffsetX   = 0,
        plateOffsetY   = 0,

        contentPadLeft  = 4,
        contentPadRight = 4,

        religionIconWidth    = 24,
        religionIconHeight   = 24,
        religionIconOffsetX  = 0,
        religionIconOffsetY  = 2,
        religionIconGapAfter = 4,

        nameOffsetX  = 0,
        nameOffsetY  = -1,
        nameGapAfter = 4,

        incomeIconWidth    = 24,
        incomeIconHeight   = 24,
        incomeIconOffsetX  = 0,
        incomeIconOffsetY  = 2,
        incomeIconGapAfter = 0,

        incomeTextOffsetX = 0,
        incomeTextOffsetY = 0,

        statusIconWidth  = 24,
        statusIconHeight = 24,
        statusRowOffsetX = 0,
        statusRowOffsetY = 0,
        statusIconGapX   = 0,

        fontSize = 24,
        textShadowOffsetX = 0,
        textShadowOffsetY = 0,
        textShadowSpread  = 5,
    }

    style = {
        anchorTileOffsetX = 0.5,
        anchorTileOffsetY = -0.25,

        plateFillImage   = "data/ui_hd/settlement_label_inner.png",
        plateBorderImage = "data/ui_hd/settlement_label_border_other.png",
        plateSliceLeft   = 16,
        plateSliceTop    = 16,
        plateSliceRight  = 16,
        plateSliceBottom = 16,
        pixelAccurateHover = true,

        bodyFont = "Montserrat-Regular.ttf",   // [ui-font] income figure (was "roboto.regular.ttf")
        nameFont = "constantine.regular.ttf",   // [ui-font] settlement name (was "roboto.medium.ttf")
        sdfText  = false,

        textShadow         = true,
        textShadowColour   = [0, 0, 0],
        textShadowAlpha    = 40,
        textShadowSoftness = 120,

        contrastThreshold = 140,
        textOnDarkPlate   = [245, 248, 232],
        textOnLightPlate  = [245, 248, 232],

        overrideFillColour   = false,
        fillColour           = [48, 52, 60, 230],
        overrideBorderColour = false,
        borderColour         = [255, 205, 90, 255],

        // The lower row takes the plate art but not the faction fill.
        lowerFillColour = [0, 0, 0, 164],

        factionFillAlpha   = 230,
        factionBorderAlpha = 255,

        fillSaturation = 160,
        fillBrightness = 120,
        borderSaturation = 60,
        borderBrightness = 110,

        defaultIconTint      = [255, 255, 255],
        queueIconTint        = [32, 196, 32],
        unknownFactionFill   = [90, 90, 100],
        unknownFactionBorder = [40, 40, 48],

        loyaltyColourVeryLow = [200, 0, 0],
        loyaltyColourLow     = [32, 32, 196],
        loyaltyColourMedium  = [196, 196, 0],
        loyaltyColourHigh    = [32, 196, 32],

        imageFilter      = 0,
        incomeIconImage  = "data/ui_hd/money.png",
        incomeIconSprite = "CONSTRUCTION_COST_ICON",

        religionOverrideImage = "data/ui_hd/cross.png",
        religionOverrideFor   = "catholic",

        constructionSprite = "SETTLEMENT_IS_BUILDING_ICON",
        recruitmentSprite  = "SETTLEMENT_IS_TRAINING_ICON",
        automanagedSprite  = "SETTLEMENT_AUTOMANAGED_ICON",
        loyaltySprite      = "SETTLEMENT_LOYALTY_ICON",

        statusSprites = { siege  = "STATUS_UNDER_SIEGE",
                          unrest = "STATUS_CIVIL_UNREST",
                          plague = "STATUS_IS_PLAGUED",
                          races  = "STATUS_HOLDING_RACES",
                          games  = "STATUS_HOLDING_GAMES" },

        growthIcons = { rising  = { sprite = "SETTLEMENT_GROWTH_ICON",          tint = [32, 196, 32] },
                        stable  = { sprite = "SETTLEMENT_GROWTH_ICON_STABLE",   tint = [255, 155, 0] },
                        falling = { sprite = "SETTLEMENT_GROWTH_ICON_NEGATIVE", tint = [200, 0, 0] } },

        // [hd-icons] Our own art for the lower row, one PNG per icon, looked for before the engine
        // sprite. A file that is missing or will not load falls back to the sprite above, so icons
        // can be replaced one at a time. Set an entry to null to keep the engine sprite on purpose.
        // Each file is looked for in hdIconFolders, first match wins; the console names what loaded.
        // Relative to the game folder, as money.png and cross.png are: "data/ui_hd/" is
        // ...\Medieval II Total War\data\ui_hd\ on whichever computer the game runs on.
        hdIconFolders = ["data/ui_hd/"],
        hdIconImages = { loyalty      = "loyalty.png",
                         rising       = "growth_rising.png",
                         stable       = "growth_stable.png",
                         falling      = "growth_falling.png",
                         construction = "construction.png",
                         recruitment  = "recruitment.png",
                         automanaged  = "automanaged.png",
                         siege        = "siege.png",
                         unrest       = "unrest.png",
                         plague       = "plague.png",
                         races        = "races.png",
                         games        = "games.png" },

        // [hd-icons] Tints for the status flags when drawn from our (white) PNGs. The engine's own
        // status sprites are already coloured and keep defaultIconTint.
        hdStatusTints = { siege  = [220, 60, 40],
                          unrest = [255, 140, 0],
                          plague = [170, 205, 60],
                          races  = [235, 200, 90],
                          games  = [235, 200, 90] },

        // [hd-icons] true: our PNGs take the same tints as the sprites (loyalty colour, green queue,
        // growth colours), so draw them white on transparent. false: full-colour art, drawn untinted.
        hdIconsTinted = true,

        // [hd-icons] Filter for the lower-row icons only; the plates keep imageFilter. 2 is what
        // radar.nut and ui_cards.nut use for art drawn at a size other than its own.
        iconImageFilter = 2,

        // [hd-icons] Religion pips by religion name (lowercase). Anything not listed uses the
        // game's own religion icon. religionOverrideFor/Image above still work.
        religionImages = { catholic = "data/ui_hd/cross.png" },

        maxStrikes = 8,
    }

    state = { tick = 0, hover = null, capturing = false, lastClickKey = "", deferred = null,
              verified = false, down = false, strikes = 0 }

    onActivated = []

    px          = null
    scope       = null
    frame       = null
    font        = null
    titleFont   = null
    art         = null
    religionArt = null
    rect        = null
    icons       = null
    name        = ""
    info        = null

    function hovered() { return this.state.hover }

    // Pulls a colour away from its own grey by saturation, then scales by brightness; both are percentages.
    function vivid(colour, saturation, brightness) {
        local satScale = saturation / 100.0
        local brightScale = brightness / 100.0
        local grey = (colour[0] + colour[1] + colour[2]) / 3.0

        local out = []
        foreach (channel in colour) {
            local level = (grey + (channel - grey) * satScale) * brightScale
            out.append(level < 0 ? 0 : (level > 255 ? 255 : level.tointeger()))
        }
        return out
    }

    // The pip for a religion, memoised: it is the same for every settlement of that religion.
    function religionIcon(religionId) {
        if (religionId in this.religionArt) {
            return this.religionArt[religionId]
        }

        local name = ::game.religionName(religionId).tolower()
        local path = ::game.religionIcon(religionId)
        if (name != "" && "religionImages" in this.style && name in this.style.religionImages
            && this.style.religionImages[name] != null) {
            path = this.style.religionImages[name]   // [hd-icons]
        } else if (name != "" && name == this.style.religionOverrideFor) {
            path = this.style.religionOverrideImage
        }

        local pip = ::UI.loadTexture(path)
        if (pip == null || pip.img == 0) {
            pip = ::UI.loadTexture(::game.religionIcon(religionId))   // our file failed: the game's own
        }
        this.religionArt[religionId] <- pip
        return pip
    }

    // [hd-icons] One lower-row icon: our PNG if it loads, else the engine sprite.
    // hd = true means `art` is a texture (drawn by its .img), false an engine sprite (drawn as is),
    // the same two forms the coin already uses.
    function iconArt(key, sprite) {
        local file = key in this.style.hdIconImages ? this.style.hdIconImages[key] : null
        if (file != null && file != "") {
            // A name with a folder in it is taken as a full path; a bare name is searched for.
            local tries = []
            if (file.indexof("/") != null) {
                tries.append(file)
            } else {
                foreach (dir in this.style.hdIconFolders) {
                    tries.append(dir + file)
                }
            }
            foreach (path in tries) {
                local tex = null
                try { tex = ::UI.loadTexture(path) } catch (e) { tex = null }
                if (tex != null && tex.img != 0) {
                    return { art = tex, hd = true }
                }
            }
            local where = ""
            foreach (path in tries) {
                where += (where == "" ? "" : ", ") + path
            }
            println("squi: [hd-icons] settlement labels could not load " + where + " - using " + sprite)
        }
        return { art = ::UI.loadSprite(sprite, ::UI.PAGE_STRATEGY), hd = false }
    }

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
            if (!works) println("squi: [ui-font] settlement labels could not use " + path)
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

        this.font = this.lookFont(this.style.bodyFont, "body")         // [ui-font]
        this.titleFont = this.lookFont(this.style.nameFont, "title")   // [ui-font]

        this.religionArt = {}
        this.art = { fill = ::UI.loadTexture(this.style.plateFillImage),
                     border = ::UI.loadTexture(this.style.plateBorderImage),
                     coin = ::UI.loadTexture(this.style.incomeIconImage),
                     coinSprite = ::UI.loadSprite(this.style.incomeIconSprite, ::UI.PAGE_STRATEGY),
                     loyalty = this.iconArt("loyalty", this.style.loyaltySprite),   // [hd-icons]
                     growth = {},
                     status = {} }
        foreach (trend, icon in this.style.growthIcons) {
            this.art.growth[trend] <- this.iconArt(trend, icon.sprite)
        }
        this.art.status.construction <- this.iconArt("construction", this.style.constructionSprite)
        this.art.status.recruitment <- this.iconArt("recruitment", this.style.recruitmentSprite)
        this.art.status.automanaged <- this.iconArt("automanaged", this.style.automanagedSprite)
        foreach (flag, sprite in this.style.statusSprites) {
            this.art.status[flag] <- this.iconArt(flag, sprite)
        }

        local nameInfo = ::UI.fontInfo(this.titleFont, fontSize)
        local textInfo = ::UI.fontInfo(this.font, fontSize)
        local nameHeight = nameInfo != null ? nameInfo.ascent + nameInfo.descent : fontSize
        local textHeight = textInfo != null ? textInfo.ascent + textInfo.descent : fontSize

        // Both plates are this tall; only their widths differ.
        this.px.plateH <- this.px.plateHeight > 0
                        ? this.px.plateHeight
                        : rowHeight + this.px.platePadTop + this.px.platePadBottom

        this.px.nameY <- (rowHeight - nameHeight) / 2 + this.px.nameOffsetY
        this.px.incomeTextY <- (rowHeight - textHeight) / 2 + this.px.incomeTextOffsetY
        this.px.incomeIconY <- (rowHeight - this.px.incomeIconHeight) / 2 + this.px.incomeIconOffsetY

        // The lower row's contents centre in the plate.
        this.px.religionIconY <- (this.px.plateH - this.px.religionIconHeight) / 2
                              + this.px.religionIconOffsetY
        this.px.statusIconY <- (this.px.plateH - this.px.statusIconHeight) / 2
                            + this.px.statusRowOffsetY
    }

    // The engine state that changes under us, sampled once so every label sees one answer.
    function update() {
        local mouse = ::UI.mouse.pos()

        this.frame = {
            mouseX = mouse[0], mouseY = mouse[1],
            hoveredSettlement = ::ui.cardManager().hoveredSettlement,
            cursorBlocked = ::UI.overlayAt(mouse[0], mouse[1]) || ::UI.cursorOverGameUi(),
            labelEverySettlement = ::game.options.labelSettlements(),
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

    // Answers whether this settlement gets a label at all.
    function initialise(sett, isLocal) {
        this.name = ""
        this.info = null

        if (!this.frame.labelEverySettlement && this.frame.hoveredSettlement != sett) {
            return false
        }
        if (!sett.fowVisible) {
            return false
        }

        this.name = sett.displayName
        if (this.name == "") {
            return false
        }
        if (!isLocal) {
            return true
        }

        local stats = sett.stats()
        if (stats == null) {
            return false
        }

        local producer = sett.aiProductionController
        local incomeText = "" + stats.netIncome

        this.info = {
            religionId = stats.majorityReligionId,
            incomeText = incomeText,
            incomeWidth = ::UI.textSize(incomeText, this.font, this.px.fontSize)[0],
            growth = stats.populationGrowth > 0.001 ? "rising"
                   : stats.populationGrowth < -0.001 ? "falling" : "stable",
            publicOrder = stats.publicOrder,
            construction = sett.constructionQueueCount > 0,
            recruitment = sett.recruitmentQueueCount > 0,
            automanaged = producer != null && producer.underControl,
            siege = sett.siegeCount > 0,
            unrest = sett.rioting,
            plague = sett.plagued,
            races = sett.races,
            games = sett.games,
        }
        return true
    }

    // Loyalty and growth always show; the rest are the flags initialise() found set.
    function statusIcons() {
        local order = this.info.publicOrder
        local loyaltyTint = order <= 70 ? this.style.loyaltyColourVeryLow
                          : order <= 80 ? this.style.loyaltyColourLow
                          : order <= 100 ? this.style.loyaltyColourMedium
                          : this.style.loyaltyColourHigh

        local growth = this.style.growthIcons[this.info.growth]
        local out = [{ art = this.art.loyalty, tint = loyaltyTint },
                     { art = this.art.growth[this.info.growth], tint = growth.tint }]
        if (this.info.construction) {
            out.append({ art = this.art.status.construction, tint = this.style.queueIconTint })
        }
        if (this.info.recruitment) {
            out.append({ art = this.art.status.recruitment, tint = this.style.queueIconTint })
        }
        if (this.info.automanaged) {
            out.append({ art = this.art.status.automanaged, tint = this.style.defaultIconTint })
        }
        foreach (flag, sprite in this.style.statusSprites) {
            if (this.info[flag]) {
                local art = this.art.status[flag]
                local tint = art.hd && flag in this.style.hdStatusTints ? this.style.hdStatusTints[flag]
                                                                         : this.style.defaultIconTint
                out.append({ art = art, tint = tint })
            }
        }
        return out
    }

    // The label's whole geometry: an upper plate of padLeft | name | coin | income | padRight,
    // and a lower one of padLeft | religion | status icons | padRight centred beneath it.
    function positionChildren(sett) {
        this.rect = null

        local anchor = ::UI.tileToScreen(sett.tileX + this.style.anchorTileOffsetX,
                                         sett.tileY + this.style.anchorTileOffsetY)
        if (!anchor[2]) {
            return false
        }

        local nameWidth = ::UI.textSize(this.name, this.titleFont, this.px.fontSize)[0]
        local width = this.px.contentPadLeft + nameWidth + this.px.nameGapAfter + this.px.contentPadRight
        if (this.info != null) {
            width += this.px.incomeIconWidth + this.px.incomeIconGapAfter + this.info.incomeWidth
        }

        local x = anchor[0] - width / 2 + this.px.labelOffsetX
        local y = anchor[1] + this.px.labelOffsetY

        local plateW = this.px.plateWidth > 0 ? this.px.plateWidth
                                              : width + this.px.platePadLeft + this.px.platePadRight
        local plateH = this.px.plateH

        local atX = x + this.px.contentPadLeft
        local nameX = atX + this.px.nameOffsetX
        atX += nameWidth + this.px.nameGapAfter

        this.rect = {
            x = x + (width - plateW) / 2 + this.px.plateOffsetX,
            y = y + (this.px.rowHeight - plateH) / 2 + this.px.plateOffsetY,
            w = plateW,
            h = plateH,
            nameX = nameX,
            nameY = y + this.px.nameY,
            coinX = atX + this.px.incomeIconOffsetX,
            coinY = y + this.px.incomeIconY,
            incomeX = atX + this.px.incomeIconWidth + this.px.incomeIconGapAfter + this.px.incomeTextOffsetX,
            incomeY = y + this.px.incomeTextY,
        }
        this.positionLowerRow()
        return true
    }

    // The status plate: its own width, the upper plate's height, centred under it.
    function positionLowerRow() {
        this.icons = null
        if (this.info == null) {
            return
        }

        this.icons = this.statusIcons()
        local hasReligion = this.info.religionId >= 0

        local content = this.icons.len() * this.px.statusIconWidth
                      + (this.icons.len() - 1) * this.px.statusIconGapX
        if (hasReligion) {
            content += this.px.religionIconWidth + this.px.religionIconGapAfter
        }

        local lowerW = content + this.px.contentPadLeft + this.px.contentPadRight
                     + this.px.platePadLeft + this.px.platePadRight
        local lowerX = this.rect.x + (this.rect.w - lowerW) / 2
        local lowerY = this.rect.y + this.rect.h + this.px.rowGap

        local atX = lowerX + this.px.platePadLeft + this.px.contentPadLeft
        this.rect.hasReligion <- hasReligion
        this.rect.religionX <- atX + this.px.religionIconOffsetX
        this.rect.religionY <- lowerY + this.px.religionIconY
        if (hasReligion) {
            atX += this.px.religionIconWidth + this.px.religionIconGapAfter
        }

        this.rect.lowerX <- lowerX
        this.rect.lowerY <- lowerY
        this.rect.lowerW <- lowerW
        this.rect.statusLeft <- atX
        this.rect.statusY <- lowerY + this.px.statusIconY
    }

    // The plate's own pixels are the hit shape, so only the gaps in the art are not live.
    function claimHover(sett, onHovered) {
        local overPlate = false
        if (!this.frame.cursorBlocked) {
            if (this.style.pixelAccurateHover && (this.art.fill.img != 0 || this.art.border.img != 0)) {
                overPlate = (this.art.fill.img != 0
                             && ::UI.imageHitTest(this.art.fill, this.rect.x, this.rect.y, this.rect.w, this.rect.h,
                                                  this.frame.mouseX, this.frame.mouseY))
                         || (this.art.border.img != 0
                             && ::UI.imageHitTest(this.art.border, this.rect.x, this.rect.y, this.rect.w, this.rect.h,
                                                  this.frame.mouseX, this.frame.mouseY))
            } else {
                overPlate = this.frame.mouseX >= this.rect.x && this.frame.mouseX < this.rect.x + this.rect.w
                         && this.frame.mouseY >= this.rect.y && this.frame.mouseY < this.rect.y + this.rect.h
            }
        }

        if (overPlate || (!this.frame.cursorBlocked && onHovered)) {
            this.state.hover = { tileX = sett.tileX, tileY = sett.tileY, sett = sett, overPlate = overPlate,
                                 x = this.rect.x, y = this.rect.y, w = this.rect.w, h = this.rect.h }
        }
        return overPlate
    }

    // The 9-sliced fill and border both rows are drawn from.
    function renderPlate(x, y, w, h, fill, border) {
        if (this.art.fill.img != 0) {
            ::UI.drawImageSliced(this.art.fill, x, y, w, h,
                                 this.style.plateSliceLeft, this.style.plateSliceTop,
                                 this.style.plateSliceRight, this.style.plateSliceBottom,
                                 0, 0, 0, fill[0], fill[1], fill[2], fill[3])
        } else {
            ::UI.drawRect(x, y, w, h, fill[0], fill[1], fill[2], fill[3])
        }
        if (this.art.border.img != 0) {
            ::UI.drawImageSliced(this.art.border, x, y, w, h,
                                 this.style.plateSliceLeft, this.style.plateSliceTop,
                                 this.style.plateSliceRight, this.style.plateSliceBottom,
                                 0, 0, 0, border[0], border[1], border[2], border[3])
        }
    }

    function renderLabel(colours) {
        ::UI.pushStyle(this.scope)

        local fill = this.style.overrideFillColour ? this.style.fillColour
                   : [colours.fill[0], colours.fill[1], colours.fill[2], this.style.factionFillAlpha]
        local border = this.style.overrideBorderColour ? this.style.borderColour
                     : [colours.border[0], colours.border[1], colours.border[2], this.style.factionBorderAlpha]
        local ink = ::UI.contrastText(fill[0], fill[1], fill[2])

        this.renderPlate(this.rect.x, this.rect.y, this.rect.w, this.rect.h, fill, border)

        ::UI.pushFont(this.titleFont, this.style.sdfText, this.px.fontSize)
        ::UI.layoutAt(this.rect.nameX, this.rect.nameY)
        ::UI.textColoured(this.name, ink[0], ink[1], ink[2], 255)
        ::UI.popFont()

        if (this.info == null) {
            ::UI.popStyle()
            return
        }

        if (this.art.coin.img != 0) {
            ::UI.image(this.art.coin.img, this.px.incomeIconWidth, this.px.incomeIconHeight,
                       this.rect.coinX, this.rect.coinY)
        } else {
            local tint = this.style.defaultIconTint
            ::UI.image(this.art.coinSprite, this.px.incomeIconWidth, this.px.incomeIconHeight,
                       this.rect.coinX, this.rect.coinY, tint[0], tint[1], tint[2], 255)
        }

        ::UI.pushFont(this.font, this.style.sdfText, this.px.fontSize)
        ::UI.layoutAt(this.rect.incomeX, this.rect.incomeY)
        ::UI.textColoured(this.info.incomeText, ink[0], ink[1], ink[2], 255)
        ::UI.popFont()

        this.renderLowerRow(border)
        ::UI.popStyle()
    }

    // Religion and the status icons, on a plate of their own under the name.
    function renderLowerRow(border) {
        if (this.icons == null) {
            return
        }

        local fill = this.style.lowerFillColour
        this.renderPlate(this.rect.lowerX, this.rect.lowerY, this.rect.lowerW, this.rect.h, fill, border)

        ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.iconImageFilter })   // [hd-icons]
        if (this.rect.hasReligion) {
            local pip = this.religionIcon(this.info.religionId)
            if (pip.img != 0) {
                ::UI.image(pip.img, this.px.religionIconWidth, this.px.religionIconHeight,
                           this.rect.religionX, this.rect.religionY)
            }
        }

        // [hd-icons] Our PNGs are drawn by texture handle, the engine sprites as themselves.
        local iconX = this.rect.statusLeft
        foreach (icon in this.icons) {
            local entry = icon.art
            local tint = entry.hd && !this.style.hdIconsTinted ? [255, 255, 255] : icon.tint
            ::UI.image(entry.hd ? entry.art.img : entry.art,
                       this.px.statusIconWidth, this.px.statusIconHeight,
                       iconX, this.rect.statusY, tint[0], tint[1], tint[2], 255)
            iconX += this.px.statusIconWidth + this.px.statusIconGapX
        }
        ::UI.popStyle()
    }

    function handleMouse() {
        local hover = this.state.hover
        if (hover == null || !hover.overPlate) {
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

            foreach (activated in this.onActivated) {
                activated(hover.sett, doubleClick)
            }
        } else if (::UI.mouse.clicked(::UI.mouse.right)) {
            ::UI.clickStratItem(hover.tileX, hover.tileY, 1, false)
        }
    }

    // One settlement's label; the hovered one is held back so the second pass draws it on top.
    function renderSettlement(sett, colours, isLocal, deferHovered = true) {
        if (!this.initialise(sett, isLocal)) {
            return
        }
        if (!this.positionChildren(sett)) {
            return
        }

        if (deferHovered) {
            local overPlate = this.claimHover(sett, this.frame.hoveredSettlement == sett)
            if (overPlate) {
                this.state.deferred.append({ sett = sett, colours = colours, isLocal = isLocal })
                return
            }
        }
        this.renderLabel(colours)
    }

    function verify() {
        if (this.px == null || this.art == null || this.religionArt == null || this.onActivated == null) {
            return false
        }
        if (this.font == null || this.titleFont == null) {
            return false
        }
        foreach (key, value in this.metrics) {
            if (!(key in this.px)) {
                return false
            }
        }
        if (!("fontSize" in this.px) || !("rowHeight" in this.px) || !("plateH" in this.px)
            || !("nameY" in this.px) || !("incomeTextY" in this.px) || !("incomeIconY" in this.px)
            || !("religionIconY" in this.px) || !("statusIconY" in this.px)) {
            return false
        }
        if (this.art.fill == null || this.art.border == null || this.art.coin == null
            || this.art.coinSprite == null || this.art.loyalty == null) {
            return false
        }
        if (!("img" in this.art.fill) || !("img" in this.art.border) || !("img" in this.art.coin)) {
            return false
        }
        if (this.art.growth == null || this.art.status == null) {
            return false
        }
        foreach (trend, icon in this.style.growthIcons) {
            if (!(trend in this.art.growth)) {
                return false
            }
        }
        foreach (flag, sprite in this.style.statusSprites) {
            if (!(flag in this.art.status)) {
                return false
            }
        }
        if (!("construction" in this.art.status) || !("recruitment" in this.art.status)
            || !("automanaged" in this.art.status)) {
            return false
        }
        if (this.style.textShadowColour == null || this.style.textShadowColour.len() < 3) {
            return false
        }
        if (this.style.unknownFactionFill == null || this.style.unknownFactionFill.len() < 3) {
            return false
        }
        if (this.style.unknownFactionBorder == null || this.style.unknownFactionBorder.len() < 3) {
            return false
        }
        if (::UI.textSize("M", this.titleFont, this.px.fontSize) == null) {
            return false
        }
        if (::ui.cardManager == null) {
            return false
        }
        return ::game.factionCount != null
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
                this.state.deferred = []

                // With per-settlement labels off only the hovered one can label, so only its owner is visited.
                local hovered = this.frame.labelEverySettlement ? null : this.frame.hoveredSettlement
                local factions = []
                if (hovered != null) {
                    local owner = hovered.owner
                    if (owner != null) {
                        factions.append(owner)
                    }
                } else if (this.frame.labelEverySettlement) {
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
                    local colours = {
                        fill = this.vivid(record != null ? [record.primaryRed, record.primaryGreen, record.primaryBlue]
                                                                 : this.style.unknownFactionFill,
                                                  this.style.fillSaturation, this.style.fillBrightness),
                        border = this.vivid(record != null ? [record.secondaryRed, record.secondaryGreen, record.secondaryBlue]
                                                                   : this.style.unknownFactionBorder,
                                                    this.style.borderSaturation, this.style.borderBrightness),
                    }
                    local isLocal = faction.id == this.frame.localFactionId
                    if (hovered != null) {
                        this.renderSettlement(hovered, colours, isLocal)
                        continue
                    }
                    local settlementCount = faction.settlementCount
                    for (local si = 0; si < settlementCount; si += 1) {
                        local sett = faction.settlement(si)
                        if (sett != null) {
                            this.renderSettlement(sett, colours, isLocal)
                        }
                    }
                }

                foreach (held in this.state.deferred) {
                    this.renderSettlement(held.sett, held.colours, held.isLocal, false)
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
            println("squi: settlement labels STOOD DOWN - " + fault)
        }
    }
}

local settlementLabels = SettlementLabels()
// [ui-look] Was ::EX.fonts.petrock. [ui-font] The labels now load Roboto themselves (style.nameFont /
// style.bodyFont); set either to null to fall back to the face chosen in hud_pane.nut's ::EX.look.
settlementLabels.open()

local labelCanvas = ::UI.canvas("##settlement_labelscanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(labelCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(labelCanvas, function() { settlementLabels.render() })
::UI.widgetUnderlay(labelCanvas, true)

::UI.onResize(function(w, h) { settlementLabels.open() })

::EX.labels <- settlementLabels
