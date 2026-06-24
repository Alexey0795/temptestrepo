--[[
  06 — клиент дрона (EEPROM). Прошить один раз, дальше только 07-server.

  flash -q 06-drone-client.lua DroneClient

  Сборка дрона: T2 8/8 — CPU T1, RAM T1, EEPROM, Nav T2, Wireless T2
  Порт: 2412 (как 04/05)

  Команды по wireless (см. 07-drone-server.lua):
    ping, mov, halt, cfg_set, cfg_get
]]

local PORT = 2412
local WAIT = 30

local cfg = { step = 1, hx = 0, hy = 0, hz = 0 }

local function proxy(name)
  local a = component.list(name)()
  if a then return component.proxy(a) end
end

local function sleep(sec)
  computer.pullSignal(sec)
end

local function hud(text)
  pcall(function() drone.setStatusText(tostring(text):sub(1, 8)) end)
end

local drone = proxy("drone")
local modem = proxy("modem")
if not drone or not modem then
  error("no drone/modem")
end
modem.open(PORT)

local function waitMove()
  local deadline = computer.uptime() + WAIT
  while drone.getOffset() > 0.5 do
    if computer.uptime() >= deadline then
      return false
    end
    sleep(0.2)
  end
  return true
end

local function doMov(dx, dy, dz)
  hud("mov")
  drone.move(dx, dy, dz)
  return waitMove()
end

local function ack(id, status, detail)
  modem.broadcast(PORT, "ack", tostring(id), status, tostring(detail or ""))
end

local function reportErr(id, err)
  hud("ERR")
  pcall(function()
    modem.broadcast(PORT, "err", tostring(id or "0"), tostring(err):sub(1, 200))
  end)
  if id then
    pcall(function() ack(id, "fail", "error") end)
  end
end

local function cfgApply(key, val)
  val = tonumber(val) or 0
  if key == "step" then cfg.step = val
  elseif key == "hx" then cfg.hx = val
  elseif key == "hy" then cfg.hy = val
  elseif key == "hz" then cfg.hz = val
  else return false
  end
  return true
end

local function cfgDump()
  return cfg.step .. "," .. cfg.hx .. "," .. cfg.hy .. "," .. cfg.hz
end

local function whereStr()
  local nav = proxy("navigation")
  if not nav then return "" end
  local ok, a, b, c = pcall(nav.getPosition)
  if ok and type(a) == "number" then
    return string.format("%.0f,%.0f,%.0f", a, b, c)
  end
  if ok and type(a) == "table" then
    return string.format("%.0f,%.0f,%.0f", a[1], a[2], a[3])
  end
  return ""
end

local running = true

local function handle(id, kind, a, b, c)
  kind = tostring(kind or "")
  if kind == "ping" then
    ack(id, "ok", "pong")
  elseif kind == "halt" then
    ack(id, "ok", "halt")
    running = false
  elseif kind == "mov" then
    local dx = math.floor(tonumber(a) or 0)
    local dy = math.floor(tonumber(b) or 0)
    local dz = math.floor(tonumber(c) or 0)
    local ok = doMov(dx, dy, dz)
    ack(id, ok and "ok" or "fail", "mov")
  elseif kind == "where" then
    local pos = whereStr()
    if pos == "" then
      ack(id, "fail", "nonav")
    else
      ack(id, "ok", pos)
    end
  elseif kind == "cfg_set" then
    if cfgApply(tostring(a), b) then
      ack(id, "ok", tostring(a))
    else
      ack(id, "fail", "badkey")
    end
  elseif kind == "cfg_get" then
    ack(id, "ok", cfgDump())
  else
    ack(id, "fail", "unknown")
  end
end

hud("idle")

local okRun, runErr = pcall(function()
  while running do
    local ev = { computer.pullSignal(60) }
    if ev[1] == "modem_message" and tonumber(ev[4]) == PORT then
      local kind = ev[6]
      local id = ev[7]
      if id and kind then
        local ok, err = pcall(handle, id, kind, ev[8], ev[9], ev[10])
        if not ok then
          reportErr(id, err)
        end
      end
    end
    sleep(0)
  end
end)

if not okRun then
  reportErr("0", runErr)
end

hud("off")
