# RSG Saloon Premium v2.1

Premium saloon management for RedM/RSGCore. Features crafting, table service, drunk effects, billing, employee management, and activity logging.


---

## ✨ Features

### Core Systems
| Feature | Description |
|---------|-------------|
| **Shop & Sales** | Customer shop with categories, stock tracking, tipping |
| **Crafting** | 15+ recipes, yield bonuses, progress bar with animations |
| **Storage** | Private storage, withdraw to inventory, refill shop |
| **Cashbox** | Balance tracking, deposits/withdrawals, transaction history |
| **Table Service** | Place drinks/food on tables with prop system |

### Management (v2.0+)
| Feature | Description |
|---------|-------------|
| **Employee System** | Hire/fire (max 4), grade-based permissions |
| **Billing** | Create/send bills, payment to cashbox |
| **Activity Logs** | Track withdrawals, crafting, storage actions (v2.1) |
| **Piano** | Play at 8 locations with animations |
| **Phonograph** | Place music props (requires xsound) |

---

## 📋 Permission Grades

| Grade | Role | Permissions |
|-------|------|-------------|
| 0 | Helper | Crafting |
| 1 | Bartender | + Refill, table service |
| 2 | Manager | + Cashbox, billing, logs, hire |
| 3 | Boss | + Fire, promote employees |

---

## 📦 Dependencies

- `rsg-core` - RSGCore framework
- `ox_lib` - UI library
- `oxmysql` - Database
- `ox_target` - Third-eye targeting
- `rsg-inventory` - Inventory system

---

## 🚀 Installation
## 📋 make sure to rename the file as rsg-saloon
### 1. Database
```sql
source installation/saloon_premium.sql;
```

### 2. server.cfg
```cfg
ensure rsg-core
ensure ox_lib
ensure oxmysql
ensure ox_target
ensure rsg-saloon
```

### 3. Jobs
Copy `installation/jobs.lua` contents to `rsg-core/shared/jobs.lua`

### 4. Items
Copy `installation/items.lua` contents to `rsg-core/shared/items.lua`

### 5. Images
Copy item PNGs to:
- `rsg-inventory/html/images/`
- `rsg-saloon/html/images/`

---

## ⚙️ Configuration

### Key Settings (config.lua)

| Setting | Default |
|---------|---------|
| `Config.Debug` | `false` |
| `Config.Keybind` | `'J'` |
| `Config.TipsEnabled` | `true` |
| `Config.DrunkEffects.enabled` | `true` |

### Adding Saloons

```lua
['yoursaloonid'] = {
    name = 'Your Saloon',
    coords = vector3(x, y, z),
    showBlip = true,
    grades = {
        crafting = 0,
        refill = 1,
        cashbox = 2,
        employees = 2,
    },
    points = {
        bar = vector3(x, y, z),
        storage = vector3(x, y, z),
    }
},
```

---

## 🎮 Usage

### Employees
1. **Access**: Third-eye on bar counter
2. **Craft**: Select recipe → items go to storage
3. **Refill**: Move storage items to shop
4. **Serve**: Place props on tables
5. **Cashbox**: Deposit/withdraw earnings
6. **Logs**: View activity history (Grade 2+)

### Customers
1. **Shop**: Browse and purchase items
2. **Pickup**: Interact with placed table items

---

## 🗂️ File Structure

```
rsg-saloon/
├── client/
│   ├── main.lua, crafting.lua, shop.lua
│   ├── propplacer.lua, consumption.lua, drunk.lua
│   ├── billing.lua, animations.lua, piano.lua, phonograph.lua
├── server/
│   ├── main.lua, crafting.lua, shop.lua, storage.lua
│   ├── cashbox.lua, employees.lua, logs.lua
│   ├── placedprops.lua, billing.lua, piano.lua, phonograph.lua
├── html/
│   ├── index.html, css/, js/app.js, images/, sounds/
├── installation/
│   ├── saloon_premium.sql, jobs.lua, items.lua
├── config.lua, fxmanifest.lua
```

---

## 📝 Changelog

### v2.2.0
- 🔧 Fixed Staff UI: Hiring, Firing, and Promoting logic repaired.
- 🔧 Fixed Serving: Drinks/Food no longer disappear without effect.
- 🔧 Fixed Permissions: Helpers can now Refill storage (Configurable).
- 🔧 Database: Improved data sync for employee list visibility.
- 💅 UI: Improved visibility of staff list rows.

### v2.1.0
- ✨ Activity logs for managers/bosses
- ✨ Storage withdrawal to player inventory
- ✨ Grade label badges (Boss/Manager)
- 🔧 Fixed undefined storage labels
- 🔧 Fixed cashbox deposit/withdraw callbacks
- 🧹 Code cleanup

### v2.0.0
- Table service with prop placer
- Drunk effects system
- Billing/invoicing
- Employee hire/fire
- Piano system (8 locations)
- Phonograph music props

### v1.0.0
- Initial release

---

## 📄 License

MIT License

---

## 🔧 Troubleshooting

### Staff List Not Showing / Invisible Employees
- Ensure you have executed the `installation/saloon_premium.sql` file to create the `saloon_premium_employees` table.
- If an employee is hired but doesn't appear immediately, the scripts now force a database save, but a resource restart can also clear up desync issues.
- Check server console for `[Saloon]` debug prints if `Config.Debug = true`.

---

**Author:** devchacha | **Framework:** RSGCore for RedM
