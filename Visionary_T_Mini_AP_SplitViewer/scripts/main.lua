--[[----------------------------------------------------------------------------

  Application Name: Visionary_T_Mini_AP_SplitViewer

  Summary:
  Show the distance and intensity image that the camera acquired

  Description:
  Set up the camera to take live images continuously. React to the "OnNewImage"
  event and display the distance and intensity image in a 2D and
  3D viewer, using the addDepthMap function. Also provides a user interface
  to modify the frameperiod and the filter settings.

  How to run:
  Start by running the app (F5) or debugging (F7+F10).
  Set a breakpoint on the first row inside the main function to debug step-by-step.
  See the results in the different image viewer on the DevicePage.

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------
-- Variables, constants, serves etc. should be declared here.
-- Start ROI and Binning Settings
local binningFactor = 4 -- valid values are 1,2,4
local roiSize = {320, 320} -- width must be divisible by 4 after binning
local roiPos = {100, 100}
-- End ROI and Binning Settings
local v2D = View.create()
local v3D = View.create("Viewer3D")
local cameraModel = nil
local provider = Image.Provider.Camera.create()
--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

---Callback funtion which is called when a new image is available
---@param image Image[] table which contains all received images
local function handleOnNewImage(images)
  v2D:clear()
  v2D:addDepthmap(images, cameraModel, nil, {"Depth", "Intensity"})
  v2D:present()

  v3D:clear()
  v3D:addDepthmap(images, cameraModel, nil, {"Depth", "Intensity"})
  v3D:present()
end

local function main()
   -- Configure frontend
  provider:stop()
  local captureConfig = provider:getConfig()
  captureConfig:setFramePeriod(33333)
  -- Set ROI
  captureConfig:setViewPos(true, roiPos[1], roiPos[2])
  captureConfig:setViewSize(true, roiSize[1], roiSize[2])
  -- Set Binning
  captureConfig:setBinning(binningFactor, binningFactor)

  if provider:setConfig(captureConfig) == false then
    Log.severe("failed to configure capture device")
  end
  -- get camera model (must be updated everytime Roi/Binning is changed)
  cameraModel = Image.Provider.Camera.getInitialCameraModel(provider)
  provider:start()

  -- setup image call back
  provider:register("OnNewImage", handleOnNewImage)
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register("Engine.OnStarted", main)

-- Set queue size to avoid overloading the system
local eventQueueHandle = Script.Queue.create()
eventQueueHandle:setMaxQueueSize(1)
eventQueueHandle:setPriority("HIGH")
eventQueueHandle:setFunction(handleOnNewImage)

--Start of Function which are used by the UI------------------------------------
---Sets the current frameperiod in ms
---@param change float frameperiod in ms
local function setFramePeriod(change)
  local currentConfig = provider:getConfig()
  local framePeriodUs = change * 1000
  currentConfig:setFramePeriod(framePeriodUs)
  provider:setConfig(currentConfig)
end

Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setFramePeriod", setFramePeriod)

---Gets the current frameperiod in ms
---@return float frameperiod in ms
local function getFramePeriod()
  local currentConfig = provider:getConfig()
  local framePeriodUs = currentConfig:getFramePeriod() / 1000
  return framePeriodUs
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getFramePeriod", getFramePeriod)

---Gets current state of distance filter
---@return bool true if distance filter is enabled
local function getDistanceFilterEnabled()
  local currentConfig = provider:getConfig()
  local enabled = currentConfig:getDistanceFilter()
  return enabled
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getDistanceFilterEnabled", getDistanceFilterEnabled)

---sets current state of distance filter
---@param change bool true to enable distance filter
local function setDistanceFilterEnabled(change)
  local currentConfig = provider:getConfig()
  currentConfig:setDistanceFilter(change)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setDistanceFilterEnabled", setDistanceFilterEnabled)

---sets current range of distance filter
---@param range float range of distance filter
local function setDistanceFilterRange(range)
  local currentConfig = provider:getConfig()
  -- Assume the filter is enabled if range is changed
  currentConfig:setDistanceFilter(true, range[1], range[2])
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setDistanceFilterRange", setDistanceFilterRange)

---gets current range of distance filter
---@return range float range of distance filter
local function getDistanceFilterRange()
  local currentConfig = provider:getConfig()
  local _, min, max = currentConfig:getDistanceFilter()
  return {min, max}
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getDistanceFilterRange", getDistanceFilterRange)

---Gets current state of intensity filter
---@return bool true if intensity filter is enabled
local function getIntensityFilterEnabled()
  local currentConfig = provider:getConfig()
  local enabled = currentConfig:getIntensityFilter()
  return enabled
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getIntensityFilterEnabled", getIntensityFilterEnabled)

---gets current range of intensity filter
---@return range float range of intensity filter
local function getIntensityFilterRange()
  local currentConfig = provider:getConfig()
  local _, min, max = currentConfig:getIntensityFilter()
  -- convert from linear to db
  if min > 0 then
    min = 20.0 * math.log(min, 10)
  end
  if max > 0 then
    max = 20.0 * math.log(max, 10)
  end
  return {min, max}
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getIntensityFilterRange", getIntensityFilterRange)

---Sets current state of intensity filter
---@param change bool true to enable intensity filter
local function setIntensityFilterEnabled(change)
  local currentConfig = provider:getConfig()
  currentConfig:setIntensityFilter(change)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setIntensityFilterEnabled", setIntensityFilterEnabled)


---sets current range of intensity filter
---@param range float range of intensity filter
local function setIntensityFilterRange(range)
  local currentConfig = provider:getConfig()
  -- convert from db to linear
  local minValue = 10 ^ (range[1] / 20)
  local maxValue = 10 ^ (range[2] / 20)
  -- Assume the filter is enabled if range is changed
  currentConfig:setIntensityFilter(true, minValue, maxValue)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setIntensityFilterRange", setIntensityFilterRange)

---Gets current state of isolated pixel filter
---@return bool true if isolated pixel filter is enabled
local function getIsoPixFilter()
  local currentConfig = provider:getConfig()
  local enabled = currentConfig:getFlyingClusterFilter()
  return enabled
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getIsoPixFilter", getIsoPixFilter)

---Gets current value of isolated pixel filter
---@return float current value of filter
local function getIsoPixValue()
  local currentConfig = provider:getConfig()
  local _, value = currentConfig:getFlyingClusterFilter()
  return value
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getIsoPixValue", getIsoPixValue)

---Sets current state of isolated pixel filter
---@param change bool true to enable isolated pixel filter
local function setIsoPixFilterEnabled(change)
  local currentConfig = provider:getConfig()
  currentConfig:setFlyingClusterFilter(change)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setIsoPixFilterEnabled", setIsoPixFilterEnabled)

---Sets current value of isolated pixel filter
---@param value float value of filter
local function setIsoPixFilterValue(value)
  local currentConfig = provider:getConfig()
  -- Assume the filter is enabled if value is changed
  currentConfig:setIntensityFilter(true, value)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setIsoPixFilterValue", setIsoPixFilterValue)

---Gets current state of ambiguity filter
---@return bool true if ambiguity filter is enabled
local function getAmbiguityFilterEnabled()
  local currentConfig = provider:getConfig()
  local enabled = currentConfig:getAmbiguityFilter()
  return enabled
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getAmbiguityFilterEnabled", getAmbiguityFilterEnabled)

---Gets current value of ambiguity filter
---@return float current value of filter
local function getAmbiguityFilterValue()
  local currentConfig = provider:getConfig()
  local _, value = currentConfig:getAmbiguityFilter()
  return value
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getAmbiguityFilterValue", getAmbiguityFilterValue)

---Sets current state of ambiguity filter
---@param change bool true to enable ambiguity filter
local function setAmbiguityFilterEnabled(change)
  local currentConfig = provider:getConfig()
  currentConfig:setAmbiguityFilter(change)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setAmbiguityFilterEnabled", setAmbiguityFilterEnabled)

---Sets current value of ambiguity filter
---@param value float value of filter
local function setAmbiguityFilter(value)
  local currentConfig = provider:getConfig()
  -- Assume the filter is enabled if value is changed
  currentConfig:setAmbiguityFilter(true, value)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setAmbiguityFilter", setAmbiguityFilter)

---Gets current state of remission filter
---@return bool true if remission filter is enabled
local function getRemisssionFilterEnabled()
  local currentConfig = provider:getConfig()
  local enabled = currentConfig:getRemissionFilter()
  return enabled
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getRemisssionFilterEnabled", getRemisssionFilterEnabled)

---gets current range of remission filter
---@return range float range of remission filter
local function getRemissionFilterRange()
  local currentConfig = provider:getConfig()
  local _, min, max = currentConfig:getRemissionFilter()
  return {min, max}
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getRemissionFilterRange", getRemissionFilterRange)

---Sets current state of remission filter
---@param change bool true to enable remission filter
local function setRemissionFilterEnabled(change)
  local currentConfig = provider:getConfig()
  currentConfig:setRemissionFilter(change)
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setRemissionFilterEnabled", setRemissionFilterEnabled)

---sets current range of remission filter
---@param range float range of remission filter
local function setRemissionFilterRange(range)
  local currentConfig = provider:getConfig()
  -- Assume the filter is enabled if range is changed
  currentConfig:setRemissionFilter(true, range[1], range[2])
  provider:setConfig(currentConfig)
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setRemissionFilterRange", setRemissionFilterRange)

---Gets current state of edge correction
---@return bool true if edge correction is enabled
local function getEdgeCorrectionEnabled()
  local currentConfig = provider:getConfig()
  local enabled, _, _ = currentConfig:getEdgeCorrection()
  return enabled
end
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.getEdgeCorrectionEnabled", getEdgeCorrectionEnabled)

---Sets state of edge correction
---@return bool true to enable edge correction
local function setEdgeCorrectionEnabled(enabled)
  local currentConfig = provider:getConfig()
  -- Assume the filter is enabled if range is changed
  currentConfig:setEdgeCorrection(enabled)
  provider:setConfig(currentConfig)
end
--End of Function which are used by the UI------------------------------------
--End of Function and Event Scope-----------------------------------------------
Script.serveFunction("Visionary_T_Mini_AP_SplitViewer.setEdgeCorrectionEnabled", setEdgeCorrectionEnabled)