



// Resource name for NUI callbacks
const RESOURCE_NAME = 'rsg-saloon';

let state = {
    saloonId: null,
    saloonName: '',
    isEmployee: false,
    playerGrade: 0,
    playerGradeLabel: '',
    permissions: {
        canCraft: false,
        canRefill: false,
        canCashbox: false,
        canManageEmployees: false,
    },
    shopStock: [],
    storage: [],
    cashboxBalance: 0,
    transactions: [],
    recipes: [],
    defaultPrices: {},
    playerInventory: {},
    imgPath: '',
    currentFilter: 'all',
    currentCraftFilter: 'all',
    selectedItem: null,
};



window.addEventListener('message', function (event) {
    const data = event.data;

    switch (data.action) {
        case 'openMenu':
            openMenu(data);
            break;
        case 'refreshData':
            refreshData(data);
            break;
        case 'closeMenu':
            closeMenu();
            break;
    }
});



document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});



function openMenu(data) {
    // Update state
    state.saloonId = data.saloonId;
    state.saloonName = data.saloonName;
    state.isEmployee = data.isEmployee;
    state.playerGrade = data.playerGrade;
    state.playerGradeLabel = data.playerGradeLabel || `Grade ${state.playerGrade}`;
    state.permissions = data.permissions;
    state.shopStock = data.shopStock || [];
    state.storage = data.storage || [];
    state.cashboxBalance = data.cashboxBalance || 0;
    state.transactions = data.transactions || [];
    state.recipes = data.recipes || [];
    state.defaultPrices = data.defaultPrices || {};
    state.playerInventory = data.playerInventory || {};
    state.imgPath = data.imgPath || '';

    // Update UI
    document.getElementById('saloonName').textContent = state.saloonName;

    // Update employee badge
    const badge = document.getElementById('employee-badge');
    if (state.isEmployee) {
        badge.classList.remove('hidden');
        badge.innerHTML = `<i class="fas fa-id-badge"></i> ${state.playerGradeLabel}`;
    } else {
        badge.classList.add('hidden');
    }

    // Update tab visibility based on permissions
    updateTabVisibility();

    // Render initial content
    renderShopItems();
    if (state.isEmployee) {
        renderCraftingRecipes();
        renderStorageItems();
        renderRefillItems();
        renderServeItems();
        if (state.permissions.canCashbox) {
            updateCashboxDisplay();
        }
    }

    // Show app
    document.getElementById('app').classList.remove('hidden');

    // Send ready callback
    fetch(`https://${RESOURCE_NAME}/ready`, {
        method: 'POST',
        body: JSON.stringify({})
    });
}

function refreshData(data) {
    state.shopStock = data.shopStock || state.shopStock;
    state.storage = data.storage || state.storage;
    state.cashboxBalance = data.cashboxBalance || state.cashboxBalance;
    state.transactions = data.transactions || state.transactions;
    state.playerInventory = data.playerInventory || state.playerInventory;

    // Re-render affected tabs
    renderShopItems();
    if (state.isEmployee) {
        renderCraftingRecipes();
        renderStorageItems();
        renderRefillItems();
        if (state.permissions.canCashbox) {
            updateCashboxDisplay();
        }
    }
}

function closeMenu() {
    document.getElementById('app').classList.add('hidden');

    fetch(`https://${RESOURCE_NAME}/closeUI`, {
        method: 'POST',
        body: JSON.stringify({})
    });
}



function updateTabVisibility() {
    // Employee-only tabs (common)
    document.querySelectorAll('.tab.employee-only').forEach(tab => {
        // Staff tab is special case
        if (tab.getAttribute('data-tab') === 'employees') return;

        if (state.isEmployee) {
            tab.classList.remove('hidden');
        } else {
            tab.classList.add('hidden');
        }
    });

    // Manager-only tabs
    document.querySelectorAll('.tab.manager-only').forEach(tab => {
        if (state.permissions.canCashbox) {
            tab.classList.remove('hidden');
        } else {
            tab.classList.add('hidden');
        }
    });

    // Staff tab - specific permission check
    const staffTab = document.querySelector('[data-tab="employees"]');
    if (staffTab) {
        if (state.permissions.canManageEmployees) {
            staffTab.classList.remove('hidden');
        } else {
            staffTab.classList.add('hidden');
        }
    }
}

function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

    // Update tab panels
    document.querySelectorAll('.tab-panel').forEach(panel => {
        panel.classList.remove('active');
    });
    document.getElementById(`${tabName}-tab`).classList.add('active');

    // Trigger data fetch for specific tabs
    if (tabName === 'employees') {
        getEmployees();
    } else if (tabName === 'cashbox') {
        updateCashboxDisplay();
    } else if (tabName === 'managers_logs') {
        getManagerLogs();
    }
}



function renderShopItems() {
    const container = document.getElementById('shop-items');

    let items = state.shopStock.filter(item => item.quantity > 0);

    // Apply filter
    if (state.currentFilter !== 'all') {
        const recipe = state.recipes.find(r => r.item === items[0]?.item);
        items = items.filter(item => {
            const r = state.recipes.find(rec => rec.item === item.item);
            return r && r.category === state.currentFilter;
        });
    }

    if (items.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-store-slash"></i>
                <p>No items available</p>
            </div>
        `;
        return;
    }

    container.innerHTML = items.map((item, index) => {
        const recipe = state.recipes.find(r => r.item === item.item);
        const category = recipe ? recipe.category : 'other';

        return `
            <div class="item-card stagger-item hover-lift" onclick="openPurchaseModal('${item.item}')">
                <img class="item-image" src="${state.imgPath}${item.image || item.item + '.png'}" alt="${item.label}" onerror="this.src='${state.imgPath}placeholder.png'">
                <div class="item-info">
                    <div class="item-category">${category}</div>
                    <div class="item-name">${item.label}</div>
                    <div class="item-price">$${parseFloat(item.price).toFixed(2)}</div>
                    <div class="item-stock">Stock: ${item.quantity}</div>
                </div>
            </div>
        `;
    }).join('');
}

function filterShop(filter) {
    state.currentFilter = filter;

    document.querySelectorAll('#shop-tab .filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');

    renderShopItems();
}



function renderCraftingRecipes() {
    const container = document.getElementById('crafting-recipes');

    let recipes = state.recipes;

    // Apply filter
    if (state.currentCraftFilter !== 'all') {
        recipes = recipes.filter(r => r.category === state.currentCraftFilter);
    }

    if (recipes.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-hammer"></i>
                <p>No recipes available</p>
            </div>
        `;
        return;
    }

    container.innerHTML = recipes.map((recipe, index) => {
        // Check if player has ingredients
        let canCraft = true;
        const reqHtml = recipe.requirements.map(req => {
            const has = state.playerInventory[req.item] || 0;
            const hasEnough = has >= req.amount;
            if (!hasEnough) canCraft = false;
            return `
                <div class="requirement ${hasEnough ? 'has' : 'missing'}">
                    <span>${req.item}</span>
                    <span>${has}/${req.amount}</span>
                </div>
            `;
        }).join('');

        return `
            <div class="item-card stagger-item ${canCraft ? 'can-craft hover-lift' : 'cannot-craft'}" onclick="${canCraft ? `startCrafting('${recipe.item}')` : ''}">
                <img class="item-image" src="${state.imgPath}${recipe.image}" alt="${recipe.label}" onerror="this.src='${state.imgPath}placeholder.png'">
                <div class="item-info">
                    <div class="item-category">${recipe.category}</div>
                    <div class="item-name">${recipe.label}</div>
                    <div class="item-yield">Yield: ${recipe.yield}x</div>
                    <div class="item-stock">${recipe.time / 1000}s craft time</div>
                </div>
                <div class="recipe-requirements">
                    ${reqHtml}
                </div>
            </div>
        `;
    }).join('');
}

function filterCrafting(filter) {
    state.currentCraftFilter = filter;

    document.querySelectorAll('#crafting-tab .filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');

    renderCraftingRecipes();
}

function startCrafting(itemName) {
    closeMenu();

    fetch(`https://${RESOURCE_NAME}/startCraft`, {
        method: 'POST',
        body: JSON.stringify({
            item: itemName,
            saloonId: state.saloonId
        })
    });
}



// Prop models for craftable items
const PROP_MODELS = {
    // Drinks
    beer: { model: 'p_bottlebeer01x', icon: 'fas fa-beer-mug-empty' },
    whiskey: { model: 'p_bottle02x', icon: 'fas fa-whiskey-glass' },
    vodka: { model: 'p_bottle02x', icon: 'fas fa-glass-whiskey' },
    tequila: { model: 'p_bottletequila02x', icon: 'fas fa-bottle-droplet' },
    rum: { model: 'p_bottle011x', icon: 'fas fa-bottle-water' },
    wine: { model: 'p_bottlewine01x', icon: 'fas fa-wine-glass' },
    coffee: { model: 'p_mug01_coffee', icon: 'fas fa-mug-hot' },
    lemonade: { model: 'p_bottlebeer01x', icon: 'fas fa-glass-water-droplet' },
    // Food
    stew: { model: 'p_bowl04x_stew', icon: 'fas fa-bowl-food' },
    steak: { model: 'p_main_primerib01x', icon: 'fas fa-drumstick-bite' },
    bread: { model: 'p_bread_14_ab_s_a', icon: 'fas fa-bread-slice' },
    soup: { model: 'p_bowl04x_stew', icon: 'fas fa-bowl-food' },
    pie: { model: 'p_plate01x', icon: 'fas fa-pie-chart' },
};

function renderServeItems() {
    const drinksContainer = document.getElementById('serve-drinks');
    const foodContainer = document.getElementById('serve-food');

    if (!drinksContainer || !foodContainer) return;

    // Filter drinks and food from recipes
    const drinks = state.recipes.filter(r => r.category === 'drinks');
    const food = state.recipes.filter(r => r.category === 'food');

    // Render drinks (pass item name for storage validation)
    drinksContainer.innerHTML = drinks.map(recipe => {
        const propData = PROP_MODELS[recipe.item] || { model: 'p_bottlebeer01x', icon: 'fas fa-glass' };

        // Find quantity in storage
        const storageItem = state.storage.find(s => s.item === recipe.item);
        const quantity = storageItem ? storageItem.quantity : 0;
        const disabled = quantity <= 0 ? 'disabled' : '';
        const onclick = quantity > 0 ? `onclick="serveDrink('${propData.model}', '${recipe.label}', '${recipe.item}')"` : '';

        return `
            <div class="serve-item hover-lift ${disabled}" ${onclick}>
                <i class="${propData.icon}"></i>
                <span>${recipe.label}</span>
                <span class="stock-badge ${quantity > 0 ? 'in-stock' : 'out-stock'}">Stock: ${quantity}</span>
            </div>
        `;
    }).join('');

    // Render food (pass item name for storage validation)
    foodContainer.innerHTML = food.map(recipe => {
        const propData = PROP_MODELS[recipe.item] || { model: 'p_plate01x', icon: 'fas fa-utensils' };

        // Find quantity in storage
        const storageItem = state.storage.find(s => s.item === recipe.item);
        const quantity = storageItem ? storageItem.quantity : 0;
        const disabled = quantity <= 0 ? 'disabled' : '';
        const onclick = quantity > 0 ? `onclick="serveFood('${propData.model}', '${recipe.label}', '${recipe.item}')"` : '';

        return `
            <div class="serve-item hover-lift ${disabled}" ${onclick}>
                <i class="${propData.icon}"></i>
                <span>${recipe.label}</span>
                <span class="stock-badge ${quantity > 0 ? 'in-stock' : 'out-stock'}">Stock: ${quantity}</span>
            </div>
        `;
    }).join('');
}

function serveDrink(model, label, itemName) {
    closeMenu();

    fetch(`https://${RESOURCE_NAME}/serveDrink`, {
        method: 'POST',
        body: JSON.stringify({
            model: model,
            label: label,
            itemName: itemName,  // For storage validation
            alcoholLevel: 25
        })
    });
}

function serveFood(model, label, itemName) {
    closeMenu();

    fetch(`https://${RESOURCE_NAME}/serveFood`, {
        method: 'POST',
        body: JSON.stringify({
            model: model,
            label: label,
            itemName: itemName  // For storage validation
        })
    });
}



function renderStorageItems() {
    const container = document.getElementById('storage-items');

    const items = state.storage.filter(item => item.quantity > 0);

    if (items.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-box-open"></i>
                <p>Storage is empty. Craft some items!</p>
            </div>
        `;
        return;
    }

    container.innerHTML = items.map(item => `
        <div class="item-card stagger-item hover-lift" onclick="openWithdrawModal('${item.item}', '${item.label}', ${item.quantity})">
            <img class="item-image" src="${state.imgPath}${item.image || item.item + '.png'}" alt="${item.label}" onerror="this.src='${state.imgPath}placeholder.png'">
            <div class="item-info">
                <div class="item-name">${item.label}</div>
                <div class="item-stock">Quantity: ${item.quantity}</div>
                <div class="item-sub">Click to Withdraw</div>
            </div>
        </div>
    `).join('');
}

function openWithdrawModal(itemName, label, quantity) {
    state.selectedItem = { item: itemName, label: label, quantity: quantity };

    document.getElementById('withdraw-item-image').src = state.imgPath + (itemName + '.png');
    document.getElementById('withdraw-item-name').textContent = label;
    document.getElementById('withdraw-item-storage').textContent = `In Storage: ${quantity}`;
    document.getElementById('withdraw-quantity').value = 1;
    document.getElementById('withdraw-quantity').max = quantity;

    document.getElementById('withdraw-modal').classList.remove('hidden');
}

function confirmWithdraw() {
    if (!state.selectedItem) return;
    if (state.isProcessing) return; // Prevent double-click

    state.isProcessing = true;

    const quantity = parseInt(document.getElementById('withdraw-quantity').value) || 1;

    fetch(`https://${RESOURCE_NAME}/withdrawStorage`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            item: state.selectedItem.item,
            quantity: quantity
        })
    }).finally(() => {
        state.isProcessing = false;
    });

    closeModal('withdraw-modal');
}



function renderRefillItems() {
    const container = document.getElementById('refill-items');

    const items = state.storage.filter(item => item.quantity > 0);

    if (items.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-boxes-packing"></i>
                <p>No items to refill. Craft some items first!</p>
            </div>
        `;
        return;
    }

    container.innerHTML = items.map(item => `
        <div class="item-card stagger-item hover-lift" onclick="openRefillModal('${item.item}', '${item.label}', ${item.quantity}, ${item.defaultPrice || 1})">
            <img class="item-image" src="${state.imgPath}${item.image || item.item + '.png'}" alt="${item.label}" onerror="this.src='${state.imgPath}placeholder.png'">
            <div class="item-info">
                <div class="item-name">${item.label}</div>
                <div class="item-stock">In Storage: ${item.quantity}</div>
                <div class="item-price">Default: $${(item.defaultPrice || 1).toFixed(2)}</div>
            </div>
        </div>
    `).join('');
}



function updateCashboxDisplay() {
    document.getElementById('cashbox-balance').textContent = `$${parseFloat(state.cashboxBalance).toFixed(2)}`;

    // Daily stats (would need to be sent from server)
    // For now, calculate from transactions
    let sales = 0, tips = 0, count = 0;
    state.transactions.forEach(t => {
        if (t.type === 'sale') {
            sales += parseFloat(t.amount);
            count++;
        } else if (t.type === 'tip') {
            tips += parseFloat(t.amount);
        }
    });

    document.getElementById('stat-sales').textContent = `$${sales.toFixed(2)}`;
    document.getElementById('stat-tips').textContent = `$${tips.toFixed(2)}`;
    document.getElementById('stat-count').textContent = count;

    // Render transactions
    const container = document.getElementById('transactions-list');
    if (state.transactions.length === 0) {
        container.innerHTML = '<p class="empty-state">No transactions yet</p>';
        return;
    }

    container.innerHTML = state.transactions.slice(0, 20).map(t => {
        const time = new Date(t.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        return `
            <div class="transaction-item">
                <span class="type ${t.type}">${t.type}</span>
                <span class="amount">$${parseFloat(t.amount).toFixed(2)}</span>
                <span class="time">${time}</span>
            </div>
        `;
    }).join('');
}

function withdrawCashbox() {
    const amount = parseFloat(document.getElementById('withdraw-amount').value);

    if (!amount || amount <= 0) {
        return;
    }

    fetch(`https://${RESOURCE_NAME}/withdrawCashbox`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            amount: amount
        })
    }).then(() => {
        document.getElementById('withdraw-amount').value = '';
    });
}

function depositCashbox() {
    const amount = parseFloat(document.getElementById('deposit-amount').value);

    if (!amount || amount <= 0) {
        return;
    }

    fetch(`https://${RESOURCE_NAME}/depositCashbox`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            amount: amount
        })
    }).then(() => {
        document.getElementById('deposit-amount').value = '';
    });
}



function openPurchaseModal(itemName) {
    const item = state.shopStock.find(i => i.item === itemName);
    if (!item) return;

    state.selectedItem = item;

    document.getElementById('purchase-item-image').src = state.imgPath + (item.image || item.item + '.png');
    document.getElementById('purchase-item-name').textContent = item.label;
    document.getElementById('purchase-item-price').textContent = `$${parseFloat(item.price).toFixed(2)} each`;
    document.getElementById('purchase-item-stock').textContent = `Stock: ${item.quantity}`;
    document.getElementById('purchase-quantity').value = 1;
    document.getElementById('purchase-quantity').max = item.quantity;
    document.getElementById('purchase-tip').value = 0;

    updatePurchaseTotal();

    document.getElementById('purchase-modal').classList.remove('hidden');
}

function updatePurchaseTotal() {
    if (!state.selectedItem) return;

    const quantity = parseInt(document.getElementById('purchase-quantity').value) || 1;
    const tip = parseFloat(document.getElementById('purchase-tip').value) || 0;
    const total = (state.selectedItem.price * quantity) + tip;

    document.getElementById('purchase-total').textContent = `$${total.toFixed(2)}`;
}

function confirmPurchase() {
    if (!state.selectedItem) return;

    const quantity = parseInt(document.getElementById('purchase-quantity').value) || 1;
    const tip = parseFloat(document.getElementById('purchase-tip').value) || 0;

    fetch(`https://${RESOURCE_NAME}/purchaseItem`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            item: state.selectedItem.item,
            quantity: quantity,
            tip: tip
        })
    });

    closeModal('purchase-modal');
}

function openRefillModal(itemName, label, storageQty, defaultPrice) {
    state.selectedItem = { item: itemName, label: label, quantity: storageQty };

    document.getElementById('refill-item-image').src = state.imgPath + itemName + '.png';
    document.getElementById('refill-item-name').textContent = label;
    document.getElementById('refill-item-storage').textContent = `In Storage: ${storageQty}`;
    document.getElementById('refill-quantity').value = 1;
    document.getElementById('refill-quantity').max = storageQty;
    document.getElementById('refill-price').value = defaultPrice.toFixed(2);

    document.getElementById('refill-modal').classList.remove('hidden');
}





function renderEmployees() {
    // This would typically fetch from server, but for now we'll assume state.employees is populated
    // or we fetch it when tab is opened

    // Trigger fetch if empty (logic would be in switchTab)
}

function updateEmployeesList(employees) {
    const container = document.getElementById('employees-list');
    const badge = document.getElementById('employee-count');

    badge.textContent = `${employees.length} / 4 Staff`;

    if (employees.length === 0) {
        container.innerHTML = '<div class="empty-state"><p>No employees hired yet.</p></div>';
        return;
    }

    container.innerHTML = employees.map(emp => {
        const isSelf = false; // Logic to check if this is the current player
        const canManage = state.playerGrade > emp.grade && state.playerGrade >= 2;
        const canPromote = state.playerGrade === 3 && emp.grade < 2; // Only Boss can promote
        const canFire = state.playerGrade === 3; // Only Boss can fire

        let actions = '';
        if (canManage && !isSelf) {
            if (canPromote) {
                actions += `
                    <button class="btn-icon" title="Promote" onclick="promoteEmployee('${emp.citizenid}')">
                        <i class="fas fa-arrow-up"></i>
                    </button>
                `;
            }
            if (canFire) {
                actions += `
                    <button class="btn-icon btn-danger" title="Fire" onclick="fireEmployee('${emp.citizenid}')">
                        <i class="fas fa-trash"></i>
                    </button>
                `;
            }
        }

        return `
            <div class="employee-row">
                <div class="emp-name">
                    <div class="name">${emp.firstname} ${emp.lastname}</div>
                    <div class="citizenid">${emp.citizenid}</div>
                </div>
                <div class="emp-rank">
                    <span class="rank-badge grade-${emp.grade}">${emp.gradeLabel}</span>
                </div>
                <div class="emp-stats text-right">
                    <div><i class="fas fa-hammer"></i> ${emp.itemsCrafted}</div>
                    <div><i class="fas fa-dollar-sign"></i> ${emp.salesTotal.toFixed(2)}</div>
                </div>
                <div class="emp-actions text-right">
                    ${actions}
                </div>
            </div>
        `;
    }).join('');
}

function getEmployees() {
    fetch(`https://${RESOURCE_NAME}/getEmployees`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId
        })
    }).then(resp => resp.json()).then(data => {
        updateEmployeesList(data);
    });
}

function fireEmployee(citizenid) {
    fetch(`https://${RESOURCE_NAME}/firePlayer`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            targetId: citizenid
        })
    }).then(() => {
        getEmployees(); // Refresh list
    });
}

function promoteEmployee(citizenid) {
    // Logic for promotion would go here
    fetch(`https://${RESOURCE_NAME}/promotePlayer`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            targetId: citizenid
        })
    }).then(() => {
        getEmployees(); // Refresh list
    });
}

function openHireModal() {
    const list = document.getElementById('hire-player-list');
    list.innerHTML = '<div class="loader"><i class="fas fa-spinner fa-spin"></i> Searching...</div>';
    document.getElementById('hire-modal').classList.remove('hidden');

    fetch(`https://${RESOURCE_NAME}/getNearbyPlayers`, {
        method: 'POST',
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(players => {
        if (!players || players.length === 0) {
            list.innerHTML = '<div class="empty-state">No players nearby</div>';
            return;
        }

        list.innerHTML = players.map(p => `
            <div class="player-item" style="display: flex; justify-content: space-between; align-items: center; padding: 10px; border-bottom: 1px solid rgba(255,255,255,0.1);">
                <div class="player-info">
                    <span class="player-name" style="font-weight: bold;">${p.name}</span>
                    <span class="player-id" style="opacity: 0.7; font-size: 0.9em;">(ID: ${p.id})</span>
                </div>
                <button class="btn btn-primary btn-sm" onclick="hirePlayerFromModal(${p.id})">
                    Hire
                </button>
            </div>
        `).join('');
    });
}

function hirePlayerFromModal(targetId) {
    fetch(`https://${RESOURCE_NAME}/hirePlayer`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            targetId: targetId
        })
    });
    closeModal('hire-modal');
    // Refresh employee list after a delay
    setTimeout(getEmployees, 1000);
}



function confirmRefill() {
    if (!state.selectedItem) return;

    const quantity = parseInt(document.getElementById('refill-quantity').value) || 1;
    const price = parseFloat(document.getElementById('refill-price').value) || 1;

    fetch(`https://${RESOURCE_NAME}/refillShop`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId,
            item: state.selectedItem.item,
            quantity: quantity,
            price: price
        })
    });

    closeModal('refill-modal');
}

// ============================================================================
// LOGS
// ============================================================================

function getManagerLogs() {
    fetch(`https://${RESOURCE_NAME}/getLogs`, {
        method: 'POST',
        body: JSON.stringify({
            saloonId: state.saloonId
        })
    }).then(resp => resp.json()).then(logs => {
        renderLogs(logs);
    });
}

function renderLogs(logs) {
    const container = document.getElementById('logs-list');

    if (!logs || logs.length === 0) {
        container.innerHTML = '<div class="empty-state">No logs available</div>';
        return;
    }

    container.innerHTML = logs.map(log => {
        const time = new Date(log.timestamp).toLocaleString();
        return `
            <div class="log-item">
                <div class="log-time">${time}</div>
                <div class="log-type action-type-${log.type}">${log.type}</div>
                <div class="log-message">${log.message}</div>
                <div class="log-staff">${log.player_name || 'Unknown'}</div>
            </div>
        `;
    }).join('');
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.add('hidden');
    state.selectedItem = null;
}



// Resource name is defined at the top of the file as RESOURCE_NAME
