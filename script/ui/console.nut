local backends       = ["console", "squirrel", "lua", "campaign"]
local defaultBackend = "console"

local Console = class {
    // Pixels, drawn as authored: the windows carry Cap.autoScale 0 and nothing here is scaled.
    metrics = {
        windowW         = 550,
        windowH         = 450,
        windowX         = 0,
        windowY         = 0,
        fallbackScreenW = 1920,
        tabHeight       = 24,
        tabGap          = 4,
        rowGap          = 6,
        minViewHeight   = 40,
        buttonHeight    = 26,
        buttonGap       = 8,
        autoclearHeight = 22,
        autoclearTop    = 2,
    }

    style = {
        windowFlags         = [::UI.WindowFlag.absoluteChildren, ::UI.WindowFlag.hidable,
                               ::UI.WindowFlag.noScrollBodyY],
        outputFlags         = [::UI.WindowFlag.stackVertical, ::UI.WindowFlag.hidable,
                               ::UI.WindowFlag.noScrollBodyY],
        windowBackground    = [22, 24, 30, 245],
        tabSelected         = [70, 92, 130, 255],
        tabIdle             = [42, 52, 68, 255],
        button              = [45, 55, 72, 255],
        text                = [255, 255, 255, 255],
        maxOutputLines      = 4000,
        outputDropBlock     = 512,
        historyDepth        = 50,
        pumpLinesPerFrame   = 500,
        pumpTagStart        = 13,
        pumpTagEnd          = 20,
        pumpScriptTag       = "[script",
        pumpIgnoredMessage  = "'[console]' failed",
    }

    inputWindow      = null
    outputWindow     = null
    outputLog        = null
    searchBox        = null
    filter           = ""
    outputLines      = null
    backendTabs      = null
    backend          = null
    editor           = null
    runButton        = null
    clearButton      = null
    clearLogButton   = null
    autoclearBox     = null
    autoclear        = true
    shown            = false
    placed           = false
    focusedFor       = null
    // One recall list per backend, newest last. The editor walks whichever one it is given.
    past             = null

    constructor() {
        this.backend          = defaultBackend
        this.backendTabs      = []
        this.outputLines      = []
        this.past             = {}
        foreach (name in backends) {
            this.past[name] <- []
        }

        this.buildInputWindow()
        this.buildOutputWindow()
        ::syslog.start(false)

        this.paintTabs()
        ::UI.widgetVisible(this.inputWindow,  false)
        ::UI.widgetVisible(this.outputWindow, false)
        ::UI.setParent(0)
    }

    function buildInputWindow() {
        local self = this

        ::UI.pushStyle({ [::UI.Cap.autoScale] = 0 })
        this.inputWindow = ::UI.window("Console  -  input", this.metrics.windowW, this.metrics.windowH, this.metrics.windowX, this.metrics.windowY, this.style.windowFlags)
        ::UI.popStyle()

        ::UI.setWidgetStyle(this.inputWindow, ::UI.Surface.window, this.style.windowBackground)
        ::UI.windowOnHide(this.inputWindow, function() { self.shown = false })

        foreach (name in backends) {
            local tab = ::UI.button(name)
            ::UI.buttonClick(tab, function() { self.backend = name; self.paintTabs() })
            ::UI.addChild(this.inputWindow, tab)
            this.backendTabs.append(tab)
        }

        this.editor = ::UI.inputMultiline()
        ::UI.inputMultilineSubmit(this.editor, function() { self.run() })
        ::UI.addChild(this.inputWindow, this.editor)

        this.runButton      = ::UI.button("Run")
        this.clearButton    = ::UI.button("Clear")
        this.clearLogButton = ::UI.button("Clear log")
        ::UI.buttonClick(this.runButton,      function() { self.run() })
        ::UI.buttonClick(this.clearButton,    function() { ::UI.inputMultilineClear(self.editor) })
        ::UI.buttonClick(this.clearLogButton, function() { self.clearOutput() })

        foreach (button in [this.runButton, this.clearButton, this.clearLogButton]) {
            ::UI.setWidgetStyle(button, ::UI.Surface.button, this.style.button); ::UI.setWidgetStyle(button, ::UI.Colour.text, this.style.text)
            ::UI.addChild(this.inputWindow, button)
        }

        this.autoclearBox = ::UI.checkbox("autoclear")
        ::UI.checkboxValue(this.autoclearBox, 1)
        ::UI.bind(this.autoclearBox, this, "autoclear")
        ::UI.addChild(this.inputWindow, this.autoclearBox)
    }

    function buildOutputWindow() {
        local self = this

        ::UI.pushStyle({ [::UI.Cap.autoScale] = 0 })
        this.outputWindow = ::UI.window("Console  -  output", this.metrics.windowW, this.metrics.windowH, this.metrics.windowX, this.metrics.windowY, this.style.outputFlags)
        ::UI.popStyle()

        ::UI.setWidgetStyle(this.outputWindow, ::UI.Surface.window, this.style.windowBackground)
        ::UI.windowOnHide(this.outputWindow, function() { self.shown = false })

        // Top-to-bottom stack: the search box keeps its own height, the log takes the rest.
        this.searchBox = ::UI.input("###consoleFilter")
        ::UI.inputPlaceholder(this.searchBox, "filter…")
        ::UI.inputChange(this.searchBox, function(text) { self.setFilter(text) })
        ::UI.addChild(this.outputWindow, this.searchBox)
        ::UI.widgetRect(this.searchBox, 0, 0, 0, this.metrics.tabHeight)

        this.outputLog = ::UI.textOutput("##consoletextOutput")
        ::UI.addChild(this.outputWindow, this.outputLog)
        ::UI.constraints(this.outputLog, 0, this.metrics.minViewHeight, 0, 0)
        ::UI.flexGrow(this.outputLog, 1)
    }

    function paintTabs() {
        foreach (index, tab in this.backendTabs) {
            local fill = (backends[index] == this.backend) ? this.style.tabSelected : this.style.tabIdle
            ::UI.setWidgetStyle(tab, ::UI.Surface.button, fill); ::UI.setWidgetStyle(tab, ::UI.Colour.text, this.style.text)
        }

        // Console tab only: Enter runs and Ctrl+Enter breaks the line.
        ::UI.setFlag(this.editor, ::UI.InputFlag.ctrlEnterNewline, this.backend == "console")
        this.armHistory()
    }

    function run() {
        local code = ::UI.inputMultilineTextGet(this.editor)
        if (code == "") return

        this.appendOutput("[" + this.backend + "] > " + code + "\n")

        this.remember(code)

        local result = ::UI.eval(this.backend, code)
        if (result != "") {
            if (result[result.len() - 1] != '\n') result += "\n"
            this.appendOutput(result)
        }

        if (this.autoclear) ::UI.inputMultilineClear(this.editor)
    }

    // Newest last, no immediate duplicate, oldest dropped once past the depth.
    function remember(code) {
        local list = this.past[this.backend]
        if (list.len() == 0 || list[list.len() - 1] != code) {
            list.append(code)
            while (list.len() > this.style.historyDepth) {
                list.remove(0)
            }
        }
        this.armHistory()
    }

    // Only the console tab recalls; the scripting backends keep Up/Down as plain line movement.
    function armHistory() {
        ::UI.inputMultilineHistory(this.editor, this.backend == "console" ? this.past[this.backend] : [])
    }

    function setFilter(text) {
        this.filter = (text == null) ? "" : text.tolower()
        this.refilter()
    }

    function matches(text) {
        if (this.filter == "") return true
        return text.tolower().indexof(this.filter) != null
    }

    function appendOutput(text) {
        this.outputLines.append(text)
        if (this.outputLines.len() > this.style.maxOutputLines) {
            this.outputLines = this.outputLines.slice(this.style.outputDropBlock)
        }
        if (this.matches(text)) ::UI.textOutputAppend(this.outputLog, text)
    }

    function refilter() {
        ::UI.textOutputClear(this.outputLog)
        foreach (text in this.outputLines) {
            if (this.matches(text)) ::UI.textOutputAppend(this.outputLog, text)
        }
    }

    function clearOutput() {
        this.outputLines.clear()
        ::UI.textOutputClear(this.outputLog)
    }

    function toggle() {
        if (::UI.context() & ::Enum.UiContext.noGame) return

        this.shown = !this.shown

        if (this.shown && !this.placed) {
            local screen = ::UI.screenSize()
            local screenWidth = (screen != null && screen[0] > 0) ? screen[0] : this.metrics.fallbackScreenW

            ::UI.widgetRect(this.inputWindow,  this.metrics.windowX, this.metrics.windowY, this.metrics.windowW, this.metrics.windowH)
            ::UI.widgetRect(this.outputWindow, screenWidth - this.metrics.windowW - this.metrics.windowX, this.metrics.windowY, this.metrics.windowW, this.metrics.windowH)
            this.placed = true
        }

        ::UI.widgetVisible(this.inputWindow,  this.shown)
        ::UI.widgetVisible(this.outputWindow, this.shown)
    }

    function pumpSystemLog() {
        if (::syslog.pending() == 0) return

        foreach (line in ::syslog.poll(this.style.pumpLinesPerFrame)) {
            if (line.len() > this.style.pumpTagEnd
                && line.slice(this.style.pumpTagStart, this.style.pumpTagEnd) == this.style.pumpScriptTag
                && line.indexof(this.style.pumpIgnoredMessage) == null) {
                this.appendOutput(line + "\n")
            }
        }
    }

    function renderInputWindow() {
        local body = ::UI.contentRect(this.inputWindow)
        if (body == null) return

        local left = body[0], top = body[1], width = body[2], height = body[3]

        local tabWidth = (width - (this.backendTabs.len() - 1) * this.metrics.tabGap) / this.backendTabs.len()
        foreach (index, tab in this.backendTabs) {
            ::UI.widgetRect(tab, left + index * (tabWidth + this.metrics.tabGap), top, tabWidth, this.metrics.tabHeight)
        }

        local rowY = top + height - this.metrics.buttonHeight
        local x = left

        foreach (button in [this.runButton, this.clearButton, this.clearLogButton]) {
            ::UI.widgetRect(button, x, rowY, 0, this.metrics.buttonHeight)
            x += ::UI.naturalSize(button)[0] + this.metrics.buttonGap
        }

        ::UI.widgetRect(this.autoclearBox, x, rowY + this.metrics.autoclearTop, 0, this.metrics.autoclearHeight)

        local editorTop = top + this.metrics.tabHeight + this.metrics.rowGap
        local editorHeight = rowY - editorTop - this.metrics.rowGap
        ::UI.widgetRect(this.editor, left, editorTop, width,
                        editorHeight > this.metrics.minViewHeight ? editorHeight : this.metrics.minViewHeight)
    }

    function render() {
        this.pumpSystemLog()
        if (::UI.context() & ::Enum.UiContext.noGame) this.shown = false

        ::UI.widgetVisible(this.inputWindow,  this.shown)
        ::UI.widgetVisible(this.outputWindow, this.shown)
        if (!this.shown) {
            ::UI.inputMultilineFocus(this.editor, false)
            this.focusedFor = null
            return
        }

        // The console tab is a prompt, so it takes the keyboard as soon as it is the one on show.
        if (this.focusedFor != this.backend) {
            this.focusedFor = this.backend
            ::UI.inputMultilineFocus(this.editor, this.backend == "console")
        }

        this.renderInputWindow()

        ::UI.raise(this.outputWindow)
        ::UI.raise(this.inputWindow)
    }


}

local console = Console()

::UI.keyboard.shortcut("show_console", function(name) {
    if (::UI.context() & ::Enum.UiContext.noGame) return false
    console.toggle()
})

::UI.onFrame(function() { console.render() })

::EX.console <- console
