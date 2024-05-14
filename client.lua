ESX = exports["es_extended"]:getSharedObject()

local spawningProp, Fire = false, false
local prop, propSpawned = nil, nil
local setups = {}
local spawnedProps = {}
local points = {}

function handleSetups()
    setups = lib.callback.await('D2D-Moonshine:GetSetups', 400)

    Debug('Received setups from server:', json.encode(setups))

    for _, setup in ipairs(setups) do
        local coords = vector3(setup.Coords.x, setup.Coords.y, setup.Coords.z)
        local point = lib.points.new({
            coords = coords,
            distance = 10.0,
            onEnter = function()
                spawnProp(setup)
                Wait(5000)
                for i, propData in ipairs(spawnedProps) do
                    if propData.iD == setup.ID then
                       StartFire(true, setup.Fuel, setup.Coords, propData.prop)
                    end
                end
            end,
            onExit = function()
                --StartFire(false, setup.Fuel, setup.Coords, spawnedProps[setup.ID])
                local propToRemove = nil
                for i, propData in ipairs(spawnedProps) do
                    if propData.iD == setup.ID then
                        propToRemove = i
                        StartFire(false, setup.Fuel, setup.Coords, propData.prop)
                    end
                end
                if propToRemove then
                    DeleteEntity(spawnedProps[propToRemove].prop)
                    table.remove(spawnedProps, propToRemove)
                end
            end,
        })
        -- Insert the mapping between point ID and setup ID into the points table
        table.insert(points, { pointId = point.id, setupId = setup.ID })
    end
end


RegisterNetEvent('D2D-Moonshine:NewClient')
AddEventHandler('D2D-Moonshine:NewClient',function()
    handleSetups()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
    handleSetups()
end)

Citizen.CreateThread(function()
    Wait(1000)
    handleSetups()
end)

RegisterNetEvent("D2D-Moonshine:Setup")
AddEventHandler("D2D-Moonshine:Setup", function(item)
    if spawningProp then
        TriggerEvent('D2D-Moonshine:Notifications', D2D.Translation['alreadyplacing'])
    else
        spawningProp = true
        SpawnProp(item)
    end
end)

local function UpdatePropHeading(prop, headingDelta)
    if prop then
        local originalHeading = GetEntityHeading(prop)
        local newHeading = (originalHeading + headingDelta) % 360
        SetEntityHeading(prop, newHeading)
    end
end

function SpawnProp(item)
    if spawningProp then
        Citizen.CreateThread(function()
            while spawningProp do
                local hit, entityHit, coords = lib.raycast.cam()
                local text = "Press [E] to Confirm               \n                 Press [Backspace] to Cancel                  \n                 Use [Scroll-Wheel] to Rotate"
                local options = {
                    position = "right-center",
                    icon = "fa-solid fa-beer-mug-empty",
                }
                lib.showTextUI(text, options)
                if hit then
                    if not prop then
                        local model = D2D.MoonShine[item].prop
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(500)
                        end

                        prop = CreateObject(model, coords.x, coords.y, coords.z, false, true, true)
                        SetEntityCollision(prop, false, true)
                        SetEntityAsMissionEntity(prop, true, true)
                        SetEntityAlpha(prop, 150, false)
                        SetModelAsNoLongerNeeded(model)
                    else
                        SetEntityCoords(prop, coords.x, coords.y, coords.z, true, true, true, true)
                        if IsControlPressed(0, 14) then -- Scroll
                            UpdatePropHeading(prop, -5)
                        elseif IsControlPressed(0, 15) then -- Scroll
                            UpdatePropHeading(prop, 5)
                        end
                    end
                end

                if IsControlPressed(0, 38) then -- Confirm
                    spawningProp = false
                    propCoords = GetEntityCoords(prop)
                    PropHeading = GetEntityHeading(prop)
                    DeleteEntity(prop)
                    prop = nil
                    TriggerServerEvent('D2D-Moonshine:AddSpawn', propCoords, PropHeading, item)
                    performAnimation("pickup", { Coords = { x = propCoords.x, y = propCoords.y, z = propCoords.z } }, {})
                    handleSetups()
                    lib.hideTextUI()
                end                

                if IsControlPressed(0, 194) then -- Cancel
                    protected = true
                    spawningProp = false
                    DeleteEntity(prop)
                    prop = nil
                    lib.hideTextUI()
                    TriggerServerEvent('D2D-Moonshine:GiveBack', protected, item)
                    protected = false
                end

                Wait(0)
            end
        end)
    else
        spawningProp = false
        lib.hideTextUI()
        DeleteEntity(prop)
        prop = nil
    end
end

function spawnProp(setup)

    for _, propData in ipairs(spawnedProps) do
        if propData.iD == setup.ID then
            Debug("Prop with ID " .. setup.ID .. " already exists.")
            return  
        end
    end

    local model = GetHashKey("prop_moonshine")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end

    local prop = CreateObject(model, setup.Coords.x, setup.Coords.y, setup.Coords.z, false, true)

    SetEntityHeading(prop, setup.Heading)
    SetEntityAsMissionEntity(prop, true, true)
    SetModelAsNoLongerNeeded(model)

    generateOptions(setup, prop)
    exports.ox_target:addLocalEntity(prop, options)

    local newPropData = {
        prop = prop,
        iD = setup.ID,
        coords = setup.Coords,
    }

    table.insert(spawnedProps, newPropData)
end

function generateOptions(setup, netID)
    coords = GetEntityCoords(netID)
    options = {
        {
            label = 'Open Distillery',
            name = 'brewing_stand',
            icon = "fa-solid fa-beer-mug-empty",
            distance = 2.0,
            onSelect = function()
                openMenu(setup, netID)
            end
        },
        {
            label = 'Pickup Distillery',
            name = 'brewing_stand',
            icon = "fa-solid fa-hand-holding",
            distance = 2.0,
            onSelect = function()
                coords = GetEntityCoords(netID)
                performAnimation("pickup", setup)
                TriggerServerEvent('D2D-Moonshine:RemoveSpawn', setup.ID, setup.Type, netID)
            end
        },
    }
    return options
end

RegisterNetEvent("D2D-Moonshine:DeleteProp")
AddEventHandler("D2D-Moonshine:DeleteProp", function(netID)
    -- Remove prop data
    for i, propData in ipairs(spawnedProps) do
        if propData.iD == netID then
            DeleteEntity(propData.prop)
            Debug("Deleted prop: ", propData.prop)
            table.remove(spawnedProps, i)
            break  -- Exit loop after removing the prop data
        end
    end

   -- Remove point
for i, pointData in ipairs(points) do
    if pointData.setupId == netID then
        local point = nil
        local allPoints = lib.points.getAllPoints()
        for _, p in ipairs(allPoints) do
            if tostring(p.id) == tostring(pointData.pointId) then
                point = p
                break
            end
        end

        if point then
            point:remove()
            Debug("Point with ID ".. pointData.pointId .." was removed.")
        else
            Debug("Point with ID ".. pointData.pointId .." could not be found.")
        end

        table.remove(points, i)
        break  -- Exit loop after removing the point data
    end
end

end)




function generateItemsAndCheck(setup)
    local fuelOptions = {}
    local ingredientOptions = {}
    local items = exports.ox_inventory:Items()

    -- Check for fuel item
    local fuelName = D2D.MoonShine[setup.Type].fuel
    local playerInventoryFuel = exports.ox_inventory:Search('count', fuelName)
    local fuelLabel = items[fuelName] and items[fuelName].label or 'No suitable items'
    if playerInventoryFuel > 0 then
        table.insert(fuelOptions, {
            title = fuelLabel,
            onSelect = function()
                DisplayPetrolCanMetadata(setup)
            end
        })
    end

    -- Check for ingredient items
    for _, ingredientName in ipairs(D2D.MoonShine[setup.Type].ingredients) do
        local playerInventoryIngredient = exports.ox_inventory:Search('count', ingredientName)
        local ingredientLabel = items[ingredientName] and items[ingredientName].label or 'No suitable items'
        if playerInventoryIngredient > 0 then
            table.insert(ingredientOptions, {
                title = ingredientLabel,
                onSelect = function()
                    performAnimation("ingredient", setup, { ingredientName = ingredientName })
                end
            })
        end
    end

    if #fuelOptions == 0 then
        table.insert(fuelOptions, {
            title = 'No suitable fuel items',
            disabled = true
        })
    end

    if #ingredientOptions == 0 then
        table.insert(ingredientOptions, {
            title = 'No suitable ingredient items',
            disabled = true
        })
    end

    lib.registerContext({
        id = 'fuel_menu',
        title = 'Fuel Selection',
        options = fuelOptions,
        onExit = function()
            Debug('Fuel menu closed')
        end
    })

    lib.registerContext({
        id = 'ingredients_menu',
        title = 'Ingredient Selection',
        options = ingredientOptions,
        onExit = function()
            Debug('Ingredient menu closed')
        end
    })
end

function openMenu(setup, netID)

    local setups = lib.callback.await('D2D-Moonshine:GetSetups', false)

    if not setups then
        Debug("Error: Failed to retrieve setup data")
        return
    end

    local setupUpdated = nil
    for _, data in ipairs(setups) do
        if data.ID == setup.ID then
            setupUpdated = data
            break
        end
    end

    if not setupUpdated then
        Debug("Error: Setup not found with ID", setupUpdated.ID)
        return
    end

    generateItemsAndCheck(setupUpdated)

    lib.registerContext({
        id = 'moonshine_menu',
        title = 'Moonshine Still',
        options = {
            {
                title = 'Fire Pit: '..setupUpdated.Fuel..'°C',
                icon = 'fa-solid fa-fire-flame-curved',
                description = 'The current temperature of your pit.',
                progress = setupUpdated.Fuel,
                colorScheme = setupUpdated.Fuel >= 50 and 'red' or 'blue'
            },
            {
                title = 'Tank: '..setupUpdated.ABV..'% ABV',
                icon = 'fa-solid fa-flask',
                description = 'The current proof of your moonshine.',
                progress = setupUpdated.ABV,
                colorScheme = 'lime'
            },
            {
                title = 'Add Fuel',
                icon = 'fa-solid fa-gas-pump',
                description = 'Keep your still fueled to ensure you can continue making moonshine',
                arrow = true,
                menu = 'fuel_menu'
            },
            {
                title = 'Add Ingredient',
                icon = 'fa-solid fa-utensils',
                description = 'Use the best ingredients to ensure you have good quality moonshine.',
                disabled = setupUpdated.Craft ~= nil,
                arrow = true,
                menu = 'ingredients_menu'
            },
            {
                title = (setupUpdated.Craft and 'Collect ' .. setupUpdated.Craft .. ' moonshine.' or 'Collect Moonshine.'),
                icon = 'fa-solid fa-hand-holding',
                description = 'Pick up your moonshine that you have brewed.',
                disabled = setupUpdated.Craft == nil,
                onSelect = function()
                    TriggerServerEvent('D2D-Moonshine:AddReward', setupUpdated)
                end
            }
        },
        onExit = function()
            Debug('Menu closed')
        end
    })
    lib.showContext('moonshine_menu')
end

function StartFire(fuel, coords)
    local dict = "core"
    local particleName = "ent_amb_barrel_fire"
    local scale = 0.8 

    Citizen.CreateThread(function()
        while true do
            if fuel then
                if fire == nil then
                    print("true")
                    RequestNamedPtfxAsset(dict)
                    while not HasNamedPtfxAssetLoaded(dict) do
                        Citizen.Wait(0)
                    end
                    UseParticleFxAssetNextCall(dict)
                    fire = StartParticleFxLoopedAtCoord(particleName, coords.x, coords.y, coords.z-0.3, 0, 0, 0, scale, false, false, false, false)
                    print(fire)
                else
                    print("false")
                end
            else
                if fire ~= nil then
                    StopParticleFxLooped(fire)
                    fire = nil  -- Reset fire variable when stopping the particle effect
                end
            end
            Citizen.Wait(500)  -- Adjust the interval as needed
        end
    end)
end



function DisplayPetrolCanMetadata(setup)
    local slotsData = exports.ox_inventory:GetSlotsWithItem(D2D.MoonShine[setup.Type].fuel)

    if slotsData and next(slotsData) ~= nil then
        local lowestSlotId = nil
        local lowestAmmo = math.huge

        for _, slotData in ipairs(slotsData) do
            if slotData.metadata and slotData.metadata.ammo and slotData.metadata.ammo > 0 and slotData.metadata.ammo < lowestAmmo then
                lowestSlotId = slotData.slot
                lowestAmmo = slotData.metadata.ammo
            end
        end

        if lowestSlotId then
            Debug("Using petrolcan in slot: " .. lowestSlotId)
            performAnimation("fuel", setup, { slotid = lowestSlotId })
        else
            TriggerEvent('D2D-Moonshine:Notifications', D2D.Translation['empty'])
        end
    else
        Debug('Tried to search for an invalid slot item.')
    end
end

function performAnimation(animationType, setup, extraParams)
    DisableControls(true)

    local weaponHash = GetHashKey("WEAPON_UNARMED")
    SetCurrentPedWeapon(PlayerPedId(), weaponHash, true)

    TaskTurnPedToFaceCoord(PlayerPedId(), setup.Coords.x, setup.Coords.y, setup.Coords.z, 3000)
    Wait(100)

    local animationData = D2D.Animations[animationType]
    local duration = tonumber(animationData.duration) * 1000

    if lib.progressCircle({
        duration = duration,
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = animationData.dict,
            clip = animationData.anim,
            flags = animationData.flag,
        },
        prop = {
            model = animationData.model,
            bone = animationData.bone,
            pos = animationData.pos,
            rot = animationData.rot,
        },
    }) then
        if animationType == "fuel" then
            Debug('Fueling')
            TriggerServerEvent('D2D-Moonshine:AddFuel', extraParams.slotid, setup)
        elseif animationType == "ingredient" then
            Debug('Adding Ingredient')
            TriggerServerEvent('D2D-Moonshine:AddIngredient', setup, extraParams.ingredientName)
        elseif animationType == 'pickup' then
            Debug('Placing/Picking Up')
        end
    end

    DisableControls(false)
end


local allControls = {
    0,  -- Attack
    1,  -- Sprint
    2,  -- Jump
    3,  -- Enter vehicle
    4,  -- Melee attack
    5,  -- Melee attack 2
    6,  -- Look behind
    24, -- Move left/right
    25, -- Move up/down
    32, -- Move up/down (Alt)
    33, -- Look left/right
    34, -- Look up/down
    35, -- Look up/down (Alt)
    44, -- Cover
    45, -- Reload
    140, -- Aim
    141, -- Look behind while in cover
    142, -- Move left/right while in cover
    143, -- Move up/down while in cover
    268, -- Context key
    269, -- Context key secondary
    288, -- Context key (Alt)
    289, -- Context key secondary (Alt)

}

function DisableControls(enable)
    if enable then

        LocalPlayer.state.invBusy = true
        LocalPlayer.state.invHotkeys = false
        exports.ox_target:disableTargeting(true)

        for _, control in ipairs(allControls) do
            lib.disableControls:Add(control, 1)
        end

    else
        LocalPlayer.state.invBusy = false
        LocalPlayer.state.invHotkeys = true
        exports.ox_target:disableTargeting(false)

        for _, control in ipairs(allControls) do
            lib.disableControls:Remove(control, 1)
        end

    end
end

RegisterCommand("daf", function(source, args, rawCommand)

        for i = #spawnedProps, 1, -1 do
            local przopData = spawnedProps[i]
            if DoesEntityExist(propData.prop) then
                DeleteEntity(propData.prop)
            end
            table.remove(spawnedProps, i)
        end

end, false)
