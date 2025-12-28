-- ============================================================================
-- RSG SALOON PREMIUM - SERVER PHONOGRAPH
-- Handles phonograph placement and audio sync
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State
local placedPhonographs = {}
local currentlyPlaying = {}
local phonoCounter = 0

-- ============================================================================
-- USEABLE ITEM - Place phonograph from inventory
-- ============================================================================

RSGCore.Functions.CreateUseableItem('phonograph', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if player is saloon employee
    local playerJob = Player.PlayerData.job.name
    local isSaloonEmployee = false
    
    for id, _ in pairs(Config.Saloons) do
        if playerJob == id then
            isSaloonEmployee = true
            break
        end
    end
    
    if not isSaloonEmployee then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Only saloon employees can use this!'
        })
        return
    end
    
    TriggerClientEvent('rsg-saloon-premium:client:startPlacingPhonograph', source)
end)

-- ============================================================================
-- PLACE PHONOGRAPH
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:placePhonograph', function(data)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Check if player is a saloon employee
    local playerJob = Player.PlayerData.job.name
    local isSaloonEmployee = false
    local saloonId = nil
    
    for id, _ in pairs(Config.Saloons) do
        if playerJob == id then
            isSaloonEmployee = true
            saloonId = id
            break
        end
    end
    
    if not isSaloonEmployee then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Only saloon employees can place a phonograph!'
        })
        return
    end
    
    -- Check if this saloon already has a phonograph placed
    for _, phono in pairs(placedPhonographs) do
        if phono.saloonId == saloonId then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Your saloon already has a phonograph placed!'
            })
            return
        end
    end
    
    phonoCounter = phonoCounter + 1
    local phonoId = 'phono_' .. saloonId .. '_' .. phonoCounter
    
    placedPhonographs[phonoId] = {
        owner = Player.PlayerData.citizenid,
        ownerId = source,
        saloonId = saloonId,
        x = data.x,
        y = data.y,
        z = data.z,
        heading = data.heading
    }
    
    -- Notify all clients to spawn the phonograph
    TriggerClientEvent('rsg-saloon-premium:client:createPhonograph', -1, {
        phonoId = phonoId,
        x = data.x,
        y = data.y,
        z = data.z,
        heading = data.heading,
        owner = Player.PlayerData.citizenid
    })
    
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Phonograph placed!'
    })
    
    if Config.Debug then
        print('[Saloon Phonograph] Placed:', phonoId, 'by', Player.PlayerData.citizenid)
    end
end)

-- ============================================================================
-- PICKUP PHONOGRAPH
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:pickupPhonograph', function(phonoId)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    local phono = placedPhonographs[phonoId]
    
    if not phono then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Phonograph not found!'
        })
        return
    end
    
    -- Check if player is a saloon employee (any saloon job)
    local playerJob = Player.PlayerData.job.name
    local isSaloonEmployee = false
    
    for saloonId, _ in pairs(Config.Saloons) do
        if playerJob == saloonId then
            isSaloonEmployee = true
            break
        end
    end
    
    -- Allow owner OR any saloon employee to pick up
    if phono.owner ~= Player.PlayerData.citizenid and not isSaloonEmployee then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Only saloon employees can remove this!'
        })
        return
    end
    
    -- Stop any playing music
    if currentlyPlaying[phonoId] then
        TriggerClientEvent('rsg-saloon-premium:client:phonoStop', -1, phonoId)
        currentlyPlaying[phonoId] = nil
    end
    
    -- Remove phonograph
    TriggerClientEvent('rsg-saloon-premium:client:removePhonograph', -1, phonoId)
    placedPhonographs[phonoId] = nil
    
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Phonograph picked up!'
    })
end)

-- ============================================================================
-- MUSIC CONTROL
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:phonoPlay', function(phonoId, coords, url, volume)
    local source = source
    
    if currentlyPlaying[phonoId] then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Music is already playing! Stop it first.'
        })
        return
    end
    
    currentlyPlaying[phonoId] = {
        url = url,
        startTime = os.time()
    }
    
    -- Broadcast to all clients
    TriggerClientEvent('rsg-saloon-premium:client:phonoPlay', -1, phonoId, coords, url, volume)
    
    -- Auto-stop after 5 minutes to prevent infinite loops
    SetTimeout(300000, function()
        if currentlyPlaying[phonoId] then
            currentlyPlaying[phonoId] = nil
        end
    end)
end)

RegisterNetEvent('rsg-saloon-premium:server:phonoStop', function(phonoId)
    currentlyPlaying[phonoId] = nil
    TriggerClientEvent('rsg-saloon-premium:client:phonoStop', -1, phonoId)
end)

RegisterNetEvent('rsg-saloon-premium:server:phonoVolume', function(phonoId, volume)
    TriggerClientEvent('rsg-saloon-premium:client:phonoVolume', -1, phonoId, volume)
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for phonoId, _ in pairs(currentlyPlaying) do
        TriggerClientEvent('rsg-saloon-premium:client:phonoStop', -1, phonoId)
    end
    
    currentlyPlaying = {}
    placedPhonographs = {}
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
    local source = source
    
    for phonoId, data in pairs(placedPhonographs) do
        if data.ownerId == source then
            -- Stop music
            if currentlyPlaying[phonoId] then
                TriggerClientEvent('rsg-saloon-premium:client:phonoStop', -1, phonoId)
                currentlyPlaying[phonoId] = nil
            end
            
            -- Remove phonograph
            TriggerClientEvent('rsg-saloon-premium:client:removePhonograph', -1, phonoId)
            placedPhonographs[phonoId] = nil
        end
    end
end)

print('^2[RSG-Saloon-Premium]^0 Phonograph server module loaded!')
