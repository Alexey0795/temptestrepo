--[[
  Обновление по repo.url (аналог .env — один URL в файле).

  1) edit repo.url   — одна строка: raw @base с / на конце
  2) lua pull.lua    — качает install.lua + manifest, запускает install

  На роботе: cd в свою папку, положите repo.url и pull.lua рядом.
]]

local shell = require("shell")
local filesystem = require("filesystem")

local CONFIG = "repo.url"
local INSTALL = "install.lua"
local MANIFEST = "manifest.txt"

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function readBase(path)
  path = path or CONFIG
  local f = io.open(path, "r")
  if not f then
    return nil, "нет файла " .. path .. " (edit repo.url)"
  end
  local line = trim(f:read("*l") or "")
  f:close()
  if line == "" or line:match("^#") then
    return nil, path .. " пустой"
  end
  if line:sub(-1) ~= "/" then
    line = line .. "/"
  end
  if not line:match("^https?://") then
    return nil, "нужен http(s) URL, не github.com страница"
  end
  if line:match("^https?://github%.com/") then
    return nil, "нужен raw.githubusercontent.com (кнопка Raw на GitHub)"
  end
  return line
end

local function wget(url, dest)
  print("GET " .. dest)
  local ok, reason = shell.execute("wget", "-f", url, dest)
  if not ok then
    return false, reason or "wget failed"
  end
  if not filesystem.exists(dest) then
    return false, "файл не появился"
  end
  return true
end

local base, err = readBase(({ ... })[1])
if not base then
  print("VERDICT: PULL_FAIL")
  print(err)
  return
end

print("=== pull ===")
print("base: " .. base)

local ok, reason = wget(base .. INSTALL, INSTALL)
if not ok then
  print("VERDICT: PULL_FAIL")
  print(reason)
  return
end

ok, reason = wget(base .. MANIFEST, MANIFEST)
if not ok then
  print("VERDICT: PULL_FAIL")
  print(reason)
  return
end

print("run install.lua ...")
ok, reason = shell.execute("lua", INSTALL, MANIFEST)
if not ok then
  print("VERDICT: PULL_FAIL")
  print(tostring(reason))
  return
end

print("VERDICT: PULL_OK")
