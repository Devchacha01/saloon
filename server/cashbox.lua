-- ============================================================================
-- RSG SALOON PREMIUM - SERVER CASHBOX
-- Handles financial operations and money management
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Debug print helper
local function DebugPrint(...)
    if Config.Debug then
        print('[Saloon Premium - Cashbox]', ...)
    end
end

-- ============================================================================
-- GET CASHBOX BALANCE
-- ============================================================================

RSGCore.Functions.CreateCallback('rsg-saloon-premium:server:getCashbox', function(source, cb, saloonId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end
    
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    local saloonConfig = Config.Saloons[saloonId]
    
    -- Check permissions
    if playerJob ~= saloonId then
        cb(nil)
        return
    end
    
    if not saloonConfig or playerGrade < saloonConfig.grades.cashbox then
        cb(nil)
        return
    end
    
    -- Get balance
    local cashboxData = MySQL.query.await(
        'SELECT balance FROM saloon_premium_cashbox WHERE saloon = ?',
        { saloonId }
    )
    
    local balance = 0
    if cashboxData and cashboxData[1] then
        balance = cashboxData[1].balance
    end
    
    -- Get recent transactions
    local transactions = MySQL.query.await([[
        SELECT type, amount, item, quantity, player_name, timestamp 
        FROM saloon_premium_transactions 
        WHERE saloon = ? 
        ORDER BY timestamp DESC 
        LIMIT 50
    ]], { saloonId })
    
    -- Calculate daily stats
    local dailyStats = MySQL.query.await([[
        SELECT 
            SUM(CASE WHEN type = 'sale' THEN amount ELSE 0 END) as total_sales,
            SUM(CASE WHEN type = 'tip' THEN amount ELSE 0 END) as total_tips,
            SUM(CASE WHEN type = 'withdraw' THEN amount ELSE 0 END) as total_withdrawals,
            COUNT(CASE WHEN type = 'sale' THEN 1 END) as sale_count
        FROM saloon_premium_transactions 
        WHERE saloon = ? AND DATE(timestamp) = CURDATE()
    ]], { saloonId })
    
    cb({
        balance = balance,
        transactions = transactions or {},
        dailyStats = dailyStats and dailyStats[1] or {
            total_sales = 0,
            total_tips = 0,
            total_withdrawals = 0,
            sale_count = 0
        }
    })
end)

-- ============================================================================
-- WITHDRAW FROM CASHBOX
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:withdrawCashbox', function(saloonId, amount)
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
    
    -- Check if employee
    if playerJob ~= saloonId then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale['not_employee']
        })
        return
    end
    
    -- Check cashbox permission
    if playerGrade < saloonConfig.grades.cashbox then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale['no_permission']
        })
        return
    end
    
    -- Validate amount
    amount = tonumber(amount) or 0
    if amount < Config.MinWithdraw then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Minimum withdrawal is $' .. Config.MinWithdraw
        })
        return
    end
    
    if amount > Config.MaxWithdraw then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Maximum withdrawal is $' .. Config.MaxWithdraw
        })
        return
    end
    
    -- Check cashbox balance
    local cashboxData = MySQL.query.await(
        'SELECT balance FROM saloon_premium_cashbox WHERE saloon = ?',
        { saloonId }
    )
    
    if not cashboxData or not cashboxData[1] or tonumber(cashboxData[1].balance) < amount then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale['cashbox_empty']
        })
        return
    end
    
    -- Remove from cashbox
    MySQL.query.await(
        'UPDATE saloon_premium_cashbox SET balance = balance - ? WHERE saloon = ?',
        { amount, saloonId }
    )
    
    DebugPrint('Removed from cashbox, adding to player...')
    
    -- Add money to player
    local success = Player.Functions.AddMoney('cash', amount, 'saloon-cashbox-withdraw')
    DebugPrint('AddMoney result:', success)
    
    -- Log transaction
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    MySQL.query.await([[
        INSERT INTO saloon_premium_transactions (saloon, type, amount, citizenid, player_name)
        VALUES (?, 'withdraw', ?, ?, ?)
    ]], { saloonId, amount, citizenid, playerName })
    
    if LogAction then
        LogAction(saloonId, 'cashbox_withdraw', string.format('Withdrew $%s', amount), citizenid, playerName)
    end
    
    -- Notify player
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format(Config.Locale['withdraw_success'], amount)
    })
    
    -- Refresh UI
    TriggerClientEvent('rsg-saloon-premium:client:refreshUI', source, saloonId)
    
    DebugPrint('Withdrawal:', amount, 'from', saloonId, 'by', playerName)
end)

-- ============================================================================
-- DEPOSIT TO CASHBOX
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:depositCashbox', function(saloonId, amount)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    local playerJob = Player.PlayerData.job.name
    local saloonConfig = Config.Saloons[saloonId]
    
    -- Validate saloon
    if not saloonConfig then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid saloon.'
        })
        return
    end
    
    -- Check if employee
    if playerJob ~= saloonId then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Locale['not_employee']
        })
        return
    end
    
    -- Validate amount
    amount = tonumber(amount) or 0
    if amount <= 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid amount.'
        })
        return
    end
    
    -- Check player cash
    if Player.Functions.GetMoney('cash') < amount then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Not enough cash.'
        })
        return
    end
    
    -- Add to cashbox
    MySQL.query.await(
        'UPDATE saloon_premium_cashbox SET balance = balance + ? WHERE saloon = ?',
        { amount, saloonId }
    )
    
    -- Remove money from player
    Player.Functions.RemoveMoney('cash', amount, 'saloon-cashbox-deposit')
    
    -- Log transaction
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    MySQL.query.await([[
        INSERT INTO saloon_premium_transactions (saloon, type, amount, citizenid, player_name)
        VALUES (?, 'deposit', ?, ?, ?)
    ]], { saloonId, amount, citizenid, playerName })
    
    if LogAction then
        LogAction(saloonId, 'cashbox_deposit', string.format('Deposited $%s', amount), citizenid, playerName)
    end
    
    -- Notify player
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format('Deposited $%s', amount)
    })
    
    -- Refresh UI
    TriggerClientEvent('rsg-saloon-premium:client:refreshUI', source, saloonId)
    
    DebugPrint('Deposit:', amount, 'to', saloonId, 'by', playerName)
end)

-- ============================================================================
-- GET EMPLOYEE STATS
-- ============================================================================

RSGCore.Functions.CreateCallback('rsg-saloon-premium:server:getEmployeeStats', function(source, cb, saloonId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end
    
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    local saloonConfig = Config.Saloons[saloonId]
    
    -- Check permissions
    if playerJob ~= saloonId or not saloonConfig then
        cb(nil)
        return
    end
    
    if playerGrade < saloonConfig.grades.employees then
        cb(nil)
        return
    end
    
    -- Get all employees for this saloon
    local employees = MySQL.query.await([[
        SELECT player_name, items_crafted, items_sold, sales_total, tips_earned
        FROM saloon_premium_employees 
        WHERE saloon = ?
        ORDER BY sales_total DESC
    ]], { saloonId })
    
    cb(employees or {})
end)

print('^2[RSG-Saloon-Premium]^0 Cashbox module loaded!')
