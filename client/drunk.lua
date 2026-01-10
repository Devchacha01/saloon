-- ============================================================================
-- RSG SALOON PREMIUM - DRUNK EFFECTS
-- Progressive intoxication system
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State
local currentAlcohol = 0.0
local targetAlcohol = 0.0
local maxAlcohol = 5.0
local isProcessing = false

-- Decorators for sync
local CAC = 'SLN_CUR_ALC' -- Current alcohol
local TAC = 'SLN_TAR_ALC' -- Target alcohol

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

CreateThread(function()
    Wait(2000)
    DecorRegister(CAC, 3) -- Float
    DecorRegister(TAC, 3) -- Float
    
    local player = PlayerPedId()
    DecorSetFloat(player, CAC, 0.0)
    DecorSetFloat(player, TAC, 0.0)
end)

-- ============================================================================
-- ADD ALCOHOL
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:client:addAlcohol', function(amount)
    if not Config.DrunkEffects or not Config.DrunkEffects.enabled then return end
    
    targetAlcohol = math.min(maxAlcohol, targetAlcohol + amount)
    
    local player = PlayerPedId()
    DecorSetFloat(player, TAC, targetAlcohol)
    
    if Config.Debug then
        print('[Drunk] Added alcohol:', amount, 'Total:', targetAlcohol)
    end
    
    -- Show notification based on level
    local level = GetDrunkLevel()
    if level == 1 then
        lib.notify({ type = 'info', description = 'You feel a slight buzz...' })
    elseif level == 2 then
        lib.notify({ type = 'warning', description = 'You\'re getting tipsy...' })
    elseif level == 3 then
        lib.notify({ type = 'warning', description = 'You\'re drunk!' })
    elseif level >= 4 then
        lib.notify({ type = 'error', description = 'You\'re completely wasted!' })
    end
    
    StartDrunkEffects()
end)

-- ============================================================================
-- DRUNK LEVEL CALCULATION
-- ============================================================================

function GetDrunkLevel()
    if currentAlcohol < 0.3 then return 0 end
    if currentAlcohol < 1.0 then return 1 end -- Tipsy
    if currentAlcohol < 2.0 then return 2 end -- Drunk
    if currentAlcohol < 3.5 then return 3 end -- Very Drunk
    return 4 -- Wasted
end

-- ============================================================================
-- DRUNK EFFECTS THREAD
-- ============================================================================

function StartDrunkEffects()
    if isProcessing then return end
    isProcessing = true
    
    CreateThread(function()
        while currentAlcohol > 0 or targetAlcohol > 0 do
            Wait(100)
            
            local player = PlayerPedId()
            
            -- Gradually adjust current to target
            if currentAlcohol < targetAlcohol then
                currentAlcohol = math.min(targetAlcohol, currentAlcohol + 0.01)
            elseif currentAlcohol > targetAlcohol then
                currentAlcohol = math.max(0, currentAlcohol - 0.005)
            end
            
            -- Decrease target over time (sobering up)
            targetAlcohol = math.max(0, targetAlcohol - 0.0001)
            
            DecorSetFloat(player, CAC, currentAlcohol)
            DecorSetFloat(player, TAC, targetAlcohol)
            
            local level = GetDrunkLevel()
            
            -- Apply effects based on level
            ApplyDrunkEffects(player, level)
        end
        
        -- Cleanup when sober
        local player = PlayerPedId()
        -- RedM: Reset movement clipset (use native hash instead of FiveM function)
        Citizen.InvokeNative(0xAA74EC0CB0F2CFAF, player, 1.0) -- ResetPedMovementClipset
        ShakeGameplayCam('', 0.0)
        AnimpostfxStop('PlayerDrunk01')
        
        isProcessing = false
    end)
end

-- ============================================================================
-- APPLY EFFECTS
-- ============================================================================

function ApplyDrunkEffects(player, level)
    -- Camera shake
    local shakeIntensity = level * 0.15
    ShakeGameplayCam('DRUNK_SHAKE', shakeIntensity)
    
    -- Visual effect
    if level >= 2 then
        if not AnimpostfxIsRunning('PlayerDrunk01') then
            AnimpostfxPlay('PlayerDrunk01')
        end
    else
        AnimpostfxStop('PlayerDrunk01')
    end
    
    -- Movement clipset
    if level >= 3 then
        RequestClipSet('MOVE_M@DRUNK@VERYDRUNK')
        while not HasClipSetLoaded('MOVE_M@DRUNK@VERYDRUNK') do Wait(10) end
        SetPedMovementClipset(player, 'MOVE_M@DRUNK@VERYDRUNK', 1.0)
    elseif level >= 2 then
        RequestClipSet('MOVE_M@DRUNK@MODERATE')
        while not HasClipSetLoaded('MOVE_M@DRUNK@MODERATE') do Wait(10) end
        SetPedMovementClipset(player, 'MOVE_M@DRUNK@MODERATE', 1.0)
    elseif level >= 1 then
        RequestClipSet('MOVE_M@DRUNK@SLIGHTLYDRUNK')
        while not HasClipSetLoaded('MOVE_M@DRUNK@SLIGHTLYDRUNK') do Wait(10) end
        SetPedMovementClipset(player, 'MOVE_M@DRUNK@SLIGHTLYDRUNK', 1.0)
    else
        -- RedM: Reset movement clipset
        Citizen.InvokeNative(0xAA74EC0CB0F2CFAF, player, 1.0) -- ResetPedMovementClipset
    end
    
    -- Random stumble/ragdoll at high levels
    if level >= 4 then
        if math.random(1, 500) == 1 then
            SetPedToRagdoll(player, 3000, 3000, 0, true, true, false)
            lib.notify({ type = 'error', description = 'You stumble and fall!' })
        end
    end
end

-- ============================================================================
-- SOBER UP (COFFEE, PASSING OUT, ETC.)
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:client:soberUp', function(amount)
    targetAlcohol = math.max(0, targetAlcohol - (amount or 1.0))
    currentAlcohol = math.max(0, currentAlcohol - (amount or 1.0))
    
    lib.notify({ type = 'success', description = 'You feel more sober.' })
end)

-- Full sober (admin/respawn)
RegisterNetEvent('rsg-saloon-premium:client:fullSober', function()
    targetAlcohol = 0
    currentAlcohol = 0
    
    local player = PlayerPedId()
    DecorSetFloat(player, CAC, 0.0)
    DecorSetFloat(player, TAC, 0.0)
    -- RedM: Reset movement clipset
    Citizen.InvokeNative(0xAA74EC0CB0F2CFAF, player, 1.0) -- ResetPedMovementClipset
    ShakeGameplayCam('', 0.0)
    AnimpostfxStop('PlayerDrunk01')
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('GetDrunkLevel', GetDrunkLevel)
exports('GetCurrentAlcohol', function() return currentAlcohol end)
exports('AddAlcohol', function(amount)
    TriggerEvent('rsg-saloon-premium:client:addAlcohol', amount)
end)

print('^2[RSG-Saloon-Premium]^0 Drunk Effects module loaded!')
