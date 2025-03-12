-- Main mod load file for Real Time Sync Mod
local modDirectory = g_currentModDirectory or ""
local modName      = g_currentModName or "unknown"
local modEnvironment

-- files to load
local sourceFiles = {
  "scripts/globalFuncs.lua",
  "scripts/realTimeSync.lua",
  "scripts/fs25ModPrefSaver.lua",
  "scripts/settingEvent.lua",
  "scripts/settingsGui.lua",
  "scripts/settingsGuiInfoFrame.lua",
  "scripts/settingsGuiTimeSyncFrame.lua",
}

---Load all of the source files
for _, file in ipairs(sourceFiles) do
  source(modDirectory .. file)
end

-- load on mission load
local function load(mission)
	assert(g_realTimeSync == nil)
	modEnvironment = RealTimeSync:new(mission, modDirectory, modName)
	getfenv(0)["g_realTimeSync"] = modEnvironment
  if mission:getIsClient() then
		addModEventListener(modEnvironment)
  end
end

-- unload on mission unload
local function unload()
  removeModEventListener(modEnvironment)
  if modEnvironment ~= nil then
    modEnvironment = nil
    if g_realTimeSync ~= nil then
      getfenv(0)["g_realTimeSync"] = nil
    end
  end
end

-- start the mod functions
local function init()
	FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)

	Mission00.load = Utils.prependedFunction(Mission00.load, load)

	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, RealTimeSync.save)
  -- Disables Sleeping in Game
  SleepManager.getCanSleep = Utils.overwrittenFunction(SleepManager.getCanSleep, RealTimeSync.disableSleep)
  -- Loads when user joins server
  FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading,RealTimeSync.join)

end



init()