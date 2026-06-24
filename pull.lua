--[[
  Обновление по repo.url (аналог .env).

  1) edit repo.url
  2) lua pull.lua

  Лог: pull-log.txt   В игре: cat pull-log.txt
]]

local LOG_PATH = "pull-log.txt"
local CONFIG = "repo.url"
local INSTALL = "install.lua"
local MANIFEST = "manifest.txt"

local logFile = io.open(LOG_PATH, "w")
if logFile then
  logFile:write("=== pull " .. os.date("%Y-%m-%d %X") .. " ===\n")
end

local function log(line)
  line = tostring(line)
  print(line)
  if logFile then
    logFile:write(os.date("%X ") .. line .. "\n")
    logFile:flush()
  end
end

local function logTrace(tag, err)
  log(tag .. ": " .. tostring(err))
  if debug and debug.traceback then
    log(debug.traceback(err, 2))
  end
end

local function appendFileToLog(path, title)
  local f = io.open(path, "r")
  if not f then
    log(title .. ": файл " .. path .. " не найден")
    return
  end
  log(title .. " (" .. path .. "):")
  for line in f:lines() do
    log("  " .. line)
  end
  f:close()
end

-- ... только на верхнем уровне скрипта (аргументы lua pull.lua …)
local CLI_ARGS = { ... }

local ok, err = xpcall(function()
  local shell = require("shell")
  local filesystem = require("filesystem")
  local computer = require("computer")
  local component = require("component")

  local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
  end

  local function shellSucceeded(...)
    local results = { ... }
    local first = results[1]
    local second = results[2]

    if first == true then
      return true, second
    end
    if first == false or first == nil then
      return false, second or "shell returned false/nil"
    end
    if type(first) == "number" then
      if first == 0 then
        return true, second
      end
      return false, second or ("exit code " .. first)
    end
    return false, "unexpected shell result: " .. tostring(first)
  end

  local function logShell(cmd, ...)
    local args = { ... }
    local parts = { cmd }
    for i = 1, #args do
      parts[#parts + 1] = tostring(args[i])
    end
    log("exec: " .. table.concat(parts, " "))
    local results = { shell.execute(cmd, nil, ...) }
    for i = 1, #results do
      log("  ret[" .. i .. "]: " .. tostring(results[i]))
    end
    return shellSucceeded(table.unpack(results))
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

    local okWget, reason = logShell("wget", "-f", url, dest)
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

  log("run install.lua ...")
  local okRun, runErr = logShell("lua", INSTALL, MANIFEST)
  if not okRun then
    log("VERDICT: PULL_FAIL (install.lua run)")
    log(tostring(runErr))
    appendFileToLog("install-log.txt", "--- install.lua ---")
    return false
  end

  log("VERDICT: PULL_OK")
  return true
end, debug.traceback)

if not ok then
  log("VERDICT: PULL_FAIL (crash)")
  logTrace("crash", err)
elseif err == false then
  -- main вернул false — уже залогировано
end

if logFile then
  logFile:close()
end

print("log: cat " .. LOG_PATH)
