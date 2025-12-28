-- ============================================================================
-- RSG SALOON PREMIUM - SERVER EMPLOYEES
-- Hire/fire employee management
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================================================
-- HIRE PLAYER
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:hirePlayer', function(targetId, saloonId, grade)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    
    if not Player or not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Player not found.'
        })
        return
    end
    
    local saloonConfig = Config.Saloons[saloonId]
    if not saloonConfig then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid saloon.'
        })
        return
    end
    
    -- Check if hiring player has permission (grade 3 = owner)
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    if playerJob ~= saloonId or playerGrade < saloonConfig.grades.employees then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You do not have permission to hire employees.'
        })
        return
    end
    
    -- Validate grade
    grade = tonumber(grade) or 0
    if grade < 0 or grade > 3 then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid grade (must be 0-3).'
        })
        return
    end
    
    -- Check employee limit (Max 4)
    local employeeCount = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE job = ?', { saloonId })
    if employeeCount >= 4 then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Maximum employee limit reached (4).'
        })
        return
    end

    -- Cannot hire someone to a higher grade than yourself
    if grade >= playerGrade then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Cannot hire someone to a grade equal or higher than yours.'
        })
        return
    end
    
    -- Set target player's job
    TargetPlayer.Functions.SetJob(saloonId, grade)
    
    -- Notify both players
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    local gradeLabel = GetGradeLabel(grade)
    
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = string.format('Hired %s as %s', targetName, gradeLabel)
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        type = 'success',
        description = string.format('You have been hired at %s as %s!', saloonConfig.name, gradeLabel)
    })
    
    -- Add to employee stats table
    MySQL.query.await([[
        INSERT IGNORE INTO saloon_premium_employees (saloon, citizenid, player_name)
        VALUES (?, ?, ?)
    ]], { saloonId, TargetPlayer.PlayerData.citizenid, targetName })
    
    if Config.Debug then
        print('[Saloon] Hired:', targetName, 'at', saloonId, 'grade', grade)
    end
end)

-- ============================================================================
-- PROMOTE PLAYER
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:promotePlayer', function(targetCitizenId, saloonId)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end

    local saloonConfig = Config.Saloons[saloonId]
    if not saloonConfig then return end

    -- Check if promoting player is Boss (Grade 3)
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    if playerJob ~= saloonId or playerGrade < 3 then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Only the Boss can promote employees.'
        })
        return
    end

    -- Find target player
    local TargetPlayer = RSGCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    
    if TargetPlayer then
        -- Player is online
        local targetJob = TargetPlayer.PlayerData.job.name
        local targetGrade = TargetPlayer.PlayerData.job.grade.level
        
        if targetJob ~= saloonId then
             TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player does not work here.' })
             return
        end
        
        if targetGrade >= 2 then
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Cannot promote further (Max: Manager).' })
            return
        end
        
        local newGrade = targetGrade + 1
        TargetPlayer.Functions.SetJob(saloonId, newGrade)
        
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = string.format('Promoted to %s', GetGradeLabel(newGrade))
        })
        TriggerClientEvent('ox_lib:notify', TargetPlayer.PlayerData.source, {
            type = 'success',
            description = string.format('You have been promoted to %s!', GetGradeLabel(newGrade))
        })
    else
        -- Player offline - check DB
        local targetData = MySQL.single.await('SELECT job, job_grade FROM players WHERE citizenid = ?', { targetCitizenId })
        if targetData and targetData.job == saloonId then
             if targetData.job_grade >= 2 then
                TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Cannot promote further (Max: Manager).' })
                return
             end
             
             MySQL.update.await('UPDATE players SET job_grade = job_grade + 1 WHERE citizenid = ?', { targetCitizenId })
             TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Employee promoted.' })
        else
            TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Employee not found.' })
        end
    end
end)

-- ============================================================================
-- FIRE PLAYER
-- ============================================================================

RegisterNetEvent('rsg-saloon-premium:server:firePlayer', function(targetCitizenId, saloonId)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    local saloonConfig = Config.Saloons[saloonId]
    if not saloonConfig then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid saloon.'
        })
        return
    end
    
    -- Check if firing player has permission (Only Boss/Owner can fire - Grade 3)
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    -- Grade 3 is required to fire (Boss)
    if playerJob ~= saloonId or playerGrade < 3 then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Only the Boss can fire employees.'
        })
        return
    end
    
    -- Find target player (could be online or offline)
    local TargetPlayer = RSGCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    
    if TargetPlayer then
        -- Player is online
        local targetGrade = TargetPlayer.PlayerData.job.grade.level
        
        -- Cannot fire someone of equal or higher grade
        if targetGrade >= playerGrade then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Cannot fire someone of equal or higher rank.'
            })
            return
        end
        
        -- Set to unemployed
        TargetPlayer.Functions.SetJob('unemployed', 0)
        
        TriggerClientEvent('ox_lib:notify', TargetPlayer.PlayerData.source, {
            type = 'error',
            description = string.format('You have been fired from %s!', saloonConfig.name)
        })
    else
        -- Player is offline - update database directly
        MySQL.query.await([[
            UPDATE players SET job = 'unemployed', job_grade = 0 
            WHERE citizenid = ? AND job = ?
        ]], { targetCitizenId, saloonId })
    end
    
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Employee has been fired.'
    })
    
    if Config.Debug then
        print('[Saloon] Fired:', targetCitizenId, 'from', saloonId)
    end
end)

-- ============================================================================
-- GET EMPLOYEES LIST
-- ============================================================================

RSGCore.Functions.CreateCallback('rsg-saloon-premium:server:getEmployees', function(source, cb, saloonId)
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then
        cb({})
        return
    end
    
    local saloonConfig = Config.Saloons[saloonId]
    if not saloonConfig then
        cb({})
        return
    end
    
    -- Check permission
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    if playerJob ~= saloonId or playerGrade < saloonConfig.grades.employees then
        cb({})
        return
    end
    
    -- Get all employees for this saloon from players table
    local employees = MySQL.query.await([[
        SELECT p.citizenid, p.charinfo, p.job,
               COALESCE(e.items_crafted, 0) as items_crafted,
               COALESCE(e.sales_total, 0) as sales_total,
               COALESCE(e.tips_earned, 0) as tips_earned
        FROM players p
        LEFT JOIN saloon_premium_employees e ON p.citizenid = e.citizenid AND e.saloon = ?
        WHERE JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.name')) = ?
        ORDER BY JSON_EXTRACT(p.job, '$.grade.level') DESC
    ]], { saloonId, saloonId })
    
    -- Parse charinfo and job to get names and grades
    local result = {}
    for _, emp in ipairs(employees or {}) do
        local charinfo = json.decode(emp.charinfo or '{}')
        local jobData = json.decode(emp.job or '{}')
        local grade = jobData.grade and jobData.grade.level or 0
        table.insert(result, {
            citizenid = emp.citizenid,
            firstname = charinfo.firstname or 'Unknown',
            lastname = charinfo.lastname or '',
            grade = grade,
            gradeLabel = GetGradeLabel(grade),
            itemsCrafted = emp.items_crafted,
            salesTotal = emp.sales_total,
            tipsEarned = emp.tips_earned
        })
    end
    
    cb(result)
end)

-- ============================================================================
-- GET NEARBY PLAYERS (for hiring)
-- ============================================================================

RSGCore.Functions.CreateCallback('rsg-saloon-premium:server:getNearbyPlayers', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then
        cb({})
        return
    end
    
    local players = RSGCore.Functions.GetPlayers()
    local result = {}
    
    for _, playerId in ipairs(players) do
        if playerId ~= source then
            local TargetPlayer = RSGCore.Functions.GetPlayer(playerId)
            if TargetPlayer then
                table.insert(result, {
                    id = playerId,
                    citizenid = TargetPlayer.PlayerData.citizenid,
                    name = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname,
                    currentJob = TargetPlayer.PlayerData.job.label
                })
            end
        end
    end
    
    cb(result)
end)

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function GetGradeLabel(grade)
    local labels = {
        [0] = 'Helper',
        [1] = 'Bartender',
        [2] = 'Manager',
        [3] = 'Owner'
    }
    return labels[grade] or 'Unknown'
end

print('^2[RSG-Saloon-Premium]^0 Employees module loaded!')
