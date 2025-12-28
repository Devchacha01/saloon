-- ============================================================================
-- RSG SALOON PREMIUM - PHONOGRAPH SYSTEM
-- Play music from URLs on phonograph props at saloons
-- Uses xsound for audio, ox_lib for menus (no jo_libs needed)
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State
local volume = Config.PhonographVolume or 0.3
local placedPhonograph = {}
local isPlacing = false

-- ============================================================================
-- EVENT FROM USEABLE ITEM
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:client:startPlacingPhonograph', function()
    StartPlacingPhonograph()
end)

-- ============================================================================
-- PLACE PHONOGRAPH
-- ============================================================================

function StartPlacingPhonograph()
    if isPlacing then return end
    
    -- Check if player already has one placed nearby
    local playerCoords = GetEntityCoords(PlayerPedId())
    for _, data in pairs(placedPhonograph) do
        if #(playerCoords - data.coords) < 50.0 then
            lib.notify({ type = 'error', description = 'You already have a phonograph placed nearby!' })
            return
        end
    end
    
    isPlacing = true
    local propHash = GetHashKey('p_phonograph01x')
    local heading = 0.0
    
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do Wait(10) end
    
    local coords = GetEntityCoords(PlayerPedId())
    local ghostProp = CreateObject(propHash, coords.x, coords.y, coords.z, false, true, false)
    SetEntityAlpha(ghostProp, 150, false)
    SetEntityCollision(ghostProp, false, false)
    
    lib.showTextUI('[LEFT/RIGHT] Rotate | [E] Place | [BACKSPACE] Cancel')
    
    while isPlacing do
        Wait(0)
        
        -- Raycast for position
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(0)
        local adjustedRot = vector3(math.rad(camRot.x), math.rad(camRot.y), math.rad(camRot.z))
        local direction = vector3(
            -math.sin(adjustedRot.z) * math.abs(math.cos(adjustedRot.x)),
            math.cos(adjustedRot.z) * math.abs(math.cos(adjustedRot.x)),
            math.sin(adjustedRot.x)
        )
        local endCoords = camCoords + direction * 5.0
        local handle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, -1, PlayerPedId(), 0)
        local _, hit, hitCoords, _, _ = GetShapeTestResult(handle)
        
        if hit then
            SetEntityCoords(ghostProp, hitCoords.x, hitCoords.y, hitCoords.z, true, true, true, false)
            SetEntityHeading(ghostProp, heading)
        end
        
        -- Rotation
        if IsControlPressed(0, 0xA65EBAB4) then heading = heading + 2.0 end -- Q/Left
        if IsControlPressed(0, 0xDEB34313) then heading = heading - 2.0 end -- E/Right
        if heading > 360.0 then heading = 0.0 elseif heading < 0.0 then heading = 360.0 end
        
        -- Place
        if IsControlJustPressed(0, 0x8AAA0AD4) then -- E
            local finalCoords = GetEntityCoords(ghostProp)
            DeleteEntity(ghostProp)
            isPlacing = false
            lib.hideTextUI()
            
            -- Create actual phonograph
            TriggerServerEvent('rsg-saloon-premium:server:placePhonograph', {
                x = finalCoords.x,
                y = finalCoords.y,
                z = finalCoords.z,
                heading = heading
            })
            break
        end
        
        -- Cancel
        if IsControlJustPressed(0, 0x156F7119) then -- Backspace
            DeleteEntity(ghostProp)
            isPlacing = false
            lib.hideTextUI()
            lib.notify({ type = 'info', description = 'Placement cancelled' })
            break
        end
    end
    
    SetModelAsNoLongerNeeded(propHash)
end

-- ============================================================================
-- PHONOGRAPH MENU (ox_lib)
-- ============================================================================

function OpenPhonographMenu(entity, phonoId)
    lib.registerContext({
        id = 'phonograph_menu',
        title = '🎵 Phonograph',
        options = {
            {
                title = '▶️ Play Music',
                description = 'Enter a YouTube or direct audio URL',
                icon = 'play',
                onSelect = function()
                    local input = lib.inputDialog('Play Music', {
                        { type = 'input', label = 'Music URL', placeholder = 'https://youtube.com/watch?v=...' }
                    })
                    
                    if input and input[1] and input[1]:sub(1, 4) == 'http' then
                        local coords = GetEntityCoords(entity)
                        TriggerServerEvent('rsg-saloon-premium:server:phonoPlay', phonoId, coords, input[1], volume)
                        lib.notify({ type = 'success', description = 'Playing music!' })
                    else
                        lib.notify({ type = 'error', description = 'Invalid URL!' })
                    end
                end
            },
            {
                title = '⏹️ Stop Music',
                description = 'Stop current track',
                icon = 'stop',
                onSelect = function()
                    TriggerServerEvent('rsg-saloon-premium:server:phonoStop', phonoId)
                    lib.notify({ type = 'info', description = 'Music stopped' })
                end
            },
            {
                title = '🔊 Volume Up',
                description = 'Current: ' .. math.floor(volume * 100) .. '%',
                icon = 'volume-up',
                onSelect = function()
                    if volume < 1.0 then
                        volume = math.min(volume + 0.1, 1.0)
                        TriggerServerEvent('rsg-saloon-premium:server:phonoVolume', phonoId, volume)
                        lib.notify({ type = 'success', description = 'Volume: ' .. math.floor(volume * 100) .. '%' })
                    else
                        lib.notify({ type = 'error', description = 'Volume at maximum!' })
                    end
                end
            },
            {
                title = '🔉 Volume Down',
                description = 'Current: ' .. math.floor(volume * 100) .. '%',
                icon = 'volume-down',
                onSelect = function()
                    if volume > 0.0 then
                        volume = math.max(volume - 0.1, 0.0)
                        TriggerServerEvent('rsg-saloon-premium:server:phonoVolume', phonoId, volume)
                        lib.notify({ type = 'success', description = 'Volume: ' .. math.floor(volume * 100) .. '%' })
                    else
                        lib.notify({ type = 'error', description = 'Volume at minimum!' })
                    end
                end
            },
        }
    })
    
    lib.showContext('phonograph_menu')
end

-- ============================================================================
-- SERVER EVENTS
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:client:createPhonograph', function(data)
    local propHash = GetHashKey('p_phonograph01x')
    
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do Wait(10) end
    
    local prop = CreateObject(propHash, data.x, data.y, data.z, false, true, false)
    SetEntityHeading(prop, data.heading or 0.0)
    FreezeEntityPosition(prop, true)
    
    placedPhonograph[data.phonoId] = {
        entity = prop,
        coords = vector3(data.x, data.y, data.z),
        owner = data.owner
    }
    
    SetModelAsNoLongerNeeded(propHash)
end)

RegisterNetEvent('rsg-saloon-premium:client:removePhonograph', function(phonoId)
    local data = placedPhonograph[phonoId]
    if data and data.entity then
        DeleteEntity(data.entity)
    end
    placedPhonograph[phonoId] = nil
    
    -- Stop xsound
    if exports.xsound then
        exports.xsound:Destroy(phonoId)
    end
end)

RegisterNetEvent('rsg-saloon-premium:client:phonoPlay', function(phonoId, coords, url, vol)
    if exports.xsound then
        exports.xsound:PlayUrlPos(phonoId, url, vol, coords)
        exports.xsound:Distance(phonoId, 15)
    end
end)

RegisterNetEvent('rsg-saloon-premium:client:phonoStop', function(phonoId)
    if exports.xsound then
        exports.xsound:Destroy(phonoId)
    end
end)

RegisterNetEvent('rsg-saloon-premium:client:phonoVolume', function(phonoId, vol)
    volume = vol
    if exports.xsound then
        exports.xsound:setVolume(phonoId, vol)
    end
end)

-- ============================================================================
-- RSG-TARGET FOR PHONOGRAPHS
-- ============================================================================

CreateThread(function()
    Wait(2000)
    
    exports['rsg-target']:AddTargetModel('p_phonograph01x', {
        options = {
            {
                icon = 'fa-solid fa-music',
                label = 'Use Phonograph',
                action = function(entity)
                    -- Find phonoId from entity
                    local phonoId = nil
                    for id, data in pairs(placedPhonograph) do
                        if data.entity == entity then
                            phonoId = id
                            break
                        end
                    end
                    
                    if phonoId then
                        OpenPhonographMenu(entity, phonoId)
                    else
                        -- Static phonograph (not player-placed)
                        local netId = NetworkGetNetworkIdFromEntity(entity)
                        OpenPhonographMenu(entity, 'static_' .. netId)
                    end
                end
            },
            {
                icon = 'fa-solid fa-hand',
                label = 'Pick Up Phonograph',
                action = function(entity)
                    for id, data in pairs(placedPhonograph) do
                        if data.entity == entity then
                            TriggerServerEvent('rsg-saloon-premium:server:pickupPhonograph', id)
                            return
                        end
                    end
                    lib.notify({ type = 'error', description = 'Cannot pick up this phonograph!' })
                end
            },
        },
        distance = 2.5
    })
end)

-- ============================================================================
-- ADD STATIC PHONOGRAPH LOCATIONS AT SALOONS
-- ============================================================================

CreateThread(function()
    Wait(3000)
    
    if not Config.PhonographLocations then return end
    
    for i, phono in ipairs(Config.PhonographLocations) do
        local propHash = GetHashKey('p_phonograph01x')
        
        RequestModel(propHash)
        while not HasModelLoaded(propHash) do Wait(10) end
        
        local prop = CreateObject(propHash, phono.coords.x, phono.coords.y, phono.coords.z, false, true, false)
        SetEntityHeading(prop, phono.heading or 0.0)
        FreezeEntityPosition(prop, true)
        
        placedPhonograph['static_' .. i] = {
            entity = prop,
            coords = phono.coords,
            owner = 'static'
        }
        
        SetModelAsNoLongerNeeded(propHash)
    end
    
    print('^2[RSG-Saloon-Premium]^0 Phonograph static locations created:', #Config.PhonographLocations or 0)
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    lib.hideTextUI()
    
    for id, data in pairs(placedPhonograph) do
        if data.entity and DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
        if exports.xsound then
            exports.xsound:Destroy(id)
        end
    end
    
    placedPhonograph = {}
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('StartPlacingPhonograph', StartPlacingPhonograph)

print('^2[RSG-Saloon-Premium]^0 Phonograph module loaded!')
