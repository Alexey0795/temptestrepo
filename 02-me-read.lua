--[[
  Шаг 2: чтение МЭ-сети. Список предметов -> me-report.txt
  Запуск: lua 02-me-read.lua

  В консоли краткий итог. Полный список: cat me-report.txt
]]

local component = require("component")

local ME_TYPES = {
  "me_controller", "me_interface", "me_exportbus", "me_importbus",
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

local items = nil
local method = nil
if me.getItemsInNetwork then
  local ok, res = pcall(function() return me.getItemsInNetwork() end)
  if ok then
    items = res
    method = "getItemsInNetwork"
  end
end

if not items then
  print("VERDICT: FAIL_NO_READ")
  print("Сначала: lua 03-api-dump.lua")
  os.exit(1)
end

local count = items.n or #items
local path = "me-report.txt"
local f = io.open(path, "w")

f:write("=== ME network items ===\n")
f:write("Component: " .. meType .. " @ " .. meAddr .. "\n")
f:write("Count: " .. count .. "\n\n")

for i = 1, count do
  local it = items[i]
  if type(it) == "table" then
    local name = it.label or it.name or "?"
    local size = it.size or it.count or "?"
    local craft = it.isCraftable and " [craft]" or ""
    f:write(string.format("%4d  %s x %s%s\n", i, name, tostring(size), craft))
  end
  if i % 50 == 0 then os.sleep(0) end
end

f:close()

print("=== network read (summary) ===")
print("Component: " .. meType)
print("Method:    " .. method)
print("Items:     " .. count)
print("VERDICT:   SUCCESS_READ_OK")
print("Report:    " .. path)
print("Read:      cat " .. path)
