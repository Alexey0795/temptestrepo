--[[
  Шаг 1: обнаружение компонента AE2.
  Запуск: lua 01-probe.lua

  VERDICT:
    FAIL_NO_ME_COMPONENT  — OC не видит AE2
    ME_COMPONENT_FOUND    — запускайте 02-me-read.lua
]]

local component = require("component")

local ME_TYPES = {
  "me_controller",
  "me_interface",
  "me_exportbus",
  "me_importbus",
}

print("=== OC x AE2 :: probe ===")
print("")

local total = 0
for _ in component.list() do
  total = total + 1
end
print(string.format("Components total: %d", total))

for addr, ctype in component.list() do
  print(string.format("  [%s] %s", ctype, addr:sub(1, 8)))
  os.sleep(0)
end

print("")

local found = {}
for i = 1, #ME_TYPES do
  local meType = ME_TYPES[i]
  for addr, ctype in component.list(meType) do
    found[#found + 1] = { addr = addr, ctype = ctype }
  end
  os.sleep(0)
end

if #found == 0 then
  print("VERDICT: FAIL_NO_ME_COMPONENT")
  print("")
  print("OpenComputers НЕ видит компонент Applied Energistics.")
  print("Проверьте:")
  print("  - Adapter стоит ВПЛОТНУЮ к ME Interface или ME Controller")
  print("  - Кабель идёт Adapter -> Computer")
  print("  - [OpenComputers] в привате региона")
  os.exit(1)
end

print(string.format("VERDICT: ME_COMPONENT_FOUND (%d)", #found))
for i = 1, #found do
  local c = found[i]
  print(string.format("  -> %s @ %s", c.ctype, c.addr:sub(1, 8)))
end
print("")
print("Следующий шаг: lua 02-me-read.lua")
