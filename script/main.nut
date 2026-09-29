::EX <- {}
::M2EX <- ::EX

local MODULES = [
    "core.fonts",
    "core.styles",
    "core.images",
    "core.scale",
    "core.theme",
    "ui.hud_pane",
    "ui.console",
    //"ui.unit_stats.sidebar",
]

// The script console ships in Retail: it takes the console shortcut from the native one.
// The double-click camera jump stays developer-only.
if (::scripting.devBuild) {
    MODULES.append("ui.camera")
}

local failed = []
foreach (name in MODULES) {
    try {
        require(name)
    }
    catch (e) {
        failed.append(name)
        println("squi: MODULE FAILED [" + name + "] " + e)
    }
}

if (failed.len() == 0) {
    println("squi: loaded")
} else {
    local list = ""
    foreach (i, name in failed) list += (i == 0 ? "" : ", ") + name
    println("squi: loaded with " + failed.len() + " module(s) SKIPPED: " + list)
}

// The HD features, each a list of modules loaded when its context stands up.
local SECTIONS = [
    { name = "hd_labels", context = "campaign", feature = ::Enum.HdFeature.labels, modules = [
          "ui.campaign.labels.settlement_labels",
          "ui.campaign.labels.fort_labels",
          "ui.campaign.labels.character_labels",
      ] },

    { name = "hd_tooltips", context = "campaign", feature = ::Enum.HdFeature.tooltips, modules = [
          "ui.campaign.tooltips.strat_tooltips",
      ] },

    { name = "hd_battle_tooltips", context = "battle", feature = ::Enum.HdFeature.battleTooltips, modules = [
          "ui.battle.tooltips.battle_tooltips",
      ] },

    { name = "hd_battle_hud", context = "battle", feature = ::Enum.HdFeature.battleHud, modules = [
          "ui.battle.hud.shortcuts",
          "ui.battle.hud.battle_hud",
          "ui.battle.hud.radar",
          "ui.battle.hud.ui_cards",
      ] },

    { name = "hd_campaign_hud", context = "campaign", feature = ::Enum.HdFeature.campaignHud, modules = [
          "ui.campaign.hud.campaign_hud",
          "ui.campaign.hud.radar",
          "ui.campaign.hud.ui_cards",
      ] },

    { name = "hd_events", context = "campaign", feature = ::Enum.HdFeature.events, modules = [
          "ui.events.event_icons",
          "ui.events.event_scroll",
      ] },

    { name = "hd_events", context = "battle", feature = ::Enum.HdFeature.events, modules = [
          "ui.events.event_icons",
          "ui.events.event_scroll",
      ] },
]

local state = { campaign = false, mods = false, battleWatch = -1 }

// Requires every .nut under script/modules, once, after the first context's sections.
local function loadMods() {
    if (state.mods) return
    state.mods = true
    try {
        foreach (name in ::scripting.listModules("modules")) {
            try {
                require(name)
                println("squi: mod loaded [" + name + "]")
            }
            catch (e) {
                println("squi: MOD FAILED [" + name + "] " + e)
            }
        }
    }
    catch (e) {
        println("squi: mod scan unavailable - " + e)
    }
}

// Requires the modules of every section belonging to this context.
local function loadSections(context) {
    foreach (section in SECTIONS) {
        if (section.context != context) continue
        foreach (name in section.modules) {
            try {
                require(name)
            }
            catch (e) {
                ::options.failHdFeature(section.feature)
                println("squi: " + section.name + " STOOD DOWN for this run - module [" + name + "] failed: " + e)
                println("squi: the preference is untouched; the engine's own UI takes over")
                break
            }
        }
    }
    loadMods()
}

::events.on("campaignMapLoaded", function () {
    if (state.campaign) return
    state.campaign = true
    loadSections("campaign")
})

// Stands the battle sections up on the first battle frame, then stops watching.
state.battleWatch = ::UI.onFrame(function () {
    if (!(::UI.context() & (::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded))) return
    ::UI.offFrame(state.battleWatch)
    loadSections("battle")
})
