--[[
  Установщик по manifest.txt (OpenOS, Internet Card).

  Первый раз (одна команда wget + запуск):
    wget -f https://raw.githubusercontent.com/USER/next-attempt-03/main/deploy/install.lua install.lua
    lua install.lua https://raw.githubusercontent.com/USER/next-attempt-03/main/deploy/manifest.txt

  Обновление (когда install.lua уже на диске):
    lua install.lua
    lua install.lua manifest.txt

  Лог: install-log.txt   В игре: cat install-log.txt

  Подробно: docs/deploy-internet.md
]]

local LOG_PATH = "install-log.txt"
local DEFAULT_MANIFEST = "manifest.txt"

local CLI_ARGS = { ... }

local logFile = io.open(LOG_PATH, "w")
if logFile then
  logFile:write("=== install " .. os.date("%Y-%m-%d %X") .. " ===\n")
end

local function log(msg)
  msg = tostring(msg)
  print(msg)
  if logFile then
    logFile:write(os.date("%X ") .. msg .. "\n")
    logFile:flush()
  end
end

local function logTrace(tag, err)
  log(tag .. ": " .. tostring(err))
  if debug and debug.traceback then
    log(debug.traceback(err, 2))
  end
end

local ok, err = xpcall(function()
  local shell = require("shell")
  local filesystem = require("filesystem")

  local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
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
    local okWget, reason = shell.execute("wget", "-f", url, dest)
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
  log("cd experiment && lua 07-drone-server.lua")
  return true
end, debug.traceback)

if not ok then
  log("VERDICT: INSTALL_FAIL (crash)")
  logTrace("crash", err)
elseif err == false then
  -- main вернул false — уже залогировано
end

if logFile then
  logFile:close()
end

print("log: cat " .. LOG_PATH)
