# rgo_esx – ESX Compatibility Layer for rgo_core

`rgo_esx` is a **standalone FiveM resource** that provides an ESX 9.0.2.0-compatible
API surface on top of `rgo_core`.  It allows existing ESX scripts to run with
**little or no modification** while the underlying framework transitions away
from `es_extended`.

---

## Requirements

| Dependency | Minimum version |
|---|---|
| [oxmysql](https://github.com/overextended/oxmysql) | latest |
| FiveM server artefact | 12913+ |

> **Note:** `es_extended` is **not** required when using `rgo_esx`.

---

## Installation

1. Copy (or clone) the `rgo_esx` folder into your server's `resources` directory.
2. Add the following line to your `server.cfg` **before** any resource that
   depends on ESX:

   ```cfg
   ensure oxmysql
   ensure rgo_esx
   ```

3. Existing resources that call `exports['es_extended']:getSharedObject()` need
   a one-line change:

   ```lua
   -- Before
   ESX = exports['es_extended']:getSharedObject()

   -- After
   ESX = exports['rgo_esx']:getSharedObject()
   ```

   Resources that use the legacy event pattern work **unchanged**:

   ```lua
   TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
   ```

---

## Usage

### Server-side

```lua
-- Obtain the ESX object
local ESX = exports['rgo_esx']:getSharedObject()

-- Register a server callback
ESX.RegisterServerCallback('myResource:getData', function(source, resolve, reject, arg1)
    resolve({ value = arg1 .. '_processed' })
end)

-- Get a player wrapper
local xPlayer = ESX.GetPlayerFromId(source)
if xPlayer then
    print(xPlayer.identifier)          -- license2:...
    print(xPlayer.getMoney())          -- cash balance
    xPlayer.addMoney(500)
    xPlayer.setJob('police', 2)
end

-- List all connected player sources
local sources = ESX.GetPlayers()   -- { 1, 3, 7, ... }
```

### Client-side

```lua
-- Obtain the ESX object
local ESX = exports['rgo_esx']:getSharedObject()

-- Trigger a server callback
ESX.TriggerServerCallback('myResource:getData', function(result)
    print(result.value)
end, 'hello')

-- Register a client callback (called by TriggerClientCallback on the server)
ESX.RegisterClientCallback('myResource:clientPing', function(resolve, payload)
    resolve({ pong = true, echo = payload })
end)
```

---

## What is already compatible (MVP)

| Feature | Status |
|---|---|
| `exports['rgo_esx']:getSharedObject()` | ✅ |
| `TriggerEvent('esx:getSharedObject', cb)` | ✅ |
| `ESX.RegisterServerCallback` | ✅ |
| `ESX.TriggerServerCallback` (client) | ✅ |
| `ESX.TriggerClientCallback` (server→client) | ✅ |
| `ESX.RegisterClientCallback` (client) | ✅ |
| `ESX.GetPlayerFromId` | ✅ |
| `ESX.GetPlayers` | ✅ |
| `ESX.GetPlayerFromIdentifier` | ✅ |
| `xPlayer.identifier` / `.source` / `.name` | ✅ |
| `xPlayer.getMoney/addMoney/removeMoney/setMoney` | ✅ |
| `xPlayer.getAccount/addAccountMoney/removeAccountMoney/setAccountMoney` | ✅ |
| `xPlayer.getInventoryItem/addInventoryItem/removeInventoryItem/canCarryItem` | ✅ (in-memory stub) |
| `xPlayer.getJob/setJob` | ✅ |
| `xPlayer.showNotification` | ✅ |
| `xPlayer.kick` | ✅ |
| `xPlayer.getGroup` stub | ✅ |
| `esx:playerLoaded` event (server + client) | ✅ |
| `esx:playerDropped` event | ✅ |
| `esx:setJob` event | ✅ |
| `esx:showNotification` event | ✅ |
| oxmysql adapter (`DB.query/single/execute/scalar`) | ✅ skeleton |

---

## What is still missing (roadmap)

| Feature | Priority |
|---|---|
| Full DB persistence (load/save player accounts & inventory from SQL) | High |
| Job/grade definitions loaded from database | High |
| `xPlayer.getLoadout/addWeapon/removeWeapon` | Medium |
| `xPlayer.getPermissions` / admin group checks | Medium |
| Usable items (`ESX.RegisterUsableItem`) | Medium |
| `ESX.RegisterCommand` | Medium |
| Society / billing / addonaccount / addoninventory | Low |
| ox_inventory bridge for inventory operations | Low |
| Full ESX 9.x event surface (all `esx:*` events) | Ongoing |

Contributions welcome – see [`CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## Architecture

```
rgo_esx/
├── fxmanifest.lua          FiveM resource manifest
├── server/
│   ├── db.lua              oxmysql adapter (thin wrappers)
│   └── main.lua            ESX shared object, callbacks, player lifecycle
└── client/
    └── main.lua            Client-side ESX object, callback routing
```

The resource is **self-contained Lua** – no TypeScript/build step required.

---

## Security notes

- All `RegisterNetEvent` handlers validate `source` implicitly through FiveM's
  net-event routing.
- Money/account helpers run server-side only; clients cannot directly mutate
  values.
- In production, add explicit permission checks inside `RegisterServerCallback`
  handlers for sensitive operations.
