--[[
  Шаг 3: диагностика API. Подробности -> me-report.txt
  Запуск: lua 03-api-dump.lua

  В консоли краткий итог. Полный отчёт: cat me-report.txt
]]

local component = require("component")

local ME_TYPES = {
  "me_controller", "me_interface", "me_exportbus", "me_importbus",
}

local NETWORK_METHODS = {
  "getItemsInNetwork",
  "getAvailableItems",
  "getFluidsInNetwork",
  "getCraftables",
  "getCpus",
  "getStoredPower",
  "getMaxStoredPower",
  "getAvgPowerUsage",
  "getAvgPowerInjection",
  "getIdlePowerUsage",
  "getInterfaceConfiguration",
  "getExportConfiguration",
  "getImportConfiguration",
}

local ABSENT_HINT = {
  getAvailableItems = "устаревшее имя, в OC: getItemsInNetwork",
  getExportConfiguration = "только me_exportbus",
  getImportConfiguration = "только me_importbus",
  getInterfaceConfiguration = "только me_interface (блок)",
}

local me, meType, meAddr = nil, nil, nil
for i = 1, #ME_TYPES do
  for addr in component.list(ME_TYPES[i]) do
    me = component.proxy(addr)
    meType = ME_TYPES[i]
    meAddr = addr
    break
  end
  if me then break end
  os.sleep(0)
end

if not me then
  print("VERDICT: FAIL_NO_ME_COMPONENT")
  os.exit(1)
end

local path = "me-report.txt"
local f = io.open(path, "w")

local function w(line)
  f:write(line .. "\n")
end

w("=== OC x AE2 :: api report ===")
w("Component: " .. meType .. " @ " .. meAddr)
w("")

w("-- methods --")
local okCount, errCount, absentCount = 0, 0, 0
local itemsCount = nil

for i = 1, #NETWORK_METHODS do
  local name = NETWORK_METHODS[i]
  if me[name] ~= nil then
    local ok, res = pcall(function() return me[name]() end)
    if ok then
      okCount = okCount + 1
      local summary
      if type(res) == "table" then
        local n = res.n or #res
        summary = "table[" .. tostring(n) .. "]"
        if name == "getItemsInNetwork" then itemsCount = n end
      else
        summary = tostring(res)
      end
      w("OK  " .. name .. " -> " .. summary)
    else
      errCount = errCount + 1
      w("ERR " .. name .. " -> " .. tostring(res))
    end
  else
    absentCount = absentCount + 1
    local hint = ABSENT_HINT[name] or "нет на этом типе компонента"
    w("N/A " .. name .. " (" .. hint .. ")")
  end
  os.sleep(0)
end

w("")
w(string.format("Summary: OK=%d ERR=%d N/A=%d", okCount, errCount, absentCount))
if itemsCount ~= nil then
  w("Items in network: " .. itemsCount)
end

f:close()

print("=== api dump (summary) ===")
print("Component: " .. meType)
print(string.format("Methods: %d OK, %d ERR, %d N/A", okCount, errCount, absentCount))
if itemsCount ~= nil then
  print("Items:   " .. itemsCount)
end
print("")
if errCount == 0 and okCount > 0 then
  print("VERDICT: API_OK")
else
  print("VERDICT: API_PARTIAL")
end
print("Report:  " .. path)
print("Read:    cat " .. path)
