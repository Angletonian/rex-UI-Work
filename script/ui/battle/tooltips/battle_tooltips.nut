local math = require("math")
local format = require("string").format
// =====================================================================================
//  BATTLE UNIT CARD - YOUR SETTINGS
//  Change the numbers below, save, and restart the game. Mix them freely.
//
//    position   1 = static: the card sits in the corner (above the HUD)
//               2 = cursor: the card follows the mouse
//
//    trigger    1 = only while Space is held
//               2 = always, no key needed
//
//    shows      1 = the unit under the mouse (Mouse Over)
//               2 = your selected unit, hovering does nothing (Sticky)
//
//  Nothing to show (no unit hovered / selected) = no card.
//
//  IN BATTLE: press X for a settings menu (far left, above the unit cards) - these three and what the card shows, as
//  tick boxes, changed on the spot - and the size of the full and minimal battle HUDs, with
//  - / + (hud_pane.nut's battleFullScale / battleMinimalScale). The menu remembers your choices in
//  data/ui_hd/battle_card_settings.txt, and they win over the numbers here; use the
//  menu's "Reset to this file's settings" to go back to them.
//
//    menuKey    the key that opens the menu, by its UI.Key name, with "ctrl+", "shift+" or
//               "alt+" in front for a combination ("ctrl+f11", "shift+f9", "f9"). The script
//               only watches this key - the game still gets it - so pick one nothing uses.
//               Avoid F10 (Windows' own menu-bar key) and F12 (Steam's screenshot key).
//    menuShortcut  OR take over one of the game's own shortcut commands you never use: its
//               name as in descr_shortcuts.txt (e.g. "toggle_xxx"). The menu then opens on that
//               command's key, and the game does NOT act on it as well. "" = use menuKey.
//               (A command's key is changed in descr_shortcuts.txt - then delete
//               preferences/keys.dat so the game re-reads it.)
//    logKeys    1 = write every shortcut command the game knows, with its keys, to the
//               console once (to find a free key or command); 0 = don't
//    remember   1 = keep the menu's choices between games, 0 = this session only
// =====================================================================================
local UNIT_CARD = {
    position = 1,
    trigger  = 1,
    shows    = 1,
    menuKey  = "x",   // if the game also uses X in battle, unbind it in descr_shortcuts.txt
    menuShortcut = "",
    logKeys  = 0,
    remember = 1,
}
// =====================================================================================
// Everything below is the card itself - no need to edit it.
// =====================================================================================

local BattleTooltips = class {
    // Pixels at 1080p, scaled once by open().
    metrics = {
        hitPad      = 2,
        padX        = 6,
        padY        = 4,
        corner      = 0,
        borderWidth = 2,
        offsetX     = 24,
        offsetY     = 34,
        wrapWidth   = 300,     // [rich-tips] also the card's widest text; longer lines wrap inside it (was 260)

        // [rich-tips] The card's own layout, at 1080p; scaled by UI.dpiScale() when drawn.
        richPad       = 9,     // inner margin (was 7)
        richGap       = 5,     // space between an icon and its text, and between badges
        richRowGap    = 3,     // space between rows (was 2)
        richAccent    = 3,     // the faction-coloured strip down the left edge
        richLogo      = 20,    // faction logo in the header
        richIcon      = 12,    // status icons in front of a row
        richBadge     = 11,    // chevrons and upgrade badges in the header
        richBarHeight = 5,     // the strength bar
        richBarMinW   = 160,   // the card is never narrower than this with a strength bar
        richTitleSize = 17,    // [tip-rich] Constantine sets smaller than Montserrat (was 15 for Montserrat)
        richBodySize  = 12,
        richSmallSize = 11,
        richOffsetX   = 22,    // card position from the cursor (richAnchor = "cursor")
        richOffsetY   = 24,
        // [dock] With a docked card: distance from the screen edges it is docked to. 180 clears the
        // unit card strip along the bottom; with M2EX's full battle bar (255 tall) use about 272.
        richDockX     = 16,
        richDockY     = 180,
        // [dock] With the full battle HUD its left panel (radar and minimap) sits in the bottom-left
        // corner, so a card docked there is lifted to clear it: this gap above the panel.
        richDockHudGap = 12,
        // [dock] Docked bottom-left on the minimal HUD: the card sits this far above the unit card
        // strip's plate, with its left edge on the plate's (both run off the screen's left edge).
        richDockCardsGap = 6,
        // [panel] The docked card's look, at 1080p.
        richPanelW    = 340,   // docked card width, so it does not jump between units (0 = fit the text)
        richPortraitW = 48,    // the unit's card portrait, left of the name (64 x 88 art, same shape)
        richPortraitH = 66,
        richInlineLogo = 14,   // faction logo before the faction name, when the portrait takes its place
        richCapsSize  = 10,    // unit kind and meter labels, in capitals
        richPipW      = 10,    // one segment of the morale / stamina meters
        richPipH      = 5,
        richPipGap    = 2,
        richCorner    = 4,     // rounded corners (0 = square)
        richShadowOffset = 3,  // drop shadow under the card (0 = none)
    }

    style = {
        delayMs    = 0,                      // the rect follows the cursor, so any dwell restarts it forever
        background = [0, 0, 0, 100],
        ink        = [255, 255, 255, 255],
        borderNone = [255, 255, 255, 255],   // white where the hovered unit has no faction to colour it

        showCategory = true,
        showFaction = true,
        showAction  = true,
        showMorale  = true,
        showFatigue = true,
        showBuilding = true,
        showHint     = true,
        showKills    = true,
        showSupportArmy = true,

        // battle.txt keys in Enum.SupportOrder order: 0 aggressive, 1 shootout, 2 defensive.
        stanceKeys = ["BMT_AISA_AGGRESSIVE", "BMT_AISA_SHOOTOUT", "BMT_AISA_DEFENSIVE"],

        killsKey = "Kills:",

        damageKey = "BMT_DAMAGE",

        maxStrikes = 8,

        // ---------------------------------------------------------------------------------
        // [modes] Set from UNIT_CARD at the top of this file.
        cardPosition = 1,
        cardTrigger  = 1,
        cardShows    = 1,

        // [space-tips] Set from cardTrigger each frame; kept for the code that reads it.
        spaceOnly = true,
        // [space-tips] Which tooltip shows while Space is held:
        //   "hd"     - the HD box. The game's own tooltips are switched off while Space is
        //              held (the Show Tooltips option, through M2EX's Lua bridge) and back on
        //              when it is released. Clicks and orders are not touched.
        //   "native" - the game's own tooltip.
        //   "both"   - the HD card, with the game's own tooltip left on (what "hd" becomes when
        //              nothing can switch the game's tooltips off).
        spaceTip = "hd",
        // [space-tips] How the game's own tooltips are switched off while Space is held (the game
        // draws them on its floating unit cards, which nothing else in Squirrel can stop):
        //   1. a tooltip option M2EX offers Squirrel, if it ever offers one;
        //   2. with useEop, the game's Show Tooltips option through the EOP Lua interface - M2TWEOP's,
        //      or the one M2EX's own Lua runtime provides for mods with an eopData folder. Off while
        //      Space is held, back to how it was on release.
        // A mod without EOP / Lua simply fails the attempt once (logged) and carries on without it:
        // nothing else changes, the game's box may then show over those cards.
        useEop = true,
        // [mute-battle] true: the game's own tooltips are switched off for the whole battle, not only
        // while Space is held (back on when the battle ends, or with the Modded HUD unticked). Needs
        // the same switch as useEop; without it nothing changes.
        muteInBattle = false,   // the whole battle muted also blanks M2EX's unit pick - see [mute-engine]
        muteOnEngine = true,    // [mute-engine] the game's tooltips off only while an engine is under the cursor
        // [restyle] false: the battle HUD, radar, cards and unit tooltip drawn as the mod draws them.
        // Switched in battle from the X menu ("Restyled HUD").
        restyle = true,
        // [veil] true: keep the game's own tooltips hidden everywhere on the battlefield, not only
        // over what M2EX's pick names - so artillery, rams, ladders and towers never show the game's
        // box. Where we have nothing to say, the game's cursor hint shows in our box instead.
        veilAlways = true,
        // [hover-label] A label floating by the cursor over a unit on the field, shown alongside the
        // card (not with Position = Cursor, where the card is already at the cursor). What it shows is
        // set on its own - from a bare name to a full copy of the card - in hoverStyle below and in
        // the X menu's "Hover label" section.
        hoverTip    = false,
        hoverTrigger = 2,   // [menu] the Unit Tooltip: 2 = always, 1 = only while Space is held
        // [card-off] false: no unit card at all (the hover label, when on, is then the only tooltip;
        // the game's own stays hidden either way). X menu: "Tooltips shown".
        cardOn      = true,

        // [rich-tips] false: the old plain text box (::EX.drawTip), exactly as before.
        rich = true,
        richScale = 1.0,   // shrinks or grows the whole card at once (0.9 = 10% smaller)
        // "gilded": the campaign tooltips' own box from hud_pane.nut - bronze-to-black fade, gold
        //           double frame and corner brackets - keeping the faction strip, glow and symbol.
        //           Falls back to "flat" if hud_pane.nut's helpers are not loaded. [tip-rich]
        // "flat": dark translucent card with a faction-coloured edge.
        // "panel": the game's own framed panel art (the tileable frame from the shared page).
        richFrame = "gilded",
        richBackground = [16, 14, 10, 215],
        richTitleInk   = [255, 214, 120, 255],   // [tip-rich] gold unit name, as the campaign headings (was off-white 240,234,220)
        richSubInk     = [208, 196, 168, 255],   // [tip-rich] the campaign tooltips' description ink (was 200,192,170)
        richBodyInk    = [235, 230, 215, 255],
        richDimInk     = [160, 152, 135, 255],
        richBadInk     = [235, 95, 75, 255],     // routing, withdrawing, dying fast, exhausted, losing
        richGoodInk    = [125, 210, 110, 255],   // Kills: when the unit has killed more than it has lost
        richHintInk    = [150, 190, 230, 255],
        barGood  = [120, 190, 90, 255],
        barMid   = [230, 205, 60, 255],   // yellow
        barLow   = [200, 70, 50, 255],
        barTrack = [0, 0, 0, 150],
        barMidBelow = 0.66,   // below this share of the starting men the bar turns yellow
        barLowBelow = 0.33,   // ...and below this, red
        // Morale and fatigue colours. The game hands the script only the display wording, so each
        // battle.txt key below is looked up in the loaded language and its wording mapped to a tier.
        // That keeps the colours right whatever the text says (English, Russian, or renamed).
        // Only the first line of each wording is compared, so mods that add effect lines under it
        // ("...\n-10% to movement speed") still match. Where several keys share one wording
        // (e.g. High/Firm/Shaken all reading "Steady"), the states cannot be told apart, and that
        // wording takes the kind's sharedTier below instead of any one state's colour.
        fatigueKeys = [["BMT_FAT_FRESH", "fresh"],   ["BMT_FAT_WARMED_UP", "fresh"],
                       ["BMT_FAT_WINDED", "tired"],  ["BMT_FAT_TIRED", "tired"],
                       ["BMT_FAT_MOST_TIRED", "exhausted"], ["BMT_FAT_EXHAUSTED", "exhausted"]],
        moraleKeys  = [["BMT_MOR_BESERK", "heroic"],    ["BMT_MOR_IMPETUOUS", "eager"],
                       ["BMT_MOR_HIGH", "high"],        ["BMT_MOR_FIRM", "steady"],
                       ["BMT_MOR_SHAKEN", "shaken"],    ["BMT_MOR_WAVERING", "wavering"],
                       ["BMT_MOR_ROUTING", "broken"]],
        // Tier -> ink. null keeps the normal row colour.
        tierInk = { fresh = [125, 210, 110, 255],     // green: fresh and warmed up
                    tired = [230, 205, 60, 255],      // yellow, as the strength bar
                    exhausted = [235, 95, 75, 255],   // red
                    heroic = [255, 215, 90, 255],     // gold
                    eager = [125, 210, 110, 255],     // green
                    high = [125, 210, 110, 255],      // green
                    steady = null,
                    shaken = [230, 205, 60, 255],     // yellow
                    wavering = [235, 150, 55, 255],   // orange
                    broken = [235, 95, 75, 255] },
        sharedTier = { morale = "steady", fatigue = null },   // null: the first key listed wins
        // Fallback only, if the keys above cannot be read: fatigue text containing these words is red.
        exhaustedWords = ["exhausted"],
        richShadow = true,    // [tip-rich] on, as the campaign tooltips now draw theirs (was off)
        // true: the card takes the campaign tooltips' font and text size from hud_pane.nut (::EX.look:
        // face, tooltipFontSize x tooltipScale, tooltipLineGap), so both tooltips always match.
        // false: the card uses richTitleFont / richBodyFont and the rich*Size metrics instead.
        richFollowLook = false,
        richTitleRatio = 1.15,   // with richFollowLook: unit name size against the text size
        richSmallRatio = 0.85,   // with richFollowLook: detail lines against the text size
        richFadeSeconds = 0.12,   // 0 turns the fade-in off
        // Fonts, by their name in Core/fonts.nut (::EX.fonts): "body" and "title" are Verdana,
        // "petrock" is Kingthings Petrock. The game's own faces work too: "tnr" / "tnr_med"
        // (its Times New Roman, used by the name labels) and "verdana_sml".
        // Or give a font file: a bare name is looked for in fontFolder below
        // (richBodyFont = "EBGaramond-Regular.ttf"); a path with a folder is used as written.
        // null: real Verdana, loaded straight from fonts/verdana.ttf by this card (hud_pane.nut's
        // ::EX.look swaps "body"/"title" for another face, so the card no longer goes through them).
        // [montserrat] Each part of the card takes its own weight of one family:
        //   title  - unit name                        sub   - unit type under the name
        //   body   - the rows                         label - "Morale:" / "Kills:" in front of a value
        //   small  - dim detail lines ("-10% attack")
        // Any of sub / label / small set to null takes the body font (label null: no split).
        // The Roboto set, to go back: title "roboto.medium.ttf", body "roboto.regular.ttf", rest null.
        // [tip-rich] The unit name in Constantine, the settlement-name face the campaign tooltip
        // headings use; if it will not load or draw, richTitleFallback. (was "Montserrat-SemiBold.ttf")
        richTitleFont = "constantine.regular.ttf",
        richTitleFallback = "Montserrat-SemiBold.ttf",
        fontFolder    = "fonts/",           // relative to where M2EX looks for fonts/verdana.ttf
        richBodyFont  = "Montserrat-Regular.ttf",
        richSubFont   = "Montserrat-MediumItalic.ttf",
        richLabelFont = "Montserrat-SemiBold.ttf",
        richSmallFont = "Montserrat-Italic.ttf",
        richTitleCaps = false,   // true: the unit name in capitals ("MARCHIC BRAN")
        // [dock] Where the card is drawn: "cursor" follows the mouse as before; "bottomLeft",
        // "bottomRight", "topLeft" or "topRight" dock it to that corner (richDockX / richDockY).
        // A card docked to a bottom corner grows upward, so a taller card never runs into the HUD.
        richAnchor = "bottomLeft",
        // [panel] Graphics. Each can be switched off on its own.
        richPortrait   = true,    // the unit's card portrait in the header
        richWatermark  = 22,      // faction symbol behind the card, alpha 0-255 (0 = off)
        factionSymbolPath = "data/ui/faction_symbols/",   // loose art, keyed by faction name, as battle_hud.nut uses
        richHeaderGlow = 55,      // faction colour washed across the header, alpha at the top (0 = off)
        richShadowAlpha = 110,    // drop shadow strength
        richKindCaps   = true,    // "HEAVY INFANTRY" under the faction name
        richKindInk    = [175, 165, 140, 255],
        richMeters     = true,    // morale and stamina as segmented meters (false: text rows as before)
        meterLabels    = { morale = "MORALE", fatigue = "STAMINA", ammo = "AMMO" },
        // [ammo] Any unit that throws or shoots - javelins included - gets an ammunition meter: one
        // segment per shot up to ammoSegments, scaled for larger quivers, with "left / full" after it.
        showAmmo       = true,
        ammoSegments   = 10,
        ammoInk        = { full = [150, 190, 230, 255],    // steel blue, as the unit card's ammo bar
                           low  = [230, 205, 60, 255],     // below ammoLowBelow of a full quiver
                           out  = [235, 95, 75, 255] },    // below ammoOutBelow, and empty
        ammoLowBelow   = 0.5,
        ammoOutBelow   = 0.2,
        pipEmpty       = [255, 255, 255, 28],
        barLoss        = [140, 40, 30, 150],   // the men lost, shaded behind the strength bar
    }

    px    = null
    scope = null
    frame = null
    text  = ""
    edge  = null
    rect  = null
    overCard = false   // [ui-look] the cursor is on an HD unit card rather than the battlefield
    fromSelection = false   // [modes] the card shows a selected unit, not the one under the cursor
    menuRect = null         // [menu] the settings menu on screen {x, y, w, h}, or null when closed
    cardTallest = 0         // [menu] the docked card's tallest height so far, kept clear by the menu
    modeAnchor = null       // [modes] "cursor" when cardPosition is "cursor", else null (richAnchor applies)
    nativeMuted = false   // [space-tips] the game's own tooltips are switched off by this module
    tipSwitch   = null    // [space-tips] the Squirrel tooltip option found: a table, false = none
    tipOriginal = null    // [space-tips] its value before this module touched it
    // [rich-tips] what the card is about this frame, and the art it draws with
    tipUnit     = null
    tipSupport  = null
    tipBuilding = null
    tipEngine   = null   // [engines] the siege engine / artillery piece under the cursor, or null
    engineCrew  = null   // [engines] the unit found working / carrying an engine at the cursor, or null
    engineLogged = false
    richArt     = null
    logos       = null
    fadeKey     = null
    fade        = 1.0
    richPushed  = null
    portraits   = null   // [panel] unit card art by path
    symbols     = null   // [panel] faction symbols by faction name
    fontChecked = null   // [rich-tips] font -> whether it actually draws, tested once each
    fileFonts   = null   // [rich-tips] fonts loaded from a path in richTitleFont / richBodyFont
    verdana     = null   // [rich-tips] the card's own Verdana, untouched by hud_pane.nut's face swap
    tiers       = null   // [rich-tips] wording (lower case) -> tier, built from battle.txt on first use
    // [menu] the in-battle settings menu (F3)
    menu        = null   // { open, keyWas, escWas, loaded, defaults, status }
    menuKeyName = "x"
    menuShortcutName = ""
    logKeys     = false
    menuRemember = true
    state = { verified = false, down = false, strikes = 0 }

    // Builds the tooltip style scope. Every length in it is authored: the engine scales style metrics
    // by UI.dpiScale() when it resolves them, so hitPad - this canvas's own cursor box, and the one
    // number that never reaches a style token - is the only one scaled here.
    function open() {
        this.px = { hitPad = (this.metrics.hitPad * ::UI.dpiScale()).tointeger() }

        local bg = this.style.background
        local ink = this.style.ink
        this.scope = {
            [::UI.Surface.tooltip]         = [bg[0], bg[1], bg[2], bg[3]],
            [::UI.Colour.tooltipText]      = [ink[0], ink[1], ink[2], ink[3]],
            [::UI.Metric.tooltipDelay]     = this.style.delayMs,
            [::UI.Metric.tooltipPadX]      = this.metrics.padX,
            [::UI.Metric.tooltipPadY]      = this.metrics.padY,
            [::UI.Metric.roundTooltip]     = this.metrics.corner,
            [::UI.Metric.borderTooltip]    = this.metrics.borderWidth,
            [::UI.Metric.tooltipOffX]      = this.metrics.offsetX,
            [::UI.Metric.tooltipOffY]      = this.metrics.offsetY,
            [::UI.Metric.tooltipWrapWidth] = this.metrics.wrapWidth,
        }

        // [rich-tips] The game's own tooltip and card art, off the shared page. A sprite that fails
        // to load comes back with img 0 and is simply not drawn.
        local shared = ::UI.PAGE_SHARED
        local load = function (name) { return ::UI.loadSprite(name, shared) }
        this.richArt = {
            goldStar   = load("GENERALS_GOLD_STAR"),
            silverStar = load("GENERALS_SILVER_STAR"),
            xp     = [load("XP_CHEVRON_BRONZE"), load("XP_CHEVRON_SILVER"), load("XP_CHEVRON_GOLD")],
            weapon = [load("MELEE_UPGRADE_BRONZE"), load("MELEE_UPGRADE_SILVER"), load("MELEE_UPGRADE_GOLD")],
            armour = [load("ARMOUR_UPGRADE_BRONZE"), load("ARMOUR_UPGRADE_SILVER"), load("ARMOUR_UPGRADE_GOLD")],
            action = { routing  = load("TT_ACTION_ROUTING"),  berserk = load("TT_ACTION_BERSERK"),
                       hiding   = load("TT_ACTION_HIDING"),   firing  = load("TT_ACTION_FIRING"),
                       fighting = load("TT_ACTION_FIGHTING"), moving  = load("TT_ACTION_MOVING"),
                       back2wall = load("TT_ACTION_BACK2WALL") },
            moraleRouting = load("TT_MORALE_ROUTING"),
            fatigue = load("TT_FATIGUE_FRESH"),
        }
        this.logos = {}
        if (this.verdana == null) {
            try {
                this.verdana = ::UI.loadFont("fonts/verdana.ttf")
            }
            catch (e) {
                this.verdana = null
            }
        }
        // Font files are loaded here, while the scripts start up, like fonts.nut does - a font first
        // loaded mid-battle can come back as a handle that draws nothing.
        foreach (f in [this.style.richTitleFont, this.style.richTitleFallback, this.style.richBodyFont,
                       this.style.richSubFont, this.style.richLabelFont, this.style.richSmallFont]) {
            if (f != null && typeof(f) == "string" && f.tolower().indexof(".ttf") != null) {
                this.fontFor(f, "body", "body")
            }
        }
        this.richPushed = { opacity = false, style = false, clip = false }
        this.portraits = {}
        this.symbols = {}
    }

    // ---------------------------------------------------------------------------------------
    // [rich-tips] The card: a header (logo, name, badges), the faction, a strength bar, then one
    // row per line with an icon where the game has one, and the cursor hint at the bottom.
    // ---------------------------------------------------------------------------------------

    function artOk(art) {
        return art != null && art.img != 0
    }

    // The small faction logo, cached per faction; null where the engine does not expose one.
    function factionLogo(faction) {
        if (faction == null) {
            return null
        }
        if (faction.id in this.logos) {
            return this.logos[faction.id]
        }
        local art = null
        try {
            art = ::UI.loadSpriteById(faction.smallLogoId, ::UI.PAGE_SHARED)
        }
        catch (e) {
            art = null
        }
        this.logos[faction.id] <- this.artOk(art) ? art : null
        return this.logos[faction.id]
    }

    // Lower case with the surrounding spaces and line breaks removed (no string library needed).
    function trimLower(text) {
        local t = text.tolower()
        local a = 0
        local b = t.len()
        while (a < b && (t[a] == ' ' || t[a] == '\t' || t[a] == '\r' || t[a] == '\n')) a++
        while (b > a && (t[b - 1] == ' ' || t[b - 1] == '\t' || t[b - 1] == '\r' || t[b - 1] == '\n')) b--
        return t.slice(a, b)
    }

    // The first line only: up to a real line break or a written "\n", trimmed and lower case.
    function firstLine(text) {
        local cut = text.len()
        foreach (mark in ["\n", "\\n"]) {
            local at = text.indexof(mark)
            if (at != null && at < cut) cut = at
        }
        return this.trimLower(text.slice(0, cut))
    }

    // Splits a wording into its lines, at real line breaks or a written "\n"; empty lines dropped.
    function lines(text) {
        local out = []
        local rest = text
        while (true) {
            local cut = null
            local width = 0
            foreach (mark in ["\n", "\\n"]) {
                local at = rest.indexof(mark)
                if (at != null && (cut == null || at < cut)) { cut = at; width = mark.len() }
            }
            local piece = cut == null ? rest : rest.slice(0, cut)
            if (this.trimLower(piece) != "") out.append(piece)
            if (cut == null) break
            rest = rest.slice(cut + width)
        }
        return out
    }

    // Adds a wording as rows: its first line in the given ink, any detail under it small and dim,
    // lined up with the text above rather than its icon. With splitDash, a " - " in the first line
    // (the engine joins the action and the battle outlook that way) also starts a detail line.
    function addRows(model, text, ink, icon, splitDash = false) {
        local pieces = this.lines(text)
        if (splitDash && pieces.len() > 0) {
            local at = pieces[0].indexof(" - ")
            if (at != null) {
                local head = pieces[0].slice(0, at)
                local tail = pieces[0].slice(at + 3)
                pieces[0] = head
                pieces.insert(1, tail)
            }
        }
        local indent = this.artOk(icon)
        foreach (i, piece in pieces) {
            if (i == 0) {
                model.rows.append({ text = piece, ink = ink, icon = icon })
            } else {
                model.rows.append({ text = piece, ink = this.style.richDimInk, icon = null, small = true,
                                    indent = indent })
            }
        }
    }

    // A font by name: a loaded font from ::EX.fonts ("body", "title"...), or one of the game's own
    // faces - by its ::EX.fonts.game key ("tnrMed", "verdana", "verdanaSml") or engine name
    // ("tnr", "tnr_med", "verdana", "verdana_sml"), which the labels and drawTip use. A font handle
    // is used as is. An unknown name falls back rather than breaking the card.
    function fontFor(wanted, preferred, fallback) {
        if (wanted != null && typeof(wanted) != "string") return wanted
        // A font file, loaded once and kept. A bare file name ("EBGaramond-Regular.ttf") is looked
        // for in style.fontFolder; a name with a folder in it is used as written.
        if (wanted != null && wanted.tolower().indexof(".ttf") != null) {
            if (this.fileFonts == null) this.fileFonts = {}
            if (!(wanted in this.fileFonts)) {
                local path = wanted.indexof("/") == null && wanted.indexof("\\") == null
                           ? this.style.fontFolder + wanted : wanted
                local loaded = null
                try { loaded = ::UI.loadFont(path) } catch (e) { loaded = null }
                if (loaded == null || loaded == 0) {
                    println("squi: [rich-tips] could not load font " + path)
                    loaded = null
                }
                this.fileFonts[wanted] <- loaded
            }
            if (this.fileFonts[wanted] != null) return this.fileFonts[wanted]
            wanted = null
        }
        local engineFaces = ["tnr", "tnr_med", "verdana", "verdana_sml"]
        foreach (name in [wanted, preferred, fallback]) {
            if (name == null) continue
            if (name in ::EX.fonts && typeof(::EX.fonts[name]) != "table") return ::EX.fonts[name]
            if ("game" in ::EX.fonts && name in ::EX.fonts.game) return ::EX.fonts.game[name]
            if (engineFaces.find(name) != null) return name
        }
        return ::EX.fonts.body
    }

    // True when the font really measures text; a font that failed to load measures nothing and
    // would draw an empty card. Checked once per font and size, and logged once if it fails.
    function fontWorks(font, size) {
        if (this.fontChecked == null) this.fontChecked = {}
        local key = font + "|" + size
        if (key in this.fontChecked) return this.fontChecked[key]
        local ok = false
        try {
            local m = ::UI.textSize("Ag", font, size)
            ok = m != null && m[0] > 0 && m[1] > 0
        }
        catch (e) {
            ok = false
        }
        if (!ok) println("squi: [rich-tips] font " + font + " does not draw - using Verdana instead")
        this.fontChecked[key] <- ok
        return ok
    }

    // [montserrat] An extra weight (sub / label / small): the file if it loads and draws, else the body
    // font, so a missing file only loses the styling. null means "use the body font".
    function extraFont(wanted, body) {
        if (wanted == null) return body
        local f = this.fontFor(wanted, "body", "body")
        return this.fontWorks(f, 12) ? f : body
    }

    // [montserrat] "Morale: Wavering (2/4)" -> ["Morale:", " Wavering (2/4)"], for a label drawn in its
    // own weight. Only a short label at the start counts, so sentences with a colon are left whole.
    function splitLabel(text) {
        local at = text.indexof(": ")
        if (at == null || at < 2 || at > 18) return null
        return [text.slice(0, at + 1), text.slice(at + 1)]
    }

    // Breaks text into lines no wider than width, at spaces; a single word wider than the line
    // keeps a line of its own rather than being cut.
    function wrapLines(text, font, size, width) {
        local out = []
        if (::UI.textSize(text, font, size)[0] <= width) {
            out.append(text)
            return out
        }
        local words = []
        local start = 0
        for (local i = 0; i <= text.len(); i++) {
            if (i == text.len() || text[i] == ' ') {
                if (i > start) words.append(text.slice(start, i))
                start = i + 1
            }
        }
        local line = ""
        foreach (word in words) {
            local tryLine = line == "" ? word : line + " " + word
            if (line != "" && ::UI.textSize(tryLine, font, size)[0] > width) {
                out.append(line)
                line = word
            } else {
                line = tryLine
            }
        }
        if (line != "") out.append(line)
        if (out.len() == 0) out.append(text)
        return out
    }

    // Builds the wording -> tier maps from the loaded battle.txt. Not cached until the strings answer,
    // since the tables may not be loaded yet when the script first runs.
    // [panel] Also the wording -> meter level maps: each key's place in its list, best first, so
    // Fresh fills every stamina segment and Exhausted none. Keys sharing one wording take the
    // average of their places.
    function buildTiers() {
        local out = { fatigue = {}, morale = {}, level = { fatigue = {}, morale = {} },
                      levelMax = { fatigue = this.style.fatigueKeys.len() - 1,
                                   morale = this.style.moraleKeys.len() - 1 } }
        local sums = { fatigue = {}, morale = {} }
        local found = 0
        foreach (pair in [["fatigue", this.style.fatigueKeys], ["morale", this.style.moraleKeys]]) {
            local count = pair[1].len()
            foreach (i, entry in pair[1]) {
                local text = ::scripting.textTable(entry[0], ::Enum.StringTable.battle)
                if (text == null || text == "") continue
                local word = this.firstLine(text)
                local map = out[pair[0]]
                if (!(word in map)) {
                    map[word] <- entry[1]
                } else if (map[word] != entry[1] && this.style.sharedTier[pair[0]] != null) {
                    map[word] = this.style.sharedTier[pair[0]]
                }
                local sum = sums[pair[0]]
                if (!(word in sum)) sum[word] <- [0, 0]
                sum[word][0] += count - 1 - i
                sum[word][1] += 1
                found++
            }
        }
        foreach (kind, sum in sums) {
            foreach (word, v in sum) {
                out.level[kind][word] <- (v[0].tofloat() / v[1] + 0.5).tointeger()
            }
        }
        if (found > 0) {
            this.tiers = out
        }
        return out
    }

    // [panel] [level, max] for a morale or fatigue wording, or null when it is not one of the keys.
    function levelFor(kind, text) {
        local maps = this.tiers != null ? this.tiers : this.buildTiers()
        if (!("level" in maps)) return null
        local word = this.firstLine(text)
        if (!(word in maps.level[kind])) return null
        return [maps.level[kind][word], maps.levelMax[kind]]
    }

    // [panel] Like addRows, for morale and fatigue: the first line becomes a meter row (label, segments,
    // wording without any "Morale:" prefix the mod put in front), the detail lines follow under it.
    function addMeterRows(model, kind, text, ink, icon, fleeing) {
        local st = this.style
        local lv = st.richMeters ? this.levelFor(kind, text) : null
        if (lv == null) {
            this.addRows(model, text, ink, icon)
            return
        }
        local pieces = this.lines(text)
        if (pieces.len() == 0) return
        local shown = pieces[0]
        local cut = this.splitLabel(shown)
        if (cut != null) shown = this.trimText(cut[1])
        model.rows.append({ text = shown, ink = ink, icon = icon,
                            meter = { level = fleeing ? 0 : lv[0], max = lv[1] },
                            label = kind in st.meterLabels ? st.meterLabels[kind] : kind.toupper() })
        local indent = this.artOk(icon)
        for (local i = 1; i < pieces.len(); i++) {
            model.rows.append({ text = pieces[i], ink = st.richDimInk, icon = null, small = true,
                                indent = indent, meterIndent = true })
        }
    }

    // [ammo] The ammunition meter: [left, full] off the same fields the unit card's ammo bar reads,
    // or nothing for a unit without expendable ammunition.
    function ammoOf(unit) {
        local left = 0
        local full = 0
        try {
            if (!unit.hasExpendableAmmo) return null
            left = unit.currentAmmo
            full = unit.currentAmmoMax
        } catch (e) {
            return null
        }
        return full > 0 ? [left < 0 ? 0 : left, full] : null
    }

    function addAmmoRow(model, unit) {
        local st = this.style
        local ammo = this.ammoOf(unit)
        if (ammo == null) return
        local left = ammo[0]
        local full = ammo[1]
        local frac = left.tofloat() / full
        local segs = full < st.ammoSegments ? full : st.ammoSegments
        local level = (frac * segs + 0.5).tointeger()
        if (left > 0 && level == 0) level = 1          // one shot left still shows
        local ink = frac < st.ammoOutBelow ? st.ammoInk.out
                  : (frac < st.ammoLowBelow ? st.ammoInk.low : st.ammoInk.full)
        local text = left.tostring() + " / " + full.tostring()
        if (st.richMeters) {
            model.rows.append({ text = text, ink = ink, icon = null,
                                meter = { level = level, max = segs },
                                label = "ammo" in st.meterLabels ? st.meterLabels.ammo : "AMMO" })
        } else {
            model.rows.append({ text = ("ammo" in st.meterLabels ? st.meterLabels.ammo : "Ammo") + ": " + text,
                                ink = ink, icon = null })
        }
    }

    // [panel] Surrounding spaces removed, case kept.
    function trimText(text) {
        local a = 0
        local b = text.len()
        while (a < b && (text[a] == ' ' || text[a] == '\t')) a++
        while (b > a && (text[b - 1] == ' ' || text[b - 1] == '\t' || text[b - 1] == '\r')) b--
        return text.slice(a, b)
    }

    // [panel] The unit's card portrait (the art on its unit card), loaded once per path.
    function portraitFor(unit) {
        local path = null
        try { path = unit.cardPath } catch (e) { path = null }
        if (path == null || path == "") return null
        if (!(path in this.portraits)) {
            local art = null
            try { art = ::UI.loadTexture(path) } catch (e) { art = null }
            this.portraits[path] <- this.artOk(art) ? art : null
        }
        return this.portraits[path]
    }

    // [panel] The faction's large symbol, loaded once per faction; null where there is none.
    function symbolFor(faction) {
        if (faction == null) return null
        local name = null
        try { name = faction.name } catch (e) { name = null }
        if (name == null || name == "") return null
        if (!(name in this.symbols)) {
            local art = null
            try { art = ::UI.loadTexture(this.style.factionSymbolPath + name + ".tga") } catch (e) { art = null }
            this.symbols[name] <- this.artOk(art) ? art : null
        }
        return this.symbols[name]
    }

    // The ink for a morale or fatigue line, or null for the normal colour.
    function tierInkFor(kind, text) {
        local maps = this.tiers != null ? this.tiers : this.buildTiers()
        local word = this.firstLine(text)
        if (word in maps[kind]) {
            return this.style.tierInk[maps[kind][word]]
        }
        if (kind == "fatigue" && this.isExhausted(text)) {
            return this.style.tierInk.exhausted
        }
        return null
    }

    // True when a fatigue line reads as exhausted (or worse) in any of the listed wordings.
    function isExhausted(text) {
        local lower = text.tolower()
        foreach (word in this.style.exhaustedWords) {
            if (lower.indexof(word.tolower()) != null) {
                return true
            }
        }
        return false
    }

    // The icon for what the unit is doing, from its battle status bits, most urgent first.
    function actionIcon(status) {
        local a = this.richArt.action
        local B = ::Enum.BattleStatus
        if (status & B.routing)            return a.routing
        if (status & B.withdrawing)        return a.routing
        if (status & B.berserk)            return a.berserk
        if (status & B.fightingToTheDeath) return a.back2wall
        if (status & B.hiding)             return a.hiding
        if (status & B.attackingMissile)   return a.firing
        if (status & B.attackingMelee)     return a.fighting
        if ((status & B.running) || (status & B.walking)) return a.moving
        return null
    }

    // Everything the card shows, as data: header, bar and rows. null when there is nothing to show.
    function richModel() {
        local st = this.style
        local model = { title = "", sub = "", kind = "", logo = null, edge = this.edge, star = null,
                        badges = [], bar = null, rows = [], portrait = null, symbol = null }

        local unit = this.tipUnit
        local support = this.tipSupport
        if (unit != null) {
            local faction = unit.army != null ? unit.army.faction : null
            model.title = unit.type != null ? unit.type.displayName : ""
            if (st.showFaction && faction != null) {
                model.sub = faction.displayName
            }
            model.logo = this.factionLogo(faction)
            model.portrait = st.richPortrait ? this.portraitFor(unit) : null
            model.symbol = st.richWatermark > 0 ? this.symbolFor(faction) : null
            if (unit.isGeneralUnit) {
                model.star = unit.commandingGeneralPresent ? this.richArt.goldStar : this.richArt.silverStar
            }

            // Upgrades and experience, as the unit card shows them.
            if (unit.weaponLevel > 0 && unit.weaponLevel <= 3) {
                model.badges.append(this.richArt.weapon[unit.weaponLevel - 1])
            }
            if (unit.armourLevel > 0 && unit.armourLevel <= 3) {
                model.badges.append(this.richArt.armour[unit.armourLevel - 1])
            }
            if (unit.experience > 0) {
                local tier = (unit.experience - 1) / 3
                if (tier > 2) tier = 2
                local count = unit.experience % 3 == 0 ? 3 : unit.experience % 3
                for (local i = 0; i < count; i++) {
                    model.badges.append(this.richArt.xp[tier])
                }
            }

            local tally = unit.battleStats()
            local men = unit.displayedSoldiers
            local start = tally.soldiersStart > 0 ? tally.soldiersStart : men
            model.bar = { now = men, full = start,
                          dying = unit.mortalityRate > 0.01 }

            local status = unit.battleStatus
            local fleeing = (status & ::Enum.BattleStatus.routing) != 0
                         || (status & ::Enum.BattleStatus.withdrawing) != 0
            local info = unit.infoText()
            if (st.showCategory && info.category != "") {
                model.kind = info.category   // [panel] drawn in the header, under the faction name
            }
            if (st.showAction && info.action != "") {
                this.addRows(model, info.action, fleeing ? st.richBadInk : st.richBodyInk,
                             this.actionIcon(status), true)
            }
            if (st.showMorale && info.morale != "") {
                local ink = fleeing ? st.richBadInk : this.tierInkFor("morale", info.morale)
                this.addMeterRows(model, "morale", info.morale, ink != null ? ink : st.richBodyInk,
                                  fleeing ? this.richArt.moraleRouting : null, fleeing)
            }
            if (st.showFatigue && info.fatigue != "") {
                local ink = this.tierInkFor("fatigue", info.fatigue)
                this.addMeterRows(model, "fatigue", info.fatigue, ink != null ? ink : st.richBodyInk, null, false)
            }
            // [ammo] What is left to throw or shoot.
            if (st.showAmmo) {
                this.addAmmoRow(model, unit)
            }
            // Kills against losses: green while the unit has killed more men than it has lost,
            // red once its losses are the greater, neutral when they are level.
            local lost = start - men
            if (lost < 0) lost = 0
            if (st.showKills && (tally.killed > 0 || lost > 0)) {
                local kills = st.killsKey + " " + tally.killed.tostring()
                if (tally.prisoners > 0) { kills += " (" + tally.prisoners.tostring() + ")" }
                local ink = tally.killed > lost ? st.richGoodInk
                          : (tally.killed < lost ? st.richBadInk : st.richSubInk)
                model.rows.append({ text = kills, ink = ink, icon = null })
            }
        } else if (st.showSupportArmy && support != null) {
            local faction = support.faction
            model.title = faction != null ? faction.displayName : ""
            model.logo = this.factionLogo(faction)
            model.symbol = st.richWatermark > 0 ? this.symbolFor(faction) : null
            local leader = support.leader
            if (leader != null && leader.record != null) {
                model.sub = leader.record.displayName
            }
            local men = 0
            local start = 0
            for (local i = 0; i < support.unitCount; i++) {
                local u = support.unit(i)
                if (u == null) continue
                men += u.displayedSoldiers
                start += u.battleStats().soldiersStart
            }
            if (start > 0) {
                model.bar = { now = men, full = start, dying = false }
            }
            local stance = support.supportOrder
            if (stance >= 0 && stance < st.stanceKeys.len()) {
                local held = ::scripting.textTable(st.stanceKeys[stance], ::Enum.StringTable.battle)
                if (held != "") model.rows.append({ text = held, ink = st.richBodyInk, icon = null })
            }
            local info = support.infoText()
            foreach (pair in [["morale", info.morale], ["fatigue", info.fatigue]]) {
                if (pair[1] == "") continue
                local ink = this.tierInkFor(pair[0], pair[1])
                this.addMeterRows(model, pair[0], pair[1], ink != null ? ink : st.richBodyInk, null, false)
            }
        } else if (this.tipEngine != null) {
            // [engines] an abandoned engine: its name as the title, its damage below
            local line = this.engineText(this.tipEngine)
            local cut = line.indexof(" [")
            model.title = cut != null ? line.slice(0, cut) : line
            if (cut != null) model.rows.append({ text = line.slice(cut + 2, line.len() - 1), ink = st.richBadInk, icon = null })
            local side = this.engineSideUnit(this.tipEngine)   // [engine-card] the faction it belongs to
            local faction = side != null && side.army != null ? side.army.faction : null
            if (faction != null) {
                model.logo = this.factionLogo(faction)
                model.symbol = st.richWatermark > 0 ? this.symbolFor(faction) : null
            }
            local crew = this.engineCrewNow(this.tipEngine)
            if (crew != null && crew.type != null) {
                local men = ""
                try { men = " (" + crew.displayedSoldiers + ")" } catch (e) {}
                model.rows.append({ text = this.engineCrewWord() + " " + crew.type.displayName + men, ink = st.richBodyInk, icon = null })
            } else {
                model.rows.append({ text = this.engineIdleWord(), ink = st.richHintInk, icon = null })
            }
        } else if (st.showBuilding && this.tipBuilding != null) {
            local damage = this.buildingText(this.tipBuilding)
            if (damage != "") model.rows.append({ text = damage, ink = st.richBadInk, icon = null })
        }

        // [engines] the engine a unit works or carries: "Ram [Damage: 0%]"
        if (unit != null && this.tipEngine != null) {
            local line = this.engineText(this.tipEngine)
            if (line != "") model.rows.insert(0, { text = line, ink = st.richBodyInk, icon = null })
        }
        if (st.showHint && this.frame != null && this.frame.hint != "") {
            model.rows.append({ text = this.frame.hint, ink = st.richHintInk, icon = null,
                                small = true, wrap = true })
        }

        if (model.title == "" && model.rows.len() == 0) {
            return null
        }
        return model
    }

    // [engine-card] Who works or carries an engine now - only its current crew, so an engine a unit
    // brought and left (ladders dropped before the battle) is not named after that unit.
    hoverEngine = null
    function engineCrewNow(eng) {
        local v = this.valueOf(eng, "crew")
        if (!this.isObj(v)) return null
        local ok = false
        try { ok = v.type != null && !v.isDead } catch (e) {}
        return ok ? v : null
    }
    // Whose side an engine is on: its crew, else the unit that last had it.
    function engineSideUnit(eng) {
        local u = this.engineCrewNow(eng)
        if (u != null) return u
        local v = this.valueOf(eng, "previousCrew")
        if (this.isObj(v)) { local ok = false; try { ok = v.type != null } catch (e) {} if (ok) return v }
        return null
    }
    function sideSubject() {
        if (this.tipUnit != null) return this.tipUnit
        if (this.tipEngine != null) return this.engineSideUnit(this.tipEngine)
        return null
    }
    function engineCrewWord() { return "Crew:" }
    function engineIdleWord() { return "Unmanned" }

    // [tip-enemy] Whether a unit fights on the other side from the player.
    enemyInk = [226, 72, 56, 235]   // the plain box's inner frame for an enemy unit
    function isEnemy(unit) {
        if (unit == null) return false
        try {
            local side = ::battle.current().localSide
            local army = unit.army
            if (side == null || army == null) return false
            local alliance = army.battleAlliance
            return alliance >= 0 && alliance != side.index
        } catch (e) {}
        return false
    }

    // [dock] Where a w x h card goes for this anchor: next to the cursor, or docked to a corner -
    // clear of the full HUD's panel, or stacked on the minimal HUD's unit card plate. Shared by the
    // styled card and the plain box. s = the card's scale (UI.dpiScale x richScale).
    // [hud-full] The top-left corner of the compact full HUD's radar block plate { x, y }, or null
    // when that layout is off. The plate reaches chromePad past the block and runs off the left edge.
    function fullBlockTop() {
        if (!("fullLayout" in ::EX) || ::EX.fullScale() == null) return null
        local L = ::EX.fullLayout()
        local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
        local pad = 5
        try { pad = ::EX.battleHud.style.chromePad } catch (e) { pad = 5 }
        pad = (pad * k + 0.5).tointeger()
        return { x = -pad, y = L.left.y - pad }
    }

    function dockPlace(w, h, anchor, s) {
        local m = this.metrics
        local P = function (v) { return (v * s + 0.5).tointeger() }
        local docked = anchor != "cursor"
        local mouse = ::UI.mouse.pos()
        local screen = ::UI.screenSize()
        local x = 0
        local y = 0
        if (!docked) {
            x = mouse[0] + P(m.richOffsetX)
            y = mouse[1] + P(m.richOffsetY)
            if (x + w > screen[0] - 4) x = mouse[0] - w - P(m.richOffsetX) / 2
            if (y + h > screen[1] - 4) y = screen[1] - h - 4
        } else {
            local dx = P(m.richDockX)
            local dy = P(m.richDockY)
            // [dock] Full HUD: clear the HUD's own panel in that corner (the left one holds the radar,
            // the right one the commands). Minimal HUD keeps the plain offset.
            if (anchor == "bottomLeft" || anchor == "bottomRight") {
                local hudFull = false
                try { hudFull = ::options.isNormalHud() } catch (e) {}
                if (hudFull && "battleHud" in ::EX && ::EX.battleHud != null) {
                    local hudPanelH = 0
                    try {
                        local hudPx = ::EX.battleHud.px
                        hudPanelH = anchor == "bottomLeft" ? hudPx.leftH : hudPx.rightH
                    } catch (e) {}
                    local hudGap = "richDockHudGap" in m ? P(m.richDockHudGap) : 0
                    if (hudPanelH + hudGap > dy) dy = hudPanelH + hudGap
                } else if (hudFull && P(272) > dy) {
                    dy = P(272)     // the game's own full HUD, same height
                }
            }
            x = anchor == "bottomRight" || anchor == "topRight" ? screen[0] - dx - w : dx
            y = anchor == "topLeft" || anchor == "topRight" ? dy : screen[1] - dy - h
        }
        if (x < 4) x = 4
        if (y < 4) y = 4
        // [dock] Minimal HUD, docked bottom-left: stacked on the unit card strip's plate and flush
        // with its left edge, which runs off the screen - so the card's frame does too.
        if (docked && anchor == "bottomLeft") {
            local full = false
            try { full = ::options.isNormalHud() } catch (e) {}
            local block = this.fullBlockTop()
            if (full && block != null) {
                // [hud-full] Compact full HUD: stacked right on top of the radar block, flush with the
                // screen's left edge as the block is - and clear of the unit card strip's plate too,
                // which the card reaches over when it is wider than the block.
                x = block.x
                local top = block.y
                try {
                    local plate = ::EX.battleCards.plateRect
                    if (plate != null && plate.x < x + w && plate.y < top) top = plate.y
                } catch (e) {}
                y = top - P(this.metrics.richDockCardsGap) - h
            } else {
                local plate = null
                try {
                    if (!full && "battleCards" in ::EX && ::EX.battleCards != null) {
                        plate = ::EX.battleCards.plateRect
                    }
                } catch (e) { plate = null }
                if (plate != null) {
                    x = plate.x
                    y = plate.y - ("richDockCardsGap" in m ? P(m.richDockCardsGap) : 0) - h
                } else if (!full && ::EX.restyled()) {
                    // [dock] Minimal HUD with the unit cards hidden (or none to show): down into the
                    // bottom-left corner itself, flush with both edges, for the widest view.
                    local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
                    local pad = (6 * k + 0.5).tointeger()
                    x = -pad
                    y = screen[1] - h + pad
                }
            }
            if (y < 4) y = 4
            if (y + h > screen[1] + P(8)) y = screen[1] + P(8) - h
            // [menu] how tall the docked card has been, so the settings menu can keep clear of it
            if (h > this.cardTallest) this.cardTallest = h
        }
        // [menu] While the settings menu is open over the card's spot, the card steps out to its right.
        if (docked && anchor == "bottomLeft" && this.menuRect != null) {
            local r = this.menuRect
            if (y < r.y + r.h && y + h > r.y) {
                local right = r.x + r.w + P(8)
                if (x < right) x = right
            }
        }
        return [x, y]
    }

    // Draws the card: docked to a corner (richAnchor) or next to the cursor, kept on screen.
    // [panel] Layout: portrait | name, faction, unit kind, strength bar; then a divider and the rows,
    // with morale and stamina as segmented meters. Behind it: a soft shadow, rounded corners, a
    // faction-coloured glow across the header and the faction's symbol as a faint watermark.
    function drawRich() {
        local model = this.richModel()
        if (model == null) {
            return
        }

        local st = this.style
        local m = this.metrics
        local s = ::UI.dpiScale()
        if (s <= 0) s = 1.0
        s = s * st.richScale
        local P = function (v) { return (v * s + 0.5).tointeger() }

        local pad = P(m.richPad)
        local gap = P(m.richGap)
        local rowGap = P(m.richRowGap)
        local accent = P(m.richAccent)
        local logoSz = P(m.richLogo)
        local inlineLogoSz = P(m.richInlineLogo)
        local iconSz = P(m.richIcon)
        local badgeSz = P(m.richBadge)
        local barH = P(m.richBarHeight)
        local titleSize = P(m.richTitleSize)
        local bodySize = P(m.richBodySize)
        local smallSize = P(m.richSmallSize)
        local capsSize = P(m.richCapsSize)
        local pipW = P(m.richPipW)
        local pipH = P(m.richPipH)
        local pipGap = P(m.richPipGap)
        if (pipGap < 1) pipGap = 1
        local lineGap = rowGap
        local look = st.richFollowLook && "look" in ::EX ? ::EX.look : null
        if (look != null) {
            local text = look.tooltipFontSize * look.tooltipScale   // 1080p units, as drawTip uses
            bodySize = P(text)
            titleSize = P(text * st.richTitleRatio)
            smallSize = P(text * st.richSmallRatio)
            lineGap = P(look.tooltipLineGap)
        }
        local maxText = P(m.wrapWidth)

        local ownFace = this.verdana != null ? this.verdana : null
        local titleFont = st.richTitleFont == null && ownFace != null ? ownFace
                        : this.fontFor(st.richTitleFont, "title", "body")
        local body = st.richBodyFont == null && ownFace != null ? ownFace
                   : this.fontFor(st.richBodyFont, "body", "body")
        // Never draw an empty card: a font that measures nothing falls back to Verdana.
        local safe = ownFace != null ? ownFace : ::EX.fonts.body
        if (!this.fontWorks(titleFont, 16) && "richTitleFallback" in st && st.richTitleFallback != null) {
            titleFont = this.fontFor(st.richTitleFallback, "title", "body")   // [tip-rich]
        }
        if (!this.fontWorks(titleFont, 16)) titleFont = safe
        if (!this.fontWorks(body, 12)) body = safe
        if (look != null && look.face != null) {
            titleFont = look.face   // the campaign tooltips' own face
            body = look.face
        }
        local subFont = look != null ? body : this.extraFont(st.richSubFont, body)
        local smallFont = look != null ? body : this.extraFont(st.richSmallFont, body)
        local labelFont = look != null || st.richLabelFont == null ? null
                        : this.extraFont(st.richLabelFont, body)
        local capsFont = labelFont != null ? labelFont : body   // unit kind and meter labels
        local bigger = function (a, b) { return a > b ? a : b }

        // [tip-rich] The campaign box, when hud_pane.nut has loaded its helpers.
        local gilded = st.richFrame == "gilded" && "tipBack" in ::EX && "tipFrame" in ::EX
                       && "tipRule" in ::EX && "look" in ::EX && "tipBgTop" in ::EX.look

        local anchor = this.modeAnchor != null ? this.modeAnchor
                     : ("richAnchor" in st && st.richAnchor != null ? st.richAnchor : "cursor")
        local docked = anchor != "cursor"

        // --- measure: header ---
        local hasPortrait = st.richPortrait && this.artOk(model.portrait)
        local portW = hasPortrait ? P(m.richPortraitW) : 0
        local portH = hasPortrait ? P(m.richPortraitH) : 0
        local hasLogo = this.artOk(model.logo)
        local logoInline = hasPortrait && hasLogo   // with a portrait, the logo sits before the faction name
        local hasStar = this.artOk(model.star)

        local badgeW = 0
        foreach (b in model.badges) {
            if (this.artOk(b)) badgeW += badgeSz + (badgeW > 0 ? 2 : 0)
        }

        local fixedW = docked && m.richPanelW > 0 ? P(m.richPanelW) - accent - pad * 2 : 0
        local colX = hasPortrait ? portW + gap + P(2) : (hasLogo ? logoSz + gap : 0)   // header text column
        local roomW = fixedW > 0 ? fixedW : maxText
        local headRoom = roomW - colX - (badgeW > 0 ? gap * 2 + badgeW : 0)
        local subLead = logoInline ? inlineLogoSz + P(4) : 0

        local titleLines = []
        foreach (raw in (model.title != "" ? this.lines(model.title) : [])) {
            local piece = st.richTitleCaps ? raw.toupper() : raw   // loop variables are read-only in quirrel
            foreach (part in this.wrapLines(piece, titleFont, titleSize, headRoom - (hasStar ? gap + iconSz : 0))) {
                titleLines.append(part)
            }
        }
        local subLines = []
        foreach (piece in (model.sub != "" ? this.lines(model.sub) : [])) {
            foreach (part in this.wrapLines(piece, subFont, smallSize, roomW - colX - subLead)) subLines.append(part)
        }
        local kindText = model.kind != "" ? (st.richKindCaps ? model.kind.toupper() : model.kind) : ""
        local titleLH = ::UI.textSize("Ag", titleFont, titleSize)[1]
        local subLH = ::UI.textSize("Ag", subFont, smallSize)[1]
        local kindLH = kindText != "" ? ::UI.textSize("Ag", capsFont, capsSize)[1] : 0
        local titleW = 0
        foreach (line in titleLines) titleW = bigger(titleW, ::UI.textSize(line, titleFont, titleSize)[0])
        local subW = 0
        foreach (line in subLines) subW = bigger(subW, ::UI.textSize(line, subFont, smallSize)[0])
        local kindW = kindText != "" ? ::UI.textSize(kindText, capsFont, capsSize)[0] : 0
        local firstTitleW = titleLines.len() > 0 ? ::UI.textSize(titleLines[0], titleFont, titleSize)[0] : 0
        local titleH = titleLines.len() * titleLH
        local subH = subLines.len() * subLH
        if (logoInline && subLines.len() > 0 && subLH < inlineLogoSz) subH += inlineLogoSz - subLH

        local barText = ""
        local barTextDim = [0, 0]
        if (model.bar != null) {
            barText = model.bar.now.tostring() + " / " + model.bar.full.tostring()
            barTextDim = ::UI.textSize(barText, body, smallSize)
        }
        local barBlockH = model.bar != null ? bigger(barH, barTextDim[1]) : 0
        // With a portrait the bar sits in the header column, under the name; without, across the card.
        local barInHead = hasPortrait && model.bar != null

        local textH = titleH + subH + (kindLH > 0 ? kindLH + P(1) : 0)
                    + (barInHead ? rowGap * 2 + barBlockH : 0)
        local headW = colX + bigger(bigger(titleW + (hasStar ? gap + iconSz : 0), subW + subLead), kindW)
                    + (badgeW > 0 ? gap * 2 + badgeW : 0)
        local headH = bigger(hasPortrait ? portH : (hasLogo ? logoSz : 0), textH)

        // --- measure: rows ---
        // Meter rows share one column layout: label, pips, then their wording.
        local labelColW = 0
        local pipsMax = 0
        foreach (row in model.rows) {
            if (!("meter" in row)) continue
            labelColW = bigger(labelColW, ::UI.textSize(row.label, capsFont, capsSize)[0])
            pipsMax = bigger(pipsMax, row.meter.max)
        }
        local meterW = pipsMax > 0 ? labelColW + gap * 2 + pipsMax * (pipW + pipGap) - pipGap + gap * 2 : 0

        local contentW = fixedW
        if (contentW <= 0) {
            contentW = headW
            if (model.bar != null) contentW = bigger(contentW, P(m.richBarMinW) + (barInHead ? colX : 0))
            foreach (row in model.rows) {
                if ("wrap" in row && row.wrap) continue
                local size = ("small" in row && row.small) ? smallSize : bodySize
                local rowFont = ("small" in row && row.small) ? smallFont : body
                local cut = labelFont != null && !("meter" in row) && !("small" in row && row.small)
                          ? this.splitLabel(row.text) : null
                local tw = cut != null ? ::UI.textSize(cut[0], labelFont, size)[0] + ::UI.textSize(cut[1], body, size)[0]
                                       : ::UI.textSize(row.text, rowFont, size)[0]
                local lw = (this.artOk(row.icon) || ("indent" in row && row.indent) ? iconSz + gap : 0)
                         + ("meter" in row || ("meterIndent" in row && row.meterIndent) ? meterW : 0)
                contentW = bigger(contentW, tw + lw)
            }
            if (contentW > maxText) contentW = maxText
        }

        local rowsH = 0
        foreach (row in model.rows) {
            local size = ("small" in row && row.small) ? smallSize : bodySize
            local rowFont = ("small" in row && row.small) ? smallFont : body
            local iconLead = this.artOk(row.icon) || ("indent" in row && row.indent) ? iconSz + gap : 0
            local lead = iconLead + ("meter" in row || ("meterIndent" in row && row.meterIndent) ? meterW : 0)
            row.iconLead <- iconLead
            row.lead <- lead
            row.room <- contentW - lead
            row.font <- rowFont
            row.size <- size
            // A short "Label:" at the start is drawn in the label weight, when the row fits on one
            // line; a row that has to wrap is drawn whole in its own font.
            local cut = labelFont != null && !("meter" in row) && !("small" in row && row.small)
                      ? this.splitLabel(row.text) : null
            if (cut != null) {
                local labelW = ::UI.textSize(cut[0], labelFont, size)[0]
                if (labelW + ::UI.textSize(cut[1], body, size)[0] <= row.room) {
                    cut.append(labelW)
                } else {
                    cut = null
                }
            }
            row.cut <- cut
            // The engine's wrapped measure does not report the extra lines, so the card breaks the
            // text itself and stacks the lines at one line height each.
            row.parts <- cut != null ? [row.text] : this.wrapLines(row.text, rowFont, size, row.room)
            local info = ::UI.fontInfo(rowFont, size)
            row.lineH <- (info != null ? info.ascent + info.descent : ::UI.textSize("Ag", rowFont, size)[1])
                         + (row.parts.len() > 1 ? lineGap : 0)
            local rh = row.parts.len() * row.lineH
            row.h <- bigger(rh, this.artOk(row.icon) ? iconSz : 0)
            rowsH += row.h + rowGap
        }

        local barBlock = model.bar != null && !barInHead ? barBlockH + rowGap * 2 : 0
        local divider = model.rows.len() > 0 && (headH > 0 || barBlock > 0) ? rowGap * 4 + 1 : 0
        local w = accent + pad * 2 + contentW
        local h = pad * 2 + headH + (headH > 0 && barBlock > 0 ? rowGap * 2 : 0) + barBlock + divider + rowsH

        // --- place: docked to a corner, or below-right of the cursor, flipped to stay on screen ---
        local at = this.dockPlace(w, h, anchor, s)
        local x = at[0]
        local y = at[1]

        // --- fade in whenever the card starts showing something new ---
        local key = this.tipUnit != null ? "u" + this.tipUnit.id : model.title
        if (key != this.fadeKey) {
            this.fadeKey = key
            this.fade = st.richFadeSeconds > 0 ? 0.0 : 1.0
        }
        if (this.fade < 1.0) {
            this.fade += ::UI.time.delta() / st.richFadeSeconds
            if (this.fade > 1.0) this.fade = 1.0
        }
        ::UI.pushOpacity(this.fade)
        this.richPushed.opacity = true

        // --- frame ---
        local edge = model.edge
        local corner = gilded ? 0 : P(m.richCorner)   // [tip-rich] square, for the corner brackets
        local canClip = corner > 0 && "pushRoundedClip" in ::UI
        local shadow = gilded ? 0 : P(m.richShadowOffset)   // [tip-rich] tipBack draws its own
        if (shadow > 0) {
            if (canClip) { ::UI.pushRoundedClip(x + shadow, y + shadow, w, h, corner); this.richPushed.clip = true }
            ::UI.drawRect(x + shadow, y + shadow, w, h, 0, 0, 0, st.richShadowAlpha)
            if (canClip) { ::UI.popRoundedClip(); this.richPushed.clip = false }
        }
        if (canClip) { ::UI.pushRoundedClip(x, y, w, h, corner); this.richPushed.clip = true }
        if (gilded) {
            ::EX.tipBack(x, y, w, h, s)   // [tip-rich] shadow and the bronze-to-black fade
        } else if (st.richFrame == "panel" && "shared" in ::EX && "images" in ::EX.shared) {
            ::UI.drawImageNine(::EX.shared.images.tileable_panel, x, y, w, h)
        } else {
            local bg = st.richBackground
            ::UI.drawRect(x, y, w, h, bg[0], bg[1], bg[2], bg[3])
        }
        // Faction glow: the faction colour across the top, fading out down the header.
        local glowH = pad + headH
        if (st.richHeaderGlow > 0 && glowH > 0) {
            local steps = glowH / 2
            for (local i = 0; i < steps; i++) {
                local a = (st.richHeaderGlow * (steps - i) / steps).tointeger()
                ::UI.drawRect(x, y + i * 2, w, 2, edge[0], edge[1], edge[2], a)
            }
        }
        // The faction's symbol, large and faint, bleeding off the right edge.
        if (st.richWatermark > 0 && this.artOk(model.symbol)) {
            local mark = (h * 1.15).tointeger()
            local markMax = P(170)
            if (mark > markMax) mark = markMax
            ::UI.image(model.symbol.img, mark, mark, x + w - mark * 3 / 4, y + (h - mark) / 2,
                       255, 255, 255, st.richWatermark)
        }
        if (gilded) {
            // [tip-rich] The faction strip, just inside the frame, then the gold frame over all.
            local inset = P(3) + 1
            ::UI.drawRect(x + inset, y + inset, accent, h - inset * 2, edge[0], edge[1], edge[2], 255)
            // [tip-enemy] an enemy unit's card gets the same fine red inner frame as the plain box
            local enemy = "tipInnerInk" in ::EX && this.isEnemy(this.sideSubject())
            if (enemy) ::EX.tipInnerInk = this.enemyInk
            ::EX.tipFrame(x, y, w, h, s)
            if (enemy) ::EX.tipInnerInk = null
        } else {
            ::UI.drawRect(x, y, w, 1, edge[0], edge[1], edge[2], 200)             // top hairline
            ::UI.drawRect(x, y + h - 1, w, 1, 0, 0, 0, 220)                       // bottom shadow line
            ::UI.drawRect(x, y, accent, h, edge[0], edge[1], edge[2], 255)        // faction strip
        }
        if (canClip) { ::UI.popRoundedClip(); this.richPushed.clip = false }

        if (st.richShadow && gilded && "tipTextShadow" in ::EX) {
            ::UI.pushStyle(::EX.tipTextShadow(s))   // [tip-rich] the campaign tooltips' own
            this.richPushed.style = true
        } else if (st.richShadow) {
            ::UI.pushStyle({ [::UI.Cap.textShadow] = 1,
                             [::UI.Colour.textShadow] = [0, 0, 0, 200],
                             [::UI.Metric.textShadowX] = 1,
                             [::UI.Metric.textShadowY] = 1,
                             [::UI.Metric.textShadowSpread] = 0,
                             [::UI.Metric.textShadowSoftness] = 100 })
            this.richPushed.style = true
        }

        local cx = x + accent + pad
        local cy = y + pad

        // The strength bar: losses shaded red behind the men left, quarter ticks, a light top edge.
        local drawBar = function (bx, by, bw) {
            local frac = model.bar.full > 0 ? model.bar.now.tofloat() / model.bar.full : 0.0
            if (frac > 1.0) frac = 1.0
            local ink = frac < st.barLowBelow ? st.barLow : (frac < st.barMidBelow ? st.barMid : st.barGood)
            local trackW = bw - barTextDim[0] - gap
            local rowH = bigger(barH, barTextDim[1])
            local ty = by + (rowH - barH) / 2
            local t = st.barTrack
            ::UI.drawRect(bx, ty, trackW, barH, t[0], t[1], t[2], t[3])
            local fill = (trackW * frac).tointeger()
            local loss = st.barLoss
            if (fill < trackW) ::UI.drawRect(bx + fill, ty, trackW - fill, barH, loss[0], loss[1], loss[2], loss[3])
            if (fill > 0) {
                ::UI.drawRect(bx, ty, fill, barH, ink[0], ink[1], ink[2], ink[3])
                ::UI.drawRect(bx, ty, fill, 1, 255, 255, 255, 70)
            }
            for (local q = 1; q < 4; q++) {
                ::UI.drawRect(bx + trackW * q / 4, ty, 1, barH, 0, 0, 0, 140)
            }
            local txt = model.bar.dying ? st.richBadInk : st.richSubInk
            ::UI.pushFont(body, false, smallSize)
            ::UI.layoutAt(bx + trackW + gap, by + (rowH - barTextDim[1]) / 2)
            ::UI.textColoured(barText, txt[0], txt[1], txt[2], txt[3])
            ::UI.popFont()
        }

        // --- header ---
        if (headH > 0) {
            local tx = cx + colX
            if (hasPortrait) {
                ::UI.drawRect(cx - 1, cy - 1, portW + 2, portH + 2, edge[0], edge[1], edge[2], 220)
                ::UI.drawRect(cx, cy, portW, portH, 0, 0, 0, 255)
                ::UI.image(model.portrait.img, portW, portH, cx, cy)
                ::UI.drawRect(cx, cy + portH - P(12), portW, P(12), 0, 0, 0, 60)   // soft foot
            } else if (hasLogo) {
                ::UI.image(model.logo.img, logoSz, logoSz, cx, cy + (headH - logoSz) / 2)
            }
            local ty = hasPortrait ? cy : cy + (headH - textH) / 2
            if (titleLines.len() > 0) {
                local ink = st.richTitleInk
                ::UI.pushFont(titleFont, false, titleSize)
                foreach (i, line in titleLines) {
                    ::UI.layoutAt(tx, ty + i * titleLH)
                    ::UI.textColoured(line, ink[0], ink[1], ink[2], ink[3])
                }
                ::UI.popFont()
                if (hasStar) {
                    ::UI.image(model.star.img, iconSz, iconSz, tx + firstTitleW + gap,
                               ty + (titleLH - iconSz) / 2)
                }
            }
            ty += titleH
            if (subLines.len() > 0) {
                local ink = st.richSubInk
                local rowH = logoInline ? bigger(subLH, inlineLogoSz) : subLH
                if (logoInline) {
                    ::UI.image(model.logo.img, inlineLogoSz, inlineLogoSz, tx, ty + (rowH - inlineLogoSz) / 2)
                }
                ::UI.pushFont(subFont, false, smallSize)
                foreach (i, line in subLines) {
                    ::UI.layoutAt(tx + subLead, ty + (rowH - subLH) / 2 + i * subLH)
                    ::UI.textColoured(line, ink[0], ink[1], ink[2], ink[3])
                }
                ::UI.popFont()
            }
            ty += subH
            if (kindText != "") {
                local ink = st.richKindInk
                ::UI.pushFont(capsFont, false, capsSize)
                ::UI.layoutAt(tx, ty + P(1))
                ::UI.textColoured(kindText, ink[0], ink[1], ink[2], ink[3])
                ::UI.popFont()
                ty += kindLH + P(1)
            }
            if (barInHead) {
                drawBar(tx, ty + rowGap * 2, contentW - colX)
            }
            // Badges hug the right edge: on the name's line with a portrait, else centred on the header.
            local bx = x + w - pad - badgeW
            local by = hasPortrait ? cy + (titleLH - badgeSz) / 2 : cy + (headH - badgeSz) / 2
            foreach (b in model.badges) {
                if (!this.artOk(b)) continue
                ::UI.image(b.img, badgeSz, badgeSz, bx, by)
                bx += badgeSz + 2
            }
            cy += headH + (barBlock > 0 ? rowGap * 2 : 0)
        }

        if (barBlock > 0) {
            drawBar(cx, cy, contentW)
            cy += barBlock
        }

        // --- divider: a faction-coloured rule that fades out to the right ---
        if (divider > 0 && gilded) {
            cy += rowGap * 2
            ::EX.tipRule(cx, cy, contentW)   // [tip-rich] the campaign tooltips' gold rule
            cy += 1 + rowGap * 2
        } else if (divider > 0) {
            cy += rowGap * 2
            local seg = contentW / 8
            for (local i = 0; i < 8; i++) {
                local a = 150 - i * 18
                ::UI.drawRect(cx + i * seg, cy, (i == 7 ? contentW - seg * 7 : seg), 1, edge[0], edge[1], edge[2], a)
            }
            cy += 1 + rowGap * 2
        }

        // --- rows ---
        local empty = st.pipEmpty
        foreach (row in model.rows) {
            local tx = cx + row.lead
            if (this.artOk(row.icon)) {
                ::UI.image(row.icon.img, iconSz, iconSz, cx, cy + (row.lineH - iconSz) / 2)
            }
            if ("meter" in row) {
                local lx = cx + row.iconLead
                local capsH = ::UI.textSize("Ag", capsFont, capsSize)[1]
                local ink = st.richKindInk
                ::UI.pushFont(capsFont, false, capsSize)
                ::UI.layoutAt(lx, cy + (row.lineH - capsH) / 2)
                ::UI.textColoured(row.label, ink[0], ink[1], ink[2], ink[3])
                ::UI.popFont()
                local px = lx + labelColW + gap * 2
                local py = cy + (row.lineH - pipH) / 2
                for (local i = 0; i < row.meter.max; i++) {
                    if (i < row.meter.level) {
                        ::UI.drawRect(px, py, pipW, pipH, row.ink[0], row.ink[1], row.ink[2], row.ink[3])
                        ::UI.drawRect(px, py, pipW, 1, 255, 255, 255, 60)
                    } else {
                        ::UI.drawRect(px, py, pipW, pipH, empty[0], empty[1], empty[2], empty[3])
                    }
                    px += pipW + pipGap
                }
            }
            if (row.cut != null) {
                // label weight, then the value straight after it, in the same colour
                ::UI.pushFont(labelFont, false, row.size)
                ::UI.layoutAt(tx, cy)
                ::UI.textColoured(row.cut[0], row.ink[0], row.ink[1], row.ink[2], row.ink[3])
                ::UI.popFont()
                ::UI.pushFont(body, false, row.size)
                ::UI.layoutAt(tx + row.cut[2], cy)
                ::UI.textColoured(row.cut[1], row.ink[0], row.ink[1], row.ink[2], row.ink[3])
                ::UI.popFont()
            } else {
                ::UI.pushFont(row.font, false, row.size)
                foreach (i, part in row.parts) {
                    ::UI.layoutAt(tx, cy + i * row.lineH)
                    ::UI.textColoured(part, row.ink[0], row.ink[1], row.ink[2], row.ink[3])
                }
                ::UI.popFont()
            }
            cy += row.h + rowGap
        }

        if (this.richPushed.style) {
            ::UI.popStyle()
            this.richPushed.style = false
        }
        ::UI.popOpacity()
        this.richPushed.opacity = false
    }

    // The visible box: the rich card, or the old plain one when rich is off or the card fails.
    // [tip-layer] Drawn on hud_pane.nut's tooltip layer, so it sits above the radar and the HUD
    // rather than under whichever canvas draws after this one; in place when there is no layer.
    function drawVisible() {
        if ("onTop" in ::EX) {
            ::EX.onTop(this.drawVisibleNow.bindenv(this))
            return
        }
        this.drawVisibleNow()
    }

    function drawVisibleNow() {
        if (this.style.rich) {
            try {
                this.drawRich()
                return
            }
            catch (e) {
                // Unwind whatever the card had pushed before it failed, so nothing leaks into the next draw.
                if (this.richPushed.style) { ::UI.popStyle(); this.richPushed.style = false }
                if (this.richPushed.clip) { ::UI.popRoundedClip(); this.richPushed.clip = false }
                if (this.richPushed.opacity) { ::UI.popOpacity(); this.richPushed.opacity = false }
                println("squi: [rich-tips] falling back to the plain box - " + e)
                this.style.rich = false
            }
        }
        if (this.text != "" && "drawTip" in ::EX) {
            // [dock] The plain box goes where the styled card would: docked unless Position is Cursor.
            local st = this.style
            local anchor = this.modeAnchor != null ? this.modeAnchor
                         : ("richAnchor" in st && st.richAnchor != null ? st.richAnchor : "cursor")
            local hooked = anchor != "cursor" && "tipPlaceWith" in ::EX
            if (hooked) {
                local s = ::UI.dpiScale()
                if (s <= 0) s = 1.0
                s = s * st.richScale
                ::EX.tipPlaceWith = function (bw, bh, k) { return this.dockPlace(bw, bh, anchor, s) }.bindenv(this)
            }
            if ("tipInnerInk" in ::EX && this.isEnemy(this.sideSubject())) ::EX.tipInnerInk = this.enemyInk   // [tip-enemy]
            try {
                ::EX.drawTip(this.text, st.background, this.edge, st.ink)
            } catch (e) {
                if (hooked) ::EX.tipPlaceWith = null
                if ("tipInnerInk" in ::EX) ::EX.tipInnerInk = null
                throw e
            }
            if (hooked) ::EX.tipPlaceWith = null
            if ("tipInnerInk" in ::EX) ::EX.tipInnerInk = null
        }
    }

    // How far down a wall, gate or tower is. Its NAME is not reachable from script yet.
    // [engines] The battle pick names units, allied armies and buildings - but a piece of artillery,
    // a siege tower, a ram or a ladder is a separate object, so hovering one left all three empty,
    // raised nothing, and the game's own tooltip showed. These look for it under the names M2EX may
    // use, find the unit working it, and word its damage as the game does. The first time an
    // unknown pick comes by, its fields are logged, to pin the names down.
    engineFields = ["engine", "siegeEngine", "siege", "equipment", "siegeEquipment", "artillery",
                    "battleEngine", "engineObject"]

    function fieldOf(obj, name) {
        try { if (name in obj) return obj[name] } catch (e) {}
        try { return obj[name] } catch (e) {}
        return null
    }

    // A field's value, calling it when M2EX exposes it as a method (unit.siegeEngine() is one).
    function isFn(v) {
        local t = typeof v
        return t == "function" || t == "native function" || t == "closure"
    }
    function valueOf(obj, name) {
        local v = this.fieldOf(obj, name)
        if (this.isFn(v)) {
            try { v = v.call(obj) } catch (e) { v = null }
        }
        return v
    }
    function isObj(v) {
        local t = typeof v
        return v != null && t != "bool" && t != "integer" && t != "float" && t != "string" && !this.isFn(v)
    }

    function engineOf(frame) {
        if (frame == null) return null
        foreach (name in this.engineFields) {
            local v = this.fieldOf(frame, name)
            if (this.isObj(v)) return v
        }
        return null
    }

    // [engines] The pick names no engine (M2EX's pick holds only unit / supportArmy / building / hint
    // and the ground point x, y, z), so the engine is found from that point instead: the battle's own
    // engine list when M2EX offers one, else the siege / artillery unit standing there, else a unit
    // that carries an engine (a ram, a ladder, a tower) within reach. Returns a stand-in engine
    // { unit, engine, x, z } or null.
    engineReach  = 9.0    // world units from the cursor's ground point to a crew / carrier

    function engineNear(frame, strict = false) {
        local pickOk = this.pickValid(frame)
        local b = null
        try { b = ::battle.current() } catch (e) { return null }
        if (b == null) return null
        local screen = this.viewReady(b)
        if (!pickOk && !screen) return null
        local px = pickOk ? this.fieldOf(frame, "x") : 0.0
        local pz = pickOk ? this.fieldOf(frame, "z") : 0.0
        // the cursor's line of sight, when the camera's position is known
        local ray = null
        if (pickOk) try {
            local cy = this.valueOf(b, "cameraY")
            local gy = this.fieldOf(frame, "y")
            if (cy != null && gy != null) ray = { cx = b.cameraX, cy = cy, cz = b.cameraZ, gx = px, gy = gy, gz = pz }
        } catch (e) { ray = null }
        // 1. the battle's own engine list: battle.engines()
        local list = this.valueOf(b, "engines")
        list = this.engineArray(list)
        local mp = null
        try { mp = ::UI.mouse.pos() } catch (err) { screen = false }
        local mx = mp != null ? mp[0] : 0
        local my = mp != null ? mp[1] : 0
        local padK = ::UI.dpiScale()
        local best = null
        local bestD = 1e12
        local gy = ray != null ? ray.gy : null
        if (typeof list == "array") {
            foreach (e in list) {
                if (!this.isObj(e)) continue
                if (this.valueOf(e, "valid") == false) continue   // a removed engine
                local at = this.enginePos(e)
                if (at == null) continue
                local shape = this.engineShape(e, at)
                local sticky = this.engineLast != null && this.sameEngine(this.engineLast, e)
                local r = shape.r * (sticky ? 1.5 : 1.0)
                local h = shape.h + (sticky ? 4.0 : 0.0)
                if (strict) r *= 0.7   // a unit is named there: only the engine's core beats it
                local baseY = this.valueOf(e, "z")   // the ground height the engine stands on
                if (typeof baseY != "float" && typeof baseY != "integer") baseY = gy
                local score = null
                // 1. on screen: the engine's box as the camera draws it, against the mouse
                if (screen) {
                    local box = this.engineScreenBox(at[0], at[1], baseY, h, r)
                    if (box != null) {
                        local pad = (sticky ? 8 : 2) * padK
                        if (mx >= box[0] - pad && mx <= box[2] + pad && my >= box[1] - pad && my <= box[3] + pad) {
                            // the nearest to the camera wins
                            local cd = (at[0] - b.cameraX) * (at[0] - b.cameraX) + (at[1] - b.cameraZ) * (at[1] - b.cameraZ)
                            score = -1e9 + cd
                        }
                    }
                }
                local d2 = (at[0] - px) * (at[0] - px) + (at[1] - pz) * (at[1] - pz)
                if (!screen && pickOk && d2 <= r * r) score = d2 / (r * r)   // the ground point is inside its footprint
                if (ray != null && !screen) {
                    local t = this.rayHit3(ray, at[0], at[1], baseY, h, r)
                    if (t != null) { local sc = t - 1.0; if (score == null || sc < score) score = sc }   // along the line of sight: the nearest to the camera wins
                }
                if (score != null && score < bestD) { bestD = score; best = { engine = e, unit = this.engineUnit(e) } }
            }
            if (best != null) { this.engineLast = best.engine; return best }
        }
        // (with the camera model the list above is the whole answer: every engine, carried ones too)
        if (strict || !pickOk || screen) { this.engineLast = null; return null }
        // 2. / 3. the siege unit standing there, or a unit carrying an engine (unit.siegeEngine())
        local siegeCat = null
        try { siegeCat = ::Enum.UnitCategory.siege } catch (e) {}
        bestD = this.engineReach * this.engineReach
        for (local si = 0; si < b.sideCount; si++) {
            local side = b.side(si)
            if (side == null) continue
            for (local a = 0; a < side.armyCount; a++) {
                local slot = side.armySlot(a)
                local army = slot != null ? slot.army : null
                if (army == null) continue
                for (local u = 0; u < army.unitCount; u++) {
                    local unit = army.unit(u)
                    if (unit == null || unit.isDead) continue
                    local carried = this.valueOf(unit, "siegeEngine")
                    if (!this.isObj(carried)) carried = null
                    local isSiege = false
                    try { isSiege = siegeCat != null && unit.type != null && unit.type.category == siegeCat } catch (e) {}
                    if (!isSiege && carried == null) continue
                    // the engine's own position when it has one (a ram sits ahead of its men)
                    local at = carried != null ? this.enginePos(carried) : null
                    if (at == null) at = [unit.x, unit.z]
                    local d = (at[0] - px) * (at[0] - px) + (at[1] - pz) * (at[1] - pz)
                    if (ray != null) {
                        // guns are low (1-5 m, descr_engines.txt); a carried tower or ladder is ~20 m
                        local t = this.rayHit(ray, at[0], at[1], carried != null ? 22.0 : 5.0, carried != null ? 6.0 : 5.0)
                        if (t != null) d = t * t
                    }
                    if (d < bestD) { bestD = d; best = { engine = carried, unit = unit } }
                }
            }
        }
        this.engineLast = best != null ? best.engine : null
        return best
    }
    engineFaults   = 0

    // [engines] [view] Our own camera. M2EX gives the battle camera's position, heading (cameraYaw) and
    // its width-wise field of view (cameraFov), not its tilt - the tilt is read back from the cursor:
    // the line from the camera to the pick's ground point passes through the mouse, so the tilt is
    // the one that puts that line at the mouse's height on screen. With it any point of the field
    // projects to the screen, and an engine is under the cursor when the mouse is inside its box -
    // which keeps working while the pick is blank (the game's tooltips off, or showing).
    viewPitch  = null     // radians down, from the last real pick
    viewCam    = null     // [x, y, z, yaw] it was read at
    viewGroundY = 0.0     // the ground height of the last real pick
    viewChecks = 0
    viewErr    = 0.0
    viewTrusted = true
    function viewFocal(b) {
        local sc = ::UI.screenSize()
        return sc[0] * 0.5 / math.tan(b.cameraFov * 0.5)
    }
    function viewCalibrate(b, px, py, pz) {
        local sc = ::UI.screenSize()
        local m = ::UI.mouse.pos()
        local f = this.viewFocal(b)
        local u = m[0] - sc[0] * 0.5
        local v = m[1] - sc[1] * 0.5
        local dx = px - b.cameraX, dy = py - b.cameraY, dz = pz - b.cameraZ
        local sy = math.sin(b.cameraYaw), cy = math.cos(b.cameraYaw)
        local ahead = dx * sy + dz * cy
        local side = dx * cy - dz * sy
        if (ahead <= 0.5) return
        local depress = math.atan2(-dy, ahead)
        local pitch = depress - math.atan2(v, f)
        // check the width-wise fit: where the model puts the pick against where the mouse is
        if (this.viewChecks < 120) {
            local fwd = ahead * math.cos(pitch) - dy * math.sin(pitch)
            if (fwd > 0.5) {
                local pu = f * side / fwd
                this.viewErr += math.fabs(pu - u)
                this.viewChecks++
                if (this.viewChecks == 30 || this.viewChecks == 120) {
                    local mean = this.viewErr / this.viewChecks
                    this.viewTrusted = mean <= 30.0 * ::UI.dpiScale()
                    if (!this.viewTrusted) println(format("squi: [engines] the camera model puts the cursor %.1f px from the mouse on average (%d checks) - engines fall back to the cursor's ground point", mean, this.viewChecks))
                }
            }
        }
        this.viewPitch = pitch
        this.viewCam = [b.cameraX, b.cameraY, b.cameraZ, b.cameraYaw]
        this.viewGroundY = py
    }
    function viewReady(b) {
        return this.viewTrusted && this.viewPitch != null && this.viewChecks >= 30
    }
    // A point of the field [x, ground z, height y] to the screen [sx, sy], or null behind the camera.
    function project(x, z, y) {
        local b = ::battle.current()
        local f = this.viewFocal(b)
        local sc = ::UI.screenSize()
        local dx = x - b.cameraX, dy = y - b.cameraY, dz = z - b.cameraZ
        local sy = math.sin(b.cameraYaw), cy = math.cos(b.cameraYaw)
        local ahead = dx * sy + dz * cy
        local side = dx * cy - dz * sy
        local sp = math.sin(this.viewPitch), cp = math.cos(this.viewPitch)
        local fwd = ahead * cp - dy * sp
        local up = ahead * sp + dy * cp
        if (fwd <= 1.0) return null
        return [sc[0] * 0.5 + f * side / fwd, sc[1] * 0.5 - f * up / fwd, fwd]
    }
    function engineScreenBox(ex, ez, y0, h, r) {
        local x0 = null, y1 = null, x1 = null, yy0 = null
        local n = 0
        foreach (c in [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
            foreach (hy in [y0, y0 + h]) {
                local at = null
                try { at = this.project(ex + c[0] * r * 0.8, ez + c[1] * r * 0.8, hy) } catch (e) { at = null }
                if (at == null) continue
                n++
                if (x0 == null || at[0] < x0) x0 = at[0]
                if (x1 == null || at[0] > x1) x1 = at[0]
                if (yy0 == null || at[1] < yy0) yy0 = at[1]
                if (y1 == null || at[1] > y1) y1 = at[1]
            }
        }
        if (n < 4) return null
        return [x0, yy0, x1, y1]
    }
    function engineFault(e) {
        if (this.engineFaults++ < 3) println("squi: [engines] engine search failed - " + e)
    }
    engineLast     = null     // the engine found last frame: it is held with a wider reach

    function sameEngine(a, b) {
        if (a == b) return true
        local ia = this.valueOf(a, "index"), ib = this.valueOf(b, "index")
        return ia != null && ia == ib
    }

    // [engines] How big an engine is, for the cursor: r wide (from its centre), h tall - by what
    // it is (descr_engines.txt: towers 19-31 m, ladders 20 m, rams low and long, guns 1-5 m,
    // trebuchets tall).
    function engineShape(e, at) {
        local name = ""
        local arty = false
        try { local info = e.infoText(); name = ("" + info.name).tolower(); arty = info.isArtillery == true } catch (err) {}
        // (kept tight: the box is what the cursor must be on, and troops stand all around engines)
        local r = 4.5, h = 5.0
        if (name.indexof("tower") != null) { r = 7.0; h = 30.0 }
        else if (name.indexof("ladder") != null) { r = 5.0; h = 4.0 }   // carried or lying: low and long
        else if (name.indexof("ram") != null && !arty) { r = 6.5; h = 6.0 }
        else if (name.indexof("trebuchet") != null) { r = 6.0; h = 15.0 }
        else if (name.indexof("catapult") != null || name.indexof("mangonel") != null) { r = 5.0; h = 7.0 }
        else if (arty) { r = 4.0; h = 4.0 }
        return { r = r, h = h }
    }

    // [engines] Where the cursor's line of sight (camera -> ground point, in 3D) passes through an
    // upright cylinder at (ex, ez) standing on height baseY, h tall and r wide: 0..1 along the line
    // (a little past the ground point is allowed, for the engine's far side), or null. The whole
    // stretch of the line inside the cylinder's footprint is tested, so a steep look down on a
    // tower's roof counts, not only the line's closest pass.
    function rayHit3(ray, ex, ez, baseY, h, r) {
        local dx = ray.gx - ray.cx
        local dz = ray.gz - ray.cz
        local len2 = dx * dx + dz * dz
        if (len2 <= 0.0001) return null
        local len = math.sqrt(len2)
        local t = ((ex - ray.cx) * dx + (ez - ray.cz) * dz) / len2
        local qx = ray.cx + t * dx - ex
        local qz = ray.cz + t * dz - ez
        local q2 = qx * qx + qz * qz
        if (q2 > r * r) return null
        local half = math.sqrt(r * r - q2) / len
        local t0 = t - half
        local t1 = t + half
        if (t0 < 0.0) t0 = 0.0
        local tmax = 1.0 + r / len
        if (t1 > tmax) t1 = tmax
        if (t0 > t1) return null
        local y0 = ray.cy + t0 * (ray.gy - ray.cy)   // the line comes down: highest at t0
        local y1 = ray.cy + t1 * (ray.gy - ray.cy)
        if (y1 > baseY + h || y0 < baseY - 1.0) return null
        // where it first dips under the top
        local tin = t0
        if (y0 > baseY + h && y0 != y1) tin = t0 + (y0 - (baseY + h)) / (y0 - y1) * (t1 - t0)
        return tin
    }

    // [mute-engine] frames, and the frame an engine was last under the cursor
    engineSeenTick = -100000
    engineHold     = null     // [mute-engine] { engine, mouse, cam } - the engine the game's tooltips are off for
    // M2EX's pick with the game's tooltips off: x, y, z all 0 and nothing named - not a place.
    function pickValid(f) {
        if (f == null) return false
        local x = this.fieldOf(f, "x"), z = this.fieldOf(f, "z")
        if (typeof x != "float" && typeof x != "integer") return false
        return !(x == 0 && z == 0 && this.fieldOf(f, "y") == 0)
    }
    function mouseNow() { try { local m = ::UI.mouse.pos(); return [m[0], m[1]] } catch (e) { return [0, 0] } }
    function camNow() { try { local b = ::battle.current(); return [b.cameraX, b.cameraY, b.cameraZ, b.cameraYaw] } catch (e) { return [0, 0, 0, 0] } }
    hoverUnit    = null
    pickUnitHold = null   // [space-units] { unit, mouse, cam } - the unit the pick last named
    // Whether a hold { mouse, cam } still stands: the mouse within a few pixels, the camera put.
    function holdStill(h) {
        if (h == null) return false
        local m = this.mouseNow()
        local tol = 6.0 * ::UI.dpiScale()
        if (math.fabs(m[0] - h.mouse[0]) > tol || math.fabs(m[1] - h.mouse[1]) > tol) return false
        local c = this.camNow()
        return !(math.fabs(c[0] - h.cam[0]) > 0.3 || math.fabs(c[1] - h.cam[1]) > 0.3 || math.fabs(c[2] - h.cam[2]) > 0.3
                 || math.fabs(c[3] - h.cam[3]) > 0.002)
    }
    // [space-units] The unit under the mouse, found on screen: each unit as an upright column from
    // its men up to where its floating card sits, as wide as a formation looks at that distance;
    // the one the mouse is deepest inside wins, nearer the camera on a tie. Enemies only when seen.
    function unitAtScreen() {
        local b = ::battle.current()
        if (b == null || !this.viewReady(b)) return null
        local m = ::UI.mouse.pos()
        local f = this.viewFocal(b)
        local k = ::UI.dpiScale()
        local mySide = b.localSide
        local seen = {}
        try {
            local ai = mySide != null ? mySide.ai : null
            if (ai != null) for (local i = 0; i < ai.visibleEnemyCount; i++) {
                local e = ai.visibleEnemy(i)
                if (e != null) seen[e.id] <- true
            }
        } catch (e) {}
        local best = null
        local bestScore = 1.0
        for (local si = 0; si < b.sideCount; si++) {
            local side = b.side(si)
            if (side == null) continue
            local own = mySide != null && side.index == mySide.index
            for (local a = 0; a < side.armyCount; a++) {
                local slot = side.armySlot(a)
                local army = slot != null ? slot.army : null
                if (army == null) continue
                for (local u = 0; u < army.unitCount; u++) {
                    local unit = army.unit(u)
                    if (unit == null || unit.isDead) continue
                    if (!own && !(unit.id in seen)) continue
                    local gy = null
                    try { gy = b.groundHeightAt(unit.x, unit.z) } catch (e) {}
                    if (gy == null) gy = this.viewGroundY
                    local p0 = this.project(unit.x, unit.z, gy)
                    local p1 = this.project(unit.x, unit.z, gy + 14.0)
                    if (p0 == null || p1 == null) continue
                    // how far the mouse is from the column p0..p1, against its half-width
                    local dx = p1[0] - p0[0], dy = p1[1] - p0[1]
                    local len2 = dx * dx + dy * dy
                    local t = len2 > 0 ? ((m[0] - p0[0]) * dx + (m[1] - p0[1]) * dy) / len2 : 0.0
                    if (t < 0.0) t = 0.0
                    if (t > 1.0) t = 1.0
                    local qx = p0[0] + t * dx - m[0], qy = p0[1] + t * dy - m[1]
                    local d = math.sqrt(qx * qx + qy * qy)
                    // a formation's half-width on screen at that distance (about 10 m), at least a card's
                    local depth = p0[2]   // how far ahead of the camera
                    local half = f * 10.0 / depth
                    if (half < 24.0 * k) half = 24.0 * k
                    local score = d / half
                    if (score < bestScore || (best != null && score == bestScore && depth < best.depth)) {
                        bestScore = score
                        best = { unit = unit, depth = depth }
                    }
                }
            }
        }
        return best != null ? best.unit : null
    }
    // Held while the mouse stays within a few pixels and the camera stays put.
    function engineHoldActive() {
        local h = this.engineHold
        if (h == null) return false
        if (this.valueOf(h.engine, "valid") == false) return false
        local m = this.mouseNow()
        local tol = 6.0 * ::UI.dpiScale()
        if (math.fabs(m[0] - h.mouse[0]) > tol || math.fabs(m[1] - h.mouse[1]) > tol) return false
        local c = this.camNow()
        if (math.fabs(c[0] - h.cam[0]) > 0.3 || math.fabs(c[1] - h.cam[1]) > 0.3 || math.fabs(c[2] - h.cam[2]) > 0.3
            || math.fabs(c[3] - h.cam[3]) > 0.002) return false
        return true
    }
    function tick() { return "tipTick" in ::EX ? ::EX.tipTick : 0 }

    // [engines] battle.engines() as a plain array, however M2EX's BattlefieldEngines hands them out.
    function engineArray(list) {
        if (list == null) return []
        if (typeof list == "array") return list
        local out = []
        // (not foreach: over an M2EX object it walks the object's own members - weakref, engine,
        // isValid, __getTable... - which is what "6 engines" was)
        local n = null
        foreach (f in ["len", "count", "size", "length", "engineCount"]) {
            local v = this.valueOf(list, f)
            if (typeof v == "integer") { n = v; break }
        }
        if (n == null) { try { n = list.len() } catch (err) {} }
        if (n == null) return out
        for (local i = 0; i < n; i++) {
            local e = null
            try { e = list.engine(i) } catch (err) {}   // BattlefieldEngines.engine(i)
            if (e == null) try { e = list[i] } catch (err) {}
            if (e == null) foreach (f in ["at", "get", "item"]) {
                local fn = this.fieldOf(list, f)
                if (this.isFn(fn)) { try { e = fn.call(list, i) } catch (err) {} }
                if (e != null) break
            }
            if (e != null) out.append(e)
        }
        return out
    }

    // An engine's ground position [x, z], or null.
    function enginePos(e) {
        // M2EX's SiegeEngine keeps its ground position in x / y and its height in z (x=-75.4
        // y=-361.4 z=52 for a Ribault whose crew stand at unit.x -75.4, unit.z -361.4)
        foreach (pair in [["x", "y"], ["posX", "posZ"], ["positionX", "positionZ"]]) {
            local x = this.valueOf(e, pair[0])
            local z = this.valueOf(e, pair[1])
            if ((typeof x == "float" || typeof x == "integer") && (typeof z == "float" || typeof z == "integer")) return [x, z]
        }
        local p = this.valueOf(e, "position")
        if (p != null) {
            local x = this.valueOf(p, "x")
            local z = this.valueOf(p, "z")
            if ((typeof x == "float" || typeof x == "integer") && (typeof z == "float" || typeof z == "integer")) return [x, z]
        }
        return null
    }

    // [engines] How far along the cursor's line of sight (camera -> ground point) an engine standing
    // at (ex, ez), h tall and r wide, is crossed: 0..1 from the camera, or null when the line passes
    // beside it or over its top. So hovering the top of a 20 m tower finds the tower, though the
    // ground point lies far behind it.
    function rayHit(ray, ex, ez, h, r) {
        local dx = ray.gx - ray.cx
        local dz = ray.gz - ray.cz
        local len2 = dx * dx + dz * dz
        if (len2 <= 0.0001) return null
        local t = ((ex - ray.cx) * dx + (ez - ray.cz) * dz) / len2
        if (t < 0.0) t = 0.0
        if (t > 1.0) t = 1.0
        local qx = ray.cx + t * dx - ex
        local qz = ray.cz + t * dz - ez
        if (qx * qx + qz * qz > r * r) return null
        local y = ray.cy + t * (ray.gy - ray.cy)
        return y <= ray.gy + h ? t : null
    }

    // The unit crewing / carrying the engine, or null for an abandoned one.
    function engineUnit(eng) {
        foreach (name in ["crew", "unit", "owner", "operator", "ownerUnit", "controller", "carrier", "user", "previousCrew"]) {
            local v = this.valueOf(eng, name)
            if (this.isObj(v)) {
                local ok = false
                try { ok = v.type != null || v.displayedSoldiers != null } catch (e) {}
                if (ok) return v
            }
        }
        return null
    }

    // "Siege Tower [Damage: 7%]", in the game's own words where M2EX gives them.
    function engineText(eng) {
        // M2EX words it itself: infoText() - a line such as "Ram [Damage: 0%]", or its parts
        local info = null
        try { info = eng.infoText() } catch (err) {}
        if (typeof info == "string" && this.trimText(info) != "") return this.trimText(info)
        if (info != null && typeof info != "string") {
            local nm = this.fieldOf(info, "name")
            if (typeof nm != "string" || nm == "") nm = this.fieldOf(info, "displayName")
            local dm = this.fieldOf(info, "damagePercent")   // SiegeEngine.infoText(): { name, damagePercent, isArtillery }
            if (dm == null) dm = this.fieldOf(info, "damage")
            if (typeof nm == "string" && nm != "") {
                local word = ::scripting.textTable(this.style.damageKey, ::Enum.StringTable.battle)
                if (word == "") word = "Damage:"
                if (typeof dm == "string" && dm != "") return nm + " [" + dm + "]"
                if (typeof dm == "integer" || typeof dm == "float") return nm + " [" + word + " " + dm.tointeger() + "%]"
                return nm
            }
        }
        local name = ""
        foreach (f in ["displayName", "name", "typeName", "localisedName"]) {
            local v = this.valueOf(eng, f)
            if (typeof v == "string" && v != "") { name = v; break }
        }
        if (name == "") {
            local t = this.valueOf(eng, "type")
            if (t != null) foreach (f in ["displayName", "name"]) {
                local v = this.valueOf(t, f)
                if (typeof v == "string" && v != "") { name = v; break }
            }
        }
        local dmg = null
        local health = this.valueOf(eng, "health")
        local maxHealth = this.valueOf(eng, "maxHealth")
        if (typeof health == "integer" || typeof health == "float") {
            if ((typeof maxHealth == "integer" || typeof maxHealth == "float") && maxHealth > 0) {
                dmg = (100 - health * 100.0 / maxHealth + 0.5).tointeger()
            }
        }
        if (dmg == null) {
            foreach (f in ["damagePercent", "damage"]) {
                local v = this.valueOf(eng, f)
                if (typeof v == "integer") { dmg = v; break }
                if (typeof v == "float") { dmg = (v <= 1.0 ? v * 100 : v).tointeger(); break }
            }
        }
        local word = ::scripting.textTable(this.style.damageKey, ::Enum.StringTable.battle)
        if (word == "") word = "Damage:"
        local text = name
        if (dmg != null) text += (text == "" ? "" : " ") + "[" + word + " " + (dmg < 0 ? 0 : dmg) + "%]"
        return text
    }

    function buildingText(building) {
        if (building.maxHealth <= 0 || building.health >= building.maxHealth) {
            return ""
        }
        local damage = 100 - (building.health * 100 / building.maxHealth)
        return ::scripting.textTable(this.style.damageKey, ::Enum.StringTable.battle)
             + " " + damage.tostring() + "%"
    }

    // An allied AI army: whose it is, who leads it, its men, and its stance, morale and fatigue.
    function supportArmyText(army) {
        local text = ""
        local faction = army.faction
        if (faction != null) { text = faction.displayName }

        local leader = army.leader
        if (leader != null && leader.record != null) {
            text += (text == "" ? "" : "\n") + leader.record.displayName
        }

        local men = 0
        local start = 0
        local counted = 0
        for (local i = 0; i < army.unitCount; i++) {
            local unit = army.unit(i)
            if (unit == null) {
                continue
            }
            men += unit.displayedSoldiers
            start += unit.battleStats().soldiersStart
            counted++
        }
        if (counted > 0) {
            text += (text == "" ? "" : "\n") + men.tostring() + "/" + start.tostring()

            local stance = army.supportOrder
            if (stance >= 0 && stance < this.style.stanceKeys.len()) {
                local held = ::scripting.textTable(this.style.stanceKeys[stance], ::Enum.StringTable.battle)
                if (held != "") { text += "\n" + held }
            }

            local info = army.infoText()
            foreach (state in [info.morale, info.fatigue]) {
                if (state != "") { text += "\n" + state }
            }
        }
        return text
    }

    // Reads the engine's battle cursor pick and prepares what the box shows.
    function update() {
        this.frame = ::battle.cursorTarget()

        // cursorTarget is the WORLD pick; a hovered unit CARD is asked for separately, same box.
        local unit = this.frame != null ? this.frame.unit : null
        this.overCard = false
        // [space-tips] over one of the game's Space cards the pick is empty: the unit that card
        // belongs to, if the card manager names it
        if (unit == null && this.spaceHeld()) {
            try {
                local cm = ::ui.cardManager()
                foreach (f in ["hoveredUnit", "hoverUnit", "unitUnderCursor"]) {
                    local v = this.valueOf(cm, f)
                    if (this.isObj(v)) { unit = v; break }
                }
            } catch (e) {}
        }
        if (unit == null && ("battleCards" in ::EX)) {
            unit = ::EX.battleCards.hovered
            this.overCard = unit != null
        }
        // [space-units] While Space is held the game's tooltips are off, and with them off the pick is
        // blank - no unit named. The unit is then found on screen with the camera model (its men and
        // the floating card above them), or else the unit last named stays while the mouse stays put.
        local spaceNow = this.spaceHeld()
        if (this.pickValid(this.frame)) {
            this.pickUnitHold = this.frame.unit != null ? { unit = this.frame.unit, mouse = this.mouseNow(), cam = this.camNow() } : null
        } else if (unit == null && spaceNow) {
            try { unit = this.unitAtScreen() } catch (e) { unit = null; this.engineFault(e) }
            if (unit == null && this.holdStill(this.pickUnitHold)) unit = this.pickUnitHold.unit
        }
        local building = this.frame != null ? this.frame.building : null
        local support = this.frame != null ? this.frame.supportArmy : null
        // [engines] artillery, towers, rams, ladders: the piece itself, and the unit working it
        local engine = null
        this.engineCrew = null
        local pickOk = this.pickValid(this.frame)
        local b0 = null
        try { b0 = ::battle.current() } catch (e) { b0 = null }
        if (pickOk) {
            // [view] every real pick tells the camera's tilt
            if (b0 != null) try { this.viewCalibrate(b0, this.frame.x, this.frame.y, this.frame.z) } catch (e) { this.engineFault(e) }
        }
        local onScreen = b0 != null && this.viewReady(b0)
        local free = support == null && building == null && !this.overCard
        if (this.engineHoldActive()) {
            // [mute-engine] the game's tooltips are off for this engine, so the pick is blank: the engine
            // stays ours while the mouse and camera stay put. Any move lets the pick back for a frame,
            // and a unit it names then wins.
            engine = this.engineHold.engine
        } else if (pickOk) {
            // [engines] Soldiers first: when the game's pick names a unit, the cursor is on its men and
            // the unit is the subject, as in the game's own tooltips. Only with no unit named is an
            // engine looked for - on screen with the camera model, else along the line of sight.
            if (unit == null && free) {
                engine = this.engineOf(this.frame)
                if (engine == null) {
                    local near = null
                    try { near = this.engineNear(this.frame, false) } catch (e) { near = null; this.engineFault(e) }
                    if (near != null) {
                        if (near.engine != null) engine = near.engine
                        else unit = near.unit   // a siege unit standing there with no engine object
                    }
                }
            } else {
                this.engineLast = null
            }
            this.engineHold = engine != null ? { engine = engine, mouse = this.mouseNow(), cam = this.camNow() } : null
        } else {
            // blank pick with no engine held: the mouse moved off a held engine (ours stays for this one
            // frame, the game's tooltips come back next frame), or the game is showing one of its own
            // tooltips - on an engine, which the camera model can still find
            if (this.nativeMuted && this.engineHold != null && this.valueOf(this.engineHold.engine, "valid") != false) {
                engine = this.engineHold.engine
                this.engineHold = null
            } else {
                this.engineHold = null
                if (onScreen && free && unit == null && (!this.nativeMuted || this.spaceHeld())) {
                    local near = null
                    try { near = this.engineNear(this.frame, false) } catch (e) { near = null; this.engineFault(e) }
                    if (near != null && near.engine != null) {
                        engine = near.engine
                        this.engineHold = { engine = engine, mouse = this.mouseNow(), cam = this.camNow() }
                    }
                }
            }
        }
        this.tipEngine = engine
        if (engine != null || this.engineCrew != null) this.engineSeenTick = this.tick()   // [mute-engine]
        // [engine-card] An engine under the cursor is the tooltip's subject, as in the game's own: its
        // name and damage, then who works or carries it now (not the unit that brought it and left it).
        this.hoverEngine = engine
        if (engine != null) {
            this.engineCrew = this.engineCrewNow(engine)
            unit = null
        }
        this.hoverUnit = this.overCard ? null : unit   // [space-units] what the hover label shows

        // [modes] "selected" shows only the selected unit; "both" falls back to it when nothing
        // is hovered.
        local shows = this.cardSetting("cardShows")
        this.fromSelection = false
        if (shows == "selected") {
            engine = null
            this.tipEngine = null
            unit = this.selectedUnit()
            this.overCard = false
            support = null
            building = null
            this.fromSelection = unit != null
        } else if (shows == "both" && unit == null && support == null && engine == null) {
            unit = this.selectedUnit()
            if (unit != null) {
                building = null
                this.fromSelection = true
            }
        }
        // [rich-tips] the card reads the objects themselves, not the flattened text
        this.tipUnit = unit
        this.tipSupport = unit == null ? support : null
        this.tipBuilding = unit == null && support == null ? building : null
        this.text = ""
        local engineLine = engine != null && !this.fromSelection ? this.engineText(engine) : ""
        if (unit != null) {
            this.text = this.unitText(unit)
            if (engineLine != "") this.text += "\n" + engineLine
        } else if (engineLine != "") {
            this.text = engineLine   // [engine-card] its name and damage, then its crew
            local crew = this.engineCrewNow(engine)
            this.text += "\n" + (crew != null && crew.type != null ? this.engineCrewWord() + " " + crew.type.displayName : this.engineIdleWord())
        } else if (this.style.showSupportArmy && support != null) {
            this.text = this.supportArmyText(support)
        } else if (this.style.showBuilding && building != null) {
            this.text = this.buildingText(building)
        }

        // The cursor line the game itself writes: why an order there would be refused.
        if (this.style.showHint && !this.fromSelection && shows != "selected"
            && this.frame != null && this.frame.hint != "") {
            this.text += (this.text == "" ? "" : "\n") + this.frame.hint
        }

        local sideUnit = unit != null ? unit : (this.tipEngine != null ? this.engineSideUnit(this.tipEngine) : null)   // [engine-card]
        local owner = sideUnit != null && sideUnit.army != null ? sideUnit.army.faction
                    : (support != null ? support.faction : null)
        local record = owner != null ? owner.record : null
        this.edge = record != null
                  ? [record.primaryRed, record.primaryGreen, record.primaryBlue, 255]
                  : this.style.borderNone

        local m = ::UI.mouse.pos()
        this.rect = [m[0] - this.px.hitPad, m[1] - this.px.hitPad,
                     this.px.hitPad * 2 + 1, this.px.hitPad * 2 + 1]
    }

    // [modes] The three settings as words, whether they were written as numbers or words.
    function cardSetting(key) {
        local v = key in this.style ? this.style[key] : 1
        if (typeof v == "string") return v
        local n = 1
        try { n = v.tointeger() } catch (e) {}
        if (key == "cardPosition") return n == 2 ? "cursor" : "static"
        if (key == "cardTrigger") return n == 2 ? "always" : "space"
        return n == 2 ? "selected" : (n == 3 ? "both" : "hovered")
    }

    // [modes] The first selected unit, or null.
    function selectedUnit() {
        try {
            local cards = ::ui.cardManager()
            if (cards != null && cards.selectedUnitCount > 0) return cards.selectedUnit(0)
        } catch (e) {}
        return null
    }

    // [veil] Whether the cursor is over any of our battle HUD pieces (plates, buttons, radar, card
    // strip, settings menu), where a hidden tooltip at the cursor would take their clicks.
    function overOurHud() {
        local m = ::UI.mouse.pos()
        local inside = function (r) {
            return r != null && m[0] >= r.x && m[0] < r.x + r.w && m[1] >= r.y && m[1] < r.y + r.h
        }
        if (inside(this.menuRect)) return true
        try {
            local hud = ::EX.battleHud
            if (hud.chromeRects != null) foreach (r in hud.chromeRects) if (inside(r)) return true
            if (hud.pieces != null) foreach (r in hud.pieces) if (inside(r)) return true
            if (hud.buttonRects != null) foreach (r in hud.buttonRects) if (inside(r)) return true
            if (hud.nudgeRects != null) foreach (r in hud.nudgeRects) if (inside(r)) return true
            if (inside(hud.speedRect)) return true
        } catch (e) {}
        try {
            local px = ::EX.battleRadar.px
            if (inside({ x = px.x, y = px.y, w = px.w, h = px.h })) return true
        } catch (e) {}
        try { if (inside(::EX.battleCards.plateRect)) return true } catch (e) {}
        try { if (::EX.battleCards.hovered != null) return true } catch (e) {}
        return false
    }

    // [space-tips] The hidden tooltip at the cursor: while an HD tooltip is up the game keeps its own
    // hidden. Not over our unit card strip or the settings menu, where the hover box it registers
    // would take the click those need.
    function veilNative() {
        if (this.overCard || !("ghostStyle" in ::EX)) return
        local m = ::UI.mouse.pos()
        if (this.menuRect != null) {
            local r = this.menuRect
            if (m[0] >= r.x && m[0] < r.x + r.w && m[1] >= r.y && m[1] < r.y + r.h) return
        }
        try {
            if ("battleCards" in ::EX && ::EX.battleCards != null && ::EX.battleCards.hovered != null) return
        } catch (e) {}
        local pad = this.px != null && "hitPad" in this.px ? this.px.hitPad : 2
        ::UI.pushStyle(this.scope)
        ::UI.pushStyle(::EX.ghostStyle())
        ::UI.tooltipAt(m[0] - pad, m[1] - pad, pad * 2 + 1, pad * 2 + 1)
        ::UI.tooltip(0, this.text != "" ? this.text : " ")
        ::UI.popStyle()
        ::UI.popStyle()
    }

    // [space-tips] Space is held (the unit cards shown over the troops). The key is looked up by
    // name once - UI.Key.space threw quietly when M2EX spells it otherwise, so Space never counted.
    spaceCode = null      // the key's code, false when UI.Key has no Space by any name

    function spaceHeld() {
        if (this.spaceCode == null) {
            this.spaceCode = this.menuKeyCode(["space", "Space", "SPACE", "spacebar", "Spacebar", "SpaceBar", "spaceBar", "SPACEBAR"])
            if (this.spaceCode == null) {
                local names = ""
                try {
                    foreach (name, code in ::UI.Key) {
                        local n = name.tostring().tolower()
                        if (n.indexof("sp") != null || n.indexof("bar") != null) names += " " + name
                    }
                } catch (e) {}
                println("squi: [space-tips] UI.Key has no Space key - close names:" + (names != "" ? names : " (none)"))
                this.spaceCode = false
            }
        }
        if (this.spaceCode == false) return false
        local held = this.keyDown(this.spaceCode)
        return held
    }

    // [space-tips] Looks through what M2EX offers Squirrel (::game.options, ::options) for the game's
    // "show tooltips" option, once, and logs what is there. Returns
    //   { kind = "setter", fn, env, get }   a setShowTooltips-like function (get: its getter, or null)
    //   { kind = "field",  env, name }       a plain value that can be assigned
    // or false when there is none.
    function findTipSwitch() {
        local places = []
        try { places.append(["::game.options", ::game.options]) } catch (e) {}
        try { places.append(["::options", ::options]) } catch (e) {}
        local setter = null
        local getter = null
        local field = null
        foreach (place in places) {
            local label = place[0]
            local tbl = place[1]
            local names = []
            try {
                foreach (name, value in tbl) names.append([name.tostring(), value])
            } catch (e) {}
            // Properties an iteration does not show: asked for by name.
            foreach (guess in ["showTooltips", "showToolTips", "tooltips", "showTooltip", "toolTips",
                               "setShowTooltips", "setShowToolTips", "setTooltips"]) {
                local known = false
                foreach (pair in names) if (pair[0] == guess) known = true
                if (!known) {
                    try { if (guess in tbl) names.append([guess, tbl[guess]]) } catch (e) {}
                }
            }
            foreach (pair in names) {
                local n = pair[0].tolower()
                if (n.indexof("tip") == null) continue
                local kind = typeof(pair[1])
                local isFn = kind == "function" || kind == "native function" || kind == "closure"
                if (isFn && n.slice(0, 3) == "set" && setter == null) setter = { fn = pair[1], env = tbl, name = label + "." + pair[0] }
                else if (isFn && getter == null) getter = { fn = pair[1], env = tbl, name = label + "." + pair[0] }
                else if (!isFn && field == null && (kind == "bool" || kind == "integer")) field = { env = tbl, name = pair[0], label = label + "." + pair[0] }
            }
        }
        if (setter != null) {
            return { kind = "setter", fn = setter.fn, env = setter.env, get = getter }
        }
        if (field != null) {
            return { kind = "field", env = field.env, name = field.name }
        }
        return false
    }

    // [space-tips] Switch the game's own tooltips off (true) or back on (false). The cursor cannot
    // keep the Space-card tooltip away - it ignores both the hidden tooltip and a claimed cursor -
    // so the option itself is flipped: through Squirrel when M2EX offers it (findTipSwitch), and
    // only with style.useEop through M2TWEOP's Lua bridge. Otherwise spaceTip falls back to "native".
    function muteNative(on) {
        if (on == this.nativeMuted) {
            return true
        }
        if (this.tipSwitch == null) {
            try { this.tipSwitch = this.findTipSwitch() } catch (e) { this.tipSwitch = false }
        }
        if (this.tipSwitch != false) {
            try {
                local sw = this.tipSwitch
                if (sw.kind == "setter") {
                    if (on && this.tipOriginal == null && sw.get != null) {
                        this.tipOriginal = sw.get.fn.call(sw.get.env)
                    }
                    local show = !on
                    if (!on && this.tipOriginal != null) show = this.tipOriginal
                    sw.fn.call(sw.env, show)
                } else {
                    local cur = sw.env[sw.name]
                    if (on && this.tipOriginal == null) this.tipOriginal = cur
                    local show = !on ? (this.tipOriginal != null ? this.tipOriginal : true) : false
                    if (typeof(cur) == "integer") show = show ? 1 : 0
                    sw.env[sw.name] = show
                }
                this.nativeMuted = on
                return true
            }
            catch (e) {
                println("squi: [space-tips] the Squirrel tooltip switch failed - " + e)
                this.tipSwitch = false
            }
        }
        if (!this.style.useEop) {
            this.nativeMuted = false
            if (on && this.style.spaceTip == "hd") {
                this.style.spaceTip = "both"
                println("squi: [space-tips] no Squirrel tooltip switch and useEop is off - the game's own tooltip is kept"
                        + " hidden by the hidden tooltip at the cursor while Space is held")
            }
            return false
        }
        return this.muteNativeEop(on)
    }

    // [space-tips] The M2TWEOP route, only with style.useEop = true.
    function muteNativeEop(on) {
        // Muting remembers the option as it was; unmuting puts back exactly that, so a player who
        // plays with tooltips off keeps them off.
        local lua = @"
local mute = " + (on ? "true" : "false") + @"
for _, name in ipairs({'getOptions1', 'getOptions2'}) do
  local get = M2TWEOP and M2TWEOP[name]
  local o = get and get()
  if o ~= nil then
    local ok, cur = pcall(function() return o.showToolTips end)
    if ok and cur ~= nil then
      local want
      if mute then
        _G.__spaceTipsWas = cur
        want = false
      else
        local was = _G.__spaceTipsWas
        if was == nil then was = true end
        want = (was == true or was == 1)
        _G.__spaceTipsWas = nil
      end
      if type(cur) == 'boolean' then o.showToolTips = want else o.showToolTips = want and 1 or 0 end
      return 'space-tips set ' .. name .. ' was ' .. tostring(cur)
    end
  end
end
return 'space-tips none'
"
        local out = ""
        try {
            out = "" + ::UI.eval("lua", lua)
        }
        catch (e) {
            out = "error " + e
        }
        local failed = out.indexof("space-tips none") != null || out.indexof("refused") != null
                       || out.indexof("error") != null || out.indexof("rror") != null
        if (failed) println("squi: [space-tips] (eop) " + (on ? "mute" : "unmute") + " failed -> " + out)
        if (failed) {
            this.nativeMuted = false
            if (on) {
                this.style.spaceTip = "both"
                println("squi: [space-tips] could not switch the game's tooltips; the HD card shows alongside")
            }
            return false
        }
        this.nativeMuted = on
        return true
    }

    // What the native box says about a unit: whose it is, what it is, what it is doing, how it holds up.
    // [hover-label] Draws the label by the cursor for the unit under it on the field, on the tooltip
    // layer. It is the card's own drawing run a second time with the hover label's switches swapped
    // in (hoverStyle), the hovered unit as its subject and the cursor as its place - so it can be
    // anything from the plain name box to a full copy of the card. Everything swapped is put back.
    hoverFade    = 1.0
    hoverFadeKey = null

    function drawHover() {
        if (!this.style.hoverTip) return
        if (this.style.hoverTrigger == 1 && !this.spaceHeld()) return   // [menu] Key Press
        if (this.style.cardOn && this.cardSetting("cardPosition") == "cursor") return   // the card is at the cursor already
        local unit = this.hoverUnit
        local eng = this.hoverEngine   // [engine-card] kept even when the card shows the selection
        if (eng != null) unit = null
        if ((unit == null && eng == null) || this.overCard) return
        // a card showing the selection raises no hidden tooltip of its own; the label needs one so
        // the game's own unit tooltip stays away
        if (this.fromSelection && "ghostStyle" in ::EX) {
            ::UI.pushStyle(this.scope)
            ::UI.pushStyle(::EX.ghostStyle())
            ::UI.tooltipAt(this.rect[0], this.rect[1], this.rect[2], this.rect[3])
            ::UI.tooltip(0, " ")
            ::UI.popStyle()
            ::UI.popStyle()
        }
        local draw = function () { this.drawHoverNow(unit, eng) }.bindenv(this)
        if ("onTop" in ::EX) ::EX.onTop(draw)
        else draw()
    }

    function drawHoverNow(unit, eng = null) {
        // what the card's drawing reads, saved to be put back afterwards
        local saved = { tipUnit = this.tipUnit, tipSupport = this.tipSupport, tipBuilding = this.tipBuilding,
                        tipEngine = this.tipEngine,
                        edge = this.edge, modeAnchor = this.modeAnchor, fade = this.fade,
                        fadeKey = this.fadeKey, text = this.text, fromSelection = this.fromSelection }
        local savedStyle = {}
        foreach (key, value in this.hoverStyle) {
            if (key in this.style) savedStyle[key] <- this.style[key]
            this.style[key] = value
        }
        // [menu] the Unit Tooltip's own scale: the styled card's size, and the plain box's text size
        savedStyle.richScale <- this.style.richScale
        this.style.richScale = this.hoverScale
        local look = "look" in ::EX ? ::EX.look : null
        local savedTipScale = look != null && "battleTooltipScale" in look ? look.battleTooltipScale : null
        if (savedTipScale != null) look.battleTooltipScale = savedTipScale * this.hoverScale
        try {
            local sideUnit = unit != null ? unit : this.engineSideUnit(eng)   // [engine-card]
            local owner = sideUnit != null && sideUnit.army != null ? sideUnit.army.faction : null
            local record = owner != null ? owner.record : null
            this.edge = record != null ? [record.primaryRed, record.primaryGreen, record.primaryBlue, 255]
                                       : this.style.borderNone
            this.tipUnit = unit
            this.tipEngine = eng
            this.tipSupport = null
            this.tipBuilding = null
            this.fromSelection = false
            this.modeAnchor = "cursor"
            this.fade = this.hoverFade
            this.fadeKey = this.hoverFadeKey
            if (eng != null) {   // [engine-card] "Ram [Damage: 0%]", then its crew
                this.text = this.engineText(eng)
                local crew = this.engineCrewNow(eng)
                this.text += "\n" + (crew != null && crew.type != null ? this.engineCrewWord() + " " + crew.type.displayName : this.engineIdleWord())
            } else {
                this.text = this.unitText(unit)
            }
            if (this.style.showHint && this.frame != null && this.frame.hint != "") {
                this.text += (this.text == "" ? "" : "\n") + this.frame.hint
            }
            if (this.style.rich) {
                this.drawRich()
            } else if (this.text != "" && "drawTip" in ::EX) {
                ::EX.tipPlaceWith = null
                if ("tipInnerInk" in ::EX && this.isEnemy(sideUnit)) ::EX.tipInnerInk = this.enemyInk   // [tip-enemy]
                ::EX.drawTip(this.text, this.style.background, this.edge, this.style.ink)
                if ("tipInnerInk" in ::EX) ::EX.tipInnerInk = null
            }
            this.hoverFade = this.fade
            this.hoverFadeKey = this.fadeKey
        } catch (e) {
            if (this.richPushed.style) { ::UI.popStyle(); this.richPushed.style = false }
            if (this.richPushed.clip) { ::UI.popRoundedClip(); this.richPushed.clip = false }
            if (this.richPushed.opacity) { ::UI.popOpacity(); this.richPushed.opacity = false }
            if ("tipInnerInk" in ::EX) ::EX.tipInnerInk = null
            println("squi: [hover-label] failed - " + e)
        }
        foreach (key, value in savedStyle) this.style[key] = value
        foreach (key, value in saved) this[key] = value
        if (savedTipScale != null) look.battleTooltipScale = savedTipScale
    }

    function unitText(unit) {
        local text = ""

        if (this.style.showFaction) {
            local faction = unit.army != null ? unit.army.faction : null
            if (faction != null) { text = faction.displayName }
        }

        local tally = unit.battleStats()

        local kind = unit.type
        if (kind != null) {
            local men = unit.displayedSoldiers.tostring()
            if (tally.soldiersStart > 0) { men += "/" + tally.soldiersStart.tostring() }
            text += (text == "" ? "" : "\n") + kind.displayName + " (" + men + ")"
        }

        // Category, what it is doing, morale and fatigue, all mapped and translated engine-side.
        local info = unit.infoText()
        foreach (shown in [this.style.showCategory ? info.category : "",
                           this.style.showAction ? info.action : "",
                           this.style.showMorale ? info.morale : "",
                           this.style.showFatigue ? info.fatigue : ""]) {
            if (shown != "") { text += (text == "" ? "" : "\n") + shown }
        }

        // [ammo] Ammunition left, for the plain box.
        if (this.style.showAmmo) {
            local ammo = this.ammoOf(unit)
            if (ammo != null) {
                text += (text == "" ? "" : "\n") + "Ammo: " + ammo[0].tostring() + " / " + ammo[1].tostring()
            }
        }

        // Dead, with the prisoners in brackets after them, as the native line reads.
        if (this.style.showKills && tally.killed > 0) {
            text += (text == "" ? "" : "\n") + this.style.killsKey + " " + tally.killed.tostring()
            if (tally.prisoners > 0) { text += " (" + tally.prisoners.tostring() + ")" }
        }

        return text
    }

    function verify() {
        if (this.px == null || !("hitPad" in this.px)) {
            return false
        }
        if (this.scope == null || !(::UI.Surface.tooltip in this.scope)
            || !(::UI.Metric.tooltipWrapWidth in this.scope)) {
            return false
        }
        foreach (colour in [this.style.background, this.style.ink, this.style.borderNone]) {
            if (colour == null || colour.len() < 4) {
                return false
            }
        }
        if (this.style.stanceKeys == null) {
            return false
        }
        if (::UI.tooltipAt == null || ::UI.tooltip == null || ::UI.mouse == null) {
            return false
        }
        if (::scripting.textTable == null) {
            return false
        }
        return ::battle.cursorTarget != null
    }


    // =========================================================================================
    // [menu] In-battle settings: F3 opens a menu of the card's settings as tick boxes.
    // =========================================================================================

    // The three UNIT_CARD settings, each a choice of one; then what the card shows, each on / off.
    menuChoices = [
        { key = "cardPosition", title = "Position", options = [[1, "Static - in the corner"], [2, "Cursor - follows the mouse"]] },
        { key = "cardTrigger",  title = "Trigger",  options = [[1, "Only while Space is held"], [2, "Always"]] },
        { key = "cardShows",    title = "Shows",    options = [[1, "The unit under the mouse"], [2, "Your selected unit"],
                                                                [3, "Under the mouse, else selected"]] },
    ]
    menuToggles = [
        ["showFaction", "Faction"], ["showCategory", "Unit Type"], ["showAction", "Current Order"],
        ["showMorale", "Morale"], ["showFatigue", "Stamina"], ["showAmmo", "Ammunition"], ["showKills", "Kills"],
        ["showSupportArmy", "Allied Armies"], ["richPortrait", "Portrait"], ["richMeters", "Meters"],
        ["rich", "Styled Card"],
    ]
    // [hover-label] What the floating label shows: the card's own switches, set apart. "rich" on
    // makes it the styled card (with portrait / meters as set here); off, the plain text box.
    hoverStyle = {
        showFaction = false, showCategory = false, showAction = false,
        showMorale = true, showFatigue = true, showAmmo = true, showKills = false,
        showHint = false, richPortrait = false, richMeters = false, rich = false,
    }
    // [hover-label] the X menu's "Hover label" section: [key, label, "hover" = a hoverStyle key]
    menuHover = [
        ["rich", "Styled Card", "hover"], ["showFaction", "Faction", "hover"],
        ["showCategory", "Unit Type", "hover"], ["showAction", "Current Order", "hover"],
        ["showMorale", "Morale", "hover"], ["showFatigue", "Stamina", "hover"],
        ["showAmmo", "Ammunition", "hover"], ["showKills", "Kills", "hover"],
        ["richPortrait", "Portrait", "hover"], ["richMeters", "Meters", "hover"],
    ]
    // [card-off] which tooltips show at all: the card and the hover label, side by side in the menu
    menuShown = [["cardOn", "Unit card", null], ["hoverTip", "Hover label", null]]

    // [menu] The Unit Card and the Unit Tooltip each: 0 Off, 1 Always On, 2 Key Press (Space held).
    function cardMode() {
        if (!this.style.cardOn) return 0
        return this.cardSetting("cardTrigger") == "always" ? 1 : 2
    }
    function setCardMode(mode) {
        this.style.cardOn = mode != 0
        if (mode == 1) this.style.cardTrigger = 2
        else if (mode == 2) this.style.cardTrigger = 1
        this.style.cardPosition = 1   // the Unit Card is the one in the corner
    }
    function tipMode() {
        if (!this.style.hoverTip) return 0
        return this.style.hoverTrigger == 1 ? 2 : 1
    }
    function setTipMode(mode) {
        this.style.hoverTip = mode != 0
        if (mode == 1) this.style.hoverTrigger = 2
        else if (mode == 2) this.style.hoverTrigger = 1
    }
    // Sticky: the selected unit, whatever is hovered; Mouse Over: the unit under the mouse. One or
    // the other.
    function cardSticky() {
        return this.cardNumber("cardShows") == 2
    }

    // A menu switch's value and setter, wherever it lives (the card's style or the hover label's).
    function flagOf(t) {
        local tbl = t.len() > 2 && t[2] == "hover" ? this.hoverStyle : this.style
        return t[0] in tbl && tbl[t[0]] == true
    }
    function setFlag(t, on) {
        local tbl = t.len() > 2 && t[2] == "hover" ? this.hoverStyle : this.style
        tbl[t[0]] = on
    }
    function flagSave(t) {
        return (t.len() > 2 && t[2] == "hover" ? "hover_" : "") + t[0]
    }
    menuFile = "data/ui_hd/battle_card_settings.txt"

    // A setting as its number (1 / 2 / 3), whether it was written as a number or a word.
    function cardNumber(key) {
        local word = this.cardSetting(key)
        if (key == "cardPosition") return word == "cursor" ? 2 : 1
        if (key == "cardTrigger") return word == "always" ? 2 : 1
        return word == "selected" ? 2 : (word == "both" ? 3 : 1)
    }

    // [menu] "ctrl+f11" -> { code, ctrl, shift, alt, label }; code null when the key is unknown.
    function menuKeySpec() {
        local spec = { code = null, ctrl = false, shift = false, alt = false, label = "" }
        local name = this.menuKeyName.tolower()
        while (true) {
            local plus = name.indexof("+")
            if (plus == null) break
            local mod = name.slice(0, plus)
            if (mod == "ctrl" || mod == "control") spec.ctrl = true
            else if (mod == "shift") spec.shift = true
            else if (mod == "alt") spec.alt = true
            name = name.slice(plus + 1)
        }
        spec.code = this.menuKeyCode([name, name.toupper()])
        spec.label = (spec.ctrl ? "Ctrl+" : "") + (spec.shift ? "Shift+" : "") + (spec.alt ? "Alt+" : "") + name.toupper()
        return spec
    }

    // True while the menu key - modifiers included - is held.
    function menuKeyHeld(spec) {
        if (spec.code == null || !this.keyDown(spec.code)) return false
        local mods = 0
        try { mods = ::UI.keyboard.mods() } catch (e) { mods = 0 }
        local want = function (flag, name) {
            local bit = name in ::UI.Mod ? ::UI.Mod[name] : 0
            return bit == 0 || ((mods & bit) != 0) == flag
        }
        return want(spec.ctrl, "ctrl") && want(spec.shift, "shift") && want(spec.alt, "alt")
    }

    // [menu] The game's own shortcut command, taken over: handled here and not by the game.
    function claimMenuShortcut() {
        if (this.menuShortcutName == "") return
        ::UI.keyboard.shortcut(this.menuShortcutName, function (name) {
            if (!(::UI.context() & (::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded))) {
                return false   // outside battle the command keeps its own job
            }
            if (this.menu != null) {
                this.menu.open = !this.menu.open
                this.menu.status = ""
            }
            return true
        }.bindenv(this))
    }

    // [keys] Every shortcut command the game knows, with its keys, once - to find a free key.
    function logAllShortcuts() {
        try {
            local rows = ::UI.keyboard.shortcuts()
            println("squi: [keys] " + rows.len() + " shortcut commands:")
            // Rows came out blank as plain strings, so each is spelled out by its type.
            foreach (row in rows) {
                local t = typeof(row)
                local out = ""
                if (t == "table" || t == "instance" || t == "class") {
                    try { foreach (k, v in row) out += (out == "" ? "" : ", ") + k + " = " + v } catch (e) {}
                } else if (t == "array") {
                    foreach (v in row) out += (out == "" ? "" : " | ") + v
                } else if (t == "string") {
                    foreach (ch in row) out += ch < 32 ? "?" : ch.tochar()   // control characters shown as ?
                } else {
                    out = "" + row
                }
                println("squi: [keys]   (" + t + ") " + out)
            }
        } catch (e) {
            println("squi: [keys] could not list the game's shortcuts - " + e)
        }
    }

    function menuKeyCode(names) {
        foreach (name in names) {
            if (name in ::UI.Key) return ::UI.Key[name]
        }
        return null
    }

    function keyDown(code) {
        if (code == null) return false
        try { return ::UI.keyboard.down(code) } catch (e) { return false }
    }

    // Everything the menu can change, as they stand now (for the reset and the saved file).
    function menuSnapshot() {
        local out = {}
        foreach (c in this.menuChoices) out[c.key] <- this.cardNumber(c.key)
        foreach (t in this.menuToggles) out[t[0]] <- this.style[t[0]] ? 1 : 0
        foreach (t in this.menuHover) out[this.flagSave(t)] <- this.flagOf(t) ? 1 : 0   // [hover-label]
        foreach (t in this.menuShown) out[this.flagSave(t)] <- this.flagOf(t) ? 1 : 0   // [card-off]
        foreach (z in this.menuSizes) out[z.save] <- this.sizePercent(z)   // [hud-size]
        out.restyle <- this.style.restyle ? 1 : 0                             // [restyle]
        out.hoverTrigger <- this.style.hoverTrigger                           // [menu]
        return out
    }

    function menuApply(values) {
        foreach (c in this.menuChoices) {
            if (c.key in values) this.style[c.key] = values[c.key]
        }
        foreach (t in this.menuToggles) {
            if (t[0] in values) this.style[t[0]] = values[t[0]] != 0
        }
        foreach (t in this.menuShown) {   // [card-off]
            local key = this.flagSave(t)
            if (key in values) this.setFlag(t, values[key] != 0)
        }
        foreach (t in this.menuHover) {   // [hover-label]
            local key = this.flagSave(t)
            if (key in values) this.setFlag(t, values[key] != 0)
        }
        local resize = false
        foreach (z in this.menuSizes) {
            if (z.save in values && values[z.save] != this.sizePercent(z)) {
                if (this.setSizePercent(z, values[z.save], false) && z.hud) resize = true
            }
        }
        if ("hoverTrigger" in values) this.style.hoverTrigger = values.hoverTrigger == 1 ? 1 : 2   // [menu]
        this.style.cardPosition = 1   // [menu] the Unit Card is always the one in the corner now
        if (this.cardNumber("cardShows") == 3) this.style.cardShows = 1   // Sticky or Mouse Over, no mix
        this.style.showHint = false        // [menu] Order Hints and Walls & Gates are no longer options:
        this.hoverStyle.showHint = false   // no order hints on either; damaged walls and gates always named
        this.style.showBuilding = true
        if ("restyle" in values && (values.restyle != 0) != this.style.restyle) {   // [restyle]
            this.style.restyle = values.restyle != 0
            this.syncRestyle(false)
            resize = true
        }
        if (resize) this.hudReopen()
        this.fadeKey = null
    }

    // [hud-size] Sizes changed from the menu, as whole percents. "look" sizes live in hud_pane.nut's
    // look, "card" in this card's style. zero: the label for 0 (the stock layout), null = no 0.
    // full: the HUD this size belongs to (true full, false minimal), null = both.
    menuSizes = [
        { key = "richScale",          save = "cardSize",       title = "Unit Card Scale",    zero = null, full = null,
          where = "card", min = 50, max = 160, hud = false },
        { key = "hoverScale",         save = "tooltipSize",    title = "Unit Tooltip Scale", zero = null, full = null,
          where = "hover", min = 50, max = 160, hud = false },
        { key = "battleRadarScale",   save = "radarSize",      title = "Radar Scale",        zero = null, full = null,
          where = "look", min = 70, max = 150, hud = true },
        { key = "battleFullScale",    save = "hudFullSize",    title = "Full HUD Scale",     zero = "M2EX Layout", full = true,
          where = "look", min = 40, max = 130, hud = true },
        { key = "battleMinimalScale", save = "hudMinimalSize", title = "Command HUD Scale",  zero = "Game Layout", full = false,
          where = "look", min = 40, max = 130, hud = true },
    ]
    hoverScale = 1.0   // [menu] the Unit Tooltip's own size (box and text), against its normal size
    hudSizeStep = 5

    function sizePercent(z) {
        local v = 0
        if (z.where == "card") v = z.key in this.style ? this.style[z.key] : 1.0
        else if (z.where == "hover") v = this.hoverScale
        else if ("look" in ::EX && z.key in ::EX.look) v = ::EX.look[z.key]
        return (v * 100 + 0.5).tointeger()
    }

    // Sets one size; with reopen, whatever it sizes is laid out again at once. True when it changed.
    function setSizePercent(z, pct, reopen = true) {
        if (pct <= 0 && z.zero != null) pct = 0
        else if (pct < z.min) pct = z.min
        if (pct > z.max) pct = z.max
        if (pct == this.sizePercent(z)) return false
        local v = pct / 100.0
        if (z.where == "card") {
            this.style[z.key] = v
        } else if (z.where == "hover") {
            this.hoverScale = v
        } else {
            if (!("look" in ::EX)) return false
            if (z.key in ::EX.look) ::EX.look[z.key] = v
            else ::EX.look[z.key] <- v
        }
        if (reopen) {
            if (z.hud) this.hudReopen()
            else this.fadeKey = null
        }
        return true
    }

    // One step up or down: 0 (the stock layout), where there is one, sits just below the smallest.
    function stepSize(z, dir) {
        local now = this.sizePercent(z)
        local next = now
        if (dir > 0) next = now == 0 ? z.min : now + this.hudSizeStep
        else next = (now <= z.min && z.zero != null) ? 0 : now - this.hudSizeStep
        return this.setSizePercent(z, next)
    }

    // [restyle] The whole restyle on or off: off, the battle HUD, radar, cards and unit tooltip go
    // back to the mod's / game's own rendering (hud_pane.nut's ::EX.restyled).
    function syncRestyle(reopen = true) {
        if (!("look" in ::EX)) return
        local on = !("restyle" in this.style) || this.style.restyle
        if ("restyle" in ::EX.look) ::EX.look.restyle = on
        else ::EX.look.restyle <- on
        if (reopen) this.hudReopen()
    }

    function hudReopen() {
        foreach (name in ["battleHud", "battleRadar", "battleCards"]) {
            if (name in ::EX && ::EX[name] != null) {
                try { ::EX[name].open() } catch (e) { println("squi: [hud-size] " + name + ".open failed - " + e) }
            }
        }
        this.fadeKey = null
    }

    // [menu] Saving and loading: Squirrel's own file library (no EOP), and only with style.useEop
    // M2TWEOP's Lua bridge after it. If neither works, the choices last for this session.
    function sqWrite(path, text) {
        // No bare blob(): M2EX's VM does not have it, and its compiler rejects unknown names, which
        // took this whole file down. A file without writestring just throws, and saving falls back.
        local io = require("io")
        local f = io.file(path, "wb")
        f.writestring(text)
        f.close()
    }

    function sqRead(path) {
        local io = require("io")
        local f = io.file(path, "rb")
        local b = f.readblob(f.len())
        f.close()
        local text = ""
        b.seek(0)
        while (!b.eos()) text += b.readn('b').tochar()
        return text
    }

    function menuSave() {
        if (!this.menuRemember) return
        local plain = ""
        local escaped = ""
        foreach (key, value in this.menuSnapshot()) {
            plain += key + "=" + value + "\n"
            escaped += key + "=" + value + "\\n"   // a written \n, for inside a Lua string
        }
        local out = ""
        try {
            this.sqWrite(this.menuFile, plain)
            out = "saved (squirrel io)"
        } catch (e) {
            local lua = "local f = io.open('" + this.menuFile + "', 'w')\n"
                      + "if f then f:write(\"" + escaped + "\") f:close() return 'saved (lua)' end\n"
                      + "return 'no file'"
            if (this.style.useEop) {   // M2TWEOP's Lua bridge only when allowed
                try { out = "" + ::UI.eval("lua", lua) } catch (e2) { out = "error " + e2 }
            } else {
                out = "squirrel io unavailable (" + e + "), useEop off"
            }
        }
        this.menu.status = out.indexof("saved") != null ? "Saved" : "Kept For This Session"
        if (out.indexof("saved") == null) println("squi: [menu] settings not saved -> " + out)
    }

    function menuLoad() {
        if (!this.menuRemember) return
        local text = ""
        try {
            text = this.sqRead(this.menuFile)
        } catch (e) {
            local lua = "local f = io.open('" + this.menuFile + "', 'r')\n"
                      + "if f then local s = f:read('*a') f:close() return s end\n"
                      + "return ''"
            if (this.style.useEop) {
                try { text = "" + ::UI.eval("lua", lua) } catch (e2) { text = "" }
            }
        }
        local values = {}
        foreach (line in text.split("\n")) {
            local at = line.indexof("=")
            if (at == null || at < 1) continue
            local key = this.trimText(line.slice(0, at))
            local raw = this.trimText(line.slice(at + 1))
            local n = null
            try { n = raw.tointeger() } catch (e) { n = null }
            if (n != null) values[key] <- n
        }
        if (values.len() > 0) {
            this.menuApply(values)
        }
    }


    // The menu key toggles the menu; the first battle frame loads the saved choices.
    function menuTick() {
        if (this.menu == null) {
            this.menu = { open = false, keyWas = false, escWas = false, loaded = false,
                          defaults = null, status = "" }
        }
        if (!this.menu.loaded) {
            this.menu.loaded = true
            this.menu.defaults = this.menuSnapshot()   // the file's own settings, for the reset
            this.menuLoad()
            if (this.logKeys) this.logAllShortcuts()
            this.menu.spec <- this.menuKeySpec()
            if (this.menu.spec.code == null) {
                local names = ""
                try {
                    foreach (name, code in ::UI.Key) {
                        local n = name.tolower()
                        if (n.len() <= 3 && n[0] == 'f') names += " " + name
                    }
                } catch (e) {}
                println("squi: [menu] no key named \"" + this.menuKeyName + "\" - set UNIT_CARD.menuKey to one of:" + names)
            }
        }
        local key = this.menuKeyHeld(this.menu.spec)
        if (key && !this.menu.keyWas) {
            this.menu.open = !this.menu.open
            this.menu.status = ""
        }
        this.menu.keyWas = key
        if (this.menu.open) {
            if ("onTop" in ::EX) ::EX.onTop(this.drawMenu.bindenv(this))
            else this.drawMenu()
        } else {
            this.menuRect = null
        }
    }

    // [menu] Size of the settings menu against its 1080p layout (0.85 = 15% smaller).
    menuScale = 0.85

    // [menu] Where the menu's bottom edge sits: just above the unit cards - on the minimal HUD the
    // card strip's plate, on the full HUD the top of the bottom bar - so it never covers them.
    function menuBottom(P) {
        local screen = ::UI.screenSize()
        local gap = P(10)
        local hudFull = false
        try { hudFull = ::options.isNormalHud() } catch (e) {}
        local compact = hudFull && "fullScale" in ::EX && ::EX.fullScale() != null   // [hud-full] cards beside the radar
        if (compact) {
            // [hud-full] above the radar block AND the unit card stacked on it (its tallest yet, so
            // the menu does not jump as units come and go); it may run up the left side.
            local top = this.fullBlockTop().y
            try {
                local plate = ::EX.battleCards.plateRect
                if (plate != null && plate.y < top) top = plate.y
            } catch (e) {}
            local cardGap = (this.metrics.richDockCardsGap * (::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0) + 0.5).tointeger()
            if (this.cardTallest > 0 && this.style.cardOn && this.cardSetting("cardPosition") != "cursor") top -= cardGap + this.cardTallest
            return top - gap
        }
        if (!hudFull) {
            try {
                if ("battleCards" in ::EX && ::EX.battleCards != null && ::EX.battleCards.plateRect != null) {
                    return ::EX.battleCards.plateRect.y - gap
                }
            } catch (e) {}
            // [dock] no cards: the unit card sits in the corner, so the menu goes above it
            local cardH = this.cardTallest > 0 && this.style.cardOn && this.cardSetting("cardPosition") != "cursor" ? this.cardTallest : 0
            return screen[1] - cardH - gap
        }
        local barH = 0
        try {
            local hudPx = ::EX.battleHud.px
            barH = hudPx.leftH > hudPx.rightH ? hudPx.leftH : hudPx.rightH
        } catch (e) { barH = 0 }
        if (barH <= 0) barH = P(272)
        return screen[1] - barH - gap
    }

    // The menu: the campaign tooltips' box (hud_pane.nut), a heading per group, a tick box per line;
    // what the card shows in two columns. Drawn on the far left, above the unit cards.
    function drawMenu() {
        local look = "look" in ::EX ? ::EX.look : null
        local k = ::UI.dpiScale() > 0 ? ::UI.dpiScale() : 1.0
        k = k * this.menuScale
        local P = function (v) { return (v * k + 0.5).tointeger() }
        local body = look != null && look.face != null ? look.face : ::EX.fonts.body
        local bold = look != null && "titleFace" in look && look.titleFace != null ? look.titleFace : body
        local head = look != null && "tooltipTitleFace" in look && look.tooltipTitleFace != null ? look.tooltipTitleFace : bold
        local gold = look != null && "tipTitle" in look ? look.tipTitle : [255, 214, 120]
        local ink = look != null && "tipBody" in look ? look.tipBody : [236, 226, 200]
        local dim = look != null && "tipHint" in look ? look.tipHint : [168, 158, 132]
        local edge = look != null && "tipEdge" in look ? look.tipEdge : [201, 164, 88, 255]

        local size = P(12)
        local headSize = P(13)
        local titleSize = P(17)
        local lineH = ::UI.textSize("Ag", body, size)[1] + P(5)
        local headH = ::UI.textSize("Ag", head, headSize)[1] + P(6)
        local pad = P(12)
        local box = P(12)
        local w = P(360)
        local colW = (w - pad * 2) / 2

        // lines: [kind, a, b] - "head" title | "tri" three choices | "pair" two toggles | "subject"
        //        Sticky / Mouse Over | "size" a scaler | "restyle" | "gap" | "action" id label
        local modes = ["Always On", "Off", "Key Press"]   // shown in this order; values 1, 0, 2
        local lines = []
        lines.append(["head", "Unit Card", null])
        lines.append(["tri", "card", null])
        lines.append(["subject", null, null])
        lines.append(["head", "Unit Tooltip", null])
        lines.append(["tri", "tip", null])
        lines.append(["head", "Unit Card - Display", null])
        for (local t = 0; t < this.menuToggles.len(); t += 3) {
            lines.append(["grid", this.menuToggles.slice(t, t + 3 < this.menuToggles.len() ? t + 3 : this.menuToggles.len()), null])
        }
        lines.append(["size", this.menuSizes[0], true])
        lines.append(["head", "Unit Tooltip - Display", null])
        // the same order and places as the Unit Card's options; a card-only one (Allied Armies)
        // leaves its place empty so every option sits in the same spot in both sections
        local hoverLayout = []
        foreach (ct in this.menuToggles) {
            local match = null
            foreach (ht in this.menuHover) if (ht[0] == ct[0]) match = ht
            hoverLayout.append(match)
        }
        // ...except that Styled Card moves up into the empty place, so there is no gap
        local gap = -1
        local styled = -1
        foreach (i, ht in hoverLayout) {
            if (ht == null && gap < 0) gap = i
            if (ht != null && ht[0] == "rich") styled = i
        }
        if (gap >= 0 && styled > gap) {
            hoverLayout[gap] = hoverLayout[styled]
            hoverLayout.remove(styled)
        }
        for (local t = 0; t < hoverLayout.len(); t += 3) {
            lines.append(["grid", hoverLayout.slice(t, t + 3 < hoverLayout.len() ? t + 3 : hoverLayout.len()), null])
        }
        lines.append(["size", this.menuSizes[1], true])
        lines.append(["head", "HUD Scale", null])
        local hudFull = true
        try { hudFull = ::options.isNormalHud() } catch (e) {}
        for (local zi = 2; zi < this.menuSizes.len(); zi++) {
            local z = this.menuSizes[zi]
            lines.append(["size", z, z.full == null || z.full == hudFull])
        }
        lines.append(["restyle", null, null])
        lines.append(["gap", null, null])
        lines.append(["action", "reset", "Reset To This File's Settings"])

        local titleH = ::UI.textSize("Ag", head, titleSize)[1] + P(10)
        local h = pad * 2 + titleH
        foreach (l in lines) h += l[0] == "head" ? headH : (l[0] == "gap" ? P(4) : lineH)
        h += lineH * 2   // the footer: two lines

        // far left, its bottom just above the unit cards; kept on screen
        local x = P(6)
        local y = this.menuBottom(P) - h
        if (y < P(8)) y = P(8)
        this.menuRect = { x = x, y = y, w = w, h = h }

        // the box, and the pointer: while it is over the menu, the battlefield does not get it
        local m = ::UI.mouse.pos()
        if (m[0] >= x && m[0] < x + w && m[1] >= y && m[1] < y + h) ::UI.mouse.capture()
        if ("tipBack" in ::EX) {
            ::EX.tipBack(x, y, w, h, k)
            ::UI.drawRect(x + 1, y + 1, w - 2, pad + titleH - P(4), edge[0], edge[1], edge[2], 30)
            ::EX.tipFrame(x, y, w, h, k)
        } else {
            ::UI.drawRect(x, y, w, h, 12, 10, 8, 235)
        }
        local shadow = "tipTextShadow" in ::EX
        if (shadow) ::UI.pushStyle(::EX.tipTextShadow(k))

        local text = function (t, face, sz, colour, tx, ty) {
            ::UI.pushFont(face, false, sz)
            ::UI.layoutAt(tx, ty)
            ::UI.textColoured(t, colour[0], colour[1], colour[2], colour.len() > 3 ? colour[3] : 255)
            ::UI.popFont()
        }
        local textH = ::UI.textSize("Ag", body, size)[1]
        // a tick box and its label in a row; returns true when clicked
        local tick = function (tx, ty, tw, label, on, round) {
            local hit = ::UI.hitRect(tx, ty, tw, lineH)
            if (hit.hovered) ::UI.drawRect(tx - P(3), ty, tw + P(6), lineH, edge[0], edge[1], edge[2], 28)
            local by = ty + (lineH - box) / 2
            ::UI.drawRect(tx, by, box, box, 0, 0, 0, 150)
            ::UI.drawRect(tx, by, box, 1, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(tx, by + box - 1, box, 1, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(tx, by, 1, box, edge[0], edge[1], edge[2], 255)
            ::UI.drawRect(tx + box - 1, by, 1, box, edge[0], edge[1], edge[2], 255)
            if (on) {
                local inset = round ? P(4) : P(3)
                if (inset < 2) inset = 2
                ::UI.drawRect(tx + inset, by + inset, box - inset * 2, box - inset * 2, gold[0], gold[1], gold[2], 255)
            }
            text(label, body, size, on ? ink : dim, tx + box + P(8), ty + (lineH - textH) / 2)
            return hit.clicked
        }.bindenv(this)

        local cx = x + pad
        local cy = y + pad
        text("Tooltip Menu", head, titleSize, gold, cx, cy)
        // close (x), top right
        local closeSz = P(16)
        local closeX = x + w - pad - closeSz
        local closeHit = ::UI.hitRect(closeX, cy, closeSz, closeSz)
        text("x", bold, P(15), closeHit.hovered ? gold : dim, closeX + P(4), cy - P(1))
        if (closeHit.clicked) this.menu.open = false
        cy += titleH
        if ("tipRule" in ::EX) ::EX.tipRule(cx, cy - P(5), w - pad * 2)

        local changed = false
        foreach (l in lines) {
            local kind = l[0]
            if (kind == "head") {
                text(l[1], head, headSize, gold, cx, cy + P(3))
                cy += headH
                continue
            }
            if (kind == "gap") {
                cy += P(4)
                continue
            }
            if (kind == "tri") {
                // Always On / Off / Key Press, side by side
                local third = (w - pad * 2) / 3
                local now = l[1] == "card" ? this.cardMode() : this.tipMode()
                foreach (ci, value in [1, 0, 2]) {
                    if (tick(cx + ci * third, cy, third - P(6), modes[ci], now == value, true)) {
                        if (l[1] == "card") this.setCardMode(value)
                        else this.setTipMode(value)
                        changed = true
                    }
                }
            } else if (kind == "subject") {
                local sticky = this.cardSticky()
                local third = (w - pad * 2) / 3   // on the same columns as Always On / Off above
                if (tick(cx, cy, third - P(6), "Sticky", sticky, true) && !sticky) {
                    this.style.cardShows = 2
                    changed = true
                }
                if (tick(cx + third, cy, third - P(6), "Mouse Over", !sticky, true) && sticky) {
                    this.style.cardShows = 1
                    changed = true
                }
            } else if (kind == "grid") {
                // three to a row, on the same columns as every other row of boxes
                local third = (w - pad * 2) / 3
                foreach (col, t in l[1]) {
                    if (t == null) continue
                    local on = this.flagOf(t)
                    if (tick(cx + col * third, cy, third - P(6), t[1], on, false)) {
                        this.setFlag(t, !on)
                        changed = true
                    }
                }
            } else if (kind == "pair") {
                foreach (col, t in [l[1], l[2]]) {
                    if (t == null) continue
                    local on = this.flagOf(t)
                    if (tick(cx + col * colW, cy, colW - P(6), t[1], on, false)) {
                        this.setFlag(t, !on)
                        changed = true
                    }
                }
            } else if (kind == "restyle") {
                local on = this.style.restyle
                if (tick(cx, cy, w - pad * 2, "Modded HUD", on, false)) {
                    this.style.restyle = !on
                    this.syncRestyle()
                    changed = true
                }
            } else if (kind == "size") {
                // [hud-size] "Full HUD   [-]  75%  [+]" - the HUD in use in full ink, the other dimmed
                local z = l[1]
                local inUse = l[2]
                // with the restyle off the HUD sizes do nothing: shown dimmed, still settable
                if (z.hud && !this.style.restyle) inUse = false
                local pct = this.sizePercent(z)
                text(z.title + (inUse && z.full != null ? "  (In Use)" : ""), body, size, inUse ? ink : dim, cx, cy + (lineH - textH) / 2)
                local btn = lineH - P(4)
                local third = (w - pad * 2) / 3
                local minusX = cx + third * 2          // under the third column of boxes
                local plusX = x + w - pad - btn
                local valX = minusX + btn
                local valW = plusX - valX
                local by = cy + P(2)
                foreach (pair in [[minusX, -1, "-"], [plusX, 1, "+"]]) {
                    local hit = ::UI.hitRect(pair[0], by, btn, btn)
                    ::UI.drawRect(pair[0], by, btn, btn, 0, 0, 0, hit.hovered ? 190 : 140)
                    ::UI.drawRect(pair[0], by, btn, 1, edge[0], edge[1], edge[2], 255)
                    ::UI.drawRect(pair[0], by + btn - 1, btn, 1, edge[0], edge[1], edge[2], 255)
                    ::UI.drawRect(pair[0], by, 1, btn, edge[0], edge[1], edge[2], 255)
                    ::UI.drawRect(pair[0] + btn - 1, by, 1, btn, edge[0], edge[1], edge[2], 255)
                    local gw = ::UI.textSize(pair[2], bold, size)[0]
                    text(pair[2], bold, size, hit.hovered ? gold : ink, pair[0] + (btn - gw) / 2, by + (btn - textH) / 2)
                    if (hit.clicked && this.stepSize(z, pair[1])) changed = true
                }
                local label = pct == 0 && z.zero != null ? z.zero : pct + "%"
                local lw = ::UI.textSize(label, bold, size)[0]
                text(label, bold, size, inUse ? gold : dim, valX + (valW - lw) / 2, cy + (lineH - textH) / 2)
            } else {
                local hit = ::UI.hitRect(cx, cy, w - pad * 2, lineH)
                if (hit.hovered) ::UI.drawRect(cx - P(3), cy, w - pad * 2 + P(6), lineH, edge[0], edge[1], edge[2], 28)
                text(l[2], bold, size, hit.hovered ? gold : dim, cx, cy + (lineH - textH) / 2)
                if (hit.clicked && l[1] == "reset" && this.menu.defaults != null) {
                    this.menuApply(this.menu.defaults)
                    changed = true
                }
            }
            cy += lineH
        }
        if (changed) {
            this.fadeKey = null   // redraw the card from scratch with the new settings
            this.menuSave()
        }
        local key = "spec" in this.menu ? this.menu.spec.label : this.menuKeyName.toupper()
        local foot = key + " To Close" + (this.menu.status != "" ? "   -   " + this.menu.status : "")
        text(foot, body, P(11), dim, cx, cy + P(3))
        text("Hold Spacebar To Show Elements", body, P(11), dim, cx, cy + P(3) + lineH)

        if (shadow) ::UI.popStyle()
    }

    // Draws the hovered unit's tooltip in a hot rect at the cursor.
    function render() {
        if (this.state.down) {
            return
        }
        if (!(::UI.context() & (::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded))) {
            this.muteNative(false)
            return
        }
        if (!::options.hdFeature(::Enum.HdFeature.battleTooltips)) {
            this.muteNative(false)
            return
        }
        // [menu] F3 settings menu - before anything below can return early
        try { this.menuTick() } catch (e) { println("squi: [menu] failed - " + e) }
        // [restyle] off: step aside entirely - no card, no hidden tooltip - so the game's own shows
        if (!this.style.restyle) {
            this.muteNative(false)
            return
        }
        // [modes] Space modes vs. always-on modes, and where the card goes.
        this.style.spaceOnly = this.cardSetting("cardTrigger") != "always"
        this.modeAnchor = this.cardSetting("cardPosition") == "cursor" ? "cursor" : null

        // [space-tips] With Space held and spaceTip = "native", step aside for the game's own tooltip.
        // The game shows its own tooltip on the unit cards drawn while Space is held, whatever
        // cardTrigger is, so it is switched off whenever Space is down - not only in Space mode.
        local spaceKey = this.spaceHeld()
        local spaceDown = this.style.spaceOnly && spaceKey
        // [space-tips] [mute-battle] With muteInBattle the game's own tooltips stay off for the whole
        // battle (while ours are on): the game draws its own box on siege engines and on the Space
        // cards, and the hidden tooltip cannot keep those away. Otherwise only while Space is held.
        // A mod where the switch is not reachable (no EOP / Lua) falls back to "both" once and stops.
        // [mute-engine] Switching the game's tooltips off for the whole battle blanked M2EX's unit pick
        // too (nothing under the cursor was named, so no tooltip of ours showed either). They are
        // switched off only while Space is held, or while one of our engines is under the cursor -
        // found from the cursor's ground point, which the pick still reports with them off - and a
        // few frames after, so crossing an engine's edge does not flicker the option.
        local onEngine = this.style.muteOnEngine && this.engineHold != null
                         && (!this.nativeMuted || this.engineHoldActive())
        if (!onEngine && !spaceKey) this.engineHold = null
        if (this.style.spaceTip == "hd" && (spaceKey || onEngine || this.style.muteInBattle)) {
            this.muteNative(true)
        } else {
            this.muteNative(false)
        }
        if (spaceDown && this.style.spaceTip == "native") {
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
                this.update()
                if (spaceDown) {
                    // [space-tips] The game's own tooltips are off while Space is held; draw the HD box.
                    if (this.text != "") {
                        if (this.style.cardOn) this.drawVisible()   // [card-off]
                    }
                } else if (this.style.spaceOnly) {
                    // [space-tips] Only the invisible tooltip, which keeps the game's own one hidden
                    // until Space is pressed. Not over an HD unit card, where it would take the click.
                    // [modes] Raised whenever something is under the cursor, whatever the card shows
                    // (with cardShows 2 the card's subject is the selection, not the hovered unit).
                    local underCursor = this.frame != null
                        && (this.frame.unit != null || this.frame.supportArmy != null || this.frame.building != null
                            || this.tipEngine != null || (this.tipUnit != null && !this.fromSelection && !this.overCard))   // [engines]
                    if (underCursor && !this.overCard) {
                        ::UI.pushStyle(this.scope)
                        ::UI.pushStyle(::EX.ghostStyle())
                        ::UI.tooltipAt(this.rect[0], this.rect[1], this.rect[2], this.rect[3])
                        ::UI.tooltip(0, this.text != "" ? this.text : " ")
                        ::UI.popStyle()
                        ::UI.popStyle()
                    }
                } else if (this.text != "" && "ghostStyle" in ::EX) {
                    // [ui-look] The engine tooltip is still raised, invisibly, so the game keeps its
                    // native unit tooltip hidden; the visible box is drawn with the label text path.
                    // Not over a unit card: the hover box it registers at the cursor would take the
                    // click the card needs, and the cards then cannot be selected. Not for a card
                    // that shows a selected unit either: nothing under the cursor needs hiding.
                    if (!this.overCard && !this.fromSelection) {
                        ::UI.pushStyle(this.scope)
                        ::UI.pushStyle(::EX.ghostStyle())
                        ::UI.tooltipAt(this.rect[0], this.rect[1], this.rect[2], this.rect[3])
                        ::UI.tooltip(0, this.text)
                        ::UI.popStyle()
                        ::UI.popStyle()
                    }
                    if (this.style.cardOn) this.drawVisible()   // [card-off]
                } else if (this.text != "") {
                    ::UI.pushStyle(this.scope)
                    ::UI.pushStyle({ [::UI.Colour.tooltipBorder] = this.edge })
                    ::UI.tooltipAt(this.rect[0], this.rect[1], this.rect[2], this.rect[3])
                    ::UI.tooltip(0, this.text)
                    ::UI.popStyle()
                    ::UI.popStyle()
                }
                this.drawHover()   // [hover-label] alongside the card
                // [space-tips] While Space is held the game puts its unit cards over the troops, and
                // hovering one of those raises the game's own tooltip - over a card the battle pick
                // names no unit, so none of the hidden tooltips above was raised. Held down, the
                // hidden tooltip now goes up at the cursor every frame, whatever is under it, so the
                // game's own never shows (as native_tooltips.nut does over the campaign windows).
                // [veil] and, with veilAlways, whenever the cursor is on the battlefield at all: the
                // game's tooltips on artillery, rams, ladders and towers (which M2EX's pick does not
                // report) never show; what we could not name gets the cursor hint, if any, instead.
                if (spaceKey || (this.style.veilAlways && !this.overOurHud())) this.veilNative()
                if (this.style.veilAlways && this.text == "" && this.frame != null && this.frame.hint != ""
                    && "drawTip" in ::EX && !this.overOurHud()) {
                    local hint = this.frame.hint
                    local st = this.style
                    local draw = function () { ::EX.tipPlaceWith = null; ::EX.drawTip(hint, st.background, st.borderNone, st.ink) }
                    if ("onTop" in ::EX) ::EX.onTop(draw)
                    else draw()
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
            ::options.failHdFeature(::Enum.HdFeature.battleTooltips)
            println("squi: battle tooltips STOOD DOWN - " + fault)
        }
    }
}

local battleTooltips = BattleTooltips()
foreach (pair in [["cardPosition", "position"], ["cardTrigger", "trigger"], ["cardShows", "shows"]]) {
    if (pair[1] in UNIT_CARD) battleTooltips.style[pair[0]] = UNIT_CARD[pair[1]]
}
// [menu] the panel's rules from the start too: the card in the corner, Sticky or Mouse Over, no
// order hints, damaged walls and gates always named
battleTooltips.style.cardPosition = 1
if (battleTooltips.cardNumber("cardShows") == 3) battleTooltips.style.cardShows = 1
battleTooltips.style.showHint = false
battleTooltips.hoverStyle.showHint = false
battleTooltips.style.showBuilding = true
if ("menuKey" in UNIT_CARD) battleTooltips.menuKeyName = UNIT_CARD.menuKey            // [menu]
if ("menuShortcut" in UNIT_CARD) battleTooltips.menuShortcutName = UNIT_CARD.menuShortcut
if ("logKeys" in UNIT_CARD) battleTooltips.logKeys = UNIT_CARD.logKeys != 0
if ("remember" in UNIT_CARD) battleTooltips.menuRemember = UNIT_CARD.remember != 0
battleTooltips.open()
try { battleTooltips.claimMenuShortcut() } catch (e) { println("squi: [menu] could not take the shortcut - " + e) }

local battleTooltipsCanvas = ::UI.canvas("##battle_tooltipscanvas", 0, 0, 4, 4)
::UI.setWidgetStyle(battleTooltipsCanvas, ::UI.Cap.autoScaleCanvas, 0)
::UI.onDraw(battleTooltipsCanvas, function() { battleTooltips.render() })
::UI.widgetUnderlay(battleTooltipsCanvas, true)

::UI.onResize(function(w, h) { battleTooltips.open() })

::EX.battleTooltips <- battleTooltips
