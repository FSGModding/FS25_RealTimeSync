---Simple debug function that does stuff with different types of vars.  
function rtDebug(data)
  local debug = false
  if debug then
    if data ~= nil then
      -- Run if data is table
      if type(data) == "table" then
        print("** Real Time Sync Debug - Table **")
        DebugUtil.printTableRecursively(data, "  tabledata : ", 0, 1)
      -- Run if data is boolean
      elseif type(data) == "boolean" then
        if data == true then 
          print("** Real Time Sync Debug - Boolean ** : true")
        else 
          print("** Real Time Sync Debug - Boolean ** : false")
        end
      -- Run if data is number
      elseif type(data) == "number" then
        print("** Real Time Sync Debug - Number ** : " .. data)
      -- Run if data is string
      elseif type(data) == "string" then
        print("** Real Time Sync Debug - String ** : " .. data)
      -- Run if data is function
      elseif type(data) == "function" then
        print("** Real Time Sync Debug - Function ** : ")
        print(data)
      -- Run if data is thread
      elseif type(data) == "thread" then
        print("** Real Time Sync Debug - Thread ** : ")
        print(data)
      -- Run if nothing else
      else
        print("** Real Time Sync Debug ** : " .. data)
      end
    else
      print("** Real Time Sync Debug ** : nil")
    end
  end
end

function convertToBool(string)
	return string == "true" or string == "True" or string == "TRUE" or string == "1"
end

function getDlcTitle(dir)
  local dirArray = string.split(dir, "/")
  local dlcTitleIndex = 0
  local dirString = "$pdlcdir$"
  for i = 1, #dirArray do
    if dirArray[i] == "pdlc" then
      dlcTitleIndex = i + 1
    end
    if i == dlcTitleIndex then
      dirString = dirString .. dirArray[i]
    end
    if dlcTitleIndex ~= 0 and i > dlcTitleIndex then
      dirString = dirString .. "/" .. dirArray[i]
    end
  end
  if dirString ~= nil then
    return dirString
  else
    return false
  end
end

function getDlcDir(dir)
  local dirArray = string.split(dir, "/")
  local dlcTitleIndex = 0
  local dirString = getAppBasePath() .. "pdlc/"
  for i = 1, #dirArray do
    if dirArray[i] == "$pdlcdir$" then
      dlcTitleIndex = i + 1
    end
    if i == dlcTitleIndex then
      dirString = dirString .. dirArray[i]
    end
    if dlcTitleIndex ~= 0 and i > dlcTitleIndex then
      dirString = dirString .. "/" .. dirArray[i]
    end
  end
  if dirString ~= nil then
    return dirString
  else
    return false
  end
end