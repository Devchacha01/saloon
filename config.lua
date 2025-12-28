Config = {}


Config.Debug = false
Config.Keybind = 'J'                    -- Keybind to open menu (set to false for target only)
Config.Img = 'nui://rsg-inventory/html/images/'  -- Path to item images


Config.StorageMaxWeight = 500000
Config.StorageMaxSlots = 100


Config.MinWithdraw = 1.0
Config.MaxWithdraw = 50000.0
Config.TipsEnabled = true
Config.DefaultTipPercent = 10


Config.JukeboxEnabled = true
Config.JukeboxDefaultVolume = 0.5
Config.JukeboxRadius = 50.0

Config.JukeboxTracks = {
    { name = 'Saloon Piano 1', file = 'piano1.mp3' },
    { name = 'Saloon Piano 2', file = 'piano2.mp3' },
    { name = 'Western Guitar', file = 'guitar1.mp3' },
    { name = 'Harmonica Blues', file = 'harmonica1.mp3' },
}


Config.Blip = {
    name = 'Saloon',
    sprite = 'blip_saloon',
    scale = 0.2
}


Config.Saloons = {
    ['valsaloontender'] = {
        name = 'Valentine Saloon',
        coords = vector3(-313.50, 805.80, 118.98),
        showBlip = true,
        -- Grade Requirements (0 = all, 1 = bartender+, 2 = manager+, 3 = owner only)
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 2,      -- Allow Managers to manage employees
        },
        -- Interaction points
        points = {
            bar = vector3(-313.50, 805.80, 118.98),
            storage = vector3(-315.50, 805.80, 118.98),
            jukebox = vector3(-310.50, 808.80, 118.98),
        }
    },
    ['blasaloontender'] = {
        name = 'Blackwater Saloon',
        coords = vector3(-817.59, -1319.08, 43.67),
        showBlip = true,
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 3,
        },
        points = {
            bar = vector3(-817.59, -1319.08, 43.67),
            storage = vector3(-819.59, -1319.08, 43.67),
            jukebox = vector3(-814.59, -1316.08, 43.67),
        }
    },
    ['rhosaloontender'] = {
        name = 'Rhodes Saloon',
        coords = vector3(1340.17, -1374.81, 80.48),
        showBlip = true,
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 3,
        },
        points = {
            bar = vector3(1340.17, -1374.81, 80.48),
            storage = vector3(1338.17, -1374.81, 80.48),
            jukebox = vector3(1343.17, -1371.81, 80.48),
        }
    },
    ['stdenissaloontender1'] = {
        name = 'Saint Denis Saloon',
        coords = vector3(2792.37, -1168.41, 47.93),
        showBlip = true,
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 2,
        },
        points = {
            bar = vector3(2792.37, -1168.41, 47.93),
            storage = vector3(2790.37, -1168.41, 47.93),
            jukebox = vector3(2795.37, -1165.41, 47.93),
        }
    },
    ['stdenissaloontender2'] = {
        name = 'Saint Denis Saloon 2',
        coords = vector3(2639.84, -1224.26, 53.38),
        showBlip = true,
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 2,
        },
        points = {
            bar = vector3(2639.84, -1224.26, 53.38),
            storage = vector3(2637.84, -1224.26, 53.38),
            jukebox = vector3(2642.84, -1221.26, 53.38),
        }
    },
    ['vansaloontender'] = {
        name = 'Van Horn Saloon',
        coords = vector3(2947.84, 528.06, 45.33),
        showBlip = true,
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 2,
        },
        points = {
            bar = vector3(2947.84, 528.06, 45.33),
            storage = vector3(2945.84, 528.06, 45.33),
            jukebox = vector3(2950.84, 531.06, 45.33),
        }
    },
    ['armsaloontender'] = {
        name = 'Armadillo Saloon',
        coords = vector3(-3699.80, -2594.40, -13.31),
        showBlip = true,
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 2,
        },
        points = {
            bar = vector3(-3699.80, -2594.40, -13.31),
            storage = vector3(-3701.80, -2594.40, -13.31),
            jukebox = vector3(-3696.80, -2591.40, -13.31),
        }
    },
    ['tumsaloontender'] = {
        name = 'Tumbleweed Saloon',
        coords = vector3(-5518.47, -2906.51, -1.75),
        showBlip = true,
        grades = {
            crafting = 0,
            refill = 1,
            cashbox = 2,
            employees = 2,
        },
        points = {
            bar = vector3(-5518.47, -2906.51, -1.75),
            storage = vector3(-5520.47, -2906.51, -1.75),
            jukebox = vector3(-5515.47, -2903.51, -1.75),
        }
    },
}


Config.Recipes = {
    -- ========== DRINKS ==========
    {
        item = 'beer',
        label = 'Beer',
        category = 'drinks',
        time = 5000,
        yield = 2,
        image = 'beer.png',
        requirements = {
            { item = 'wheat', amount = 1 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'whiskey',
        label = 'Whiskey',
        category = 'drinks',
        time = 7000,
        yield = 1,
        image = 'whiskey.png',
        requirements = {
            { item = 'corn', amount = 2 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'vodka',
        label = 'Vodka',
        category = 'drinks',
        time = 6000,
        yield = 1,
        image = 'vodka.png',
        requirements = {
            { item = 'potato', amount = 2 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'tequila',
        label = 'Tequila',
        category = 'drinks',
        time = 6000,
        yield = 1,
        image = 'tequila.png',
        requirements = {
            { item = 'sugar', amount = 2 },
            { item = 'cactus', amount = 1 },
        }
    },
    {
        item = 'rum',
        label = 'Rum',
        category = 'drinks',
        time = 6000,
        yield = 1,
        image = 'rum.png',
        requirements = {
            { item = 'sugar', amount = 3 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'wine',
        label = 'Red Wine',
        category = 'drinks',
        time = 8000,
        yield = 1,
        image = 'wine.png',
        requirements = {
            { item = 'grape', amount = 3 },
            { item = 'sugar', amount = 1 },
        }
    },
    {
        item = 'coffee',
        label = 'Coffee',
        category = 'drinks',
        time = 3000,
        yield = 2,
        image = 'coffee.png',
        requirements = {
            { item = 'coffeebeans', amount = 1 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'lemonade',
        label = 'Lemonade',
        category = 'drinks',
        time = 3000,
        yield = 2,
        image = 'lemonade.png',
        requirements = {
            { item = 'lemon', amount = 2 },
            { item = 'sugar', amount = 1 },
            { item = 'water', amount = 1 },
        }
    },
    -- ========== FOOD ==========
    {
        item = 'stew',
        label = 'Meat Stew',
        category = 'food',
        time = 10000,
        yield = 2,
        image = 'stew.png',
        requirements = {
            { item = 'meat', amount = 1 },
            { item = 'carrot', amount = 1 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'steak',
        label = 'Fried Steak',
        category = 'food',
        time = 6000,
        yield = 1,
        image = 'steak.png',
        requirements = {
            { item = 'meat', amount = 1 },
            { item = 'herb', amount = 1 },
        }
    },
    {
        item = 'bread',
        label = 'Fresh Bread',
        category = 'food',
        time = 8000,
        yield = 3,
        image = 'bread.png',
        requirements = {
            { item = 'wheat', amount = 2 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'soup',
        label = 'Vegetable Soup',
        category = 'food',
        time = 6000,
        yield = 2,
        image = 'soup.png',
        requirements = {
            { item = 'carrot', amount = 1 },
            { item = 'corn', amount = 1 },
            { item = 'water', amount = 1 },
        }
    },
    {
        item = 'pie',
        label = 'Apple Pie',
        category = 'food',
        time = 8000,
        yield = 1,
        image = 'pie.png',
        requirements = {
            { item = 'apple', amount = 2 },
            { item = 'wheat', amount = 1 },
            { item = 'sugar', amount = 1 },
        }
    },
    {
        item = 'roastedmeat',
        label = 'Roasted Meat',
        category = 'food',
        time = 7000,
        yield = 1,
        image = 'roastedmeat.png',
        requirements = {
            { item = 'meat', amount = 2 },
            { item = 'herb', amount = 1 },
        }
    },
}


Config.DefaultPrices = {
    -- Drinks
    beer = 5.00,
    whiskey = 8.00,
    vodka = 7.00,
    tequila = 7.00,
    rum = 6.00,
    wine = 10.00,

    coffee = 3.00,
    lemonade = 2.00,
    -- Food
    stew = 4.00,
    steak = 6.00,
    bread = 2.00,
    soup = 3.00,
    pie = 5.00,
    roastedmeat = 7.00,
}


Config.DrunkEffects = {
    enabled = true,
    alcoholItems = { 'beer', 'whiskey', 'vodka', 'tequila', 'rum', 'wine' },
    effectDuration = 60000,  -- 60 seconds
    maxDrunkLevel = 5,       -- After 5 drinks, max effect
}


Config.Locale = {
    -- General
    ['no_permission'] = 'You do not have permission to do this.',
    ['not_employee'] = 'You are not employed at this saloon.',
    ['menu_opened'] = 'Welcome to the saloon!',
    
    -- Crafting
    ['crafting_start'] = 'Crafting %s...',
    ['crafting_success'] = 'Successfully crafted %sx %s!',
    ['crafting_failed'] = 'Crafting failed. Missing ingredients.',
    ['missing_ingredients'] = 'You are missing required ingredients.',
    
    -- Shop
    ['purchase_success'] = 'Purchased %sx %s for $%.2f',
    ['purchase_failed'] = 'Purchase failed. Not enough money.',
    ['out_of_stock'] = 'This item is out of stock.',
    
    -- Refill
    ['refill_success'] = 'Added %sx %s to the shop.',
    ['refill_failed'] = 'Failed to refill shop.',
    ['no_storage'] = 'No items in storage to refill.',
    
    -- Cashbox
    ['withdraw_success'] = 'Withdrew $%.2f from the cashbox.',
    ['withdraw_failed'] = 'Failed to withdraw. Not enough in cashbox.',
    ['cashbox_empty'] = 'The cashbox is empty.',
    
    -- Tips
    ['tip_received'] = 'You received a $%.2f tip!',
    ['tip_given'] = 'You tipped $%.2f.',
    
    -- Jukebox
    ['jukebox_playing'] = 'Now playing: %s',
    ['jukebox_stopped'] = 'Music stopped.',
    
    -- Prop Placer (V2.0)
    ['prop_placed'] = 'Item placed on table.',
    ['prop_consumed'] = 'Enjoy!',
    ['prop_removed'] = 'Item removed.',
    
    -- Billing (V2.0)
    ['bill_sent'] = 'Bill sent successfully.',
    ['bill_received'] = 'You received a bill!',
    ['bill_paid'] = 'Bill paid.',
}




Config.ServableDrinks = {
    -- Beers
    { model = 'p_bottlebeer01x', label = 'Pioneer Beer', alcohol = 0.1, type = 'small' },
    { model = 'p_bottlebeer01a', label = 'Sehiffer Beer', alcohol = 0.1, type = 'small' },
    { model = 'p_bottlebeer01a_1', label = 'McCarth Beer', alcohol = 0.1, type = 'small' },
    { model = 'p_bottlebeer01a_2', label = 'BlackBurnAle', alcohol = 0.1, type = 'small' },
    { model = 'p_bottlebeer01a_3', label = 'Baltz Brewer', alcohol = 0.1, type = 'small' },
    { model = 'p_bottlebeer02x', label = 'DraftHorse Beer', alcohol = 0.2, type = 'small' },
    { model = 'p_bottlebeer03x', label = 'New Hanover Beer', alcohol = 0.2, type = 'small' },
    { model = 'p_bottle008x', label = 'Lager', alcohol = 0.2, type = 'large' },
    { model = 'p_bottle008x_big', label = 'Giant Lager', alcohol = 0.3, type = 'large' },
    
    -- Whiskey & Spirits
    { model = 'p_bottle02x', label = 'Limping Williams Whiskey', alcohol = 0.6, type = 'large' },
    { model = 'p_bottle009x', label = 'Full Rye Whiskey', alcohol = 0.4, type = 'large' },
    { model = 'p_bottle006x', label = 'Prairie Moon Gin', alcohol = 0.5, type = 'large' },
    { model = 'p_bottle010x', label = 'Absinthe', alcohol = 1.0, type = 'large' },
    { model = 'p_bottle011x', label = 'House Special', alcohol = 0.5, type = 'large' },
    { model = 'p_bottleabsinthe01x', label = 'Old Farm Absinthe', alcohol = 1.5, type = 'large' },
    { model = 'p_bottletequila02x', label = 'Tequila', alcohol = 0.6, type = 'large' },
    { model = 'p_bottlebrandy01x', label = 'Antonette Brandy', alcohol = 0.5, type = 'large' },
    
    -- Wine & Champagne
    { model = 'p_bottlechampagne01x', label = 'RobesPierre Champagne', alcohol = 0.2, type = 'large' },
    { model = 'p_bottlecognac01x', label = 'Richesse Cognac', alcohol = 0.2, type = 'large' },
    { model = 'p_bottlesherry01x', label = 'Antoinette Sherry', alcohol = 0.3, type = 'large' },
    { model = 'p_bottlewine01x', label = 'Red Wine (1887)', alcohol = 0.3, type = 'large' },
    { model = 'p_bottlewine02x', label = 'Red Wine (1895)', alcohol = 0.3, type = 'large' },
    { model = 'p_bottlewine03x', label = 'White Wine Merlot', alcohol = 0.2, type = 'large' },
    { model = 'p_bottlewine04x', label = 'White Wine Cabernet', alcohol = 0.2, type = 'large' },
    { model = 'p_bottleredmist01x', label = 'Red Mist Gift', alcohol = 0.4, type = 'large' },
    
    -- Non-Alcoholic
    { model = 'p_mugCoffee01x', label = 'Coffee', alcohol = 0, type = 'other' },
    { model = 'p_bottle01x', label = 'Milk', alcohol = 0, type = 'other' },
}


Config.ServableFoods = {
    { model = 'p_bowl04x_stew', label = 'Meat Stew' },
    { model = 'p_bacon_cabbage01x', label = 'Bacon Salad' },
    { model = 'p_beefstew01x', label = 'Beef Stew' },
    { model = 'p_chillicurry01x', label = 'Chili Con Carne' },
    { model = 'p_fishstew01x', label = 'Fish Stew' },
    { model = 'p_lobster_bisque01x', label = 'Lobster Bisque' },
    { model = 'p_oatmeal01x', label = 'Oatmeal' },
    { model = 'p_wheat_milk01x', label = 'Wheat Cereal' },
    { model = 'p_oyster_plate', label = 'Oysters with Lemon' },
    { model = 'p_stewplate01x', label = 'Meat Hash' },
    { model = 'p_crab_plate_02', label = 'Crab Plate' },
}


Config.PlateMainDishes = {
    { model = 'p_main_breastmutton01x', label = 'Lamb Breast' },
    { model = 'p_main_cornedbeef01x', label = 'Corned Beef' },
    { model = 'p_main_friedcatfish02x', label = 'Fried Catfish' },
    { model = 'p_main_lamb_heart01x', label = 'Lamb Heart' },
    { model = 'p_main_lambfrytoast01x', label = 'Lamb Toast' },
    { model = 'p_main_lobstertail01x', label = 'Lobster Tail' },
    { model = 'p_main_prairiechicken01x', label = 'Prairie Chicken' },
    { model = 'p_main_primerib01x', label = 'Prime Rib' },
    { model = 'p_main_roastbeef01x', label = 'Roast Beef' },
}


Config.PlateSideDishes = {
    { model = 'P_SIDE_GREENPEASPOTATO01X', label = 'Potatoes & Peas' },
}


Config.PlateStyles = {
    { model = 'p_plate01x', label = 'White Plate' },
    { model = 'p_plate02x', label = 'Decorated White Plate' },
    { model = 'p_plate14x', label = 'Blue Decorated Plate' },
    { model = 'p_plate17x', label = 'Simple Plate' },
}


Config.PianoEnabled = true
Config.PianoTipInterval = 30 -- seconds between tip chances
Config.PianoTipChance = 75 -- % chance to receive tip
Config.PianoTipMin = 0.10
Config.PianoTipMax = 0.50

-- Piano locations at saloons
-- Coordinates from Don Dapper & DevDokus piano scripts
Config.PianoLocations = {
    { 
        coords = vector3(-312.36, 799.05, 118.48), 
        heading = 102.30, 
        saloonId = 'valsaloontender',
        name = 'Valentine Piano'
    },
    { 
        coords = vector3(2631.82, -1232.31, 53.70), 
        heading = 62.0, 
        saloonId = 'stdenissaloontender2',
        name = 'Saint Denis Piano'
    },
    { 
        coords = vector3(2799.58, -1163.93, 47.92), 
        heading = 237.40, 
        saloonId = 'stdenissaloontender1',
        name = 'Saint Denis #2 Piano'
    },
    { 
        coords = vector3(-814.98, -1313.04, 43.18), 
        heading = 358.0, 
        saloonId = 'blasaloontender',
        name = 'Blackwater Piano'
    },
    { 
        coords = vector3(1346.95, -1371.07, 79.99), 
        heading = 351.0, 
        saloonId = 'rhosaloontender',
        name = 'Rhodes Piano'
    },
    { 
        coords = vector3(-3706.38, -2589.00, -13.80), 
        heading = 360.0, 
        saloonId = 'armsaloontender',
        name = 'Armadillo Piano'
    },
    { 
        coords = vector3(-5516.0, -2914.53, -2.26), 
        heading = 121.4, 
        saloonId = 'tumsaloontender',
        name = 'Tumbleweed Piano'
    },
    { 
        coords = vector3(2944.12, 528.87, 44.85), 
        heading = 359.03, 
        saloonId = 'vansaloontender',
        name = 'Van Horn Piano'
    },
}


Config.PhonographEnabled = true
Config.PhonographVolume = 0.3 -- Default volume (0.0 - 1.0)
Config.PhonographDistance = 15 -- Audio range in meters

-- Optional: Pre-placed phonograph locations (leave empty to only allow player placement)
Config.PhonographLocations = {
    -- Example:
    -- { coords = vector3(-312.0, 799.0, 118.5), heading = 90.0 },
}
