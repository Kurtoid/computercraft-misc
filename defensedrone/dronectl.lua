local dr = peripheral.wrap("bottom")
local pl = peripheral.wrap("back")
local chat = peripheral.wrap("left")
local ar = peripheral.wrap("top")

function waitAction(d)
    if d.getAction() == nil then return end
    while (not d.isActionDone()) do
      sleep(1)
    end
end


function vecDist(p1, p2)
    if p1 == nil or p2 == nil then return 0 end
    if p1.x == nil or p2.x == nil then return 0 end

    return math.sqrt((p1.x-p2.x)^2 + (p1.y-p2.y)^2 + (p1.z-p2.z)^2)
end


function goto(plloc, wait)
    dr.addArea(plloc.x, plloc.y, plloc.z, plloc.x, plloc.y+1, plloc.z, "Filled")
    dr.setAction("goto")
    if wait then
        waitAction(dr)
    end
    dr.clearArea()
end

local lastGotoPos = nil
local lastGotoThresh = 3

function gotoFast(plloc, dr, wait)
    -- dronepos = dr.getDronePositionVec()
    if lastGotoPos == nil or vecDist(plloc, lastGotoPos) > lastGotoThresh then
        print("too far, moving")
        goto(plloc, wait)
        lastGotoPos = plloc
    else
        -- print("close enough")
    end
end

dr.hideArea()

local playerName = "Kurtoid"
local charging = false
local chargingLoc = {x=48, y=12, z=22}
function runDroneStep()
    if not dr.isConnectedToDrone() then return end

    -- save position
    dronepos = dr.getDronePositionVec()
    local file = fs.open("dronepos","w")
    file.write(textutils.serialize(dronepos))
    file.close()

    -- charging
    local dronePres = dr.getDronePressure()
    if dronePres < 6 then -- TODO: testing - set to 2
        if not charging then
            charging = true
            chat.sendMessageToPlayer("Low pressure!", "Kurtoid")
            dr.clearArea()
            goto(chargingLoc, true)
            dr.setAction("suicide")
            -- when the drone restarts, it will run it's hardcoded script before connecting to the controller
            return
        end
    end
    if charging then
        -- if dronePres > 9 then
        --     charging = false
        --     chat.sendMessageToPlayer("Done charging!", "Kurtoid")
        -- end

        -- drone could be exported early - if we can reach it, just continue
        charging = false
    end
    if charging then return end

    plloc = pl.getPlayerPos(playerName)
    if plloc == nil or plloc.x == nil then
        local chloc = {x=48, y=78, z=40}
        goto(chloc, true)
        return
    end
    dronepos = dr.getDronePositionVec()
    local dist = vecDist(plloc, dronepos)

    ar.drawStringWithId("dronepos", string.format("drone x: %5d y: %5d z: %5d dist: %5d", dronepos.x, dronepos.y, dronepos.z, dist), 10, 500, 0xffffff)
    ar.drawStringWithId("dronepres", string.format("        pres: %5d%%", dronePres*10), 10, 510, 0xffffff)

    -- go to player
    if dist > 5 then
        dr.abortAction()
        print('going to player ' .. dist)
        gotoFast(plloc, dr, false)
    else
        dr.abortAction()
        lastGotoPos = nil -- we might have aborted a valid move
        -- check for things to attack
        local attackRadius = 15
        -- dr.addArea(plloc.x-attackRadius, plloc.y-attackRadius, plloc.z-attackRadius, plloc.x+attackRadius, plloc.y+attackRadius, plloc.z+attackRadius, "Filled")
        dr.setVariable("attackzone1", plloc.x-attackRadius, plloc.y-attackRadius, plloc.z-attackRadius)
        dr.setVariable("attackzone2", plloc.x+attackRadius, plloc.y+attackRadius, plloc.z+attackRadius)

        -- the below block is now done in pneu code
        -- query for mobs (or kurtoid)
        -- dr.setMaxActions(1)
        -- dr.setUseMaxActions(false)
        -- dr.clearWhitelistText()
        -- dr.addWhitelistText("@mob")
        -- dr.addBlacklistText("@player")
        --dr.setCheckLineOfSight(true)
        -- dr.setAction("entity_attack")
        -- waitAction(dr)
        -- dr.setUseMaxActions(false)
        -- dr.clearBlacklistText()
        -- dr.clearWhitelistText()
        -- dr.clearArea()
        -- print('done attacking')
        dr.exitPiece()
    end
end


return runDroneStep

