--[[
  Обновление по repo.url (аналог .env).

  1) edit repo.url
  2) lua pull.lua

  Весь вывод (включая wget и ошибки) — в pull-log.txt
  В игре: cat pull-log.txt
]]

local LOG_PATH = "pull-log.txt"
local CONFIG = "repo.url"
local INSTALL = "install.lua"
local MANIFEST = "manifest.txt"
local CONSOLE_QUIET = true

local CLI_ARGS = { ... }

local unpack = table.unpack or unpack

local logFile = io.open(LOG_PATH, "w")
if logFile then
  logFile:write("=== pull " .. os.date("%Y-%m-%d %X") .. " ===\n")
end

local nativePrint = print

local function logRaw(msg)
  msg = tostring(msg)
  if logFile then
    logFile:write(msg .. "\n")
    logFile:flush()
  end
end

local function log(msg)
  msg = tostring(msg)
  logRaw(os.date("%X ") .. msg)
  if not CONSOLE_QUIET then
    nativePrint(msg)
  end
end

local function logTrace(tag, err)
  err = tostring(err)
  logRaw(os.date("%X ") .. tag .. ": " .. err)
  if debug and debug.traceback then
    logRaw(debug.traceback(err, 2))
  end
end

local function say(msg)
  nativePrint(msg)
  logRaw(os.date("%X ") .. "[console] " .. msg)
end

local function appendFileToLog(path, title)
  local f = io.open(path, "r")
  if not f then
    log(title .. ": файл " .. path .. " не найден")
    return
  end
  log(title .. " (" .. path .. "):")
  for line in f:lines() do
    logRaw("  " .. line)
  end
  f:close()
end

local ok, err = xpcall(function()
  local shell = require("shell")
  local filesystem = require("filesystem")
  local computer = require("computer")
  local component = require("component")

  local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
  end

  local function shellToLog(cmd, ...)
    local args = { ... }
    local parts = { cmd }
    for i = 1, #args do
      parts[#parts + 1] = tostring(args[i])
    end
    log("exec: " .. table.concat(parts, " "))
    logRaw("  (stdout/stderr -> " .. LOG_PATH .. ")")
    local results = {
      shell.execute(cmd, nil, unpack(args), ">>", LOG_PATH, "2>>", LOG_PATH)
    }
    local first, second = results[1], results[2]
    log("  exit: " .. tostring(first) .. " " .. tostring(second or ""))
    if first == true or first == 0 then
      return true, second
    end
    return false, second or ("exit " .. tostring(first))
  end

  local function readBase(path)
    path = path or CONFIG
    log("read " .. path)
    local f = io.open(path, "r")
    if not f then
      return nil, "нет файла " .. path .. " (edit repo.url)"
    end
    local raw = f:read("*a") or ""
    f:close()
    log("  bytes: " .. #raw)
    for line in raw:gmatch("[^\r\n]+") do
      line = trim(line)
      if line ~= "" and not line:match("^#") then
        log("  url: " .. line)
        if line:sub(-1) ~= "/" then
          line = line .. "/"
        end
        if not line:match("^https?://") then
          return nil, "нужен http(s) URL"
        end
        if line:match("^https?://github%.com/") then
          return nil, "нужен raw.githubusercontent.com (кнопка Raw)"
        end
        return line
      end
    end
    return nil, path .. " пустой или только комментарии"
  end

  local function ensureParentDir(path)
    local parent = path:match("^(.+)/[^/]+$")
    if not parent or parent == "" then return end
    if not filesystem.exists(parent) then
      filesystem.makeDirectory(parent)
    end
  end

  local function downloadFile(url, dest)
    log("GET " .. url)
    dest = shell.resolve(dest)
    log("  -> " .. tostring(dest))

    if not component.isAvailable("internet") then
      return false, "нет Internet Card в компьютере"
    end

    ensureParentDir(dest)

    local okWget, reason = shellToLog("wget", "-f", url, dest)
    if not okWget then
      return false, reason or "wget failed"
    end

    if not filesystem.exists(dest) then
      return false, "файл не создан: " .. dest
    end

    local sizeF = io.open(dest, "r")
    if sizeF then
      local n = #(sizeF:read("*a") or "")
      sizeF:close()
      log("  size: " .. n .. " bytes")
      if n == 0 then
        filesystem.remove(dest)
        return false, "файл пустой (0 bytes) — проверьте URL"
      end
    end

    log("download ok")
    return true
  end

  local function runInstall(manifestPath)
    log("run install.lua (in-process) ...")
    _G.__INSTALL_ARG__ = manifestPath
    _G.__INSTALL_LAST_OK__ = nil

    local chunk, loadErr = loadfile(INSTALL)
    if not chunk then
      _G.__INSTALL_ARG__ = nil
      logTrace("loadfile " .. INSTALL, loadErr)
      return false
    end

    local okRun, runErr = xpcall(chunk, debug.traceback)
    _G.__INSTALL_ARG__ = nil

    appendFileToLog("install-log.txt", "--- install-log.txt ---")

    if not okRun then
      logTrace("install.lua uncaught", runErr)
      return false
    end
    if _G.__INSTALL_LAST_OK__ == false then
      log("install.lua: VERDICT fail (см. install-log.txt выше)")
      return false
    end
    if _G.__INSTALL_LAST_OK__ ~= true then
      log("install.lua: неизвестный результат, см. install-log.txt")
      return false
    end
    return true
  end

  log("log: " .. LOG_PATH)
  log("pwd: " .. tostring(shell.getWorkingDirectory()))
  log("uptime: " .. tostring(computer.uptime()))
  log("internet: " .. tostring(component.isAvailable("internet")))

  local base, readErr = readBase(CLI_ARGS[1])
  if not base then
    log("VERDICT: PULL_FAIL")
    log(readErr)
    return false
  end

  log("base: " .. base)

  local okDl, reason = downloadFile(base .. INSTALL, INSTALL)
  if not okDl then
    log("VERDICT: PULL_FAIL (install.lua)")
    log(tostring(reason))
    return false
  end

  okDl, reason = downloadFile(base .. MANIFEST, MANIFEST)
  if not okDl then
    log("VERDICT: PULL_FAIL (manifest.txt)")
    log(tostring(reason))
    return false
  end

  if not runInstall(MANIFEST) then
    log("VERDICT: PULL_FAIL (install.lua run)")
    return false
  end

  log("VERDICT: PULL_OK")
  return true
end, debug.traceback)

if not ok then
  log("VERDICT: PULL_FAIL (crash)")
  logTrace("crash", err)
elseif err == false then
  -- уже залогировано
end

if logFile then
  logFile:close()
end

if ok and err ~= false then
  say("OK — cat " .. LOG_PATH)
else
  say("ОШИБКА — cat " .. LOG_PATH)
end
