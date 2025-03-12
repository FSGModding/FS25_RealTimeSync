SettingEvent = {}
local SettingEvent_mt = Class(SettingEvent, Event)

InitEventClass(SettingEvent, "SettingEvent")

function SettingEvent.emptyNew()
	return Event.new(SettingEvent_mt)
end
---@class SettingEvent
function SettingEvent.new(valueType, valueName, valueData)
	local self = SettingEvent.emptyNew()
  self.valueType = valueType
	self.valueName = valueName
  self.valueData = valueData
	return self
end

function SettingEvent:readStream(streamId, connection)
  self.valueType = streamReadUInt8(streamId)
  self.valueName = streamReadString(streamId)
  -- Check if valuetype is nil
  if self.valueType == nil then 
    print('RealTimeSync:SettingEvent:readStream:Error:valueType=nil - valueType can not be nil.  Must be int.')
    return
  end
  -- Check if valueName is nil
  if self.valueName == nil then 
    print('RealTimeSync:SettingEvent:readStream:Error:valueName=nil - valueName can not be nil.  Must be string.')
    return
  end
  -- String
  if     self.valueType == 1 then self.valueData = streamReadString(streamId) 
  -- Bool
  elseif self.valueType == 2 then self.valueData = streamReadBool(streamId) 
  -- Int8
  elseif self.valueType == 3 then self.valueData = streamReadInt8(streamId) 
  -- Int32
  elseif self.valueType == 4 then self.valueData = streamReadInt32(streamId) 
  -- UInt8
  elseif self.valueType == 5 then self.valueData = streamReadUInt8(streamId) 
  -- UInt16
  elseif self.valueType == 6 then self.valueData = streamReadUInt16(streamId) 
  -- UIntN
  elseif self.valueType == 7 then self.valueData = streamReadUIntN(streamId) 
  -- Float32
  elseif self.valueType == 8 then self.valueData = streamReadFloat32(streamId)
  -- Unknown
  else printf('RealTimeSync:SettingEvent:readStream:Error:valueType: %s not correct type.') end
  -- Debug
	self:run(connection)
end

function SettingEvent:writeStream(streamId, connection)
  streamWriteUInt8(streamId, self.valueType)
  streamWriteString(streamId, self.valueName)
  -- Check if valuetype is nil
  if self.valueType == nil then 
    return
  end
  -- Check if valueName is nil
  if self.valueName == nil then 
    return
  end
  -- String
  if     self.valueType == 1 then streamWriteString(streamId, self.valueData) 
  -- Bool
  elseif self.valueType == 2 then streamWriteBool(streamId, self.valueData) 
  -- Int8
  elseif self.valueType == 3 then streamWriteInt8(streamId, self.valueData) 
  -- Int32
  elseif self.valueType == 4 then streamWriteInt32(streamId, self.valueData)
  -- UInt8
  elseif self.valueType == 5 then streamWriteUInt8(streamId, self.valueData) 
  -- UInt16
  elseif self.valueType == 6 then streamWriteUInt16(streamId, self.valueData) 
  -- UIntN
  elseif self.valueType == 7 then streamWriteUIntN(streamId, self.valueData) 
  -- Float32
  elseif self.valueType == 8 then streamWriteFloat32(streamId, self.valueData)
  -- Unknown
  else 
    streamWriteInt8(streamId, 0)
  end
  
end

function SettingEvent:run(connection)
	if not connection:getIsServer() then
    --print("SettingEvent:run:g_server:broadcastEvent - data being sent from client to server")
		g_server:broadcastEvent(SettingEvent.new(self.valueType, self.valueName, self.valueData), nil, connection)
  end
  -- Save data to xml file if global var is set
  if g_realTimeSync ~= nil then
    if self.valueName ~= nil and self.valueName == "realTimeSyncNoti" then
      -- Display notification to player
      g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, self.valueData)
    else
      -- Save realtime data from server to local
      g_realTimeSync.settings:setValue(self.valueName, self.valueData)
      g_realTimeSync.settings:saveSettings()
    end
  end
end

function SettingEvent.sendEvent(...)
	if g_server ~= nil then
		g_server:broadcastEvent(SettingEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(SettingEvent.new(...))
	end
end