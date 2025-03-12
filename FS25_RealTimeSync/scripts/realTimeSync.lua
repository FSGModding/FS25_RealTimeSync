rtDebug("RealTimeSync Class")

RealTimeSync = {}
RealTimeSync.modName = g_currentModName
RealTimeSync.modDirectory = g_currentModDirectory
RealTimeSync.baseXmlKey = "RealTimeSync"
RealTimeSync.xmlKey = RealTimeSync.baseXmlKey.."."

local RealTimeSync_mt = Class(RealTimeSync, Event)

InitEventClass(RealTimeSync, "RealTimeSync")

function RealTimeSync.new(mission, i18n, modDirectory, modName)
  rtDebug("RealTimeSync-New")
  local self = setmetatable({}, RealTimeSync_mt)
  self.mission                = mission
  self.i18n                   = i18n
  self.modDirectory           = modDirectory
  self.modName                = modName
  self.isServer               = g_currentMission:getIsServer()
  self.justSetFalse           = false
  self.speedFix               = false
  self.setValueTimerFrequency = 60
  self.ServerUpdate           = false
  self.ServerHour             = 0
  self.ServerMinCleanUTC      = 0
  self.TimeSpeed              = 1
  self.displayMessage         = 1
  self.serverMin              = 0

  -- Load mod default settings
  self.settings = FS25PrefSaver:new(
    "FS25_RealTimeSync",
    "RealTimeSync.xml",
    false,
    {
      progressNoti        = {true, "bool"},
      timeSyncEnable      = {true, "bool"},
      serverOffset        = {1, "int"},
      timeFixHour         = {1, "int"},
      autoSetTime         = {false, "bool"},
    },
		nil,
		nil
  )

	return self
end

-- Run on map load
-- FS25 - There is a new way to load menus.  Will have to come back to this.
function RealTimeSync:loadMap(filename)
  rtDebug(" Info: RealTimeSync-loadMap")

	self.settings:loadSettings()
	self.settings:saveSettings()

  local InfoFrame = SettingsGuiInfoFrame:new(nil, g_i18n)
  local TimeSyncFrame = SettingsGuiTimeSyncFrame:new(nil, g_i18n)

  g_gui:loadProfiles(RealTimeSync.modDirectory .. "xml/guiProfiles.xml")

  RealTimeSync.gui = SettingsGui:new(g_messageCenter, g_i18n, g_inputBinding)

  g_gui:loadGui(RealTimeSync.modDirectory .. "xml/settingsGuiInfoFrame.xml", "SettingsGuiInfoFrame", InfoFrame, true)
  g_gui:loadGui(RealTimeSync.modDirectory .. "xml/settingsGuiTimeSyncFrame.xml", "SettingsGuiTimeSyncFrame", TimeSyncFrame, true)
  g_gui:loadGui(RealTimeSync.modDirectory .. "xml/settingsGui.xml", "SettingsGui", RealTimeSync.gui)

end

-- Register Player Interaction
function RealTimeSync:updateActionEvents()
  -- We have to run this often to work in MP
	local _, actionEventId = g_inputBinding:registerActionEvent('REAL_TIME_SYNC_MENU', self, RealTimeSync.actionAdditionalInfo_openGui, false, true, false, true)
	g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
  g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("REAL_TIME_SYNC_MENU"))
end

-- Load the gui
function RealTimeSync:actionAdditionalInfo_openGui(actionName, keyStatus, arg3, arg4, arg5)
  rtDebug(" Info: RealTimeSync - actionAdditionalInfo_openGui")
  if g_gui.currentGui == nil then
    -- Load the gui
    g_gui:showGui("SettingsGui")
  end
end

function RealTimeSync:update(dt)
  -- Register the button input
  RealTimeSync:updateActionEvents()

  -- Set Defaults
  local TimeDiff = 0
  local TimeSpeed = 1

  -- check if within the loopCount, and if server or single player.  Don't run on server clients.

  -- If the game timescale IS NOT 1x then run the time adjustments every 60 milliseconds. -- Myrithis (Catalyzer Industries)
  -- If the game timescale IS     1x then run the time adjustments every 10 minutes. -- Myrithis (Catalyzer Industries)
  if (g_currentMission.missionInfo.timeScale ~= 1 and g_updateLoopIndex % self.setValueTimerFrequency and RealTimeSync:singleServerCheck())
      or (g_updateLoopIndex % ((self.setValueTimerFrequency*60)*10) == 0 and RealTimeSync:singleServerCheck()) then

    self.settings:loadSettings()
    if self.settings:getValue("timeSyncEnable") == false then
      -- Check to see if just set as false.  if so then set speed to 1
      if self.justSetFalse == true then
        if RealTimeSync:isSinglePlayer() then
          g_currentMission.missionInfo.timeScale = 1
        else
          g_currentMission:setTimeScale(1);
        end
        self.justSetFalse = false
      end
      return
    else
      self.justSetFalse = true
    end
    -- Get server hour and min
    local getServerHour = getTime()
    -- Get current hour from time
    local getTotalHours = (getServerHour / 60) / 60
    local getTotalDays = (getTotalHours / 24) - math.floor(getTotalHours / 24)
    local ServerHour = math.floor(getTotalDays * 24)
    -- Get current minute from time
    local ServerMinuteUTC = ((getTotalDays * 24) - math.floor(getTotalDays * 24)) * 60
    local ServerMinCleanUTC = math.floor(ServerMinuteUTC)
    -- Setup the times so they work with game times
    local ServerMin = MathUtil.round(ServerMinuteUTC / 60, 2)
    local ServerTime = ServerHour + ServerMin
    -- Set defaults for later changed vars
    local AlwaysRun = false
    local SetServerTime = 0
    -- Convert timeFixHour to a read able format
    local setTimeFixHour = self.settings:getValue("timeFixHour")
    local setServerOffset = self.settings:getValue("serverOffset") - 11
    local setAutoSetTime = self.settings:getValue("autoSetTime")
    -- Start the time fix process if enabled
    rtDebug("setTimeFixHour: " .. setTimeFixHour)
    local runTimeFixHour = 1
    if setTimeFixHour == 1 then
      AlwaysRun = true;
    else
      runTimeFixHour = setTimeFixHour
      rtDebug("runTimeFixHour: " .. runTimeFixHour)
    end
    -- get the current hour with offset if one is set
    -- check if there is a time offset - if so then offset the server time so we can match the game time to that offset
    if type(setServerOffset) == "number" and setServerOffset ~= 0 then
      rtDebug("RealTimeSync:serverTimeBeforeOffset: " .. ServerHour + ServerMin)
      ServerHour = (ServerHour + setServerOffset);
    end
    -- check if timeFixHour is set and if so then check if that time matches current time.  Stop script if not 0 or hour matches
    if AlwaysRun == false and runTimeFixHour ~= tonumber(ServerHour) then
      rtDebug("RealTimeSync:TimeFixHour not Always and ServerHour does not match TimeFixHour: " .. ServerHour .. "~=" .. runTimeFixHour)
      -- Set the speed to 1 just in case server was not done fixing the time.
      if self.speedFix == true then
        if RealTimeSync:isSinglePlayer() then
          g_currentMission.missionInfo.timeScale = 1
        else
          g_currentMission:setTimeScale(1);
        end
        self.ServerUpdate = false -- Disable notification
        TimeSpeed = 1 -- Time scale speed
        self.speedFix = false
      end
      return
    end
    -- Get the game time for comparison 
    local GameHour = g_currentMission.environment.currentHour
    local GameMinute = g_currentMission.environment.currentMinute
    local GameMin = MathUtil.round(GameMinute / 60, 2)
    local GameTime = GameHour + GameMin
    -- Set the current server time with minutes added
    ServerTime = ServerHour + ServerMin;
    -- Check if ServerTime is greater than 24 and subtract if so so that it is not getting an invalid number
    if ServerTime > 24 then
      ServerTime = (ServerTime - 24)
    elseif ServerTime < 0 then
      ServerTime = (ServerTime + 24)
    end
    -- Time to set the game to if game is too far ahead of server time
    SetServerTime = ServerTime - 0.03

    -- get the time difference between server time and game time so we can see if we need to speed up or slow down
    TimeDiff = MathUtil.round(ServerTime - GameTime, 2);

    rtDebug("RealTimeSync:SetServerTime: " .. SetServerTime)
    rtDebug("RealTimeSync:ServerTime: " .. ServerTime)
    rtDebug("RealTimeSync:GameTime: " .. GameTime)
    rtDebug("RealTimeSync:TimeDiff: " .. TimeDiff)

    -- Set server time to global for notifications use
    self.ServerHour = ServerHour
    self.ServerMinCleanUTC = ServerMinCleanUTC

    -- Check if time if server time is greater than game time, if so then speed up time to catch up
    -- If server time is less than in game time, then pause time until caught up
    -- Need a 5 minute window to keep it from constantly changing

    -- Check if Game time is less than server time by more than 1 hour.  Speed time way up if so.
    if GameTime < ServerTime and TimeDiff > 1 then
      rtDebug("RealTimeSync:GameTime < ServerTime and time is off by more than an hour - speed up time x240")
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 240
      else
        g_currentMission:setTimeScale(240);
      end
      self.ServerUpdate = true -- Enable notification
      TimeSpeed = 240 -- Time scale speed

    -- Check if Game time is less than server time by more than 0.75 hours.  Speed time way up if so.
    elseif GameTime < ServerTime and TimeDiff > 0.75 then
      rtDebug("RealTimeSync:GameTime < ServerTime and time is off by more than an hour - speed up time x120")
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 120
      else
        g_currentMission:setTimeScale(120);
      end
      self.ServerUpdate = true -- Enable notification
      TimeSpeed = 120 -- Time scale speed

    -- Check if Game time is less than server time by more than 0.5 hours.  Speed time way up if so.
    elseif GameTime < ServerTime and TimeDiff > 0.5 then
      rtDebug("RealTimeSync:GameTime < ServerTime and time is off by more than an hour - speed up time x60")
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 60
      else
        g_currentMission:setTimeScale(60);
      end
      self.ServerUpdate = true -- Enable notification
      TimeSpeed = 60 -- Time scale speed

    -- Check if Game time is less than server time by more than 0.25 hours.  Speed time way up if so.
    elseif GameTime < ServerTime and TimeDiff > 0.25 then
      rtDebug("RealTimeSync:GameTime < ServerTime and time is off by more than an hour - speed up time x30")
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 30
      else
        g_currentMission:setTimeScale(30);
      end
      self.ServerUpdate = true -- enable notification
      TimeSpeed = 30 -- Time scale speed

    -- Check if Game time is less than server time.  Speed time up if so.
    elseif GameTime < ServerTime and TimeDiff > 0 then
      rtDebug("RealTimeSync:GameTime < ServerTime - speed up time x5")
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 5
      else
        g_currentMission:setTimeScale(5);
      end
      self.ServerUpdate = false -- disable notification
      TimeSpeed = 5 -- Time scale speed

    -- Check if Game time is greater than server time and set time is true.  Set the time to match
    elseif GameTime > ServerTime and TimeDiff < 0 and TimeDiff < -0.8 and setAutoSetTime == true then
      rtDebug("RealTimeSync:GameTime > ServerTime - slow way down time")

      -- Sets the time for current day
      local gameTime = SetServerTime * 1000 * 60 * 60
      local gameDayTime = math.floor(gameTime)
      g_currentMission.environment:setEnvironmentTime(g_currentMission.environment.currentMonotonicDay, g_currentMission.environment.currentDay, gameDayTime, g_currentMission.environment.daysPerPeriod, false)
      g_currentMission.environment.lighting:setDayTime(g_currentMission.environment.dayTime, true)
      g_currentMission.environment.weather.cheatedTime = true
      EnvironmentTimeEvent.broadcastEvent()
      
      -- Check if server then broadcast, if not then send local
      local setNotificationData = g_i18n:getText("title_realTimeSync_setInProgress") .. self.ServerHour .. ":" .. self.ServerMinCleanUTC - 2
      if self.isServer then
        g_server:broadcastEvent(SettingEvent.new(1, "realTimeSyncNoti", setNotificationData), nil, connection)
      else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, setNotificationData)
      end
      self.ServerUpdate = false -- disable notification
      TimeSpeed = 1 -- Time scale speed

    -- Check if Game time is greater than server time.  Slow time down if so.
    elseif GameTime > ServerTime and TimeDiff < -0.03 then
      rtDebug("RealTimeSync:GameTime > ServerTime - slow way down time")
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 0.1
      else
        g_currentMission:setTimeScale(0.1);
      end
      self.ServerUpdate = false -- disable notification
      TimeSpeed = 0.1 -- Time scale speed

    -- Check if Game time is greater than server time.  Slow time down if so.
    elseif GameTime > ServerTime then
      rtDebug("RealTimeSync:GameTime > ServerTime - slow down time")
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 0.5
      else
        g_currentMission:setTimeScale(0.5);
      end
      self.ServerUpdate = false -- disable notification
      TimeSpeed = 0.5 -- Time scale speed

    -- If time matches, then keep at scale 1
    elseif g_currentMission.missionInfo.timeScale ~= 1 then	  
      if RealTimeSync:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 1
      else
        g_currentMission:setTimeScale(1);
      end
      self.ServerUpdate = false -- Disable notification
      TimeSpeed = 1 -- Time scale speed
    end
  end
  -- Check if we should notify players that there was a change
  if self.ServerUpdate == true and TimeDiff ~= 0 and TimeSpeed ~= self.TimeSpeed then
    -- Add zero to min if less than 10
    local addZero = "";
    if self.ServerMinCleanUTC < 10 then addZero = "0" else addZero = "" end
    -- Check if player has time sync message enabled
    local progressNoti = self.settings:getValue("progressNoti")
    if progressNoti == true then
      rtDebug("progressNoti - Display Message")
      -- Notify players time sync in progress
      local notificationData = g_i18n:getText("title_realTimeSync_inProgress") .. self.ServerHour .. ":" .. addZero .. self.ServerMinCleanUTC
      -- Check if server then broadcast, if not then send local
      if self.isServer then
        g_server:broadcastEvent(SettingEvent.new(1, "realTimeSyncNoti", notificationData), nil, connection)
      else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, notificationData)
      end
    end
    self.TimeSpeed = TimeSpeed -- Time scale speed
    self.ServerUpdate = false
    self.speedFix = true
  end
end

-- Run on savegame
function RealTimeSync:save()
  rtDebug(" Info: save")

  g_realTimeSync.settings:saveSettings()

end

-- Disable the sleep stuffs
function RealTimeSync:disableSleep()
  -- Check to see if sleep is disabled
  local canDisableSleep = true
  if canDisableSleep ~= nil and canDisableSleep then
    return false
  else
    return not g_sleepManager.isSleeping
  end
end

-- Check if client is a server or single player
function RealTimeSync:singleServerCheck()
  -- Check if server
  if g_currentMission:getIsServer() == true and g_currentMission:getIsClient() == true and g_dedicatedServer ~= nil and g_server ~= nil then 
    -- Multiplayer Server Host
    return true
  -- Check if single player
  elseif g_currentMission:getIsServer() == true and g_currentMission:getIsClient() == true and g_dedicatedServer == nil and g_server ~= nil then 
    -- Single player client
    return true
  else
    -- Client on dedicated server
    return false
  end
end

-- Check if single player
function RealTimeSync:isSinglePlayer()
  if g_currentMission:getIsServer() == true and g_currentMission:getIsClient() == true and g_dedicatedServer == nil and g_server ~= nil then 
    return true
  else
    return false
  end
end

-- Refresh RealTimeSync Menus
function RealTimeSync:refresh()
  if g_dedicatedServer == nil then
    SettingsGuiRealTimeSyncFrame:updateRealTimeSync()
    SettingsGuiTimeSyncFrame:updateRealTimeSync()
    SettingsGuiToolsFrame:updateRealTimeSync()
  end
end

-- Event when player joins server
function RealTimeSync:join()
  rtDebug("RealTimeSync:join")
  -- Send settings to new client
  SettingEvent.sendEvent(2, "progressNoti", g_realTimeSync.settings:getValue("progressNoti"))
  SettingEvent.sendEvent(2, "timeSyncEnable", g_realTimeSync.settings:getValue("timeSyncEnable"))
  SettingEvent.sendEvent(3, "serverOffset", g_realTimeSync.settings:getValue("serverOffset"))
  SettingEvent.sendEvent(3, "timeFixHour", g_realTimeSync.settings:getValue("timeFixHour"))
  SettingEvent.sendEvent(2, "autoSetTime", g_realTimeSync.settings:getValue("autoSetTime"))
end