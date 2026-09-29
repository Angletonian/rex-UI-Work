local BattleShortcuts = class {
    style = {
        claimed = true,
        maxStrikes = 8,
    }

    bound = null
    hidden = false
    // [hud-toggles] The native toggle keys hide pieces of the native HUD, which M2EX keeps out of
    // focus while the HD battle HUD is on, so they did nothing visible. These flags hide the HD pieces.
    hide = { cards = false, buttons = false, radar = false }
    toggleNames = {
        toggle_cards = "cards", toggle_unit_cards = "cards",
        toggle_buttons = "buttons",
        toggle_radar = "radar",
    }
    logged = false
    state = { verified = false, down = false, strikes = 0 }

    function open() {
        if (this.bound != null) {
            return
        }
        this.bound = {}
        foreach (name, method in { toggle_fire_at_will = "fireAtWill",
                                   toggle_skirmish = "skirmish",
                                   toggle_defend = "guard",
                                   toggle_run = "run",
                                   toggle_formation_tightness = "closeFormation",
                                   toggle_special_ability = "specialAbility",
                                   order_withdraw = "withdraw",
                                   order_halt = "halt",
                                   toggle_auto_link_up = "groupAi",
                                   hide_gui = "hideGui",
                                   toggle_pause_button = "playPause",
                                   pause_button = "playPause" }) {   // Rome's name for the same key
            this.bound[name] <- method
        }
        foreach (name, group in this.toggleNames) {
            this.bound[name] <- "hide:" + group
        }
        this.claim()
    }

    // Hands every mapped key, and the eight formation keys, to this module's handlers.
    function claim() {
        foreach (name, method in this.bound) {
            ::UI.keyboard.shortcut(name, function (name) { return this.fire(method) }.bindenv(this))
        }
        for (local i = 0; i < 8; i++) {
            local index = i
            ::UI.keyboard.shortcut("formation_" + (index + 1), function (name) {
                return this.formation(index)
            }.bindenv(this))
        }
    }

    // Live only while the script hud owns the battle; otherwise the engine's own handler should run.
    function active() {
        if (!this.style.claimed) {
            return false
        }
        if (!(::UI.context() & (::Enum.UiContext.battleLive | ::Enum.UiContext.battleEnded))) {
            return false
        }
        return ::options.hdFeature(::Enum.HdFeature.battleHud)
    }

    function verify() {
        if (this.bound == null || this.bound.len() == 0) {
            return false
        }
        foreach (name, method in this.bound) {
            if (typeof(method) != "string" || method == "") {
                return false
            }
        }
        if (::UI.keyboard == null || ::UI.keyboard.shortcut == null) {
            return false
        }
        if (::options.hdFeature == null || ::options.failHdFeature == null) {
            return false
        }
        if (::ui.cardManager == null) {
            return false
        }
        return ::battle.selection != null && ::battle.selection.setGroupFormation != null
    }

    function fire(method) {
        if (this.state.down) {
            return false
        }
        if (!this.active()) {
            return false
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

        local handled = false
        if (fault == "") {
            try {
                if (method == "hideGui") {
                    this.hidden = !this.hidden
                    handled = true
                } else if (method.len() > 5 && method.slice(0, 5) == "hide:") {
                    local group = method.slice(5)
                    this.hide[group] = !this.hide[group]
                    println("squi: [hud-toggles] " + group + (this.hide[group] ? " hidden" : " shown"))
                    handled = true
                } else if ("battleHud" in ::EX) {
                    ::EX.battleHud.runCommand(method)
                    handled = true
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
            println("squi: battle shortcuts STOOD DOWN - " + fault)
        }

        return handled
    }

    // True while the player has toggled that part of the HD battle HUD off.
    function isHidden(group) {
        return group in this.hide && this.hide[group]
    }

    // Once per session, on the first battle frame: write the battle's toggle shortcuts to
    // system.log.txt, so the names bound above can be checked against the game's own.
    function logShortcuts() {
        if (this.logged || !(::UI.context() & ::Enum.UiContext.battleLive)) {
            return
        }
        this.logged = true
        try {
            foreach (row in ::UI.keyboard.shortcuts()) {
                local r = row.tolower()
                if (r.indexof("toggle") != null || r.indexof("radar") != null || r.indexof("card") != null
                    || r.indexof("hud") != null || r.indexof("gui") != null) {
                    println("squi: [hud-toggles] shortcut " + row)
                }
            }
        }
        catch (e) {
            println("squi: [hud-toggles] could not list shortcuts - " + e)
        }
    }

    function formation(index) {
        if (this.state.down) {
            return false
        }
        if (!this.active()) {
            return false
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

        local handled = false
        if (fault == "") {
            try {
                if (::ui.cardManager().selectedGroupCount != 0) {
                    ::battle.selection.setGroupFormation(index)
                    handled = true
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
            println("squi: battle shortcuts STOOD DOWN - " + fault)
        }

        return handled
    }
}

local battleShortcuts = BattleShortcuts()
battleShortcuts.open()
local shortcutLogId = null
shortcutLogId = ::UI.onFrame(function() {
    battleShortcuts.logShortcuts()
    if (battleShortcuts.logged) { ::UI.offFrame(shortcutLogId) }
})

::EX.battleShortcuts <- battleShortcuts
