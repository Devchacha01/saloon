-- ============================================================================
-- RSG SALOON PREMIUM - PROP PLACER
-- System for placing food/drinks on tables for RP serving
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State
local isPlacing = false
local currentProp = nil
local currentRotation = 0.0
local placedProps = {}

-- Prompt IDs
local PlacePrompt = nil
local CancelPrompt = nil
local RotateLeftPrompt = nil
local RotateRightPrompt = nil
local PromptGroup = GetRandomIntInRange(0, 0xffffff)

-- ============================================================================
-- INITIALIZE PROMPTS
-- ============================================================================

CreateThread(function()
    Wait(1000)
    
    -- Place prompt
    local str = CreateVarString(10, 'LITERAL_STRING', 'Place')
    PlacePrompt = PromptRegisterBegin()
    PromptSetControlAction(PlacePrompt, 0x8AAA0AD4) -- E key
    PromptSetText(PlacePrompt, str)
    PromptSetEnabled(PlacePrompt, true)
    PromptSetVisible(PlacePrompt, true)
    PromptSetHoldMode(PlacePrompt, true)
    PromptSetGroup(PlacePrompt, PromptGroup)
    PromptRegisterEnd(PlacePrompt)
    
    -- Cancel prompt
    str = CreateVarString(10, 'LITERAL_STRING', 'Cancel')
    CancelPrompt = PromptRegisterBegin()
    PromptSetControlAction(CancelPrompt, 0xF84FA74F) -- Backspace
    PromptSetText(CancelPrompt, str)
    PromptSetEnabled(CancelPrompt, true)
    PromptSetVisible(CancelPrompt, true)
    PromptSetHoldMode(CancelPrompt, true)
    PromptSetGroup(CancelPrompt, PromptGroup)
    PromptRegisterEnd(CancelPrompt)
    
    -- Rotate left
    str = CreateVarString(10, 'LITERAL_STRING', 'Rotate Left')
    RotateLeftPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4) -- Q key
    PromptSetText(RotateLeftPrompt, str)
    PromptSetEnabled(RotateLeftPrompt, true)
    PromptSetVisible(RotateLeftPrompt, true)
    PromptSetStandardMode(RotateLeftPrompt, true)
    PromptSetGroup(RotateLeftPrompt, PromptGroup)
    PromptRegisterEnd(RotateLeftPrompt)
    
    -- Rotate right
    str = CreateVarString(10, 'LITERAL_STRING', 'Rotate Right')
    RotateRightPrompt = PromptRegisterBegin()
    PromptSetControlAction(RotateRightPrompt, 0xDEB34313) -- E key
    PromptSetText(RotateRightPrompt, str)
    PromptSetEnabled(RotateRightPrompt, true)
    PromptSetVisible(RotateRightPrompt, true)
    PromptSetStandardMode(RotateRightPrompt, true)
    PromptSetGroup(RotateRightPrompt, PromptGroup)
    PromptRegisterEnd(RotateRightPrompt)
end)

-- ============================================================================
-- RAYCASTING FOR PLACEMENT
-- ============================================================================

local function GetPlacementCoords()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(0)
    local adjustedRot = vector3(
        math.rad(camRot.x),
        math.rad(camRot.y),
        math.rad(camRot.z)
    )
    
    local direction = vector3(
        -math.sin(adjustedRot.z) * math.abs(math.cos(adjustedRot.x)),
        math.cos(adjustedRot.z) * math.abs(math.cos(adjustedRot.x)),
        math.sin(adjustedRot.x)
    )
    
    local endCoords = camCoords + direction * 5.0
    
    local handle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, -1, PlayerPedId(), 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(handle)
    
    if hit then
        return hitCoords
    end
    return nil
end

-- ============================================================================
-- PROP PLACER FUNCTION
-- ============================================================================

function StartPropPlacer(modelName, propType, extraData)
    if isPlacing then return end
    
    isPlacing = true
    currentRotation = 0.0
    
    local propHash = GetHashKey(modelName)
    
    -- Request model
    RequestModel(propHash)
    local timeout = 0
    while not HasModelLoaded(propHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(propHash) then
        isPlacing = false
        lib.notify({ type = 'error', description = 'Failed to load model' })
        return
    end
    
    -- Create ghost prop
    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
    currentProp = CreateObject(propHash, x, y, z, false, true, false, false, true)
    SetEntityAlpha(currentProp, 150, false)
    SetEntityCompletelyDisableCollision(currentProp, true, true)
    SetEntityCollision(currentProp, false, false)
    
    -- Placement loop
    while isPlacing do
        Wait(0)
        
        local coords = GetPlacementCoords()
        if coords then
            SetEntityCoords(currentProp, coords.x, coords.y, coords.z, true, true, true, false)
            SetEntityRotation(currentProp, 0.0, 0.0, currentRotation, 2, true)
        end
        
        -- Show prompts
        local promptLabel = CreateVarString(10, 'LITERAL_STRING', 'Place Item')
        PromptSetActiveGroupThisFrame(PromptGroup, promptLabel)
        
        -- Handle rotation
        if IsControlPressed(0, 0xA65EBAB4) then -- Q
            currentRotation = currentRotation - 2.0
        end
        if IsControlPressed(0, 0xDEB34313) then -- E
            currentRotation = currentRotation + 2.0
        end
        
        -- Handle placement
        if PromptHasHoldModeCompleted(PlacePrompt) then
            local finalCoords = GetEntityCoords(currentProp)
            
            -- Delete ghost
            DeleteEntity(currentProp)
            currentProp = nil
            isPlacing = false
            
            -- Send to server to create networked prop
            TriggerServerEvent('rsg-saloon-premium:server:placeProp', {
                model = modelName,
                x = finalCoords.x,
                y = finalCoords.y,
                z = finalCoords.z,
                rotation = currentRotation,
                propType = propType or 'drink',
                extraData = extraData or {}
            })
            
            lib.notify({ type = 'success', description = 'Item placed!' })
            break
        end
        
        -- Handle cancel
        if PromptHasHoldModeCompleted(CancelPrompt) then
            DeleteEntity(currentProp)
            currentProp = nil
            isPlacing = false
            SetModelAsNoLongerNeeded(propHash)
            lib.notify({ type = 'info', description = 'Placement cancelled' })
            break
        end
    end
end

-- Export for use in other files
exports('StartPropPlacer', StartPropPlacer)

-- ============================================================================
-- PLACED PROP INTERACTION (Using ox_target now)
-- ============================================================================

-- Old prompt system commented out - now using ox_target addSphereZone instead
-- local PickupPrompt = nil
-- local RemovePrompt = nil
-- local PickupGroup = GetRandomIntInRange(0, 0xffffff)
-- Prompts are no longer needed since we use ox_target:addSphereZone on each placed prop

-- Track zone names for cleanup
local propZones = {}

-- ============================================================================
-- HANDLE PLACED PROPS FROM SERVER
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:client:createPlacedProp', function(data)
    local propHash = GetHashKey(data.model)
    
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do Wait(10) end
    
    local prop = CreateObject(propHash, data.x, data.y, data.z, false, true, false)
    SetEntityRotation(prop, 0.0, 0.0, data.rotation or 0.0, 2, true)
    SetEntityCompletelyDisableCollision(prop, true, true)
    SetEntityCollision(prop, false, false)
    FreezeEntityPosition(prop, true)
    
    -- Store reference
    placedProps[data.propId] = {
        entity = prop,
        model = data.model,
        propType = data.propType,
        extraData = data.extraData or {},
        coords = vector3(data.x, data.y, data.z)
    }
    
    -- Add ox_target sphere zone at the prop location
    local propId = data.propId
    local propType = data.propType or 'drink'
    local label = propType == 'food' and 'Eat' or 'Drink'
    local zoneName = 'saloon_prop_' .. propId
    
    -- Build options for the target zone
    local options = {
        {
            name = 'consume_' .. propId,
            icon = propType == 'food' and 'fas fa-utensils' or 'fas fa-glass-water',
            label = label,
            onSelect = function()
                TriggerServerEvent('rsg-saloon-premium:server:consumePlacedProp', propId)
            end,
        },
        {
            name = 'remove_' .. propId,
            icon = 'fas fa-trash',
            label = 'Remove',
            onSelect = function()
                TriggerServerEvent('rsg-saloon-premium:server:removePlacedProp', propId)
            end,
            canInteract = function()
                -- Only employees can remove placed props
                local PlayerData = RSGCore.Functions.GetPlayerData()
                if not PlayerData or not PlayerData.job then return false end
                local job = PlayerData.job.name
                for saloonId, _ in pairs(Config.Saloons) do
                    if job == saloonId then
                        return true
                    end
                end
                return false
            end,
        },
    }
    
    -- Create sphere zone at prop location and store the returned zone ID
    local zoneId = exports.ox_target:addSphereZone({
        coords = vector3(data.x, data.y, data.z),
        radius = 0.8,
        debug = Config.Debug,
        options = options
    })
    
    -- Store zone ID for cleanup
    propZones[propId] = zoneId
    
    if Config.Debug then
        print('[Saloon] Added ox_target sphere zone for prop:', propId, 'Zone ID:', zoneId)
    end
end)

-- Remove placed prop
RegisterNetEvent('rsg-saloon-premium:client:removePlacedProp', function(propId)
    local propData = placedProps[propId]
    if propData and propData.entity then
        DeleteEntity(propData.entity)
    end
    
    -- Remove the ox_target zone
    local zoneId = propZones[propId]
    if zoneId then
        exports.ox_target:removeZone(zoneId)
        if Config.Debug then
            print('[Saloon] Removed ox_target zone:', zoneId)
        end
    end
    
    placedProps[propId] = nil
    propZones[propId] = nil
end)

-- ============================================================================
-- CONSUME PROP WITH HUNGER/THIRST RESTORATION
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:client:consumeProp', function(propData)
    local playerPed = PlayerPedId()
    local propType = propData.propType or 'drink'
    
    -- Play consume animation
    if propType == 'food' then
        -- Simple eating animation
        TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_SEAT_STEPS_EATING_BREAD'), -1, true, false, false, false)
        Wait(3000)
        ClearPedTasks(playerPed)
        
        -- Restore hunger (Client-side HUD update to match rsg-consume)
        local currentHunger = LocalPlayer.state.hunger or 0
        TriggerEvent('hud:client:UpdateHunger', currentHunger + 30)
        -- Also sync to server just in case
        TriggerServerEvent('rsg-saloon:server:restoreHunger', 30)
        
        lib.notify({ type = 'success', description = 'That was delicious!' })
    else
        -- Simple drinking animation
        TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_SEAT_STEPS_DRINK_BEER'), -1, true, false, false, false)
        Wait(3000)
        ClearPedTasks(playerPed)
        
        -- Restore thirst (Client-side HUD update to match rsg-consume)
        local currentThirst = LocalPlayer.state.thirst or 0
        TriggerEvent('hud:client:UpdateThirst', currentThirst + 30)
        -- Also sync to server just in case
        TriggerServerEvent('rsg-saloon:server:restoreThirst', 30)
        
        lib.notify({ type = 'success', description = 'Refreshing!' })
    end
end)

-- ============================================================================
-- NUI CALLBACKS FOR SERVING MENU
-- ============================================================================

RegisterNUICallback('serveDrink', function(data, cb)
    local model = data.model or 'p_bottlebeer01x'
    -- Pass itemName in extraData for storage validation
    StartPropPlacer(model, 'drink', { 
        alcoholLevel = data.alcoholLevel or 0,
        itemName = data.itemName
    })
    cb({ success = true })
end)

RegisterNUICallback('serveFood', function(data, cb)
    local model = data.model or 'p_beefstew01x'
    -- Pass itemName in extraData for storage validation
    StartPropPlacer(model, 'food', {
        itemName = data.itemName
    })
    cb({ success = true })
end)

RegisterNUICallback('servePlate', function(data, cb)
    -- For custom plates, we'll pass extra data
    StartPropPlacer(data.plate or 'p_plate01x', 'plate', {
        mainDish = data.mainDish,
        sideDish = data.sideDish
    })
    cb({ success = true })
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if currentProp then
        DeleteEntity(currentProp)
    end
    
    for propId, propData in pairs(placedProps) do
        if propData.entity then
            DeleteEntity(propData.entity)
        end
        
        -- Remove zones
        local zoneId = propZones[propId]
        if zoneId then
            exports.ox_target:removeZone(zoneId)
        end
    end
end)

print('^2[RSG-Saloon-Premium]^0 Prop Placer module loaded!')
