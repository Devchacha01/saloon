-- ============================================================================
-- RSG SALOON PREMIUM - SERVER STORAGE
-- Handles employee storage and shop refill operations
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Debug print helper
local function DebugPrint(...)
    if Config.Debug then
        print('[Saloon Premium - Storage]', ...)
    end
end

-- ============================================================================
-- GET STORAGE CONTENTS
-- ============================================================================

RSGCore.Functions.CreateCallback('rsg-saloon-premium:server:getStorage', function(source, cb, saloonId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end
    
    local playerJob = Player.PlayerData.job.name
    
    -- Check if employee
    if playerJob ~= saloonId then
        cb({})
        return
    end
    
    local storageData = MySQL.query.await(
        'SELECT item, quantity FROM saloon_premium_storage WHERE saloon = ? AND quantity > 0 ORDER BY item',
        { saloonId }
    )
    
    local enrichedStorage = {}
    for _, storage in ipairs(storageData or {}) do
        local itemInfo = RSGCore.Shared.Items[storage.item]
        table.insert(enrichedStorage, {
            item = storage.item,
            label = RSGCore.Shared.Items[storage.item] and RSGCore.Shared.Items[storage.item].label or storage.item,
            quantity = storage.quantity,
            image = itemInfo and itemInfo.image or (storage.item .. '.png'),
            defaultPrice = Config.DefaultPrices[storage.item] or 1.00,
        })
    end
    
    cb(enrichedStorage)
end)

-- ============================================================================
-- REFILL SHOP FROM STORAGE
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:refillShop', function(saloonId, itemName, quantity, price)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    local saloonConfig = Config.Saloons[saloonId]
    
    -- Validate saloon
    if not saloonConfig then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid saloon.'
        })
        return
    end
    
    -- Check if employee at this saloon
    if playerJob ~= saloonId then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale['not_employee']
        })
        return
    end
    
    -- Check refill permission
    if playerGrade < saloonConfig.grades.refill then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale['no_permission']
        })
        return
    end
    
    quantity = math.max(1, math.floor(quantity or 1))
    price = math.max(0.01, price or Config.DefaultPrices[itemName] or 1.00)
    
    -- Check storage quantity
    local storageData = MySQL.query.await(
        'SELECT quantity FROM saloon_premium_storage WHERE saloon = ? AND item = ?',
        { saloonId, itemName }
    )
    
    if not storageData or not storageData[1] or storageData[1].quantity < quantity then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale['no_storage']
        })
        return
    end
    
    -- Remove from storage
    MySQL.query.await(
        'UPDATE saloon_premium_storage SET quantity = quantity - ? WHERE saloon = ? AND item = ?',
        { quantity, saloonId, itemName }
    )
    
    -- Add to shop stock (upsert)
    MySQL.query.await([[
        INSERT INTO saloon_premium_stock (saloon, item, quantity, price)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE quantity = quantity + ?, price = ?
    ]], { saloonId, itemName, quantity, price, quantity, price })
    
    -- Log refill transaction
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    MySQL.query.await([[
        INSERT INTO saloon_premium_transactions (saloon, type, amount, item, quantity, citizenid, player_name)
        VALUES (?, 'refill', ?, ?, ?, ?, ?)
    ]], { saloonId, price * quantity, itemName, quantity, citizenid, playerName })
    
    -- Get item label
    local itemInfo = RSGCore.Shared.Items[itemName]
    local itemLabel = itemInfo and itemInfo.label or itemName
    
    -- Notify player
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format(Config.Locale['refill_success'], quantity, itemLabel)
    })
    
    -- Refresh UI
    TriggerClientEvent('rsg-saloon-premium:client:refreshUI', source, saloonId)
    
    DebugPrint('Refilled shop:', itemName, 'x', quantity, '@', price, 'by', playerName)
end)

-- ============================================================================
-- WITHDRAW FROM STORAGE
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:withdrawStorage', function(saloonId, itemName, quantity)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    local playerJob = Player.PlayerData.job.name
    
    -- Check if employee at this saloon
    if playerJob ~= saloonId then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Config.Locale['not_employee'] })
        return
    end
    
    quantity = math.max(1, math.floor(quantity or 1))
    
    -- Check storage quantity
    local storageData = MySQL.query.await(
        'SELECT quantity FROM saloon_premium_storage WHERE saloon = ? AND item = ?',
        { saloonId, itemName }
    )
    
    if not storageData or not storageData[1] or storageData[1].quantity < quantity then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = Config.Locale['no_storage'] })
        return
    end
    
    -- Remove from storage
    if storageData[1].quantity == quantity then
         MySQL.query.await('DELETE FROM saloon_premium_storage WHERE saloon = ? AND item = ?', { saloonId, itemName })
    else
         MySQL.query.await('UPDATE saloon_premium_storage SET quantity = quantity - ? WHERE saloon = ? AND item = ?', { quantity, saloonId, itemName })
    end
    
    -- Add to player inventory
    Player.Functions.AddItem(itemName, quantity)
    TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items[itemName], 'add')
    
    -- Log action
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local itemLabel = RSGCore.Shared.Items[itemName].label
    
    if LogAction then
        LogAction(saloonId, 'storage_withdraw', string.format('Withdrew %dx %s', quantity, itemLabel), citizenid, playerName)
    end
    
    -- Notify player
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format('Withdrew %dx %s', quantity, itemLabel)
    })
    
    -- Refresh UI
    TriggerClientEvent('rsg-saloon-premium:client:refreshUI', source, saloonId)
end)

-- ============================================================================
-- CLEANUP EMPTY STORAGE/STOCK ENTRIES
-- ============================================================================

CreateThread(function()
    while true do
        Wait(300000) -- Every 5 minutes
        MySQL.query('DELETE FROM saloon_premium_storage WHERE quantity <= 0')
        MySQL.query('DELETE FROM saloon_premium_stock WHERE quantity <= 0')
        if Config.Debug then
            DebugPrint('Cleaned up empty storage/stock entries')
        end
    end
end)

print('^2[RSG-Saloon-Premium]^0 Storage module loaded!')
