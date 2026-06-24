--[[
  09 — минимальный эксперимент: корутины + event.pull (OpenOS).

  Запуск:
    cd experiment
    lua 09-coroutine-demo.lua

  Что происходит:
    - «worker» — корутина, печатает шаг и отдаёт управление (yield)
    - «main» — ждёт Enter или 3s, снова resume

  VERDICT: CORO_OK  — 3 шага, корутина завершилась
  VERDICT: CORO_FAIL — ошибка resume
]]

local event = require("event")
local computer = require("computer")
local keyboard = require("keyboard")

local STEPS = 3
local AUTO_SEC = 3

local function isEnter(ev)
  return ev[1] == "key_down"
    and (ev[4] == keyboard.keys.enter or ev[4] == keyboard.keys.numpadenter)
end

local worker = coroutine.create(function()
  for i = 1, STEPS do
    print(string.format("worker: step %d / %d", i, STEPS))
    coroutine.yield("need_wait")
  end
  return "finished"
end)

local function waitEnterOrTimeout()
  local deadline = computer.uptime() + AUTO_SEC
  repeat
    local ev = { event.pull(1) }
    if isEnter(ev) then
      print("main: Enter")
      return
    end
    if computer.uptime() >= deadline then
      print(string.format("main: auto (%ds)", AUTO_SEC))
      return
    end
    os.sleep(0)
  until false
end

print("=== coroutine demo ===")
print("Enter — следующий шаг. Без Enter — шаг через " .. AUTO_SEC .. "s")
print("")

while coroutine.status(worker) ~= "dead" do
  local ok, token = coroutine.resume(worker)
  if not ok then
    print("VERDICT: CORO_FAIL")
    print(tostring(token))
    os.exit(1)
  end
  if coroutine.status(worker) == "dead" then
    print("VERDICT: CORO_OK result=" .. tostring(token))
    os.exit(0)
  end
  if token == "need_wait" then
    waitEnterOrTimeout()
  end
end

print("VERDICT: CORO_OK")
