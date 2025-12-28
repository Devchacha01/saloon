-- ============================================================================
-- RSG SALOON PREMIUM - SERVER LOGS
-- Handles logging of significant actions (withdrawals, deposits, etc.)
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

CreateThread(function()
    -- Create logs table if it doesn't exist
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS saloon_premium_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            saloon VARCHAR(50) NOT NULL,
            type VARCHAR(50) NOT NULL,
            message TEXT NOT NULL,
            citizenid VARCHAR(50),
            player_name VARCHAR(100),
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    print('^2[RSG-Saloon-Premium]^0 Logs module loaded!')
end)

-- ============================================================================
-- LOG ACTION HELPER
-- ============================================================================

function LogAction(saloonId, type, message, citizenid, name)
    MySQL.query.await([[
        INSERT INTO saloon_premium_logs (saloon, type, message, citizenid, player_name)
        VALUES (?, ?, ?, ?, ?)
    ]], { saloonId, type, message, citizenid, name })
    
    if Config.Debug then
        print(string.format('[Saloon Log] [%s] %s: %s (%s)', saloonId, type, message, name))
    end
end
exports('LogAction', LogAction) -- Export for other resources if needed

-- ============================================================================
-- GET LOGS CALLBACK
-- ============================================================================

RSGCore.Functions.CreateCallback('rsg-saloon-premium:server:getLogs', function(source, cb, saloonId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end
    
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    local saloonConfig = Config.Saloons[saloonId]
    
    -- Check permissions (Boss/Manager only)
    if playerJob ~= saloonId or not saloonConfig then
        cb({})
        return
    end
    
    -- Manager (2) or Boss (3)
    if playerGrade < 2 then 
        cb({})
        return
    end
    
    -- Get logs (Limit 100)
    local logs = MySQL.query.await([[
        SELECT id, type, message, player_name, timestamp 
        FROM saloon_premium_logs 
        WHERE saloon = ? 
        ORDER BY timestamp DESC 
        LIMIT 100
    ]], { saloonId })
    
    cb(logs or {})
end)
