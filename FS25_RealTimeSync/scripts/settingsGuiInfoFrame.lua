--
-- Settings GUI Info Frame
--

SettingsGuiInfoFrame = {}

local SettingsGuiInfoFrame_mt = Class(SettingsGuiInfoFrame, TabbedMenuFrameElement)

function SettingsGuiInfoFrame:new(subclass_mt, l10n)
    local self = SettingsGuiInfoFrame:superClass().new(nil, subclass_mt or SettingsGuiInfoFrame_mt)

    rtDebug("SettingsGuiInfoFrame-new")

    self.messageCenter      = g_messageCenter
    self.l10n               = l10n
    self.isMPGame           = g_currentMission.missionDynamicInfo.isMultiplayer

    return self
end

function SettingsGuiInfoFrame:copyAttributes(src)
    SettingsGuiInfoFrame:superClass().copyAttributes(self, src)

    self.ui   = src.ui
    self.l10n = src.l10n
end


function SettingsGuiInfoFrame:initialize()
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
end


function SettingsGuiInfoFrame:onGuiSetupFinished()
    SettingsGuiInfoFrame:superClass().onGuiSetupFinished(self)

end


function SettingsGuiInfoFrame:delete()
    SettingsGuiInfoFrame:superClass().delete(self)
    self.messageCenter:unsubscribeAll(self)
end


function SettingsGuiInfoFrame:updateMenuButtons()


    self.menuButtonInfo = {}
    self.menuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK
        }
    }

    self:setMenuButtonInfoDirty()
end


function SettingsGuiInfoFrame:onFrameOpen()
    SettingsGuiInfoFrame:superClass().onFrameOpen(self)

    rtDebug("SettingsGuiInfoFrame:onFrameOpen")

end


function SettingsGuiInfoFrame:onRefreshEvent()

end


function SettingsGuiInfoFrame:onFrameClose()
    SettingsGuiInfoFrame:superClass().onFrameClose(self)

    self.messageCenter:unsubscribeAll(self)
end