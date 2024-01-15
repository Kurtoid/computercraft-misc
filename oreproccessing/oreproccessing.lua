local inputChest = peripheral.wrap("minecraft:chest_1")
local enrichingFactory = peripheral.wrap("minecraft:chest_4")
local smeltingFactory = peripheral.wrap("minecraft:chest_5")
local inductionSmelter = peripheral.wrap("minecraft:chest_6")
print("Input chest: " .. peripheral.getName(inputChest))
print("Enriching factory: " .. peripheral.getName(enrichingFactory))
print()

local configFileName = "config.json"

-- function listToDict(list)
--     local dict = {}
--     for _, item in pairs(list) do
--         dict[item] = true
--     end
--     return dict
-- end

function serializeConfig(config)
    serialized = textutils.serializeJSON(config)
    -- write to file
    local file = fs.open(configFileName, "w")
    file.write(serialized)
    file.close()
end

function deserializeConfig()
    local file = fs.open(configFileName, "r")
    local serialized = file.readAll()
    file.close()
    return textutils.unserializeJSON(serialized)
end

function makeBaseConfig()
    local enrichItemList = {"forge:raw_materials/copper", "forge:ores/certus_quartz",
    "forge:raw_materials/iron", "forge:ores/coal", "forge:raw_materials/lead", "forge:raw_materials/silver",}
    local smeltItemList = {}
    local inductionSmeltItemList = {}
    -- keep the written config the simplified list format for ease of editing
    local unknownItems = {}
    local config = {
        enrichItemList = enrichItemList,
        smeltItemList = smeltItemList,
        inductionSmeltItemList = inductionSmeltItemList,
        unknownItems = unknownItems,
    }
    return config
end

function loadConfig()
    if fs.exists(configFileName) then
        return deserializeConfig()
    else
        local config = makeBaseConfig()
        serializeConfig(config)
        return config
    end
end

local config = loadConfig()

-- for each destination, we have a list of items, and a destination.
-- convert these into a single lookup table of item: destination
function createProcessingTable(table, list, destination)
    for _, item in pairs(list) do
        table[item] = destination
    end
end

local processingTable = {}

createProcessingTable(processingTable, config.enrichItemList, enrichingFactory)
createProcessingTable(processingTable, config.smeltItemList, smeltingFactory)
createProcessingTable(processingTable, config.inductionSmeltItemList, inductionSmelter)
-- repeat for other destinations

-- now, to find out where to send an item, we just look it up in the table

local inputChestSlotIndex = 1

-- get any item from the chest
-- returns a name and a slot number
-- if called successively, will return all items in the chest
function getSingleItem()
    -- start at inputChestSlotIndex
    -- if we find an item, update inputChestSlotIndex and return it
    -- if we reach the end of the chest, set inputChestSlotIndex to 1 and return nil
    local slot = inputChestSlotIndex
    local item = inputChest.getItemDetail(slot)
    while item == nil do
        slot = slot + 1
        if slot > inputChest.size() then
            inputChestSlotIndex = 1
            return nil
        end
        item = inputChest.getItemDetail(slot)
    end
    inputChestSlotIndex = slot + 1
    if inputChestSlotIndex > inputChest.size() then
        inputChestSlotIndex = 1
    end
    return item.name, slot
end

function getTagsForItem(origin, slot)
    local tags = {}
    local item = origin.getItemDetail(slot)
    if item == nil then
        return tags
    end
    for tag, _ in pairs(item.tags) do
        table.insert(tags, tag)
    end
    return tags
end

function getDestinationForTags(tags)
    for _, tag in pairs(tags) do
        if processingTable[tag] ~= nil then
            return processingTable[tag]
        end
    end
    return nil
end

function processOneOre()
    local name, slot = getSingleItem()
    if name == nil then
        print("No items in chest")
        return
    end
    print("Processing " .. name .. " in slot " .. slot)
    itemTags = getTagsForItem(inputChest, slot)
    destination = getDestinationForTags(itemTags)
    if destination == nil then
        print("No destination for item " .. name)
        -- is name in the unknownItems list?
        if config.unknownItems[name] == nil then
            config.unknownItems[name] = itemTags
            for _, tag in pairs(itemTags) do
                print("  " .. tag)
            end
        end
    else
        -- remove from unknownItems, if present
        config.unknownItems[name] = nil
        print("Sending to " .. peripheral.getName(destination))
        local result = inputChest.pushItems(peripheral.getName(destination), slot)
        print("Push result: " .. result)
    end
    print("done")
    print()

end

local timer_id = os.startTimer(0.1)
function timerTick()
    local event, id
    repeat
        -- event, id = os.pullEvent("timer")
        event = {os.pullEventRaw()}
        if event[1] == "terminate" then
            print("Terminating")
            return false
        elseif event[1] == "timer" then
            id = event[2]
        end
    
    until id == timer_id
    processOneOre()
    timer_id = os.startTimer(0.1)
    return true
end

while true do
    local result = timerTick()
    if not result then
        serializeConfig(config)
        print("saved config")
        break
    end
end
