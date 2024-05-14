local ESX = exports["es_extended"]:getSharedObject()

local setups = {}
local setupPoints = {} -- Store references to setup points

local function SaveSetupsToFile(setups)
    local jsonData = json.encode(setups)
    SaveResourceFile(GetCurrentResourceName(), "moonshine.json", jsonData, -1)
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        print("Saving setups data before resource stop...")

        if not setups then
            print("Error: Failed to retrieve setup data")
            return
        end

        SaveSetupsToFile(setups)

        print("Setups data saved successfully.")
    end
end)

-- Function to load setups from the JSON file
local function LoadSetupsFromFile()
    local file = LoadResourceFile(GetCurrentResourceName(), "moonshine.json")
    if file then
        setups = json.decode(file) or {}
    end
    Wait(100)
    lib.callback.register('D2D-Moonshine:GetSetups', function()
    return setups
    end)
end

local function PrintSetups()
    Debug("Loaded setups:")
    for index, setup in ipairs(setups) do
        Debug("Setup " .. index .. ":")
        Debug("   ID: " .. setup.ID)
        Debug("   Coords: " .. json.encode(setup.Coords))
        Debug("   Heading: " .. setup.Heading)
        Debug("   Type: " .. setup.Type)
    end
end

Citizen.CreateThread(function()
    LoadSetupsFromFile()
end)

for item, data in pairs(D2D.MoonShine) do
    ESX.RegisterUsableItem(item, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if CheckIfSetup(xPlayer, item) then
            TriggerClientEvent('D2D-Moonshine:Notifications', source, D2D.Translation["havesetup"])
        else
            exports.ox_inventory:RemoveItem(source, item, 1)
            TriggerClientEvent('D2D-Moonshine:Setup', source, item)
        end
    end)
end

function CheckIfSetup(player, item)
    local identifier = player.getIdentifier()

    if not setups then
        print("Error: Setups table is nil")
        return false
    end

    for _, data in ipairs(setups) do
        if data.playerID == identifier and data.Type == item then
            return true
        end
    end

    return false
end


RegisterServerEvent("D2D-Moonshine:AddSpawn")
AddEventHandler("D2D-Moonshine:AddSpawn", function(propCoords, PropHeading, item)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    SaveSetupsToFile(setups)

    local file = LoadResourceFile(GetCurrentResourceName(), "moonshine.json")
    local existingData = {}
    if file then
        existingData = json.decode(file)
    end

    table.insert(existingData, {
        ID = "moonshine_equipment_"..math.random(1,9999).."_"..math.random(1,9999),
        playerID = identifier,
        Coords = propCoords,
        Heading = PropHeading,
        Type = item,
        Fuel = 0,
        Craft = nil,
        ABV = 0
    })

    local jsonData = json.encode(existingData)

    SaveResourceFile(GetCurrentResourceName(), "moonshine.json", jsonData, -1)

    LoadSetupsFromFile()
    Wait(3000)

    local players = GetPlayers()
    for _, player in ipairs(players) do
        if tonumber(player) ~= source then
            TriggerClientEvent('D2D-Moonshine:NewClient', player, setups)
        end
    end
end)


RegisterServerEvent("D2D-Moonshine:GiveBack")
AddEventHandler("D2D-Moonshine:GiveBack", function(canGive, item)
    canCarry = exports.ox_inventory:CanCarryItem(source, item, 1)
    if canGive then
        if canCarry then
            exports.ox_inventory:AddItem(source, item, 1)
        else
            TriggerClientEvent('D2D-Moonshine:Notifications', source, D2D.Translation["cantcarry"])
        end
    else
        print('ID: '..source..', is trying to exploit or trigger events using a lua executor.')
    end
end)

RegisterServerEvent("D2D-Moonshine:RemoveSpawn")
AddEventHandler("D2D-Moonshine:RemoveSpawn", function(ID, item)
    local source = source
    local canCarry = exports.ox_inventory:CanCarryItem(source, item, 1)
    if not canCarry then
        TriggerClientEvent('D2D-Moonshine:Notifications', source, D2D.Translation["cantcarry"])
        return
    end

    exports.ox_inventory:AddItem(source, item, 1)

    TriggerClientEvent('D2D-Moonshine:DeleteProp', -1, ID)

    SaveSetupsToFile(setups)

    local file = LoadResourceFile(GetCurrentResourceName(), "moonshine.json")
    if file then
        local setups = json.decode(file) or {}

        local setupIndexToRemove = nil
        for i, setup in ipairs(setups) do
            if setup.ID == ID then
                setupIndexToRemove = i
                break
            end
        end

        if setupIndexToRemove then
            table.remove(setups, setupIndexToRemove)
            Debug('Setup data removed with ID:', ID)

            local jsonData = json.encode(setups)
            SaveResourceFile(GetCurrentResourceName(), "moonshine.json", jsonData, -1)

            LoadSetupsFromFile()        
        else
            Debug('No setup data found with ID:', ID)
        end
    else
        Debug('Error: Unable to open moonshine.json')
    end
end)

RegisterServerEvent("D2D-Moonshine:AddFuel")
AddEventHandler("D2D-Moonshine:AddFuel", function(slotId, setupToUpdate)
    local source = source

    if not setups then
        print("Error: Failed to retrieve setup data")
        return
    end

    if not setupToUpdate then
        print("Error: Setup with ID " .. setupToUpdate.ID .. " not found")
        return
    end

    local slotData = exports.ox_inventory:GetSlot(source, slotId)
    if not slotData or not slotData.metadata or not slotData.metadata.ammo or not slotData.metadata.durability then
        print("Error: Missing or invalid metadata for fuel in slot data")
        return
    end

    local oldFuel = setupToUpdate.Fuel
    local fuelToAdd = slotData.metadata.ammo
    local newFuel = math.min(100, oldFuel + fuelToAdd) 

    local fuelUsed = newFuel - oldFuel

    slotData.metadata.ammo = math.max(0, slotData.metadata.ammo - fuelUsed) 
    slotData.metadata.durability = math.max(0, slotData.metadata.durability - fuelUsed) 

    exports.ox_inventory:SetMetadata(source, slotId, slotData.metadata)

    for i, setup in ipairs(setups) do
        if setup.ID == setupToUpdate.ID then
            setup.Fuel = newFuel
            setups[i] = setup
            break
        end
    end

    print("Fuel added to setup with ID:", setupToUpdate.ID)
end)

RegisterServerEvent("D2D-Moonshine:AddIngredient")
AddEventHandler("D2D-Moonshine:AddIngredient", function(setupToUpdate, item)

    exports.ox_inventory:RemoveItem(source, item, 1)
    if setups then
        for _, setup in ipairs(setups) do
            if setup.ID == setupToUpdate.ID then
                setup.Craft = item
                TriggerClientEvent('D2D-Moonshine:Notifications', source, string.format(D2D.Translation['added'], item))
                return
            end
        end
        print("Error: Setup not found with ID " .. setupToUpdate.ID)
    else
        print("Error: Failed to retrieve setup data")
    end
end)

RegisterServerEvent("D2D-Moonshine:AddReward")
AddEventHandler("D2D-Moonshine:AddReward", function(setupToUpdate)
    if setups then
        for _, setup in ipairs(setups) do
            if setup.ID == setupToUpdate.ID then
                if setup.Craft ~= nil then
                    setup.Craft = nil
                    local success, response = exports.ox_inventory:AddItem(source, 'moonshine', 1, 'ABV: ' .. setup.ABV)
                    setup.ABV = 0
                    if not success then
                        Debug("Failed to add moonshine with ABV " .. setup.ABV .. ": " .. response)
                    end
                else
                    TriggerClientEvent('D2D-Moonshine:Notifications', source, D2D.Translation["cheater"])
                end
                return  
            end
        end
        Debug("Error: Setup not found with ID " .. setupToUpdate.ID)
    else
        Debug("Error: Failed to retrieve setup data")
    end
end)


local fuelTick = tonumber(D2D.FuelTick) or 1

Citizen.CreateThread(function()
    while true do
        Wait(fuelTick * 1000) 
        for _, setup in ipairs(setups) do
            if setup.Fuel and setup.Fuel > 0 then
                setup.Fuel = math.max(0, setup.Fuel - 1)
                print(setup.Fuel)
            end
        end
    end
end)

local ABVTick = tonumber(D2D.ABVTick) or 1

Citizen.CreateThread(function()
    while true do
        Wait(ABVTick * 1000) -- Wait for ABVTick seconds
        
        for _, setup in ipairs(setups) do
            if setup.Fuel and setup.Fuel > 0 then
                -- Check if the setup has a crafting ingredient specified
                if setup.Craft then
                    local ingredientConfig = D2D.Ingredients[setup.Craft]
                    if ingredientConfig and ingredientConfig.maxABV then
                        -- Increase ABV by 1 if it's below the maximum allowed
                        setup.ABV = (setup.ABV or 0) + 1  -- Increase ABV by 1
                        setup.ABV = math.min(ingredientConfig.maxABV, setup.ABV) -- Cap ABV at max allowed
                    end
                end
            end
        end
    end
end)

