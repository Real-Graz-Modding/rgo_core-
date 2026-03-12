# rgo_qb – QBCore Compatibility Layer for rgo_core

`rgo_qb` is a **standalone FiveM resource** that provides a QBCore-compatible
API surface on top of `rgo_core`.  It allows existing QB scripts to run with
**little or no modification** while the underlying framework is `rgo_core`
rather than `qb-core`.

---

## Requirements

| Dependency | Minimum version |
|---|---|
| [oxmysql](https://github.com/overextended/oxmysql) | latest |
| FiveM server artifact | 12913+ |

> **Note:** `qb-core` is **not** required when using `rgo_qb`.

---

## Installation

1. Copy (or clone) the `rgo_qb` folder into your server's `resources` directory.
2. Add the following lines to your `server.cfg` **before** any resource that
   depends on QBCore:

   ```cfg
   ensure oxmysql
   ensure rgo_qb
   ```

3. Existing resources that call `exports['qb-core']:GetCoreObject()` need a
   one-line change:

   ```lua
   -- Before
   QBCore = exports['qb-core']:GetCoreObject()

   -- After
   QBCore = exports['rgo_qb']:GetCoreObject()
   ```

   Resources that use the legacy event pattern work **unchanged**:

   ```lua
   TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
   ```

---

## Usage

### Server-side

```lua
local QBCore = exports['rgo_qb']:GetCoreObject()

-- Get a player object
local Player = QBCore.Functions.GetPlayer(source)
if Player then
    print(Player.PlayerData.citizenid)      -- STRT000001
    print(Player.PlayerData.license)        -- license2:...
    print(Player.Functions.GetMoney('cash'))

    Player.Functions.AddMoney('bank', 1000)
    Player.Functions.SetJob('police', 2)
    Player.Functions.Notify('Welcome!', 'success', 3000)
end

-- List all connected player sources
local sources = QBCore.Functions.GetPlayers()   -- { 1, 3, 7, ... }

-- Register a server callback
QBCore.Functions.CreateCallback('myResource:getData', function(source, resolve, reject, arg)
    resolve({ value = arg .. '_ok' })
end)

-- Trigger a callback to a specific client from the server
QBCore.Functions.TriggerCallback('myResource:clientPing', source, function(result)
    print(result.pong)
end, 'hello')
```

### Client-side

```lua
local QBCore = exports['rgo_qb']:GetCoreObject()

-- Trigger a server callback
QBCore.Functions.TriggerCallback('myResource:getData', function(result)
    print(result.value)
end, 'hello')

-- Register a client callback (called by TriggerCallback on the server)
QBCore.Functions.RegisterCallback('myResource:clientPing', function(resolve, payload)
    resolve({ pong = true, echo = payload })
end)

-- Read current player data
local pd = QBCore.PlayerData
print(pd.citizenid, pd.job.name, pd.money.cash)
```

---

## What is already compatible (MVP)

| Feature | Status |
|---|---|
| `exports['rgo_qb']:GetCoreObject()` | ✅ |
| `TriggerEvent('QBCore:GetObject', cb)` | ✅ |
| `QBCore.Functions.GetPlayer(source)` | ✅ |
| `QBCore.Functions.GetPlayers()` | ✅ |
| `QBCore.Functions.GetPlayerByCitizenId(cid)` | ✅ |
| `QBCore.Functions.GetPlayerByPhone(phone)` | ✅ |
| `QBCore.Functions.CreateCallback` | ✅ |
| `QBCore.Functions.TriggerCallback` (server→client) | ✅ |
| `QBCore.Functions.TriggerCallback` (client→server) | ✅ |
| `QBCore.Functions.RegisterCallback` (client) | ✅ |
| `QBCore.Functions.Notify(source, text, type, length)` | ✅ |
| `QBCore.Functions.HasPermission / AddPermission / RemovePermission` | ✅ stub |
| `QBCore.Functions.GetIdentifier` | ✅ |
| `Player.PlayerData` (citizenid, license, name, money, job, gang, metadata, charinfo) | ✅ |
| `Player.Functions.GetMoney / AddMoney / RemoveMoney / SetMoney` | ✅ |
| `Player.Functions.GetJob / SetJob` | ✅ |
| `Player.Functions.GetGang / SetGang` | ✅ |
| `Player.Functions.AddItem / RemoveItem / HasItem / GetItemByName` | ✅ (in-memory) |
| `Player.Functions.GetMetaData / SetMetaData` | ✅ |
| `Player.Functions.Notify / Kick / Save` | ✅ |
| `QBCore:Server:OnPlayerLoaded` event | ✅ |
| `QBCore:Server:PlayerUnload` event | ✅ |
| `QBCore:Server:SetJob` event | ✅ |
| `QBCore:Client:OnPlayerLoaded` event | ✅ |
| `QBCore:Client:PlayerUnload` event | ✅ |
| `QBCore:Client:SetJob` event | ✅ |
| `QBCore:Player:SetPlayerData` event | ✅ |
| `QBCore:Notify` event | ✅ |
| `QBCore.Config` stub | ✅ |
| `QBCore.Shared` stub (Jobs/Gangs/Items/Vehicles) | ✅ |
| oxmysql adapter (`DB.query/single/execute/scalar`) | ✅ skeleton |

---

## What is still missing (roadmap)

| Feature | Priority |
|---|---|
| Full DB persistence (load/save PlayerData from SQL) | High |
| Jobs/Gangs/Items from database into `QBCore.Shared` | High |
| `citizenid` generated/loaded from DB | High |
| `Player.Functions.Save()` persists to DB | High |
| `charinfo` loaded from DB | High |
| `QBCore.Functions.CreateUseableItem` | Medium |
| `QBCore.Functions.UseItem` | Medium |
| `QBCore.Functions.AddItem` (global, not player) | Medium |
| `QBCore.Functions.CanAddItem` | Medium |
| `QBCore.Commands` system | Medium |
| `Player.Functions.GetVehicles` | Low |
| ox_inventory bridge for inventory operations | Low |
| `QBCore.Config.Whitelist` / ACE-based permissions | Low |

Contributions welcome – see [`CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## Architecture

```
rgo_qb/
├── fxmanifest.lua          FiveM resource manifest
├── server/
│   ├── db.lua              oxmysql adapter (thin wrappers)
│   └── main.lua            QBCore shared object, callbacks, player lifecycle
└── client/
    └── main.lua            Client-side QBCore object, callback routing
```

The resource is **self-contained Lua** – no TypeScript/build step required.

---

## Security notes

- All `RegisterNetEvent` handlers validate `source` implicitly through FiveM's
  net-event routing.
- Money and inventory mutations are server-side only; clients cannot directly
  mutate values.
- In production, add explicit permission checks inside `CreateCallback` handlers
  for sensitive operations.
