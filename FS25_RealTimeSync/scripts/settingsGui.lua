--
-- Settings GUI
--

SettingsGui = {}

local SettingsGui_mt = Class(SettingsGui, TabbedMenu)

function SettingsGui:new(messageCenter, l18n, inputManager)
    local self = TabbedMenu.new(nil, SettingsGui_mt, messageCenter, l18n, inputManager)

    rtDebug("SettingsGui - new")

    self.messageCenter = messageCenter
    self.l18n          = l18n
    self.inputManager  = g_inputBinding

    return self
end

function SettingsGui:onGuiSetupFinished()
    
    rtDebug("SettingsGui - onGuiSetupFinished")

    SettingsGui:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

    self.pageInfo:initialize()
    self.pageTimeSync:initialize()

    self:initData()

    self:setupPages(self)

    self:setupMenuButtonInfo(self)

end

function SettingsGui:setupPages(gui)

    rtDebug("SettingsGui - setupPages")

    local pages = {
        {gui.pageInfo,       'gui.icon_options_help2'},
        {gui.pageTimeSync,   'gui.icon_ingameMenu_calendar'},
    }

    for idx, thisPage in ipairs(pages) do
        local page, icon  = unpack(thisPage)

        gui:registerPage(page, idx)

        gui:addPageTab(page, nil, nil, icon)

    end
    gui:rebuildTabList()

end

function SettingsGui:initData()
  rtDebug("SettingsGui:initData")
end

function SettingsGui:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback;

    self.defaultMenuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK,
            text        = g_i18n:getText("button_back"),
            callback    = onButtonBackFunction
        },
        {
            inputAction = InputAction.MENU_ACTIVATE,
            text        = g_i18n:getText("button_back"),
            callback    = onButtonBackFunction
        }
    }

    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK]     = self.defaultMenuButtonInfo[1]

    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
    }
end

function SettingsGui:exitMenu()
    rtDebug("SettingsGui:exitMenu")
    self:initData()
    self:changeScreen()
end
