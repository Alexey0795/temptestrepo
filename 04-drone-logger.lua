--[[
  Приёмник телеметрии от 05-drone-lap.lua (Wireless T2, порт 2412).
  Запуск на базовом компьютере ДО активации дрона:

    lua 05-drone-logger.lua

  Лог: drone-log.txt (append). Чтение: cat drone-log.txt
]]

local event = require("event")
local component = require("component")

local PORT = 2412
local PATH = "drone-log.txt"

local modem = component.modem
if modem then
  modem.open(PORT)
end

local f = io.open(PATH, "a")
if not f then
  print("VERDICT: FAIL_NO_LOG_FILE")
  os.exit(1)
end

f:write("\n=== logger start " .. os.date("%Y-%m-%d %X") .. " ===\n")
f:flush()

print("=== drone logger ===")
print("Port:   " .. PORT)
print("Log:    " .. PATH)
print("VERDICT: LOGGER_READY")
print("")

while true do
  local _, _, from, port, distance, kind, text = event.pull("modem_message")
  if port == PORT and kind == "tel" then
    local line = os.date("%X") .. " " .. tostring(text) .. "\n"
    f:write(line)
    f:flush()
    print(text)
  end
  os.sleep(0)
end
