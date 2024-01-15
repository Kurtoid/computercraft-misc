local c = peripheral.wrap("left")
local ar = peripheral.wrap("top")
ar.clear()
--c.sendMessageToPlayer("test", "Kurtoid")

local inv = peripheral.wrap("right")

local knownInfusers = {["Strength"]=32000,
                 ["Swiftness"]=32000,
                 ["Resistance"]=32000,
                 ["Regeneration"]=32000}
local fillThresh = 0.15

function setContains(set, key)
    return set[key] ~= nil
end

local dctl = require("dronectl")

function checkLevels()
    print('checking levels')
  local curios = inv.listCurios()
  for _, curio in pairs(curios) do repeat
    --print(curio.nbt.display.Name)
  local displayName = curio.nbt.display
    if displayName == nil then
        break
    end
    displayName = textutils.unserializeJSON(displayName.Name).text
    local fluidAmount = curio.nbt.Fluid
    if fluidAmount == nil then
        fluidAmount = 0
    else
        fluidAmount = fluidAmount.Amount
    end
    print(displayName .. " " .. fluidAmount .. " out of " .. knownInfusers[displayName])
    if fluidAmount < knownInfusers[displayName] * fillThresh then
        c.sendMessageToPlayer("Your " .. displayName .. " is low: " .. fluidAmount, "Kurtoid")
        sleep(1)

    end
  until true end
end

local potionTime = 0
print(os.time())
while true do
    dctl()
    local ctime = (os.time() * 1000 + 18000)%24000
    if ctime - potionTime > 20*30 then
        checkLevels()
        potionTime = ctime
    end
    os.queueEvent("wait")
    os.pullEvent("wait")
    sleep(1)
    -- ar.clear()
end


