

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State variables
local currentSaloon = nil
local isMenuOpen = false
local saloonBlips = {}



local function DebugPrint(...)
    if Config.Debug then
        print('[Saloon Premium]', ...)
    end
end

-- Get player's current job
local function GetPlayerJob()
    local playerData = RSGCore.Functions.GetPlayerData()
    if playerData and playerData.job then
        return playerData.job.name, playerData.job.grade.level
    end
    return nil, nil
end

-- Check if player is employee at specific saloon
local function IsEmployeeAt(saloonId)
    local job, _ = GetPlayerJob()
    return job == saloonId
end



RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    isMenuOpen = false
    currentSaloon = nil
    cb('ok')
end)

RegisterNUICallback('ready', function(_, cb)
    cb('ok')
end)



RegisterNUICallback('getNearbyPlayers', function(_, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local nearby = {}
    
    -- Loop through active players
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then -- Exclude self
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            
            if #(coords - targetCoords) < 5.0 then
                local serverId = GetPlayerServerId(playerId)
                table.insert(nearby, {
                    id = serverId,
                    name = GetPlayerName(playerId) .. ' (' .. serverId .. ')'
                })
            end
        end
    end
    
    cb(nearby)
end)

RegisterNUICallback('hirePlayer', function(data, cb)
    TriggerServerEvent('rsg-saloon-premium:server:hirePlayer', data.targetId, data.saloonId)
    cb('ok')
end)

RegisterNUICallback('firePlayer', function(data, cb)
    TriggerServerEvent('rsg-saloon-premium:server:firePlayer', data.targetId, data.saloonId)
    cb('ok')
end)

RegisterNUICallback('promotePlayer', function(data, cb)
    TriggerServerEvent('rsg-saloon-premium:server:promotePlayer', data.targetId, data.saloonId)
    cb('ok')
end)

RegisterNUICallback('getEmployees', function(data, cb)
    RSGCore.Functions.TriggerCallback('rsg-saloon-premium:server:getEmployees', function(employees)
        cb(employees or {})
    end, data.saloonId)
end)

RegisterNUICallback('withdrawStorage', function(data, cb)
    TriggerServerEvent('rsg-saloon-premium:server:withdrawStorage', data.saloonId, data.item, data.quantity)
    cb('ok')
end)

RegisterNUICallback('getLogs', function(data, cb)
    RSGCore.Functions.TriggerCallback('rsg-saloon-premium:server:getLogs', function(logs)
        cb(logs or {})
    end, data.saloonId)
end)

RegisterNUICallback('withdrawCashbox', function(data, cb)
    TriggerServerEvent('rsg-saloon-premium:server:withdrawCashbox', data.saloonId, data.amount)
    cb('ok')
end)

RegisterNUICallback('depositCashbox', function(data, cb)
    TriggerServerEvent('rsg-saloon-premium:server:depositCashbox', data.saloonId, data.amount)
    cb('ok')
end)



local function OpenSaloonMenu(saloonId)
    if isMenuOpen then return end
    
    local saloonConfig = Config.Saloons[saloonId]
    if not saloonConfig then
        DebugPrint('Invalid saloon config:', saloonId)
        return
    end
    
    currentSaloon = saloonId
    
    -- Request data from server
    RSGCore.Functions.TriggerCallback('rsg-saloon-premium:server:getSaloonData', function(data)
        if not data then
            lib.notify({
                type = 'error',
                description = 'Failed to load saloon data.'
            })
            return
        end
        
        -- Get player inventory for crafting
        RSGCore.Functions.TriggerCallback('rsg-saloon-premium:server:getPlayerInventory', function(inventory)
            -- Send data to NUI
            SetNuiFocus(true, true)
            isMenuOpen = true
            
            SendNUIMessage({
                action = 'openMenu',
                saloonId = saloonId,
                saloonName = data.saloonName,
                isEmployee = data.isEmployee,
                playerGrade = data.playerGrade,
                playerGradeLabel = data.playerGradeLabel,
                permissions = data.permissions,
                shopStock = data.shopStock,
                storage = data.storage,
                cashboxBalance = data.cashboxBalance,
                transactions = data.transactions,
                recipes = data.recipes,
                defaultPrices = data.defaultPrices,
                playerInventory = inventory,
                imgPath = Config.Img,
            })
            
            DebugPrint('Menu opened for:', saloonId)
        end)
    end, saloonId)
end

-- Export for external resources
exports('OpenSaloonMenu', OpenSaloonMenu)



RegisterNetEvent('rsg-saloon-premium:client:refreshUI', function(saloonId)
    if not isMenuOpen or currentSaloon ~= saloonId then return end
    
    RSGCore.Functions.TriggerCallback('rsg-saloon-premium:server:getSaloonData', function(data)
        if not data then return end
        
        RSGCore.Functions.TriggerCallback('rsg-saloon-premium:server:getPlayerInventory', function(inventory)
            SendNUIMessage({
                action = 'refreshData',
                shopStock = data.shopStock,
                storage = data.storage,
                cashboxBalance = data.cashboxBalance,
                transactions = data.transactions,
                playerInventory = inventory,
            })
        end)
    end, saloonId)
end)



local function SetupTargetZones()
    for saloonId, saloon in pairs(Config.Saloons) do
        -- Main bar target using ox_target
        exports.ox_target:addSphereZone({
            coords = saloon.points.bar,
            radius = 1.5,
            debug = Config.Debug,
            options = {
                {
                    name = 'saloon_menu_' .. saloonId,
                    icon = 'fas fa-beer',
                    label = saloon.name .. ' Menu',
                    onSelect = function()
                        OpenSaloonMenu(saloonId)
                    end,
                },
            }
        })
        
        -- Personal Storage target - Opens rsg-inventory stash
        if saloon.points.storage then
            exports.ox_target:addSphereZone({
                coords = saloon.points.storage,
                radius = 1.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'saloon_personal_storage_' .. saloonId,
                        icon = 'fas fa-box',
                        label = saloon.name .. ' Personal Storage',
                        canInteract = function()
                            -- Only employees can access personal storage
                            local job, _ = GetPlayerJob()
                            return job == saloonId
                        end,
                        onSelect = function()
                            -- Open rsg-inventory stash
                            local stashName = 'saloon_storage_' .. saloonId
                            TriggerServerEvent('rsg-saloon:server:openStorage', saloonId)
                        end,
                    },
                }
            })
        end
        
        DebugPrint('Added ox_target zones for:', saloonId)
    end
end



local function CreateBlips()
    for saloonId, saloon in pairs(Config.Saloons) do
        if saloon.showBlip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, saloon.coords.x, saloon.coords.y, saloon.coords.z)
            SetBlipSprite(blip, joaat(Config.Blip.sprite), true)
            SetBlipScale(blip, Config.Blip.scale)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, saloon.name)
            
            saloonBlips[saloonId] = blip
            DebugPrint('Created blip for:', saloonId)
        end
    end
end

local function RemoveBlips()
    for saloonId, blip in pairs(saloonBlips) do
        RemoveBlip(blip)
    end
    saloonBlips = {}
end



if Config.Keybind then
    -- Register command for keybind
    RegisterCommand('opensaloon', function()
        -- Find nearest saloon
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearestSaloon = nil
        local nearestDist = 999
        
        for saloonId, saloon in pairs(Config.Saloons) do
            local dist = #(playerCoords - saloon.coords)
            if dist < nearestDist and dist < 10.0 then
                nearestDist = dist
                nearestSaloon = saloonId
            end
        end
        
        if nearestSaloon then
            OpenSaloonMenu(nearestSaloon)
        else
            lib.notify({
                type = 'error',
                description = 'You are not near a saloon.'
            })
        end
    end, false)
    
    -- Use ox_lib keybind for RedM compatibility
    lib.addKeybind({
        name = 'opensaloon',
        description = 'Open Saloon Menu',
        defaultKey = Config.Keybind,
        onPressed = function()
            ExecuteCommand('opensaloon')
        end
    })
end



CreateThread(function()
    Wait(1000)
    SetupTargetZones()
    CreateBlips()
    print('^2[RSG-Saloon-Premium]^0 Client loaded successfully!')
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    RemoveBlips()
end)
