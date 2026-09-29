local format = require("string").format

local BattleHud = class (::EX.HudPane) {
    // Pixels against the 1920x540 pane at 1080p, scaled once by pane.w / paneWidth; gap and bottom are from the named edges.
    metrics = {
        paneWidth  = 1920,
        paneHeight = 540,

        leftW      = 320,
        leftH      = 255,
        rightW     = 320,
        rightH     = 255,
        midW       = 1280,
        midH       = 224,
        cardsW     = 1280,
        cardsH     = 214,
        overflowW  = 182,
        overflowH  = 340,

        // Array order is draw order; sprite is the BSD_ symbol with the prefix stripped, off UI.PAGE_BATTLE.
        buttons = [
            { id = "halt", cmd = ::Enum.UnitCommand.halt, sprite = "HALT_BUTTON_IMAGE_SELECTED",                w = 53,  h = 53,  edge = "right", gap = 165, bottom = 16 },
            { id = "withdraw", cmd = ::Enum.UnitCommand.withdraw, sprite = "WITHDRAW_BUTTON_IMAGE_SELECTED",            w = 53,  h = 53,  edge = "right", gap = 213, bottom = 36 },
            { id = "guard", cmd = ::Enum.UnitCommand.guard, sprite = "GUARD_BUTTON_IMAGE",                        w = 53,  h = 53,  edge = "right", gap = 232, bottom = 83 },
            { id = "skirmish", cmd = ::Enum.UnitCommand.skirmish, sprite = "SKIRMISH_BUTTON_IMAGE",                     w = 53,  h = 53,  edge = "right", gap = 213, bottom = 131 },
            { id = "fireAtWill", cmd = ::Enum.UnitCommand.fireAtWill, sprite = "AUTOFIRE_BUTTON_IMAGE",                     w = 53,  h = 53,  edge = "right", gap = 165, bottom = 151 },
            { id = "run", cmd = ::Enum.UnitCommand.run, sprite = "WALK_BUTTON_IMAGE",                         w = 53,  h = 53,  edge = "right", gap = 117, bottom = 131 },
            { id = "closeFormation", cmd = ::Enum.UnitCommand.closeFormation, sprite = "FORMATION_TIGHTNESS_BUTTON_IMAGE_SELECTED", w = 53,  h = 53,  edge = "right", gap = 98,  bottom = 83 },
            { id = "specialAbility", cmd = ::Enum.UnitCommand.specialAbility, sprite = "NO_SPECIAL_ABILITY_BUTTON_IMAGE",           w = 53,  h = 53,  edge = "right", gap = 117, bottom = 36 },
            { id = "flashUnits", art = "portrait",  w = 78,  h = 78,  edge = "right", gap = 153, bottom = 71 },
            { art = "hoop",      w = 188, h = 188, edge = "right", gap = 98,  bottom = 16, placeholder = true },
            { id = "group", cmd = ::Enum.UnitCommand.group, sprite = "GROUP_BUTTON_IMAGE",                        w = 44,  h = 44,  edge = "right", gap = 24,  bottom = 24 },
            { id = "groupAi", cmd = ::Enum.UnitCommand.group, sprite = "AI_CONTROL_BUTTON_IMAGE",                   w = 44,  h = 44,  edge = "right", gap = 24,  bottom = 87 },
            { id = "formations", sprite = "SHOW_GROUP_FORMATIONS_BUTTON_IMAGE", w = 44, h = 44, edge = "right", gap = 24,  bottom = 150 },
            { id = "timeSlow", art = "timeSlow",  w = 18,  h = 24,  edge = "left",  gap = 228, bottom = 10 },
            { id = "timeSpeed", art = "timeSpeed", w = 18,  h = 24,  edge = "left",  gap = 268, bottom = 10 },
            { id = "playPause", art = "playPause", w = 38,  h = 38,  edge = "left",  gap = 238, bottom = 56 },
            { gauge = "time", art = "hourglass", w = 38,  h = 38,  edge = "left",  gap = 238, bottom = 127 },
            { art = "zoomOut",   w = 22,  h = 22,  edge = "left",  gap = 61,  bottom = 218, placeholder = true },
            { art = "zoomIn",    w = 22,  h = 22,  edge = "left",  gap = 22,  bottom = 218, placeholder = true },
            { gauge = "power", art = "powerBar",  w = 73,  h = 11,  edge = "left",  gap = 127, bottom = 241 },
        ]

        formationW = 44, formationH = 44, formationGap = 4,
        formationEdgeGap = 96, formationBottom = 200,

        speedTextGap = 248, speedTextBottom = 118,
        speedSliderGap = 236, speedSliderBottom = 236,
        speedSliderW = 444, speedSliderH = 20,
        speedGrabW = 20,

        minimal = {
            panels = [
                { art = "miniLeft",   x = 308, y = 0, w = 128, h = 52 },
                { art = "miniMiddle", x = 436, y = 0, w = 153, h = 49 },
                { art = "miniRight",  x = 589, y = 0, w = 127, h = 52 },
                { art = "miniFrame",  x = 796, y = 0, w = 228, h = 200 },
            ],

            buttons = [
                { id = "halt", cmd = ::Enum.UnitCommand.halt, sprite = "HALT_BUTTON_IMAGE_SELECTED",                x = 325, y = 1,   w = 35, h = 35 },
                { id = "withdraw", cmd = ::Enum.UnitCommand.withdraw, sprite = "WITHDRAW_BUTTON_IMAGE_SELECTED",            x = 363, y = 1,   w = 35, h = 35 },
                { id = "group", cmd = ::Enum.UnitCommand.group, sprite = "GROUP_BUTTON_IMAGE",                        x = 402, y = 3,   w = 32, h = 32 },
                { id = "guard", cmd = ::Enum.UnitCommand.guard, sprite = "GUARD_BUTTON_IMAGE",                        x = 438, y = 1,   w = 35, h = 35 },
                { id = "skirmish", cmd = ::Enum.UnitCommand.skirmish, sprite = "SKIRMISH_BUTTON_IMAGE",                     x = 476, y = 1,   w = 35, h = 35 },
                { id = "run", cmd = ::Enum.UnitCommand.run, sprite = "WALK_BUTTON_IMAGE",                         x = 513, y = 1,   w = 35, h = 35 },
                { id = "closeFormation", cmd = ::Enum.UnitCommand.closeFormation, sprite = "FORMATION_TIGHTNESS_BUTTON_IMAGE_SELECTED", x = 552, y = 1,   w = 35, h = 35 },
                { id = "groupAi", cmd = ::Enum.UnitCommand.group, sprite = "AI_CONTROL_BUTTON_IMAGE",                   x = 591, y = 3,   w = 32, h = 32 },
                { id = "fireAtWill", cmd = ::Enum.UnitCommand.fireAtWill, sprite = "AUTOFIRE_BUTTON_IMAGE",                     x = 626, y = 1,   w = 35, h = 35 },
                { id = "specialAbility", cmd = ::Enum.UnitCommand.specialAbility, sprite = "NO_SPECIAL_ABILITY_BUTTON_IMAGE",           x = 665, y = 1,   w = 35, h = 35 },
                { art = "zoomOut",   x = 825, y = 5,   w = 25, h = 28, placeholder = true },
                { art = "zoomIn",    x = 802, y = 5,   w = 25, h = 28, placeholder = true },
                { gauge = "time", art = "hourglass", x = 807, y = 41,  w = 39, h = 39 },
                { id = "timeSlow", art = "timeSlow",  x = 808, y = 115, w = 17, h = 26 },
                { id = "timeSpeed", art = "timeSpeed", x = 829, y = 115, w = 17, h = 26 },
                { id = "playPause", art = "playPause", x = 808, y = 147, w = 38, h = 39 },
                { gauge = "power", art = "powerBar",  x = 900, y = 177, w = 73, h = 11 },
            ],

            formationX = [367, 411, 445, 479, 513, 547, 581, 624],
            formationY = 45, formationW = 33, formationH = 35,

            speedTextX = 817, speedTextY = 91,
            speedSliderX = 900, speedSliderY = 192, speedSliderW = 90, speedSliderH = 20,
            speedGrabW = 12,
            speedFontSize = 11,

            // [radar-below] The radar column with its controls in two rows under the map (856..1024
            // x 0..168): play, slower, faster, the rate and the hourglass; then the strength bar and
            // the speed slider. Same 1024x768 units as above.
            radarBelow = {
                frame = { x = 850, y = 0, w = 174, h = 226 },
                slots = {
                    playPause = { x = 857, y = 195, w = 26, h = 26 },
                    timeSlow  = { x = 887, y = 195, w = 17, h = 26 },
                    timeSpeed = { x = 906, y = 195, w = 17, h = 26 },
                    powerBar  = { x = 952, y = 203, w = 40, h = 10 },
                    hourglass = { x = 996, y = 195, w = 26, h = 26 },
                    zoomIn    = { x = 860, y = 4, w = 16, h = 18 },
                    zoomOut   = { x = 878, y = 4, w = 16, h = 18 },
                },
                // the slider row spans the map; speedNudge puts - / + at its two ends
                speed = { sliderX = 856, sliderY = 172, sliderW = 168, sliderH = 18,
                          textX = 927, textY = 201 },
            },
        },
    }

    style = {
        leftImage      = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/L-bottomUI.png",
        rightImage     = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/R-bottomUI.png",
        midImage       = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M-bottomUI.png",
        cardsImage     = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/unitcardsUI.png",
        overflowLeft   = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/L-overflow.png",
        overflowRight  = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/R-overflow.png",
        radialImage    = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_radialbutton.png",
        portraitImage  = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_charbutton.png",
        hoopImage      = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_hoopoverlay.png",
        groupImage     = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_groupbutton.png",
        timeSlowImage  = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_timeslow.png",
        timeSpeedImage = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_timespeed.png",
        playPauseImage = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_playbutton.png",
        hourglassImage = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_hourglass.png",
        zoomInImage    = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_zoomin.png",
        zoomOutImage   = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_zoomout.png",
        powerBarImage  = "data/ui_hd/M2ex layout proj/M2ex layout proj/M2ex_UI_mock_images/M2EX_powerbar.png",
        imageFilter    = 2,   // [hud-restyle] smooth scaling for the enlarged button art (was 0, blocky)
        showOverflow   = true,

        // ---------------------------------------------------------------------------------------
        // [hud-restyle] The panels behind the buttons and around the radar.
        //   "gilded" - drawn in the campaign tooltips' style (hud_pane.nut): one bronze plate with a
        //              gold double frame per part of the HUD, in place of the stretched panel art.
        //   "native" - the game's (or the mod's) own panel art, stretched as before.
        //   "auto"   - gilded on the minimal HUD, the mod's own art on the full HUD (the default)
        // Falls back to "native" when hud_pane.nut's helpers are missing.
        chrome         = "auto",
        chromePad      = 5,       // 1080p units the plate reaches past what it holds
        chromeGap      = 2,       // ...and the gap between the button row and the formation row

        // [mini-layout] Where the MINIMAL HUD's command bar, radar and radar controls sit, and the
        // radar's own size, are set in hud_pane.nut's look (battleMiniBar, battleMiniRadar,
        // battleRadarControls, battleRadarScale). This is only the fallback without it.
        miniRadarControls = "below",

        // [hud-restyle] Our own button art, OPTIONAL and one button at a time. For each button the
        // HUD looks for <id>.png (and <id>_on.png for its lit state) in hdButtonFolders; a button
        // with no file keeps the game's or the mod's sprite, with all its selected / disabled art,
        // exactly as before - so a mod's reskinned buttons still show unless you drop a file in.
        // Formations: formation_1.png .. formation_8.png, in the engine's button order.
        // ids: halt withdraw guard skirmish fireAtWill run closeFormation group groupAi formations
        //      timeSlow timeSpeed playPause (specialAbility and flashUnits always use the game's art)
        // true: on both HUDs; "minimal": on the minimal HUD and the compact full HUD (hud_pane.nut's
        // battleFullScale), while M2EX's own full layout keeps the mod's art (the default); false: never.
        hdButtons       = "minimal",
        hdButtonFolders = ["data/ui_hd/battle/", "data/ui_hd/"],
        hdDisabledTint  = 115,               // our art has no dead state: it is dimmed instead
        hdLitFrame      = [255, 214, 120],   // a lit button with no _on file gets a gold frame
        // The minimal HUD scales width and height apart (screen / 1024 and / 768), so on a wide
        // screen every slot is wider than tall and round art goes oval. true: our art is drawn
        // square, centred in its slot. The game's / mod's sprites keep their slots as before.
        hdKeepAspect    = true,
        hdHoverGlow     = 36,   // how much a hovered button of ours brightens (additive, 0-255)
        showButtons    = true,
        showPlaceholders = false,   // the bottom-right cluster is white stand-in art, not the real sprites
        disabledTint     = 110,     // wash for a dead button the engine ships no dead art for
        hoverLighten     = 12,      // how much a hovered button brightens
        pressDarken      = 20,      // how much a held button darkens
        pressOffset      = 1,       // px a held button sinks
        hoverAlpha       = 205,     // alpha a hovered button fades to
        pressAlpha       = 150,
        // The engine's own time ladder, fastest rung last.
        speedSteps       = [0.0, 0.5, 1.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0],
        flamingSiegeAs   = 90,      // a siege engine's flaming shot uses its own art, keyed off this stand-in ordinal
        showFormations   = false,
        showTooltips     = true,
        showSpeed        = true,
        speedStepFine    = 0.1,
        // [speed-nudge] - / + buttons at the ends of the speed slider (restyle on). Each click moves
        // the rate by speedNudgeStep; held down, it keeps stepping.
        speedNudge       = true,
        speedNudgeStep   = 0.5,   // what the slider moves in, against the button ladder's rungs
        speedCapBefore   = 1.0,   // nothing runs faster than this until the fighting starts
        speedInk         = [255, 245, 139],
        speedFontSize    = 14,
        maxStrikes       = 8,

        // The game's own slider art: a track, two end buttons and the handle, off the shared page.
        speedTrackSprite  = "SLIDER_HORIZ",
        speedLeftSprite   = "SLIDER_LEFT",
        speedRightSprite  = "SLIDER_RIGHT",
        speedHandleSprite = "SLIDER_HANDLE",

        miniLeftSprite   = "MINI_UI_LEFT",
        miniMiddleSprite = "MINI_UI_MIDDLE",
        miniRightSprite  = "MINI_UI_RIGHT",
        miniFrameSprite  = "MINI_UI_MAP_FRAME",

        // battle.txt keys for the two gauges' readouts.
        timeKeys     = { none = "BMT_NO_TIME_LIMIT", hour = "BMT_1_HOUR_REMAINING",
                         hours = "BMT_TIME_REMAINING_HOURS", minute = "BMT_1_MIN_REMAINING",
                         minutes = "BMT_TIME_REMAINING_MINS" },
        strengthKeys = { allies = "BMT_PERCENTAGE_ALLIES_KILLED",
                         enemies = "BMT_PERCENTAGE_ENEMIES_KILLED" },

        // battle.txt keys in Enum.CombatStatus order, 0 not-in-combat .. 7 being wiped out.
        combatKeys = ["", "BMT_COM_WIN_BIG", "BMT_COM_WIN", "BMT_COM_WIN_SLIGHT", "BMT_COM_EVEN",
                      "BMT_COM_LOSE_SLIGHT", "BMT_COM_LOSE", "BMT_COM_LOSE_BIG"],

        // The eight group formations, in the engine's own button order.
        formationSprites = ["GROUP_FORMATION_BUTTON_IMAGE_SINGLE", "GROUP_FORMATION_BUTTON_IMAGE_SORTED_SINGLE",
                            "GROUP_FORMATION_BUTTON_IMAGE_DOUBLE", "GROUP_FORMATION_BUTTON_IMAGE_SORTED_DOUBLE",
                            "GROUP_FORMATION_BUTTON_IMAGE_4", "GROUP_FORMATION_BUTTON_IMAGE_5",
                            "GROUP_FORMATION_BUTTON_IMAGE_6", "GROUP_FORMATION_BUTTON_IMAGE_COLUMN"],

        // Each toggle's selected art, so a lit button swaps picture rather than only tint.
        selectedSprites = { guard = "GUARD_BUTTON_IMAGE_SELECTED",
                            skirmish = "SKIRMISH_BUTTON_IMAGE_SELECTED",
                            fireAtWill = "AUTOFIRE_BUTTON_IMAGE_SELECTED",
                            closeFormation = "FORMATION_TIGHTNESS_BUTTON_IMAGE",
                            run = "RUN_BUTTON_IMAGE",
                            formations = "SHOW_GROUP_FORMATIONS_BUTTON_IMAGE_SELECTED",
                            group = "GROUP_BUTTON_IMAGE_SELECTED",
                            groupAi = "AI_CONTROL_BUTTON_IMAGE_SELECTED" },

        // The artist-drawn dead state for each button.
        disabledSprites = { halt = "HALT_BUTTON_IMAGE_DISABLED",
                            withdraw = "WITHDRAW_BUTTON_IMAGE_DISABLED",
                            guard = "GUARD_BUTTON_IMAGE_DISABLED",
                            skirmish = "SKIRMISH_BUTTON_IMAGE_DISABLED",
                            fireAtWill = "AUTOFIRE_BUTTON_IMAGE_DISABLED",
                            run = "RUN_BUTTON_IMAGE_DISABLED",
                            closeFormation = "FORMATION_TIGHTNESS_BUTTON_IMAGE_DISABLED",
                            group = "GROUP_BUTTON_IMAGE_DISABLED",
                            groupAi = "AI_CONTROL_BUTTON_IMAGE_DISABLED" },

        // battle.txt keys, not text: off is the tooltip while the state is not set, on while it is.
        tooltips = { halt = { off = ["BMT_HALT"] },
                     withdraw = { off = ["BMT_WITHDRAW"] },
                     guard = { off = ["BMT_TOGGLE_DEFEND_ON"], on = ["BMT_TOGGLE_DEFEND_OFF"] },
                     skirmish = { off = ["BMT_TOGGLE_SKIRMISH_ON"], on = ["BMT_TOGGLE_SKIRMISH_OFF"] },
                     fireAtWill = { off = ["BMT_TOGGLE_FIRE_ON"], on = ["BMT_TOGGLE_FIRE_OFF"] },
                     run = { off = ["BMT_RUN"], on = ["BMT_WALK"] },
                     closeFormation = { off = ["BMT_TOGGLE_FORMATION_TIGHT"],
                                        on = ["BMT_TOGGLE_FORMATION_LOOSE"] },
                     group = { off = ["BMT_GROUP"], on = ["BMT_UNGROUP"] },
                     groupAi = { off = ["BMT_ENABLE_AI_GROUPING"], on = ["BMT_DISABLE_AI_GROUPING"] },
                     formations = { off = ["BMT_SHOW_GROUP_FORMATIONS"],
                                    on = ["BMT_HIDE_GROUP_FORMATIONS"] },
                     playPause = { off = ["BMT_PAUSE"], on = ["BMT_NEW_PLAY", "BMT_PAUSE"] },
                     timeSpeed = { off = ["BMT_FASTER", "BMT_DOUBLE"] },
                     timeSlow = { off = ["BMT_SLOWER"] },   // Rome ships no slower key at all
                     flashUnits = { off = ["BMT_FLASH_UNITS"] },
                     specialAbility = { off = ["BMT_NO_SPECIAL_ABILITY"] } },
        formationTooltip = "BMT_GROUP_FORMATION_",   // the eight are keyed by position, 1-based

        // battle.txt keys, off the same ability ordinal the art is keyed by.
        abilityTooltips = {
            [::Enum.SpecialAbility.testudo] = "BMT_TURTLE",
            [::Enum.SpecialAbility.phalanx] = "BMT_PHALANX",
            [::Enum.SpecialAbility.wedge] = "BMT_WEDGE_SPECIAL",
            [::Enum.SpecialAbility.dropEngines] = "BMT_DROP_SIEGE_EQUIPMENT",
            [::Enum.SpecialAbility.flamingAmmo] = "BMT_FLAMING_AMMO_SPECIAL",
            [::Enum.SpecialAbility.warcry] = "BMT_WARCRY_SPECIAL",
            [::Enum.SpecialAbility.chant] = "BMT_CHANT_SPECIAL",
            [::Enum.SpecialAbility.curse] = "BMT_CURSE_SPECIAL",
            [::Enum.SpecialAbility.beserk] = "BMT_BERSERK_SPECIAL",
            [::Enum.SpecialAbility.rally] = "BMT_RALLY_SPECIAL",
            [::Enum.SpecialAbility.killElephants] = "BMT_KILL_ELEPHANTS_SPECIAL",
            [::Enum.SpecialAbility.cantabrianCircle] = "BMT_CANTABRIAN_CIRCLE_SPECIAL",
            [::Enum.SpecialAbility.shieldWall] = "BMT_SHIELD_WALL_SPECIAL",
            [::Enum.SpecialAbility.stealth] = "BMT_STEALTH_SPECIAL",
            [::Enum.SpecialAbility.feignedRout] = "BMT_FEIGNED_ROUT_SPECIAL",
            [::Enum.SpecialAbility.schiltrom] = "BMT_SCHILTROM",
        },

        factionSymbolPath = "data/ui/faction_symbols/",   // loose art, keyed by the faction's internal name

        abilitySprites = {
            [::Enum.SpecialAbility.testudo] = ["SPECIAL_FORMATION_BUTTON_IMAGE", "SPECIAL_FORMATION_BUTTON_IMAGE_SELECTED"],
            [::Enum.SpecialAbility.phalanx] = ["SPECIAL_FORMATION_PHALANX_BUTTON_IMAGE", "SPECIAL_FORMATION_PHALANX_BUTTON_IMAGE_SELECTED"],
            [::Enum.SpecialAbility.wedge] = ["SPECIAL_FORMATION_WEDGE_BUTTON", "SPECIAL_FORMATION_WEDGE_BUTTON_SELECTED"],
            [::Enum.SpecialAbility.dropEngines] = ["DROP_EQUIPMENT_BUTTON_IMAGE", "DROP_EQUIPMENT_BUTTON_IMAGE_INACTIVE"],
            [::Enum.SpecialAbility.flamingAmmo] = ["SPECIAL_FORMATION_FLAMING_ARROW_BUTTON_IMAGE", "SPECIAL_FORMATION_FLAMING_ARROW_BUTTON_IMAGE_SELECTED"],
            [90] = ["SPECIAL_FORMATION_FLAMING_SHOT_BUTTON_IMAGE", "SPECIAL_FORMATION_FLAMING_SHOT_BUTTON_IMAGE_SELECTED"],
            [::Enum.SpecialAbility.warcry] = ["WARCRY_BUTTON_IMAGE_INACTIVE", "SPECIAL_FORMATION_WARCRY_BUTTON_IMAGE"],
            [::Enum.SpecialAbility.chant] = ["SPECIAL_FORMATION_DRUIDIC_CHANT_BUTTON_IMAGE", "SPECIAL_FORMATION_DRUIDIC_CHANT_BUTTON_IMAGE_SELECTED"],
            [::Enum.SpecialAbility.curse] = ["SPECIAL_FORMATION_SCREECHING_WOMEN_BUTTON_IMAGE", "SPECIAL_FORMATION_SCREECHING_WOMEN_BUTTON_IMAGE_SELECTED"],
            [::Enum.SpecialAbility.beserk] = ["AI_CONTROL_BUTTON_IMAGE", "AI_CONTROL_BUTTON_IMAGE"],
            [::Enum.SpecialAbility.rally] = ["RALLY_BUTTON_IMAGE_INACTIVE", "SPECIAL_FORMATION_RALLY_BUTTON_IMAGE"],
            [::Enum.SpecialAbility.killElephants] = ["KILL_ELEPHANTS_BUTTON_IMAGE_INACTIVE", "SPECIAL_FORMATION_KILL_ELEPHANTS_BUTTON_IMAGE"],
            [::Enum.SpecialAbility.cantabrianCircle] = ["SPECIAL_FORMATION_CANTABRIAN_CIRCLE_BUTTON_IMAGE", "SPECIAL_FORMATION_CANTABRIAN_CIRCLE_BUTTON_IMAGE_SELECTED"],
            [::Enum.SpecialAbility.shieldWall] = ["SHIELD_WALL_BUTTON_IMAGE", "SHIELD_WALL_BUTTON_IMAGE_SELECTED"],
            [::Enum.SpecialAbility.stealth] = ["AI_CONTROL_BUTTON_IMAGE", "AI_CONTROL_BUTTON_IMAGE"],
            [::Enum.SpecialAbility.feignedRout] = ["AI_CONTROL_BUTTON_IMAGE", "AI_CONTROL_BUTTON_IMAGE"],
            [::Enum.SpecialAbility.schiltrom] = ["SCHILTROM_BUTTON_IMAGE", "SCHILTROM_BUTTON_IMAGE_SELECTED"],

            // A hero ability's art is keyed by its descr_hero_abilities name; vanilla defines none.
        },
    }

    feature     = ::Enum.HdFeature.battleHud
    art         = null
    selection   = null
    buttonRects = null
    abilityArt  = null
    selectedArt = null
    disabledArt = null
    formationRects = null
    timeFull    = -1
    lastSpeed   = 1.0
    speedSlider = null
    symbolFor   = -1
    pieces      = null
    layout      = null
    minimalUi   = false
    formationsInline = false
    speedRect   = null
    speedTextAt = null
    nudgeRects  = null   // [speed-nudge] the - / + squares beside the speed slider, or null
    nudgeHeld   = 0.0    // [speed-nudge] how long one has been held (repeats after a moment)
    chromeRects = null   // [hud-restyle] one plate per HUD part: { group, x, y, w, h }
    hdArt       = null   // [hud-restyle] file name -> texture, or null when there is no such file
    pendingTip  = null   // [hd-tips] the hovered control's tooltip (text or entries), drawn after the HUD
    state       = { verified = false, down = false, strikes = 0 }

    function open() {
        this.minimalUi = !::options.isNormalHud()

        local scale = this.openPane(false, { paneWidth = true, paneHeight = true })
        local virt = ::UI.virtualScale()
        local vx = virt[0]
        local vy = virt[1]

        this.px = {
            leftW = (this.metrics.leftW * scale).tointeger(),
            leftH = (this.metrics.leftH * scale).tointeger(),
            rightW = (this.metrics.rightW * scale).tointeger(),
            rightH = (this.metrics.rightH * scale).tointeger(),
            midW = (this.metrics.midW * scale).tointeger(),
            midH = (this.metrics.midH * scale).tointeger(),
            cardsW = (this.metrics.cardsW * scale).tointeger(),
            cardsH = (this.metrics.cardsH * scale).tointeger(),
            overflowW = (this.metrics.overflowW * scale).tointeger(),
            overflowH = (this.metrics.overflowH * scale).tointeger(),
            speedTextGap = (this.metrics.speedTextGap * scale).tointeger(),
            speedTextBottom = (this.metrics.speedTextBottom * scale).tointeger(),
            speedSliderGap = (this.metrics.speedSliderGap * scale).tointeger(),
            speedSliderBottom = (this.metrics.speedSliderBottom * scale).tointeger(),
            speedSliderW = (this.metrics.speedSliderW * scale).tointeger(),
            speedSliderH = (this.metrics.speedSliderH * scale).tointeger(),
            speedGrabW = (this.metrics.speedGrabW * scale).tointeger(),
            speedFontSize = (this.style.speedFontSize * scale).tointeger(),
        }

        this.symbolFor = -1

        this.art = { left = ::UI.loadTexture(this.style.leftImage),
                     right = ::UI.loadTexture(this.style.rightImage),
                     mid = ::UI.loadTexture(this.style.midImage),
                     cards = ::UI.loadTexture(this.style.cardsImage),
                     overflowLeft = ::UI.loadTexture(this.style.overflowLeft),
                     overflowRight = ::UI.loadTexture(this.style.overflowRight),
                     radial = ::UI.loadTexture(this.style.radialImage),
                     portrait = ::UI.loadTexture(this.style.portraitImage),
                     hoop = ::UI.loadTexture(this.style.hoopImage),
                     group = ::UI.loadTexture(this.style.groupImage),
                     timeSlow = ::UI.loadTexture(this.style.timeSlowImage),
                     timeSpeed = ::UI.loadTexture(this.style.timeSpeedImage),
                     playPause = ::UI.loadTexture(this.style.playPauseImage),
                     hourglass = ::UI.loadTexture(this.style.hourglassImage),
                     zoomIn = ::UI.loadTexture(this.style.zoomInImage),
                     zoomOut = ::UI.loadTexture(this.style.zoomOutImage),
                     powerBar = ::UI.loadTexture(this.style.powerBarImage),
                     miniLeft = ::UI.loadSprite(this.style.miniLeftSprite, ::UI.PAGE_SHARED),
                     miniMiddle = ::UI.loadSprite(this.style.miniMiddleSprite, ::UI.PAGE_SHARED),
                     miniRight = ::UI.loadSprite(this.style.miniRightSprite, ::UI.PAGE_SHARED),
                     miniFrame = ::UI.loadSprite(this.style.miniFrameSprite, ::UI.PAGE_SHARED) }

        this.selectedArt = {}
        foreach (id, name in this.style.selectedSprites) {
            this.selectedArt[id] <- ::UI.loadSprite(name, ::UI.PAGE_BATTLE)
        }
        this.disabledArt = {}
        foreach (id, name in this.style.disabledSprites) {
            this.disabledArt[id] <- ::UI.loadSprite(name, ::UI.PAGE_BATTLE)
        }

        this.abilityArt = {}
        foreach (ability, pair in this.style.abilitySprites) {
            this.abilityArt[ability] <- [::UI.loadSprite(pair[0], ::UI.PAGE_BATTLE),
                                         ::UI.loadSprite(pair[1], ::UI.PAGE_BATTLE)]
        }

        local mini = this.metrics.minimal
        this.formationsInline = this.minimalUi
        this.formationRects = []
        for (local i = 0; i < this.style.formationSprites.len(); i++) {
            local r = null
            if (this.minimalUi) {
                // [hud-scale] through hud_pane.nut's minimal layout (vx / vy when that is absent)
                r = this.miniRect(mini.formationX[i], mini.formationY, mini.formationW, mini.formationH, "centre", vx, vy)
            } else {
                local w = (this.metrics.formationW * scale).tointeger()
                local h = (this.metrics.formationH * scale).tointeger()
                local gap = (this.metrics.formationEdgeGap * scale).tointeger()
                local step = w + (this.metrics.formationGap * scale).tointeger()
                r = { w = w, h = h,
                      x = (this.pane.x + this.pane.w - gap - w - i * step).tointeger(),
                      y = (this.pane.y + this.pane.h
                           - (this.metrics.formationBottom * scale).tointeger() - h).tointeger() }
            }
            r.index <- i
            r.image <- ::UI.loadSprite(this.style.formationSprites[i], ::UI.PAGE_BATTLE)
            r.dead <- ::UI.loadSprite(this.style.formationSprites[i] + "_DISABLED", ::UI.PAGE_BATTLE)
            this.formationRects.append(r)
        }

        this.pieces = []
        this.buttonRects = []
        if (this.minimalUi) {
            this.layout = mini.buttons
            // [radar-below] the radar column's controls in a row beneath the map instead of beside it
            local want = "look" in ::EX && "battleRadarControls" in ::EX.look ? ::EX.look.battleRadarControls
                       : this.style.miniRadarControls
            local below = want == "below" && (!("restyled" in ::EX) || ::EX.restyled())
            local rb = mini.radarBelow
            foreach (p in mini.panels) {
                local q = below && p.art == "miniFrame" ? rb.frame : p
                local at = this.miniRect(q.x, q.y, q.w, q.h, p.art == "miniFrame" ? "right" : "centre", vx, vy)
                this.pieces.append({ image = this.art[p.art],
                                     group = p.art == "miniFrame" ? "radar" : "buttons",
                                     x = at.x, y = at.y, w = at.w, h = at.h })
            }
            foreach (b in mini.buttons) {
                local art = ("sprite" in b) ? ::UI.loadSprite(b.sprite, ::UI.PAGE_BATTLE) : this.art[b.art]
                local q = below && "art" in b && b.art in rb.slots ? rb.slots[b.art] : b
                local at = this.miniRect(q.x, q.y, q.w, q.h, b.x >= 796 ? "right" : "centre", vx, vy)   // [hud-scale]
                this.buttonRects.append({ image = art, placeholder = ("placeholder" in b),
                                          isTex = !("sprite" in b),   // [hud-restyle] a loose image file
                                          gauge = ("gauge" in b) ? b.gauge : null,
                                          id = ("id" in b) ? b.id : null, cmd = ("cmd" in b) ? b.cmd : null,
                                          w = at.w, h = at.h,
                                          group = b.x >= 796 ? "radar" : "buttons",
                                          x = at.x, y = at.y })
            }
            // [hud-scale] the slider, the readout and their sizes follow the same layout
            local sp = below ? rb.speed : { sliderX = mini.speedSliderX, sliderY = mini.speedSliderY,
                                            sliderW = mini.speedSliderW, sliderH = mini.speedSliderH,
                                            textX = mini.speedTextX, textY = mini.speedTextY }
            this.speedRect = this.miniRect(sp.sliderX, sp.sliderY, sp.sliderW, sp.sliderH, "right", vx, vy)
            local textAt = this.miniRect(sp.textX, sp.textY, 1, mini.speedFontSize, "right", vx, vy)
            this.speedTextAt = { x = textAt.x, y = textAt.y }
            this.px.speedFontSize = textAt.h
            this.px.speedGrabW = this.miniRect(0, 0, mini.speedGrabW, 1, "right", vx, vy).w
        } else if (this.fullCompact()) {
            this.openFullCompact()
        } else {
            this.layout = this.metrics.buttons
            local bottom = this.pane.y + this.pane.h
            local midX = this.pane.x + (this.pane.w - this.px.midW) / 2
            if (this.style.showOverflow && this.pane.w < ::UI.screenSize()[0]) {
                local wingY = bottom - this.px.overflowH
                this.pieces.append({ image = this.art.overflowLeft, group = "radar", x = this.pane.x - this.px.overflowW,
                                     y = wingY, w = this.px.overflowW, h = this.px.overflowH })
                this.pieces.append({ image = this.art.overflowRight, group = "buttons", x = this.pane.x + this.pane.w,
                                     y = wingY, w = this.px.overflowW, h = this.px.overflowH })
            }
            this.pieces.append({ image = this.art.left, group = "radar", x = this.pane.x, y = bottom - this.px.leftH,
                                 w = this.px.leftW, h = this.px.leftH })
            this.pieces.append({ image = this.art.right, group = "buttons", x = this.pane.x + this.pane.w - this.px.rightW,
                                 y = bottom - this.px.rightH, w = this.px.rightW, h = this.px.rightH })
            this.pieces.append({ image = this.art.mid, group = "cards", x = midX, y = bottom - this.px.midH,
                                 w = this.px.midW, h = this.px.midH })
            this.pieces.append({ image = this.art.cards, group = "cards", x = midX, y = bottom - this.px.cardsH,
                                 w = this.px.cardsW, h = this.px.cardsH })

            foreach (b in this.metrics.buttons) {
                local w = (b.w * scale).tointeger()
                local h = (b.h * scale).tointeger()
                local gap = (b.gap * scale).tointeger()
                local x = b.edge == "left" ? this.pane.x + gap : this.pane.x + this.pane.w - gap - w
                local y = this.pane.y + this.pane.h - (b.bottom * scale).tointeger() - h
                local art = ("sprite" in b) ? ::UI.loadSprite(b.sprite, ::UI.PAGE_BATTLE) : this.art[b.art]
                this.buttonRects.append({ image = art, placeholder = ("placeholder" in b),
                                          isTex = !("sprite" in b),   // [hud-restyle] a loose image file
                                          gauge = ("gauge" in b) ? b.gauge : null,
                                          id = ("id" in b) ? b.id : null, cmd = ("cmd" in b) ? b.cmd : null,
                                          group = b.edge == "left" ? "radar" : "buttons",
                                          w = w, h = h, x = x.tointeger(), y = y.tointeger() })
            }
            this.speedRect = { x = this.pane.x + this.px.speedSliderGap,
                               y = this.pane.y + this.pane.h - this.px.speedSliderBottom
                                   - this.px.speedSliderH,
                               w = this.px.speedSliderW, h = this.px.speedSliderH }
            this.speedTextAt = { x = this.pane.x + this.px.speedTextGap,
                                 y = this.pane.y + this.pane.h - this.px.speedTextBottom }
        }

        // [speed-nudge] - and + at the slider's two ends, each a square as tall as the slider, so a
        // small slider can still be set exactly; the slider keeps what is left between them
        this.nudgeRects = null
        if (this.style.speedNudge && (!("restyled" in ::EX) || ::EX.restyled()) && this.speedRect != null) {
            local r = this.speedRect
            local b = r.h
            local gap = (2 * (::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0) + 0.5).tointeger()
            if (r.w > b * 4) {
                this.nudgeRects = [{ x = r.x, y = r.y, w = b, h = b, dir = -1, id = "##nudgeSlow" },
                                   { x = r.x + r.w - b, y = r.y, w = b, h = b, dir = 1, id = "##nudgeFast" }]
                this.speedRect = { x = r.x + b + gap, y = r.y, w = r.w - (b + gap) * 2, h = r.h }
            }
        }
        if (this.speedSlider != null) {
            ::UI.setWidgetStyle(this.speedSlider, ::UI.Metric.grabMinSize, this.px.speedGrabW)
            // the slider's own end arrows give way to the - / + buttons
            ::UI.setWidgetStyle(this.speedSlider, ::UI.Cap.sliderArrows, this.nudgeRects != null ? 0 : 1)
        }

        this.timeFull = -1
        this.openHdArt()      // [hud-restyle]
        this.openChrome()
    }

    // [hud-full] The full HUD in its compact restyle (hud_pane.nut's look.battleFullScale).
    function fullCompact() {
        return !this.minimalUi && "fullLayout" in ::EX && ::EX.fullScale() != null
    }

    // [hud-full] The compact full HUD: the radar block bottom-left (hud_pane.nut's ::EX.fullLayout),
    // the command ring bottom-right at M2EX's own arrangement scaled by k, the formation row above
    // the ring. The two blocks are chrome pieces, so they claim the pointer as the panels did.
    function openFullCompact() {
        local L = ::EX.fullLayout()
        local k = L.k
        local P = function (v) { return (v * k + 0.5).tointeger() }
        local screen = ::UI.screenSize()
        local W = screen[0]
        local H = screen[1]
        this.layout = this.metrics.buttons

        // the radar block's own controls, by art name / gauge
        local leftSlots = { timeSlow = L.timeSlow, timeSpeed = L.timeSpeed, playPause = L.playPause,
                            hourglass = L.time, powerBar = L.power, zoomOut = L.zoomOut, zoomIn = L.zoomIn }
        local rx0 = W
        local ry0 = H
        foreach (b in this.metrics.buttons) {
            local at = null
            if (b.edge == "left") {
                local slot = "art" in b && b.art in leftSlots ? leftSlots[b.art] : null
                at = slot != null ? { x = slot.x, y = slot.y, w = slot.w, h = slot.h }
                                  : { x = L.radar.x, y = L.radar.y, w = P(b.w), h = P(b.h) }
            } else {
                at = { w = P(b.w), h = P(b.h) }
                at.x <- W - P(b.gap) - at.w
                at.y <- H - P(b.bottom) - at.h
                if (at.x < rx0) rx0 = at.x
                if (at.y < ry0) ry0 = at.y
            }
            local art = ("sprite" in b) ? ::UI.loadSprite(b.sprite, ::UI.PAGE_BATTLE) : this.art[b.art]
            this.buttonRects.append({ image = art, placeholder = ("placeholder" in b),
                                      isTex = !("sprite" in b),
                                      gauge = ("gauge" in b) ? b.gauge : null,
                                      id = ("id" in b) ? b.id : null, cmd = ("cmd" in b) ? b.cmd : null,
                                      group = b.edge == "left" ? "radar" : "buttons",
                                      w = at.w, h = at.h, x = at.x, y = at.y })
        }

        // the group formations, a row above the ring, right-aligned with it
        local fw = P(this.metrics.formationW)
        local fh = P(this.metrics.formationH)
        local step = fw + P(this.metrics.formationGap)
        foreach (f in this.formationRects) {
            f.w = fw
            f.h = fh
            f.x = W - P(this.metrics.formationEdgeGap) - fw - f.index * step
            f.y = H - P(this.metrics.formationBottom) - fh
        }

        // the two blocks, flush with their corners; drawn as plates, and claiming the pointer
        local claim = this.art.miniMiddle
        this.pieces.append({ image = claim, claimOnly = true, group = "radar",
                             x = L.left.x, y = L.left.y, w = L.left.w, h = L.left.h })
        local pad = P(this.style.chromePad * 2)
        this.pieces.append({ image = claim, claimOnly = true, group = "buttons",
                             x = rx0 - pad, y = ry0 - pad, w = W - rx0 + pad, h = H - ry0 + pad })

        this.speedRect = { x = L.slider.x, y = L.slider.y, w = L.slider.w, h = L.slider.h }
        this.speedTextAt = { x = L.speedText.x, y = L.speedText.y }
        this.px.speedFontSize = L.speedText.size
        this.px.speedGrabW = P(16)
        // what battle_tooltips.nut clears when it docks above the HUD
        this.px.leftH = L.left.h
        this.px.rightH = H - ry0 + pad
    }

    // [hud-restyle] The optional button art: a texture for each file that exists, null otherwise.
    function hdFile(name) {
        if (!(name in this.hdArt)) {
            local found = null
            foreach (dir in this.style.hdButtonFolders) {
                local tex = null
                try { tex = ::UI.loadTexture(dir + name + ".png") } catch (e) { tex = null }
                if (tex != null && tex.img != 0) {
                    found = tex
                    break
                }
            }
            this.hdArt[name] <- found
        }
        return this.hdArt[name]
    }

    // [hud-scale] A minimal-HUD rect in the game's 1024x768 units, on this screen: hud_pane.nut's
    // scaled, anchored layout when it has one, else the game's own stretch (vx / vy).
    function miniRect(x, y, w, h, anchor, vx, vy) {
        // [mini-layout] hud_pane.nut's layout: the scale, the command bar's corner and the radar
        // column's place and size are all worked out there, so radar.nut lands in the same spot
        if ("miniRect" in ::EX) return ::EX.miniRect(x, y, w, h, anchor)
        return { x = (x * vx).tointeger(), y = (y * vy).tointeger(),
                 w = (w * vx).tointeger(), h = (h * vy).tointeger() }
    }

    // [hud-restyle] Whether our button art and plates apply on the HUD in use.
    function hdActive() {
        if ("restyled" in ::EX && !::EX.restyled()) return false   // [restyle] the mod's own art
        local v = this.style.hdButtons
        // [hud-full] "minimal" covers the compact full HUD too: the same buttons on both
        return v == true || (v == "minimal" && (this.minimalUi || this.fullCompact()))
    }

    function chromeGilded() {
        if ("restyled" in ::EX && !::EX.restyled()) return false   // [restyle] the mod's own panels
        local v = this.style.chrome
        return (v == "gilded" || (v == "auto" && (this.minimalUi || this.fullCompact())))
               && "tipBack" in ::EX && "tipFrame" in ::EX && this.chromeRects != null
    }

    // [hud-restyle] A button. imageButton draws the game's sprites but NOTHING for a loose image
    // file (loadTexture) - which is why M2EX's own play / speed buttons never showed on the
    // minimal HUD, and why our art vanished whenever a button was live. A file is drawn with
    // UI.image instead, its clicks read with UI.hitRect, and hover / press drawn by hand.
    // Returns what imageButton returns: clicked, clickedRight, hovered, held.
    function pressButton(id, art, isTex, at, tint, live) {
        if (!live) {
            ::UI.image(art.img, at.w, at.h, at.x, at.y, tint, tint, tint, 255)
            return { clicked = false, clickedRight = false, hovered = false, held = false }
        }
        if (!isTex) {
            return ::UI.imageButton(id, art, at.w, at.h, at.x, at.y, tint, tint, tint, 255)
        }
        local hit = ::UI.hitRect(at.x, at.y, at.w, at.h)
        local held = "held" in hit && hit.held
        local hovered = "hovered" in hit && hit.hovered
        local t = held ? tint * 80 / 100 : tint
        local sink = held ? this.style.pressOffset : 0
        local glow = hovered && !held ? this.style.hdHoverGlow : 0
        if (glow > 0) {
            ::UI.pushStyle({ [::UI.Colour.imageGlow] = [glow, glow, glow, 255] })
        }
        ::UI.image(art.img, at.w, at.h, at.x, at.y + sink, t, t, t, 255)
        if (glow > 0) {
            ::UI.popStyle()
        }
        return hit
    }

    function openHdArt() {
        if (this.hdArt == null) this.hdArt = {}
        local count = 0
        foreach (r in this.buttonRects) {
            r.hd <- null
            r.hdOn <- null
            if (!this.hdActive() || r.id == null || r.gauge != null
                || r.id == "specialAbility" || r.id == "flashUnits") {
                continue
            }
            r.hd = this.hdFile(r.id)
            r.hdOn = r.hd != null ? this.hdFile(r.id + "_on") : null
            if (r.hd != null) count++
        }
        // [hud-full] M2EX's full HUD draws the play / speed buttons from loose mock-up files that
        // most installs lack, so they drew nothing; any such button takes our art instead.
        foreach (r in this.buttonRects) {
            if (r.hd != null || r.id == null || !r.isTex || r.gauge != null) continue
            if (r.image != null && r.image.img != 0) continue
            r.hd = this.hdFile(r.id)
            r.hdOn = r.hd != null ? this.hdFile(r.id + "_on") : null
            if (r.hd != null) count++
        }
        foreach (f in this.formationRects) {
            f.hd <- this.hdActive() ? this.hdFile("formation_" + (f.index + 1)) : null
            if (f.hd != null) count++
        }
    }

    // [hud-restyle] One plate per HUD part - the union of that part's panel pieces, grown by
    // chromePad; on the minimal HUD the button plate also takes in the formation row under it.
    function openChrome() {
        this.chromeRects = []
        local scale = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
        local pad = (this.style.chromePad * scale + 0.5).tointeger()
        local unions = {}
        local order = []
        foreach (p in this.pieces) {
            if (!(p.group in unions)) {
                unions[p.group] <- { x0 = p.x, y0 = p.y, x1 = p.x + p.w, y1 = p.y + p.h }
                order.append(p.group)
            } else {
                local u = unions[p.group]
                if (p.x < u.x0) u.x0 = p.x
                if (p.y < u.y0) u.y0 = p.y
                if (p.x + p.w > u.x1) u.x1 = p.x + p.w
                if (p.y + p.h > u.y1) u.y1 = p.y + p.h
            }
        }
        if (this.minimalUi && "buttons" in unions) {
            local u = unions.buttons
            foreach (f in this.formationRects) {
                if (f.y + f.h > u.y1) u.y1 = f.y + f.h + (this.style.chromeGap * scale).tointeger()
            }
        }
        local screen = ::UI.screenSize()
        foreach (group in order) {
            local u = unions[group]
            local x0 = u.x0 - pad
            local y0 = u.y0 - pad
            local x1 = u.x1 + pad
            local y1 = u.y1 + pad
            // a plate that meets a screen edge runs off it, so no frame line shows along the edge
            // (within the plate's own pad of an edge counts too - the bar moved into a corner sits
            // a few px in, and a frame line a hair from the edge only looks misplaced)
            if (u.y0 <= pad + 1) y0 = -pad
            if (u.x0 <= pad + 1) x0 = -pad
            if (u.x1 >= screen[0] - pad - 1) x1 = screen[0] + pad
            if (u.y1 >= screen[1] - pad - 1) y1 = screen[1] + pad
            this.chromeRects.append({ group = group, x = x0, y = y0, w = x1 - x0, h = y1 - y0 })
        }
    }

    // [hud-restyle] The gilded plates, from their own canvas made just before this module's, so
    // they sit under everything this module draws - the speed slider included.
    function renderPlates() {
        if (this.state.down || !this.chromeGilded()) {
            return
        }
        if (!this.visible(::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded)) {
            return
        }
        if ((!::options.isNormalHud()) != this.minimalUi) {
            return   // the HUD is switching; the main canvas re-opens this frame
        }
        local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
        foreach (c in this.chromeRects) {
            if (this.groupHidden(c.group)) {
                continue
            }
            ::EX.tipBack(c.x, c.y, c.w, c.h, k)
            ::EX.tipFrame(c.x, c.y, c.w, c.h, k)
        }
    }

    // [hud-restyle] Where our (square) art sits in a slot: the slot itself, or the largest square
    // centred in it when hdKeepAspect is on.
    function hdSlot(r) {
        if (!this.style.hdKeepAspect || r.w == r.h) {
            return { x = r.x, y = r.y, w = r.w, h = r.h }
        }
        local side = r.w < r.h ? r.w : r.h
        return { x = r.x + (r.w - side) / 2, y = r.y + (r.h - side) / 2, w = side, h = side }
    }

    // [hud-restyle] The panels: gilded plates, or the game's / mod's own art.
    function renderChrome() {
        local gilded = this.chromeGilded()
        if (!gilded) {
            foreach (i, p in this.pieces) {
                if (this.groupHidden(p.group)) {
                    continue
                }
                if (p.image != null && p.image.img != 0) {
                    local a = "claimOnly" in p && p.claimOnly ? 0 : 255   // [hud-full] a block, not art
                    ::UI.imageButton("##piece" + i, p.image, p.w, p.h, p.x, p.y, 255, 255, 255, a)
                }
            }
            return
        }
        // [hud-restyle] The plates themselves are drawn by the chrome canvas (renderPlates), BEFORE
        // this one: what a canvas draws paints over its own child widgets, so plates drawn here
        // covered the speed slider, a widget of this canvas.
        // The panels still claim the pointer exactly as before - the same art, in the same place,
        // through the same imageButton - only drawn fully transparent, so the buttons on top of
        // them behave as they always did.
        foreach (i, p in this.pieces) {
            if (this.groupHidden(p.group)) {
                continue
            }
            if (p.image != null && p.image.img != 0) {
                ::UI.imageButton("##piece" + i, p.image, p.w, p.h, p.x, p.y, 255, 255, 255, 0)
            }
        }
    }

    // Live when the selection would accept the order, spelled as the native hud spells each rule.
    function commandLive(id, cmd) {
        // These act on the battle, not the selection, so they are live whenever one is running.
        if (id == "playPause" || id == "timeSpeed" || id == "timeSlow" || id == "flashUnits"
            || id == "formations") {
            return true
        }

        local cards = ::ui.cardManager()
        if (this.selection.len() == 0) {
            return false
        }

        // AI-link follows the GROUPS in the selection, not the units, and is barred in multiplayer.
        if (id == "groupAi") {
            return cards.selectedGroupCount > 0 && !::battle.isNetworkBattle()
        }

        // Every selected unit must share one ability, or already be in it, before the button offers it.
        if (id == "specialAbility") {
            local ability = -1
            local allActive = true
            for (local i = 0; i < this.selection.len(); i++) {
                local unit = this.selection[i]
                if (unit == null) return false
                if (!unit.specialAbilityActive) allActive = false
                if (ability < 0) ability = unit.specialAbility
                else if (ability != unit.specialAbility) ability = -2
            }
            if (ability == ::Enum.SpecialAbility.none || (ability == -2 && !allActive)) {
                return false
            }
        }

        if (cmd == null) {
            return false
        }
        for (local i = 0; i < this.selection.len(); i++) {
            local unit = this.selection[i]
            if (unit != null && unit.orderAllowed(cmd)) {
                return true
            }
        }
        return false
    }

    // Lit when every unit that CAN hold the state has it; a unit that cannot hold it is not a vote against.
    function commandLit(id) {
        // These two describe the battle and the hud, not the selection, so they answer first.
        if (id == "playPause") {
            return ::battle.current().localSpeed <= 0.0
        }
        if (id == "formations") {
            return this.style.showFormations
        }

        local cards = ::ui.cardManager()
        if (this.selection.len() == 0) {
            return false
        }

        if (id == "groupAi") {
            if (cards.selectedGroupCount == 0) {
                return false
            }
            for (local i = 0; i < cards.selectedGroupCount; i++) {
                local group = cards.selectedGroup(i)
                if (group == null || !group.isAutomated) return false
            }
            return true
        }

        // The group button reads as 'clicking will ungroup' only when the whole selection is one group.
        if (id == "group") {
            if (cards.selectedGroupCount != 1) {
                return false
            }
            for (local i = 0; i < this.selection.len(); i++) {
                local unit = this.selection[i]
                if (unit == null || unit.group == null) return false
            }
            return true
        }

        local capable = 0
        for (local i = 0; i < this.selection.len(); i++) {
            local unit = this.selection[i]
            if (unit == null) return false

            if (id == "guard") {
                if (!unit.orderAllowed(::Enum.UnitCommand.guard)) continue
                if (!unit.hasBattleProperty(::Enum.UnitBattleProperty.guardMode)) return false
            } else if (id == "skirmish") {
                if (!unit.orderAllowed(::Enum.UnitCommand.skirmish)) continue
                if (!unit.hasBattleProperty(::Enum.UnitBattleProperty.skirmish)) return false
            } else if (id == "fireAtWill") {
                if (!unit.orderAllowed(::Enum.UnitCommand.fireAtWill)) continue
                if (!unit.hasBattleProperty(::Enum.UnitBattleProperty.fireAtWill)) return false
            } else if (id == "run") {
                if (!unit.orderAllowed(::Enum.UnitCommand.run)) continue
                if (!unit.isRunning) return false
            } else if (id == "closeFormation") {
                if (!unit.isCloseFormation) return false
            } else if (id == "specialAbility") {
                if (!unit.specialAbilityActive) return false
            } else {
                return false
            }
            capable++
        }
        return capable > 0
    }

    // The native button orders, each acting on the whole selection; a toggle flips the units' current state.
    function runCommand(id) {
        this.readSelection()
        local sel = ::battle.selection
        local lit = this.commandLit(id)
        if (id == "halt") {
            sel.halt()
        } else if (id == "withdraw") {
            sel.withdraw()
        } else if (id == "guard") {
            sel.setMeleeState(::Enum.UnitBattleProperty.guardMode, !lit)
        } else if (id == "skirmish") {
            sel.setMeleeState(::Enum.UnitBattleProperty.skirmish, !lit)
        } else if (id == "fireAtWill") {
            sel.setMeleeState(::Enum.UnitBattleProperty.fireAtWill, !lit)
        } else if (id == "run") {
            sel.setRunning(!lit)
        } else if (id == "closeFormation") {
            sel.setCloseFormation(!lit)
        } else if (id == "specialAbility") {
            sel.useSpecialAbility(!lit)
        } else if (id == "group") {
            sel.group()
        } else if (id == "groupAi") {
            sel.setGroupAi(!lit)
        } else if (id == "playPause") {
            local rate = ::battle.current().localSpeed
            if (rate > 0.0) { this.lastSpeed = rate }
            ::battle.current().localSpeed = rate > 0.0 ? 0.0 : this.lastSpeed
        } else if (id == "timeSpeed") {
            this.stepSpeed(1)
        } else if (id == "timeSlow") {
            this.stepSpeed(-1)
        } else if (id == "flashUnits") {
            ::battle.current().flashUnitMarkers()
        } else if (id == "formations") {
            this.style.showFormations = !this.style.showFormations
        }
    }

    // One rung along the engine's ladder, clamped to the ends.
    function stepSpeed(direction) {
        local steps = this.style.speedSteps
        local rate = ::battle.current().localSpeed
        if (direction > 0) {
            for (local i = 0; i < steps.len(); i++) {
                if (steps[i] > rate) { ::battle.current().localSpeed = steps[i]; return }
            }
            ::battle.current().localSpeed = steps[steps.len() - 1]
            return
        }
        for (local i = steps.len() - 1; i >= 0; i--) {
            if (steps[i] < rate) {
                if (steps[i] > 0.0) { this.lastSpeed = steps[i] }
                ::battle.current().localSpeed = steps[i]
                return
            }
        }
    }

    // The local faction's symbol - the same loose file the native players-army button opens, not a page sprite.
    function refreshFactionSymbol() {
        local b = ::battle.current()
        local army = b != null && b.playerArmyCount > 0 ? b.playerArmy(0) : null
        local mine = army != null ? army.faction : null
        if (mine == null || mine.id == this.symbolFor) {
            return
        }
        local symbol = ::UI.loadTexture(this.style.factionSymbolPath + mine.name + ".tga")
        if (symbol == null || symbol.img == 0) {
            return
        }
        this.symbolFor = mine.id
        this.art.portrait = symbol
        foreach (r in this.buttonRects) {
            if (r.id == "flashUnits") { r.image = symbol }
        }
    }

    // How long the battle has left, in the game's own hours-then-minutes wording.
    function timeText(seconds) {
        if (seconds < 0) {
            return ::scripting.textTable(this.style.timeKeys.none, ::Enum.StringTable.battle)
        }
        local minutes = seconds / 60
        if (minutes >= 60) {
            local hours = minutes / 60
            local key = hours == 1 ? this.style.timeKeys.hour : this.style.timeKeys.hours
            return ::scripting.textTable(key, ::Enum.StringTable.battle) + " " + hours.tostring()
        }
        local key = minutes == 1 ? this.style.timeKeys.minute : this.style.timeKeys.minutes
        return ::scripting.textTable(key, ::Enum.StringTable.battle) + " " + minutes.tostring()
    }

    // What the strength bar says: how much of each side is down, and who is winning.
    function strengthText(side) {
        local s = ::battle.sideStrength(side.index)
        local ours = s.deployed > 0 ? 100 - (s.remaining * 100 / s.deployed) : 0
        local theirs = s.enemyDeployed > 0 ? 100 - (s.enemyRemaining * 100 / s.enemyDeployed) : 0
        local text = ::scripting.textTable(this.style.strengthKeys.allies, ::Enum.StringTable.battle)
                   + " " + ours.tostring() + "%   -   "
                   + ::scripting.textTable(this.style.strengthKeys.enemies, ::Enum.StringTable.battle)
                   + " " + theirs.tostring() + "%"
        local state = side.combatStatus
        if (state > 0 && state < this.style.combatKeys.len()) {
            local status = ::scripting.textTable(this.style.combatKeys[state], ::Enum.StringTable.battle)
            if (status != "") { text += "\n" + status }
        }
        return text
    }

    // The speed slider is a real widget over the strip, one rung of the ladder per step.
    function buildSpeedSlider() {
        if (this.speedSlider != null) {
            return
        }
        local self = this
        local top = this.style.speedSteps[this.style.speedSteps.len() - 1]
        this.speedSlider = ::UI.slider("###battleSpeed", 0.0, top, this.style.speedStepFine,
                                       this.px.speedSliderW, this.px.speedSliderH)
        ::UI.placeAbsolute(this.speedSlider)
        // The chrome is built after this, and a canvas hands the mouse to its last-created child
        // first, so without this the left panel eats the slider's first rungs.
        ::UI.raise(this.speedSlider)

        // Per-widget styling for this slider alone: no border, no read-out.
        ::UI.setWidgetStyle(this.speedSlider, {
            [::UI.Cap.autoScaleAbsolute] = 0,
            [::UI.Cap.sliderArrows] = this.nudgeRects != null ? 0 : 1,   // [speed-nudge]
            [::UI.Cap.sliderFill] = 0,
            [::UI.Metric.grabMinSize] = this.px.speedGrabW,
            [::UI.Metric.borderFrame] = 0,
            [::UI.Colour.border] = [0, 0, 0, 0],
            [::UI.Colour.text] = [0, 0, 0, 0] })

        // Each part is applied on its own, and one that failed to load is skipped.
        foreach (part in [[::UI.Surface.sliderTrack, this.style.speedTrackSprite],
                          [::UI.Surface.sliderArrowStart, this.style.speedLeftSprite],
                          [::UI.Surface.sliderArrowEnd, this.style.speedRightSprite],
                          [::UI.Surface.sliderGrabber, this.style.speedHandleSprite]]) {
            local art = ::UI.loadSprite(part[1], ::UI.PAGE_SHARED)
            if (art != null && art.img != 0) {
                ::UI.setWidgetStyle(this.speedSlider, part[0], art)
            }
        }
        ::UI.sliderChange(this.speedSlider, function (value) {
            local rate = value < 0.0 ? 0.0 : (value > top ? top : value)
            if (rate > 0.0) { self.lastSpeed = rate }
            ::battle.current().localSpeed = rate
        })
    }

    // The slider follows the battle's own rate, and is capped to a walk until the fighting starts.
    function trackSpeed() {
        local b = ::battle.current()
        local top = this.style.speedSteps[this.style.speedSteps.len() - 1]
        if (b.phase < ::Enum.BattleState.conflict) {
            top = this.style.speedCapBefore
        }
        ::UI.sliderRange(this.speedSlider, 0.0, top)

        // The grab owns the value while it is being dragged - the battle reports last tick.
        if (::UI.state.drag(this.speedSlider)) return

        ::UI.sliderValue(this.speedSlider, b.localSpeed > top ? top : b.localSpeed)
    }

    // [speed-nudge] The - / + squares: a dark box in the gold frame with the sign in it. A click
    // steps the rate; held, it steps again every tenth of a second after a short wait.
    function renderNudge() {
        local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
        local look = "look" in ::EX ? ::EX.look : null
        local gold = look != null && "tipTitle" in look ? look.tipTitle : [255, 214, 120]
        local edge = look != null && "tipEdge" in look ? look.tipEdge : [201, 164, 88, 255]
        local face = look != null && "titleFace" in look && look.titleFace != null ? look.titleFace : ::EX.fonts.body
        local anyHeld = false
        foreach (n in this.nudgeRects) {
            local hit = ::UI.hitRect(n.x, n.y, n.w, n.h)
            local held = "held" in hit && hit.held
            ::UI.drawRect(n.x, n.y, n.w, n.h, 0, 0, 0, held ? 210 : (hit.hovered ? 185 : 150))
            ::UI.drawRect(n.x, n.y, n.w, 1, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(n.x, n.y + n.h - 1, n.w, 1, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(n.x, n.y, 1, n.h, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(n.x + n.w - 1, n.y, 1, n.h, edge[0], edge[1], edge[2], 255)
            // the sign drawn as bars, so it sits dead centre at any size
            local t = (n.h / 9) > 1 ? n.h / 9 : 1
            local len = n.w / 2
            local cx = n.x + n.w / 2
            local cy = n.y + n.h / 2
            local ink = hit.hovered ? gold : [236, 226, 200]
            ::UI.drawRect(cx - len / 2, cy - t / 2, len, t, ink[0], ink[1], ink[2], 255)
            if (n.dir > 0) ::UI.drawRect(cx - t / 2, cy - len / 2, t, len, ink[0], ink[1], ink[2], 255)
            if (hit.clicked) {
                this.nudgeSpeed(n.dir)
                this.nudgeHeld = 0.0
            } else if (held) {
                anyHeld = true
                local before = this.nudgeHeld
                this.nudgeHeld += ::UI.time.delta()
                if (this.nudgeHeld > 0.45 && (before * 10).tointeger() != (this.nudgeHeld * 10).tointeger()) {
                    this.nudgeSpeed(n.dir)
                }
            }
            if (this.style.showTooltips) {
                local key = n.dir > 0 ? ["BMT_FASTER", "BMT_DOUBLE"] : ["BMT_SLOWER"]
                local text = ""
                foreach (kk in key) {
                    if (text == "") text = ::scripting.textTable(kk, ::Enum.StringTable.battle)
                }
                if (text != "") this.raiseTip(n.x, n.y, n.w, n.h, text)
            }
        }
        if (!anyHeld) this.nudgeHeld = 0.0
    }

    // [speed-nudge] One step of the rate, within the same cap the slider has.
    function nudgeSpeed(dir) {
        local b = ::battle.current()
        local top = this.style.speedSteps[this.style.speedSteps.len() - 1]
        if (b.phase < ::Enum.BattleState.conflict) top = this.style.speedCapBefore
        local v = b.localSpeed + dir * this.style.speedNudgeStep
        v = (v * 10 + (v >= 0 ? 0.5 : -0.5)).tointeger() / 10.0
        if (v < 0.0) v = 0.0
        if (v > top) v = top
        if (v > 0.0) this.lastSpeed = v
        b.localSpeed = v
    }

    // The rate the player is running at, in the game's own x notation.
    function speedText() {
        return format("%.1f", ::battle.current().localSpeed)
    }

    // A card riding the cursor owns the release, so no button takes it as a click.
    function dragging() {
        return "battleCards" in ::EX && ::EX.battleCards.dragLive()
    }

    // [hd-tips] A control's tooltip in the campaign tooltips' styled box (hud_pane.nut) rather than
    // the engine's own in the game's legacy face. The engine tooltip is still raised, invisibly, so
    // hovering behaves as before; the visible box is drawn once the HUD is done. `tip` is plain text,
    // or a list of tooltip entries for ::EX.drawTipRich. Without hud_pane.nut: the engine's, as before.
    function raiseTip(x, y, w, h, tip) {
        local plain = typeof(tip) == "array" && "tipSectionsToText" in ::EX ? ::EX.tipSectionsToText(tip) : tip
        if (typeof(plain) != "string" || plain == "") {
            return
        }
        if (!("drawTip" in ::EX) || !("ghostStyle" in ::EX) || ("restyled" in ::EX && !::EX.restyled())) {   // [restyle]
            ::UI.tooltipAt(x, y, w, h)
            ::UI.tooltip(0, plain)
            return
        }
        ::UI.pushStyle(::EX.ghostStyle())
        ::UI.tooltipAt(x, y, w, h)
        ::UI.tooltip(0, plain)
        ::UI.popStyle()
        local m = ::UI.mouse.pos()
        if (m[0] >= x && m[0] < x + w && m[1] >= y && m[1] < y + h) {
            this.pendingTip = tip
        }
    }

    // [hd-tips] Draws the tooltip raiseTip kept, if any.
    function drawPendingTip() {
        local tip = this.pendingTip
        this.pendingTip = null
        if (tip == null || this.dragging()) {
            return
        }
        try {
            if (typeof(tip) == "array" && "drawTipRich" in ::EX && "tooltipRich" in ::EX.look && ::EX.look.tooltipRich) {
                ::EX.drawTipRich(tip)
            } else if ("drawTip" in ::EX) {
                local text = typeof(tip) == "array" ? ::EX.tipSectionsToText(tip) : tip
                ::EX.drawTip(text, [0, 0, 0, 160], [255, 245, 139, 255], [255, 245, 139, 255])
            }
        }
        catch (e) {
            println("squi: [hd-tips] battle hud tooltip failed - " + e)
        }
    }

    // [hd-tips] The strength gauge as a tooltip entry: who is winning as the heading, then how much
    // of each side is down, each as a gold "Label:" and its figure.
    function strengthSections(side) {
        local s = ::battle.sideStrength(side.index)
        local ours = s.deployed > 0 ? 100 - (s.remaining * 100 / s.deployed) : 0
        local theirs = s.enemyDeployed > 0 ? 100 - (s.enemyRemaining * 100 / s.enemyDeployed) : 0
        local entry = { title = null, tag = null, lines = [] }
        local state = side.combatStatus
        if (state > 0 && state < this.style.combatKeys.len()) {
            local status = ::scripting.textTable(this.style.combatKeys[state], ::Enum.StringTable.battle)
            if (status != "") entry.title = status
        }
        foreach (pair in [[this.style.strengthKeys.allies, ours], [this.style.strengthKeys.enemies, theirs]]) {
            local label = ::scripting.textTable(pair[0], ::Enum.StringTable.battle)
            if (label == "") continue
            if (label[label.len() - 1] != ':') label += ":"
            entry.lines.append({ text = label + " " + pair[1].tostring() + "%", kind = "label" })
        }
        return entry.title != null || entry.lines.len() > 0 ? [entry] : []
    }

    // The button's own localised tooltip, in whichever state it is in; "" when no key resolves.
    function tooltipText(id, lit) {
        if (id == "specialAbility") {
            local selected = ::ui.cardManager().selectedUnitCount > 0
                           ? ::ui.cardManager().selectedUnit(0) : null
            local ability = selected != null ? selected.specialAbility : ::Enum.SpecialAbility.none
            if (ability in this.style.abilityTooltips) {
                local key = this.style.abilityTooltips[ability]
                local text = lit ? ::scripting.textTable(key + "_OFF", ::Enum.StringTable.battle) : ""
                return text != "" ? text : ::scripting.textTable(key, ::Enum.StringTable.battle)
            }
        }
        if (!(id in this.style.tooltips)) {
            return ""
        }
        local entry = this.style.tooltips[id]
        foreach (key in lit && ("on" in entry) ? entry.on : entry.off) {
            local text = ::scripting.textTable(key, ::Enum.StringTable.battle)
            if (text != "") {
                return text
            }
        }
        return ""
    }

    // Right-click on a state button means OFF, never on - the native buttons treat it that way.
    function forceOff(id) {
        local sel = ::battle.selection
        if (id == "guard") {
            sel.setMeleeState(::Enum.UnitBattleProperty.guardMode, false)
        } else if (id == "skirmish") {
            sel.setMeleeState(::Enum.UnitBattleProperty.skirmish, false)
        } else if (id == "fireAtWill") {
            sel.setMeleeState(::Enum.UnitBattleProperty.fireAtWill, false)
        } else if (id == "run") {
            sel.setRunning(false)
        } else if (id == "closeFormation") {
            sel.setCloseFormation(false)
        }
    }

    // The group formations, which act on the selected control GROUPS and draw no lit state.
    // [hud-toggles] True while the player has toggled that part of the HUD off.
    function groupHidden(group) {
        return group != null && "battleShortcuts" in ::EX && "isHidden" in ::EX.battleShortcuts
               && ::EX.battleShortcuts.isHidden(group)
    }

    function renderFormations() {
        local live = ::ui.cardManager().selectedGroupCount > 0
        local formations = ::battle.groupFormationCount()
        foreach (f in this.formationRects) {
            if (f.index >= formations) {
                continue
            }
            local art = live ? f.image : (f.dead != null && f.dead.img != 0 ? f.dead : f.image)
            local tint = 255
            if ("hd" in f && f.hd != null) {   // [hud-restyle] our art, dimmed when it cannot be used
                art = f.hd
                tint = live ? 255 : this.style.hdDisabledTint
            }
            if (art == null || art.img == 0) {
                continue
            }
            local ours = "hd" in f && f.hd != null
            local at = ours ? this.hdSlot(f) : f   // [hud-restyle] square
            local hit = this.pressButton("##form" + f.index, art, ours, at, tint, live)
            if (this.style.showTooltips) {
                local text = ::scripting.textTable(this.style.formationTooltip + (f.index + 1),
                                              ::Enum.StringTable.battle)
                if (text != "") {
                    this.raiseTip(f.x, f.y, f.w, f.h, text)   // [hd-tips]
                }
            }
            if (live && hit.clicked && !this.dragging()) {
                ::battle.selection.setGroupFormation(f.index)
            }
        }
    }

    // The selection every button and shortcut asks about, read once instead of once per question.
    function readSelection() {
        local cards = ::ui.cardManager()
        this.selection = []
        for (local i = 0; i < cards.selectedUnitCount; i++) {
            this.selection.append(cards.selectedUnit(i))
        }
    }

    function verify() {
        if (this.pane == null || this.px == null || this.art == null) {
            return false
        }
        foreach (key in ["speedSliderGap", "speedSliderBottom", "speedSliderW", "speedSliderH",
                         "speedGrabW", "speedTextGap", "speedTextBottom", "speedFontSize"]) {
            if (!(key in this.px)) {
                return false
            }
        }
        if (this.pieces == null || this.pieces.len() == 0) {
            return false
        }
        if (this.layout == null || this.buttonRects == null
            || this.buttonRects.len() != this.layout.len()) {
            return false
        }
        if (this.speedRect == null || this.speedTextAt == null) {
            return false
        }
        if (this.formationRects == null
            || this.formationRects.len() != this.style.formationSprites.len()) {
            return false
        }
        if (this.abilityArt == null || this.selectedArt == null || this.disabledArt == null) {
            return false
        }
        if (this.style.speedSteps.len() == 0) {
            return false
        }
        if (!("fonts" in ::EX) || !("body" in ::EX.fonts)) {
            return false
        }
        if (::ui.cardManager == null || ::battle.current == null) {
            return false
        }
        return ::scripting.textTable != null && ::options.failHdFeature != null
    }

    function render() {
        if (this.state.down) {
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
                this.readSelection()

                local minimal = !::options.isNormalHud()
                if (minimal != this.minimalUi) {
                    this.open()
                }

                local shown = this.visible(::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded)

                // The speed slider is a widget, not canvas content, so it is placed before the canvas bail.
                if (this.style.showSpeed) {
                    this.buildSpeedSlider()
                    local speedShown = shown && !this.groupHidden("radar")
                    ::UI.widgetVisible(this.speedSlider, speedShown)
                    if (speedShown) {
                        this.trackSpeed()
                        ::UI.widgetRect(this.speedSlider, this.speedRect.x, this.speedRect.y,
                                        this.speedRect.w, this.speedRect.h)
                    }
                }

                this.pendingTip = null   // [hd-tips]
                if (shown) {
                    this.refreshFactionSymbol()

                    // The panels are chrome: they claim the pointer so a click cannot fall through, and never react to it.
                    ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter,
                                     [::UI.Metric.hoverLighten] = 0,
                                     [::UI.Metric.pressDarken] = 0,
                                     [::UI.Metric.pressOffset] = 0 })
                    ::UI.pushHitMode(::UI.Hit.alpha)

                    this.renderChrome()   // [hud-restyle]
                    ::UI.popStyle()

                    if (this.style.showButtons) {
                        ::UI.pushStyle({ [::UI.Metric.imageFilter] = this.style.imageFilter,
                                         [::UI.Metric.hoverLighten] = this.style.hoverLighten,
                                         [::UI.Metric.pressDarken] = this.style.pressDarken,
                                         [::UI.Metric.pressOffset] = this.style.pressOffset })

                        local selected = ::ui.cardManager().selectedUnitCount > 0 ? ::ui.cardManager().selectedUnit(0) : null
                        foreach (ri, r in this.buttonRects) {
                            if (r.placeholder && !this.style.showPlaceholders) {
                                continue
                            }
                            if (this.groupHidden(r.group)) {
                                continue
                            }

                            // A gauge is a readout, not a control: it draws its own fill and never takes the click.
                            if (r.gauge == "time") {
                                local left = ::battle.current().timeRemaining
                                if (this.timeFull < left) this.timeFull = left
                                if (left >= 0 && this.timeFull > 0 && r.image != null && r.image.img != 0) {
                                    local sand = (r.h * left / this.timeFull).tointeger()
                                    ::UI.pushClip(r.x, r.y + r.h - sand, r.w, sand)
                                    ::UI.image(r.image.img, r.w, r.h, r.x, r.y)
                                    ::UI.popClip()
                                } else if (left >= 0 && this.timeFull > 0 && this.fullCompact()) {
                                    // [hud-full] no hourglass art: a slim gold sand column
                                    local bw = r.w / 4
                                    local bx = r.x + (r.w - bw) / 2
                                    local sand = (r.h * left / this.timeFull).tointeger()
                                    ::UI.drawRect(bx, r.y, bw, r.h, 0, 0, 0, 140)
                                    ::UI.drawRect(bx, r.y + r.h - sand, bw, sand, 214, 176, 96, 230)
                                }
                                if (this.style.showTooltips) {
                                    this.raiseTip(r.x, r.y, r.w, r.h, this.timeText(left))   // [hd-tips]
                                }
                                continue
                            }
                            if (r.gauge == "power") {
                                local side = ::battle.current().localSide
                                if (side != null && r.image != null && r.image.img != 0) {
                                    ::UI.pushClip(r.x, r.y, (r.w * side.relativeStrength).tointeger(), r.h)
                                    ::UI.image(r.image.img, r.w, r.h, r.x, r.y)
                                    ::UI.popClip()
                                } else if (side != null && this.fullCompact()) {
                                    // [hud-full] no power bar art: ours, green against the enemy's red
                                    local share = side.relativeStrength
                                    if (share < 0) share = 0
                                    if (share > 1) share = 1
                                    local mine = (r.w * share).tointeger()
                                    ::UI.drawRect(r.x - 1, r.y - 1, r.w + 2, r.h + 2, 0, 0, 0, 170)
                                    ::UI.drawRect(r.x, r.y, r.w, r.h, 170, 64, 50, 230)
                                    ::UI.drawRect(r.x, r.y, mine, r.h, 110, 180, 90, 240)
                                    ::UI.drawRect(r.x, r.y, r.w, 1, 255, 214, 120, 120)
                                }
                                if (this.style.showTooltips && side != null) {
                                    // [hd-tips] as entries, so the styled box can head it with the outlook
                                    local tip = "drawTipRich" in ::EX ? this.strengthSections(side) : this.strengthText(side)
                                    this.raiseTip(r.x, r.y, r.w, r.h, tip)
                                }
                                continue
                            }

                            // The special-ability button wears the selection's own ability, and draws nothing when it has none.
                            local art = r.image
                            if (r.id == "specialAbility") {
                                local lit = this.commandLit(r.id)

                                // A hero ability is named by descr_hero_abilities, so its art is keyed by that name.
                                local hero = selected != null && selected.general != null ? selected.general.heroAbility : ""
                                if (hero != "" && hero in this.abilityArt) {
                                    art = this.abilityArt[hero][lit ? 1 : 0]
                                } else {
                                    local ability = selected != null ? selected.specialAbility : ::Enum.SpecialAbility.none
                                    if (ability == ::Enum.SpecialAbility.flamingAmmo && selected.type != null
                                        && selected.type.category == ::Enum.UnitCategory.siege) {
                                        ability = this.style.flamingSiegeAs
                                    }
                                    if (!(ability in this.abilityArt)) {
                                        continue
                                    }
                                    art = this.abilityArt[ability][lit ? 1 : 0]
                                }
                            }
                            // [hud-restyle] our art, when this button has a file in ui_hd
                            local hd = "hd" in r && r.hd != null
                            if (hd) {
                                art = r.hd
                            }
                            if (art == null || art.img == 0) {
                                continue
                            }

                            local live = this.commandLive(r.id, r.cmd)
                            local lit = r.id != null && this.commandLit(r.id)
                            local tint = 255
                            if (hd) {
                                // No dead art of its own: dimmed. Lit: its _on file, or a gold frame.
                                if (lit && r.hdOn != null) art = r.hdOn
                                tint = live ? 255 : this.style.hdDisabledTint
                                if (lit && r.hdOn == null) {
                                    local g = this.style.hdLitFrame
                                    local t = (2 * ::UI.dpiScale() + 0.5).tointeger()
                                    local q = this.hdSlot(r)
                                    ::UI.drawRect(q.x - t, q.y - t, q.w + t * 2, t, g[0], g[1], g[2], 255)
                                    ::UI.drawRect(q.x - t, q.y + q.h, q.w + t * 2, t, g[0], g[1], g[2], 255)
                                    ::UI.drawRect(q.x - t, q.y, t, q.h, g[0], g[1], g[2], 255)
                                    ::UI.drawRect(q.x + q.w, q.y, t, q.h, g[0], g[1], g[2], 255)
                                }
                            } else {
                                if (lit && r.id in this.selectedArt && this.selectedArt[r.id].img != 0) {
                                    art = this.selectedArt[r.id]
                                }
                                // A dead button wears its own art and stops reacting.
                                local dead = !live && r.id != null && r.id in this.disabledArt ? this.disabledArt[r.id] : null
                                if (dead != null && dead.img != 0) {
                                    art = dead
                                }
                                tint = live || (dead != null && dead.img != 0) ? 255 : this.style.disabledTint
                            }

                            local at = hd ? this.hdSlot(r) : r   // [hud-restyle] our art stays square
                            local hit = this.pressButton("##cmd" + ri, art, hd || r.isTex, at, tint, live)
                            if (this.style.showTooltips && r.id != null) {
                                local text = this.tooltipText(r.id, lit)
                                if (text != "") {
                                    this.raiseTip(r.x, r.y, r.w, r.h, text)   // [hd-tips]
                                }
                            }
                            if (live && hit.clicked && !this.dragging() && r.id != null && !r.placeholder) {
                                this.runCommand(r.id)
                            }
                            // Right-click FORCES a state off rather than toggling it, as the native button does.
                            if (live && hit.clickedRight && !this.dragging() && lit && r.id != null) {
                                this.forceOff(r.id)
                            }
                        }

                        if ((this.style.showFormations || this.formationsInline) && !this.groupHidden("buttons")) {
                            this.renderFormations()
                        }

                        // The rate, above the pause button.
                        if (this.style.showSpeed && !this.groupHidden("radar")) {
                            local ink = this.style.speedInk
                            // [tip-rich] the rate in the SemiBold face, with the tooltips' text shadow
                            local face = "look" in ::EX && "titleFace" in ::EX.look && ::EX.look.titleFace != null
                                       ? ::EX.look.titleFace : ::EX.fonts.body
                            local shadow = "tipTextShadow" in ::EX
                            if (shadow) ::UI.pushStyle(::EX.tipTextShadow(::UI.dpiScale()))
                            ::UI.pushFont(face, false, this.px.speedFontSize)
                            ::UI.layoutAt(this.speedTextAt.x, this.speedTextAt.y)
                            ::UI.textColoured(this.speedText(), ink[0], ink[1], ink[2], 255)
                            ::UI.popFont()
                            if (shadow) ::UI.popStyle()
                        }
                        if (this.style.showSpeed && this.nudgeRects != null && !this.groupHidden("radar")) {
                            this.renderNudge()   // [speed-nudge]
                        }

                        ::UI.popStyle()
                    }
                    ::UI.popHitMode()
                    this.drawPendingTip()   // [hd-tips]
                }
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
            println("squi: battle hud STOOD DOWN - " + fault)
        }
    }
}

local battleHud = BattleHud()
battleHud.open()

// [hud-restyle] The plates' own canvas, made first so it draws first - under the HUD, its buttons
// and its speed slider.
local battleChromeCanvas = ::UI.canvas("##battle_hudchrome", 0, 0, 4, 4)
::UI.setWidgetStyle(battleChromeCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.setWidgetStyle(battleChromeCanvas, ::UI.Cap.autoScale, 0)
::UI.onDraw(battleChromeCanvas, function() {
    try { battleHud.renderPlates() } catch (e) { println("squi: [hud-restyle] battle plates failed - " + e) }
})
::UI.widgetUnderlay(battleChromeCanvas, true)

local battleHudCanvas = ::UI.canvas("##battle_hudcanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(battleHudCanvas, ::UI.Cap.autoScaleCanvas, 0)
// This pane's numbers are already physical px, so a widget hosted in it must not be scaled again.
::UI.setWidgetStyle(battleHudCanvas, ::UI.Cap.autoScale, 0)
::UI.onDraw(battleHudCanvas, function() { battleHud.render() })
::UI.widgetUnderlay(battleHudCanvas, true)

::UI.onResize(function(w, h) { battleHud.open() })

::EX.battleHud <- battleHud
