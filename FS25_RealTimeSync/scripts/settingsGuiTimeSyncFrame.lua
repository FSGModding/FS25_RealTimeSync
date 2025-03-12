--
-- Setting GUI Time Sync Frame
--

SettingsGuiTimeSyncFrame = {}

local SettingsGuiTimeSyncFrame_mt = Class(SettingsGuiTimeSyncFrame, TabbedMenuFrameElement)

function SettingsGuiTimeSyncFrame:new(subclass_mt, l10n)
    local self = SettingsGuiTimeSyncFrame:superClass().new(nil, subclass_mt or SettingsGuiTimeSyncFrame_mt)

    rtDebug("SettingsGuiTimeSyncFrame-new")

    self.messageCenter      = g_messageCenter
    self.l10n               = l10n
    self.isMPGame           = g_currentMission.missionDynamicInfo.isMultiplayer

    return self
end


function SettingsGuiTimeSyncFrame:copyAttributes(src)
    SettingsGuiTimeSyncFrame:superClass().copyAttributes(self, src)

    self.ui   = src.ui
    self.l10n = src.l10n
end


function SettingsGuiTimeSyncFrame:initialize()
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
end


function SettingsGuiTimeSyncFrame:onGuiSetupFinished()
    SettingsGuiTimeSyncFrame:superClass().onGuiSetupFinished(self)

end


function SettingsGuiTimeSyncFrame:delete()
    SettingsGuiTimeSyncFrame:superClass().delete(self)
    self.messageCenter:unsubscribeAll(self)
end


function SettingsGuiTimeSyncFrame:updateMenuButtons()


    self.menuButtonInfo = {}
    self.menuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK
        }
    }

    self:setMenuButtonInfoDirty()
end


function SettingsGuiTimeSyncFrame:onFrameOpen()
    SettingsGuiTimeSyncFrame:superClass().onFrameOpen(self)

    rtDebug("SettingsGuiTimeSyncFrame:onFrameOpen")

    -- Load Settings
    g_realTimeSync.settings:loadSettings()

    self.isOpening = true

    -- Reload the settings
    self:updateSettings()

    -- Show the stuffs
		self.rtsSettingsLayout:setVisible(true)
		self.rtsSettingsLayout:invalidateLayout()

    -- Alternates the background colors
    local set = true
    for _, tableRow in pairs(self.rtsSettingsLayout.elements) do
      if tableRow.name == "sectionHeader" or tableRow.name == "rtsSettingsNoPermissionText" then
        set = true
      elseif tableRow:getIsVisible() then
        local color = InGameMenuSettingsFrame.COLOR_ALTERNATING[set]
        tableRow:setImageColor(nil, unpack(color))
        set = not set
      end
    end

    self.rtsSettingsNoPermissionText:setVisible(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)


end


function SettingsGuiTimeSyncFrame:onRefreshEvent()

end


function SettingsGuiTimeSyncFrame:onFrameClose()
    SettingsGuiTimeSyncFrame:superClass().onFrameClose(self)

    self.messageCenter:unsubscribeAll(self)
end

function SettingsGuiTimeSyncFrame:updateSettings()
  rtDebug("SettingsGuiTimeSyncFrame:updateSettings")

  local timeSyncEnable = g_realTimeSync.settings:getValue("timeSyncEnable")
  self.updateTimeSyncEnable:setIsChecked(timeSyncEnable, self.isOpening)
  self.updateTimeSyncEnable:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)
  
  local serverOffset = g_realTimeSync.settings:getValue("serverOffset")
  self.updateTimeSyncServerOffset:setState(serverOffset)
  self.updateTimeSyncServerOffset:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local timeFixHour = g_realTimeSync.settings:getValue("timeFixHour")
  self.updateTimeSyncTimeFixHour:setState(timeFixHour)
  self.updateTimeSyncTimeFixHour:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local autoSetTime = g_realTimeSync.settings:getValue("autoSetTime")
  self.updateTimeSyncAutoSetTime:setIsChecked(autoSetTime, self.isOpening)
  self.updateTimeSyncAutoSetTime:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local progressNoti = g_realTimeSync.settings:getValue("progressNoti")
  self.updateTimeSyncProgressNotification:setIsChecked(progressNoti, self.isOpening)
  self.updateTimeSyncProgressNotification:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

end

function SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncEnable(state)
  rtDebug("SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncEnable")
  g_realTimeSync.settings:setValue(
    "timeSyncEnable",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_realTimeSync.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rtDebug('SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncEnable: ')
    rtDebug(state)

    SettingEvent.sendEvent(2, "timeSyncEnable", state)
  end
end

function SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncServerOffset(state)
  rtDebug("SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncServerOffset")
  g_realTimeSync.settings:setValue("serverOffset",state)
  g_realTimeSync.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rtDebug('SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncServerOffset: ')
    rtDebug(state)

    SettingEvent.sendEvent(3, "serverOffset", state)
  end
end

function SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncTimeFixHour(state)
  rtDebug("SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncTimeFixHour")
  g_realTimeSync.settings:setValue("timeFixHour",state)
  g_realTimeSync.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rtDebug('SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncTimeFixHour: ')
    rtDebug(state)

    SettingEvent.sendEvent(3, "timeFixHour", state)
  end
end

function SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncAutoSetTime(state)
  rtDebug("SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncAutoSetTime")
  g_realTimeSync.settings:setValue(
    "autoSetTime",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_realTimeSync.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rtDebug('SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncAutoSetTime: ')
    rtDebug(state)

    SettingEvent.sendEvent(2, "autoSetTime", state)
  end
end

function SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncProgressNotification(state)
  rtDebug("SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncProgressNotification")
  g_realTimeSync.settings:setValue(
    "progressNoti",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_realTimeSync.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rtDebug('SettingsGuiTimeSyncFrame:onClickUpdateTimeSyncProgressNotification: ')
    rtDebug(state)

    SettingEvent.sendEvent(2, "progressNoti", state)
  end
end