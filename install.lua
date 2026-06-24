--[[
  Установщик по manifest.txt (OpenOS, Internet Card).

  lua install.lua
  lua install.lua manifest.txt

  Весь вывод — в install-log.txt
  В игре: cat install-log.txt

  Подробно: docs/deploy-internet.md
]]

local LOG_PATH = "install-log.txt"
local DEFAULT_MANIFEST = "manifest.txt"
local CONSOLE_QUIET = true

local CLI_ARGS
if _G.__INSTALL_ARG__ ~= nil then
  CLI_ARGS = { _G.__INSTALL_ARG__ }
else
  CLI_ARGS = { ... }
end

local unpack = table.unpack or unpack

local logFile = io.open(LOG_PATH, "w")
if logFile then
  logFile:write("=== install " .. os.date("%Y-%m-%d %X") .. " ===\n")
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

local ok, err = xpcall(function()
  local shell = require("shell")
  local filesystem = require("filesystem")

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

  local function ensureParentDir(path)
    local parent = path:match("^(.+)/[^/]+$")
    if not parent or parent == "" then return end
    if not filesystem.exists(parent) then
      filesystem.makeDirectory(parent)
    end
  end

  local function wget(url, dest)
    ensureParentDir(dest)
    log("GET " .. dest)
    local okWget, reason = shellToLog("wget", "-f", url, dest)
    if not okWget then
      return false, reason or "wget failed"
    end
    if not filesystem.exists(dest) then
      return false, "file missing after wget"
    end
    return true
  end

  local function loadManifest(path)
    local f = io.open(path, "r")
    if not f then
      return nil, "cannot open " .. path
    end
    local base = nil
    local files = {}
    for line in f:lines() do
      line = trim(line)
      if line ~= "" and not line:match("^#") then
        if line:match("^@base%s+") then
          base = trim(line:gsub("^@base%s+", ""))
        else
          files[#files + 1] = line
        end
      end
    end
    f:close()
    if not base or base == "" then
      return nil, "manifest: missing @base"
    end
    if base:sub(-1) ~= "/" then
      base = base .. "/"
    end
    if #files == 0 then
      return nil, "manifest: empty file list"
    end
    return { base = base, files = files }
  end

  local function resolveManifestArg(arg1)
    if not arg1 or arg1 == "" then
      if filesystem.exists(DEFAULT_MANIFEST) then
        return DEFAULT_MANIFEST, false
      end
      return nil, "no manifest (wget manifest.txt or pass URL)"
    end
    if arg1:match("^https?://") then
      log("fetch manifest " .. arg1)
      local okWget, wgetErr = wget(arg1, DEFAULT_MANIFEST)
      if not okWget then return nil, wgetErr end
      return DEFAULT_MANIFEST, true
    end
    return arg1, false
  end

  log("log: " .. LOG_PATH)
  log("pwd: " .. tostring(shell.getWorkingDirectory()))
  log("args: " .. tostring(CLI_ARGS[1] or "(default manifest.txt)"))

  local manifestArg = CLI_ARGS[1]
  local manifestPath, fetched = resolveManifestArg(manifestArg)
  if not manifestPath then
    log("VERDICT: INSTALL_FAIL")
    log(fetched)
    return false
  end

  local manifest, loadErr = loadManifest(manifestPath)
  if not manifest then
    log("VERDICT: INSTALL_FAIL")
    log(loadErr)
    return false
  end

  log("=== install start ===")
  log("base: " .. manifest.base)
  if fetched then
    log("manifest: downloaded -> " .. manifestPath)
  else
    log("manifest: " .. manifestPath)
  end

  local okCount, failCount = 0, 0
  for i = 1, #manifest.files do
    local rel = manifest.files[i]
    local url = manifest.base .. rel
    local okWget, reason = wget(url, rel)
    if okWget then
      okCount = okCount + 1
    else
      failCount = failCount + 1
      log("FAIL " .. rel .. ": " .. tostring(reason))
    end
    os.sleep(0)
  end

  log(string.format("done: %d ok, %d fail", okCount, failCount))
  if failCount > 0 then
    log("VERDICT: INSTALL_PARTIAL")
    return false
  end
  log("VERDICT: INSTALL_OK")
  return true
end, debug.traceback)

if not ok then
  log("VERDICT: INSTALL_FAIL (crash)")
  logTrace("crash", err)
  _G.__INSTALL_LAST_OK__ = false
elseif err == false then
  _G.__INSTALL_LAST_OK__ = false
else
  _G.__INSTALL_LAST_OK__ = true
end

if logFile then
  logFile:close()
end

if _G.__INSTALL_ARG__ == nil then
  if _G.__INSTALL_LAST_OK__ then
    say("OK — cat " .. LOG_PATH)
  else
    say("ОШИБКА — cat " .. LOG_PATH)
  end
end
