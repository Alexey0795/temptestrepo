--[[
  Шаг 5: прошивка EEPROM для дрона — взлёт, квадрат, посадка.

  ВАЖНО: на EEPROM дрона нет OpenOS — нельзя require().
  component / computer — глобальные; прокси через component.list + proxy.

  Сборка (Drone Case T2, complexity 8/8):
    CPU T1, RAM T1 x1, EEPROM (этот файл), Navigation T2, Wireless T2

  Прошивка на компьютере с OpenOS:
    flash -q 05-drone-lap.lua DroneLap

  Тест на компьютере (lua 05-drone-lap.lua) НЕ показателен — там есть require.

  Приёмник на базе: lua 04-drone-logger.lua  (порт 2412)
]]

local PORT = 2412
local STEP = 3
local ALTITUDE = 4
local WAIT_SEC = 30

local function proxyFirst(name)
  local addr = component.list(name)()
  if addr then
    return component.proxy(addr)
  end
  return nil
end

local function sleep(sec)
  computer.pullSignal(sec)
end

local drone = proxyFirst("drone")
if not drone then
  error("no drone component")
end

local modem = proxyFirst("modem")
local nav = proxyFirst("navigation")

local function posStr()
  if not nav then return "" end
  local ok, a, b, c = pcall(nav.getPosition)
  if ok and type(a) == "number" then
    return string.format(" @%.0f,%.0f,%.0f", a, b, c)
  end
  if ok and type(a) == "table" then
    return string.format(" @%.0f,%.0f,%.0f", a[1], a[2], a[3])
  end
  return ""
end

local function tel(text)
  text = tostring(text)
  pcall(function() drone.setStatusText(text:sub(1, 40)) end)
  if modem then
    pcall(function() modem.broadcast(PORT, "tel", text) end)
  end
end

local function waitMove()
  local deadline = computer.uptime() + WAIT_SEC
  while drone.getOffset() > 0.5 do
    if computer.uptime() >= deadline then
      return false
    end
    tel(string.format("wait off=%.1f v=%.1f%s",
      drone.getOffset(), drone.getVelocity(), posStr()))
    sleep(0.2)
  end
  return true
end

local function fly(dx, dy, dz, tag)
  tel(string.format("%s %d,%d,%d%s", tag, dx, dy, dz, posStr()))
  drone.move(dx, dy, dz)
  if not waitMove() then
    return false
  end
  sleep(0)
  return true
end

local legs = {
  { STEP, 0, 0 },
  { 0, 0, STEP },
  { -STEP, 0, 0 },
  { 0, 0, -STEP },
}

tel("boot DroneLap")
sleep(0.5)

if not fly(0, ALTITUDE, 0, "up") then
  tel("VERDICT FAIL_TAKEOFF")
  return
end

for i = 1, #legs do
  local leg = legs[i]
  if not fly(leg[1], leg[2], leg[3], "leg" .. i) then
    tel("VERDICT FAIL_LEG" .. i)
    fly(0, -ALTITUDE, 0, "land")
    return
  end
  sleep(0)
end

if fly(0, -ALTITUDE, 0, "down") then
  tel("VERDICT FLIGHT_OK")
else
  tel("VERDICT FAIL_LAND")
end
