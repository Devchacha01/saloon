-- ============================================================================
-- RSG SALOON PREMIUM - PIANO SYSTEM
-- Play piano at saloon locations with animations
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State
local isPlaying = false

-- ============================================================================
-- PIANO SCENARIOS
-- ============================================================================

local PianoScenarios = {
    male = {
        'PROP_HUMAN_PIANO',
        'PROP_HUMAN_PIANO_UPPERCLASS',
        'PROP_HUMAN_PIANO_RIVERBOAT',
        'PROP_HUMAN_PIANO_SKETCHY'
    },
    female = {
        'PROP_HUMAN_ABIGAIL_PIANO'
    }
}

-- ============================================================================
-- PLAY PIANO FUNCTION
-- ============================================================================

function StartPlayingPiano(piano)
    if isPlaying then
        lib.notify({ type = 'error', description = 'Already playing!' })
        return
    end
    
    local ped = PlayerPedId()
    local isMale = IsPedMale(ped)
    
    -- Select random scenario
    local scenarios = isMale and PianoScenarios.male or PianoScenarios.female
    local scenario = scenarios[math.random(1, #scenarios)]
    
    -- Start scenario
    TaskStartScenarioAtPosition(ped, GetHashKey(scenario), 
        piano.coords.x, piano.coords.y, piano.coords.z, 
        piano.heading, 0, true, true, 0, true)
    
    isPlaying = true
    
    lib.notify({
        type = 'info',
        description = 'Playing piano... Press Backspace to stop.'
    })
end

function StopPlayingPiano()
    if not isPlaying then return end
    
    ClearPedTasks(PlayerPedId())
    isPlaying = false
    
    lib.notify({
        type = 'info',
        description = 'Stopped playing piano.'
    })
end

-- ============================================================================
-- STOP KEY DETECTION (Backspace while playing)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(0)
        
        if isPlaying then
            -- Disable movement while playing
            DisableControlAction(0, 0x8FD015D8, true) -- W
            DisableControlAction(0, 0xD27782E3, true) -- S
            DisableControlAction(0, 0xA65EBAB4, true) -- A
            DisableControlAction(0, 0x6319DB71, true) -- D
            
            -- Check for backspace to stop
            if IsControlJustPressed(0, 0x156F7119) then -- Backspace
                StopPlayingPiano()
            end
        else
            Wait(500) -- Less frequent check when not playing
        end
    end
end)

-- ============================================================================
-- RSG-TARGET ZONES FOR PIANOS
-- ============================================================================

CreateThread(function()
    Wait(2000)
    
    if not Config.PianoLocations or not Config.PianoEnabled then
        print('^3[RSG-Saloon-Premium]^0 Piano system disabled or no locations defined.')
        return
    end
    
    for i, piano in ipairs(Config.PianoLocations) do
        exports['rsg-target']:AddCircleZone(
            'saloon_piano_' .. i,
            piano.coords,
            1.0,
            {
                name = 'saloon_piano_' .. i,
                debugPoly = Config.Debug,
            },
            {
                options = {
                    {
                        icon = 'fa-solid fa-music',
                        label = 'Play Piano',
                        action = function()
                            StartPlayingPiano(piano)
                        end,
                    },
                    {
                        icon = 'fa-solid fa-stop',
                        label = 'Stop Playing',
                        canInteract = function()
                            return isPlaying
                        end,
                        action = function()
                            StopPlayingPiano()
                        end,
                    },
                },
                distance = 2.0,
            }
        )
    end
    
    print('^2[RSG-Saloon-Premium]^0 Piano targets created for', #Config.PianoLocations, 'locations.')
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('IsPlayingPiano', function() return isPlaying end)
exports('StartPlayingPiano', StartPlayingPiano)
exports('StopPlayingPiano', StopPlayingPiano)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isPlaying then
        ClearPedTasks(PlayerPedId())
    end
end)

print('^2[RSG-Saloon-Premium]^0 Piano module loaded!')
