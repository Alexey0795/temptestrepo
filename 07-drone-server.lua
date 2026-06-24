--[[
  07 — сервер управления дроном (OpenOS, HDD).

  Запуск:
    cd experiment
    lua 07-drone-server.lua
    lua 07-drone-server.lua demo

  Нужен errlog.lua в той же папке.
  Ошибки: cat drone-error.txt
]]

local event = require("event")
local component = require("component")
local computer = require("computer")
local keyboard = require("keyboard")

local function loadErrlog()
  for _, path in ipairs({ "errlog.lua", "experiment/errlog.lua" }) do
    local chunk = loadfile(path)
    if chunk then return chunk() end
  end
  return {
    path = function() return "drone-error.txt" end,
    write = function(tag, err, path)
      path = path or "drone-error.txt"
      local f = io.open(path, "a")
      if not f then return false end
      f:write("\n=== " .. tostring(tag) .. " " .. os.date("%X") .. " ===\n" .. tostring(err) .. "\n")
      f:close()
      return true
    end,
    guard = function(tag, fn, path)
      local ok, res = xpcall(fn, debug.traceback)
      if not ok then
        local p = path or "drone-error.txt"
        local f = io.open(p, "a")
        if f then
          f:write("\n=== " .. tag .. " ===\n" .. tostring(res) .. "\n")
          f:close()
        end
        print("ERROR -> " .. p)
        print(tostring(res):match("^[^\n]+") or res)
        return false
      end
      return true, res
    end,
  }
end

local errlog = loadErrlog()
local ERR_PATH = errlog.path()

local PORT = 2412
local CFG_PATH = "drone-server.cfg"
local LOG_PATH = "drone-remote-log.txt"
local ACK_TIMEOUT = 35
local ACK_HINT_AFTER = 5
local STEP_DEFAULT = 1
local RUN_DEMO = ({ ... })[1] == "demo"

local modem = component.modem
if not modem then
  print("VERDICT: FAIL_NO_MODEM")
  os.exit(1)
end
modem.open(PORT)

local cfg = {
  step = STEP_DEFAULT,
  home_x = 0,
  home_y = 0,
  home_z = 0,
  port = PORT,
}

local cmdId = 0
local logFile = nil

local function log(line)
  line = tostring(line)
  print(line)
  if logFile then
    logFile:write(os.date("%X ") .. line .. "\n")
    logFile:flush()
  end
end

local function logDroneErr(id, text)
  errlog.write("drone " .. tostring(id), text, ERR_PATH)
  log("DRONE ERR -> " .. ERR_PATH)
end

local function loadCfg()
  local f = io.open(CFG_PATH, "r")
  if not f then return end
  for line in f:lines() do
    local k, v = line:match("^(%w+)=(.-)$")
    if k and v then
      local n = tonumber(v)
      if k == "step" then cfg.step = n or STEP_DEFAULT
      elseif k == "home_x" then cfg.home_x = n or 0
      elseif k == "home_y" then cfg.home_y = n or 0
      elseif k == "home_z" then cfg.home_z = n or 0
      elseif k == "port" then cfg.port = n or PORT
      end
    end
  end
  f:close()
end

local function saveCfg()
  local f = io.open(CFG_PATH, "w")
  if not f then return end
  f:write(string.format("step=%d\n", cfg.step))
  f:write(string.format("home_x=%d\n", cfg.home_x))
  f:write(string.format("home_y=%d\n", cfg.home_y))
  f:write(string.format("home_z=%d\n", cfg.home_z))
  f:write(string.format("port=%d\n", cfg.port))
  f:close()
end

local function nextId()
  cmdId = cmdId + 1
  return tostring(cmdId)
end

local function send(kind, a, b, c)
  local id = nextId()
  if c ~= nil then
    modem.broadcast(PORT, kind, id, a, b, c)
  elseif b ~= nil then
    modem.broadcast(PORT, kind, id, a, b)
  elseif a ~= nil then
    modem.broadcast(PORT, kind, id, a)
  else
    modem.broadcast(PORT, kind, id)
  end
  return id
end

local function isEnterKey(ev)
  if ev[1] ~= "key_down" then return false end
  local code = ev[4]
  return code == keyboard.keys.enter or code == keyboard.keys.numpadenter
end

local function waitAck(expectId)
  local deadline = computer.uptime() + ACK_TIMEOUT
  local started = computer.uptime()
  local hinted = false

  while computer.uptime() < deadline do
    local elapsed = computer.uptime() - started
    if not hinted and elapsed >= ACK_HINT_AFTER then
      hinted = true
      print(string.format(
        "... нет ответа %ds. Enter — отменить, ждём до %ds (дрон выключен?)",
        math.floor(elapsed), ACK_TIMEOUT))
    end

    local ev = { event.pull(1) }
    if ev[1] == "modem_message" and tonumber(ev[4]) == PORT then
      if ev[6] == "err" then
        logDroneErr(ev[7], ev[8])
      elseif ev[6] == "ack" and tostring(ev[7]) == tostring(expectId) then
        return ev[8], ev[9]
      end
    elseif hinted and isEnterKey(ev) then
      return nil, "cancelled"
    elseif ev[1] == "interrupted" then
      return nil, "interrupted"
    end
    os.sleep(0)
  end
  return nil, "timeout"
end

local function command(kind, a, b, c)
  local id = send(kind, a, b, c)
  local status, detail = waitAck(id)
  if not status then
    if detail == "cancelled" then
      log("ACK " .. id .. " cancelled (Enter)")
    elseif detail == "timeout" then
      log("ACK " .. id .. " timeout")
    else
      log("ACK " .. id .. " " .. tostring(detail))
    end
    return false, detail
  end
  log("ACK " .. id .. " " .. status .. " " .. tostring(detail))
  return status == "ok", detail
end

local function mov(dx, dy, dz)
  return command("mov", dx, dy, dz)
end

local function pushCfg()
  command("cfg_set", "step", cfg.step)
  command("cfg_set", "hx", cfg.home_x)
  command("cfg_set", "hy", cfg.home_y)
  command("cfg_set", "hz", cfg.home_z)
end

local function parsePos(text)
  local x, y, z = tostring(text):match("([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)")
  if x then
    return math.floor(tonumber(x)), math.floor(tonumber(y)), math.floor(tonumber(z))
  end
  return nil
end

local function where()
  local ok, pos = command("where")
  if not ok then return nil end
  return parsePos(pos)
end

local function gotoPos(tx, ty, tz)
  local cx, cy, cz = where()
  if not cx then
    log("goto: no position")
    return false
  end
  local dx, dy, dz = tx - cx, ty - cy, tz - cz
  log(string.format("goto delta %d,%d,%d from %d,%d,%d", dx, dy, dz, cx, cy, cz))
  if dx ~= 0 and not mov(dx, 0, 0) then return false end
  if dy ~= 0 and not mov(0, dy, 0) then return false end
  if dz ~= 0 and not mov(0, 0, dz) then return false end
  return true
end

local function charge()
  if cfg.home_x == 0 and cfg.home_y == 0 and cfg.home_z == 0 then
    log("charge: home not set (home X Y Z)")
    return false
  end
  log(string.format("charge -> %d,%d,%d", cfg.home_x, cfg.home_y, cfg.home_z))
  if gotoPos(cfg.home_x, cfg.home_y, cfg.home_z) then
    log("VERDICT: CHARGE_OK")
    return true
  end
  log("VERDICT: CHARGE_FAIL")
  return false
end

local function showCfg()
  log("--- server cfg ---")
  log(string.format("step=%d home=%d,%d,%d port=%d",
    cfg.step, cfg.home_x, cfg.home_y, cfg.home_z, cfg.port))
  local ok, detail = command("cfg_get")
  if ok then
    log("drone cfg: step,hx,hy,hz = " .. tostring(detail))
  end
end

local function help()
  print([[
Команды:
  ping                    проверка связи (Enter отменяет ожидание после 5s)
  u d f b l r             шаг на step блоков (вверх/вниз/вперёд/назад/влево/вправо)
  mov DX DY DZ            сдвиг, пример: mov 1 -2 3
  step N                  размер шага для u/d/f/b/l/r (по умолчанию 1)
  home X Y Z              точка базы/зарядки, пример: home 120 64 -340
  here                    home = текущая позиция дрона (над charger)
  push                    отправить cfg (home, step) на дрон
  cfg                     показать cfg сервера и дрона
  where                   где дрон сейчас (navigation)
  goto X Y Z              полёт к координатам, пример: goto 125 70 -330
  charge                  полёт на home (сначала here или home)
  mission                 сценарий 08: база → цель → возврат
  halt                    остановить клиент на дроне
  demo                    автотест: ping + вверх/вниз
  help                    эта справка
  quit                    выход

Ошибки: cat drone-error.txt
]])
end

local function runMission()
  print("")
  print("=== Mission 08: база -> цель -> возврат ===")
  print("")

  if not command("ping") then
    log("VERDICT: MISSION_FAIL (no link)")
    return
  end

  print("1) Активируйте дрон (ПКМ). Enter...")
  io.read()

  print("2) База: дрон над charger, команда here")
  local x, y, z = where()
  if not x then
    log("VERDICT: MISSION_FAIL (where)")
    return
  end
  cfg.home_x, cfg.home_y, cfg.home_z = x, y, z
  saveCfg()
  pushCfg()
  log(string.format("home=%d,%d,%d", x, y, z))

  print("")
  print("3) Отойдите с компьютером на расстояние (wireless).")
  print("   В креативе: 20-40 блоков. Enter когда готов...")
  io.read()

  if not command("ping") then
    log("VERDICT: MISSION_FAIL (link lost)")
    return
  end

  print("")
  print("4) Цель: введите X Y Z (координаты куда лететь)")
  print("   пример: 125 70 -330")
  io.write("target> ")
  local targetLine = io.read()
  if not targetLine then return end
  local tp = {}
  for w in targetLine:gmatch("%S+") do tp[#tp + 1] = w end
  local tx, ty, tz = tonumber(tp[1]), tonumber(tp[2]), tonumber(tp[3])
  if not tx then
    log("VERDICT: MISSION_FAIL (bad coords)")
    return
  end

  log(string.format("goto %d,%d,%d", tx, ty, tz))
  if not gotoPos(tx, ty, tz) then
    log("VERDICT: MISSION_FAIL (goto)")
    return
  end

  local cx, cy, cz = where()
  if cx then
    log(string.format("at %d,%d,%d", cx, cy, cz))
  end

  print("")
  print("5) Возврат на базу? (y/n)")
  io.write("> ")
  local ans = io.read()
  if ans and (ans == "y" or ans == "Y" or ans == "д" or ans == "Д") then
    if not charge() then
      log("VERDICT: MISSION_FAIL (charge)")
      return
    end
  else
    log("return skipped")
  end

  log("VERDICT: MISSION_OK")
end

local function runDemo()
  if not command("ping") then
    log("VERDICT: REMOTE_FAIL")
    return
  end
  pushCfg()
  if mov(0, cfg.step, 0) and mov(0, -cfg.step, 0) then
    log("VERDICT: REMOTE_OK")
  else
    log("VERDICT: REMOTE_FAIL")
  end
end

local function dispatch(line)
  local parts = {}
  for w in line:gmatch("%S+") do
    parts[#parts + 1] = w
  end
  local cmd = parts[1]
  if not cmd or cmd == "" then return true end

  if cmd == "ping" then command("ping")
  elseif cmd == "u" or cmd == "up" then mov(0, cfg.step, 0)
  elseif cmd == "d" or cmd == "down" then mov(0, -cfg.step, 0)
  elseif cmd == "f" or cmd == "fwd" then mov(0, 0, cfg.step)
  elseif cmd == "b" or cmd == "back" then mov(0, 0, -cfg.step)
  elseif cmd == "l" or cmd == "left" then mov(-cfg.step, 0, 0)
  elseif cmd == "r" or cmd == "right" then mov(cfg.step, 0, 0)
  elseif cmd == "mov" then
    mov(tonumber(parts[2]) or 0, tonumber(parts[3]) or 0, tonumber(parts[4]) or 0)
  elseif cmd == "step" then
    cfg.step = tonumber(parts[2]) or STEP_DEFAULT
    saveCfg()
    log("step=" .. cfg.step)
  elseif cmd == "home" then
    cfg.home_x = tonumber(parts[2]) or 0
    cfg.home_y = tonumber(parts[3]) or 0
    cfg.home_z = tonumber(parts[4]) or 0
    saveCfg()
    pushCfg()
    log(string.format("home=%d,%d,%d", cfg.home_x, cfg.home_y, cfg.home_z))
  elseif cmd == "here" then
    local x, y, z = where()
    if x then
      cfg.home_x, cfg.home_y, cfg.home_z = x, y, z
      saveCfg()
      pushCfg()
      log(string.format("home=%d,%d,%d (here)", x, y, z))
    end
  elseif cmd == "push" then pushCfg()
  elseif cmd == "cfg" then showCfg()
  elseif cmd == "where" then
    local x, y, z = where()
    if x then log(string.format("pos %d,%d,%d", x, y, z)) end
  elseif cmd == "goto" then
    local tx, ty, tz = tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])
    if tx and gotoPos(tx, ty, tz) then log("VERDICT: GOTO_OK") end
  elseif cmd == "charge" then charge()
  elseif cmd == "halt" then command("halt")
  elseif cmd == "demo" then runDemo()
  elseif cmd == "mission" then runMission()
  elseif cmd == "help" then help()
  elseif cmd == "quit" or cmd == "q" or cmd == "exit" then return false
  else log("unknown: " .. cmd)
  end
  return true
end

local function main()
  loadCfg()
  logFile = io.open(LOG_PATH, "a")
  if logFile then
    logFile:write("\n=== server start " .. os.date("%Y-%m-%d %X") .. " ===\n")
    logFile:flush()
  end

  print("=== drone server ===")
  print("Port:  " .. PORT)
  print("Log:   " .. LOG_PATH)
  print("Errors:" .. ERR_PATH)
  print("VERDICT: SERVER_READY")
  print("")

  if RUN_DEMO then
    runDemo()
    return
  end

  while true do
    io.write("drone> ")
    local line = io.read()
    if not line then break end
    local quit = false
    errlog.guard("dispatch:" .. line, function()
      if not dispatch(line) then quit = true end
    end, ERR_PATH)
    if quit then break end
  end
end

local ok = errlog.guard("main", main, ERR_PATH)
if logFile then logFile:close() end
print(ok and "VERDICT: SERVER_STOP" or "VERDICT: SERVER_CRASH")
