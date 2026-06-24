--[[
  Запись ошибок в файл (OpenOS).
  Использование: local errlog = dofile("errlog.lua")
]]

local errlog = {}

local DEFAULT_PATH = "drone-error.txt"

function errlog.path()
  return DEFAULT_PATH
end

function errlog.write(tag, err, path)
  path = path or DEFAULT_PATH
  local f = io.open(path, "a")
  if not f then
    return false
  end
  f:write(string.format("\n=== %s %s ===\n", tostring(tag), os.date("%Y-%m-%d %X")))
  f:write(tostring(err))
  if not tostring(err):match("\n") then
    f:write("\n")
  end
  f:close()
  return true
end

function errlog.guard(tag, fn, path)
  local ok, res = xpcall(fn, debug.traceback)
  if not ok then
    errlog.write(tag, res, path)
    print("ERROR (see " .. (path or DEFAULT_PATH) .. ")")
    local first = tostring(res):match("([^\n]+)")
    if first then print(first) end
    return false, res
  end
  return true, res
end

return errlog
