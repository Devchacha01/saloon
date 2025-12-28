-- ============================================================================
-- RSG SALOON PREMIUM - CLIENT CRAFTING
-- Handles crafting UI callbacks, animations, and progress bars
-- ============================================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State
local isCrafting = false

-- ============================================================================
-- CRAFTING ANIMATIONS
-- ============================================================================



-- ============================================================================
-- CRAFTING NUI CALLBACK
-- ============================================================================

RegisterNUICallback('startCraft', function(data, cb)
    if isCrafting then
        cb({ success = false, error = 'Already crafting' })
        return
    end
    
    local itemName = data.item
    local saloonId = data.saloonId
    local recipe = nil
    
    -- Find recipe
    for _, r in ipairs(Config.Recipes) do
        if r.item == itemName then
            recipe = r
            break
        end
    end
    
    if not recipe then
        cb({ success = false, error = 'Recipe not found' })
        return
    end
    
    -- Close menu temporarily
    SetNuiFocus(false, false)
    
    -- Start crafting
    isCrafting = true
    
    -- Progress bar with animation from rex-mining workshop
    local success = lib.progressBar({
        duration = recipe.time,
        label = string.format(Config.Locale['crafting_start'], recipe.label),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mech_inventory@crafting@fallbacks',
            clip = 'full_craft_and_stow',
            flag = 16,
        },
    })
    
    isCrafting = false
    
    if success then
        -- Notify server to process craft
        TriggerServerEvent('rsg-saloon-premium:server:craftItem', saloonId, itemName)
        cb({ success = true })
    else
        lib.notify({
            type = 'error',
            description = 'Crafting cancelled.'
        })
        cb({ success = false, error = 'Cancelled' })
    end
    
    -- Reopen menu after short delay
    Wait(500)
    if not isCrafting then
        exports['rsg-saloon-premium']:OpenSaloonMenu(saloonId)
    end
end)

-- ============================================================================
-- CHECK INGREDIENTS (for UI highlighting)
-- ============================================================================

RegisterNUICallback('checkIngredients', function(data, cb)
    local itemName = data.item
    
    -- Find recipe
    local recipe = nil
    for _, r in ipairs(Config.Recipes) do
        if r.item == itemName then
            recipe = r
            break
        end
    end
    
    if not recipe then
        cb({ canCraft = false, missing = {} })
        return
    end
    
    -- Check ingredients via callback
    RSGCore.Functions.TriggerCallback('rsg-saloon-premium:server:getPlayerInventory', function(inventory)
        local canCraft = true
        local missing = {}
        
        for _, req in ipairs(recipe.requirements) do
            local hasAmount = inventory[req.item] or 0
            if hasAmount < req.amount then
                canCraft = false
                table.insert(missing, {
                    item = req.item,
                    need = req.amount,
                    have = hasAmount,
                })
            end
        end
        
        cb({
            canCraft = canCraft,
            missing = missing,
        })
    end)
end)
