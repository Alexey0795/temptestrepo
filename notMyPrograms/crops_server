local event = require("event")
local cmp = require("component")
local srl = require("serialization")
local messagesListen = 0
local interruptListen = 0
local exitF = false
local crops = {
    C5 = "0f45",
    M4 = "f42b",
    C4 = "2b6c",
    M3 = "367a",
    C3 = "0ddc",
    M2 = "04bd",
    C2 = "0c0d",
    M1 = "d02f",
    C1 = "76c8"
}
local cropSizes = {
    weed = 5,
    brownmushrooms = 3,
    pumpkin = 4,
    redmushrooms = 3,
    wheat = 7,
    brownmushroom = 3,
    carrots = 3,
    dandelion = 4,
    rose = 4,
    flax = 4,
    indigo = 4,
    melon = 4,
    olivia = 4,
    potato = 4,
    redmushroom = 3,
    reed = 3,
    cocoa = 4,
    fertilia = 4,
    venomilia = 6,
    zomplant = 4,
    sapphirum = 4,
    spidernip = 4,
    stickreed = 4,
    corpseplant = 4,
    hops = 7,
    netherwart = 3,
    nickelback = 3,
    terrawart = 3,
    tine = 3,
    bauxia = 3,
    blazereed = 4,
    coppon = 3,
    corium = 4,
    cyprium = 4,
    eatingplant = 6,
    eggplant = 3,
    ferru = 4,
    galvania = 3,
    milkwart = 3,
    plumbilia = 4,
    plumbiscus = 4,
    redwheat = 7,
    slimeplant = 4,
    stagnium = 4,
    trollplant = 5,
    argentia = 4,
    coffee = 5,
    creeperweed = 4,
    lazulia = 4,
    meatrose = 4,
    aurelia = 5,
    evilore = 4,
    liveroots = 4,
    shining = 5,
    tearstalks = 4,
    withereed = 4,
    godofthunder = 4,
    oilberries = 4,
    titania = 3,
    enderbloom = 4,
    glowheat = 7,
    steeleafranks = 4,
    bobsyeruncleranks = 4,
    platina = 4,
    diareed = 4,
    pyrolusium = 3,
    quantaria = 4,
    reactoria = 4,
    scheelinium = 3,
    stargatium = 4,
    starwart = 4,
    transformium = 4,
    [""] = 0
}
cmp.modem.open(234)

local function stopAll()
    print("shutdown")
    event.cancel(messagesListen)
    event.cancel(interruptListen)
    exitF = true
end

local function getCrop(cropName)
    local cropStats = {
        exist = false,
        name = "",
        gain = 0,
        grow = 0,
        resistance = 0,
        size = 0,
        maxSize = 0
    }
    local addr, why = cmp.get(crops[cropName])
    if not addr then
        print("warning: "..why.." by addr: "..crops[cropName])
        return cropStats
    end
    local crop = cmp.proxy(addr)
    cropStats.exist = true
    cropStats.name = crop.getID()
    cropStats.gain = crop.getGain()
    cropStats.grow = crop.getGrowth()
    cropStats.resistance = crop.getResistance()
    cropStats.size = crop.getSize()
    cropStats.maxSize = cropSizes[string.lower(cropStats.name)] --openperipheral donthave api for this. string.lower is used just in case.
    return cropStats
end

local function scanCrop(...)
    local var = {...}
    print(var[6])
    if not var[6] then
        return
    end

    local tosend = getCrop(var[6])
    print(srl.serialize(tosend))
    cmp.modem.broadcast(234, "cropServer", srl.serialize(tosend))
end

messagesListen = event.listen("modem_message", scanCrop)
interruptListen = event.listen("interrupted", stopAll)

while not exitF do
    event.pull(5)
end