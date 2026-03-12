# rgo_qb – QBCore-Kompatibilitäts-Layer für rgo_core

`rgo_qb` ist eine **eigenständige FiveM-Ressource**, die eine QBCore-kompatible  
API-Oberfläche auf Basis von `rgo_core` bereitstellt.  
Damit können bestehende QBCore-Skripte **ohne oder mit minimalen Änderungen** weiterhin  
verwendet werden – ohne dass `qb-core` installiert sein muss.

---

## ✅ Voraussetzungen

| Abhängigkeit | Mindestversion |
|---|---|
| [rgo_core](https://github.com/Real-Graz-Modding/rgo_core-) | – |
| [oxmysql](https://github.com/overextended/oxmysql/releases/latest) | latest |
| FiveM Server Artifact | 12913+ |

> **Hinweis:** `qb-core` wird **nicht** benötigt.

---

## 🚀 Installation

1. Stelle sicher, dass `rgo_core` bereits installiert und konfiguriert ist  
   → Anleitung: [README.md](../README.md)

2. Kopiere den Ordner `rgo_qb` in dein `resources`-Verzeichnis auf dem Server  
   (er ist bereits Teil des `rgo_core`-Repositories).

3. Füge folgende Zeilen in deine `server.cfg` ein – **in dieser Reihenfolge**:

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure rgo_core
   ensure rgo_qb
   ```

4. Starte deinen Server neu.

---

## 🔄 Migration bestehender QB-Skripte

Skripte, die `exports['qb-core']:GetCoreObject()` aufrufen, benötigen  
**eine einzige Code-Änderung**:

```lua
-- Vorher
QBCore = exports['qb-core']:GetCoreObject()

-- Nachher
QBCore = exports['rgo_qb']:GetCoreObject()
```

Skripte, die das **Legacy-Event** verwenden, funktionieren **unverändert**:

```lua
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
```

---

## 📖 Verwendung

### Server-seitig

```lua
local QBCore = exports['rgo_qb']:GetCoreObject()

-- Spieler abrufen
local Player = QBCore.Functions.GetPlayer(source)
if Player then
    print(Player.PlayerData.citizenid)        -- STRT000001
    print(Player.PlayerData.license)          -- license2:...
    print(Player.Functions.GetMoney('cash'))  -- Bargeld

    Player.Functions.AddMoney('bank', 1000)
    Player.Functions.SetJob('police', 2)
    Player.Functions.Notify('Willkommen!', 'success', 3000)
end

-- Alle verbundenen Spieler-Sources abrufen
local sources = QBCore.Functions.GetPlayers()   -- { 1, 3, 7, ... }

-- Server-Callback registrieren
QBCore.Functions.CreateCallback('meineRessource:getDaten', function(source, resolve, reject, arg)
    resolve({ wert = arg .. '_ok' })
end)

-- Callback zum Client senden (Server→Client)
QBCore.Functions.TriggerCallback('meineRessource:clientPing', source, function(result)
    print(result.pong)
end, 'hallo')
```

### Client-seitig

```lua
local QBCore = exports['rgo_qb']:GetCoreObject()

-- Server-Callback auslösen
QBCore.Functions.TriggerCallback('meineRessource:getDaten', function(result)
    print(result.wert)
end, 'hallo')

-- Client-Callback registrieren (wird vom Server via TriggerCallback aufgerufen)
QBCore.Functions.RegisterCallback('meineRessource:clientPing', function(resolve, payload)
    resolve({ pong = true, echo = payload })
end)

-- Aktuelle Spielerdaten lesen
local pd = QBCore.PlayerData
print(pd.citizenid, pd.job.name, pd.money.cash)
```

---

## ✅ Bereits kompatibel (MVP)

| Feature | Status |
|---|---|
| `exports['rgo_qb']:GetCoreObject()` | ✅ |
| `TriggerEvent('QBCore:GetObject', cb)` | ✅ |
| `QBCore.Functions.GetPlayer(source)` | ✅ |
| `QBCore.Functions.GetPlayers()` | ✅ |
| `QBCore.Functions.GetPlayerByCitizenId(cid)` | ✅ |
| `QBCore.Functions.GetPlayerByPhone(phone)` | ✅ |
| `QBCore.Functions.CreateCallback` | ✅ |
| `QBCore.Functions.TriggerCallback` (Server→Client) | ✅ |
| `QBCore.Functions.TriggerCallback` (Client→Server) | ✅ |
| `QBCore.Functions.RegisterCallback` (Client) | ✅ |
| `QBCore.Functions.Notify(source, text, type, length)` | ✅ |
| `QBCore.Functions.HasPermission / AddPermission / RemovePermission` | ✅ Stub |
| `QBCore.Functions.GetIdentifier` | ✅ |
| `Player.PlayerData` (citizenid, license, name, money, job, gang, metadata, charinfo) | ✅ |
| `Player.Functions.GetMoney / AddMoney / RemoveMoney / SetMoney` | ✅ |
| `Player.Functions.GetJob / SetJob` | ✅ |
| `Player.Functions.GetGang / SetGang` | ✅ |
| `Player.Functions.AddItem / RemoveItem / HasItem / GetItemByName` | ✅ (In-Memory) |
| `Player.Functions.GetMetaData / SetMetaData` | ✅ |
| `Player.Functions.Notify / Kick / Save` | ✅ |
| Event `QBCore:Server:OnPlayerLoaded` | ✅ |
| Event `QBCore:Server:PlayerUnload` | ✅ |
| Event `QBCore:Server:SetJob` | ✅ |
| Event `QBCore:Client:OnPlayerLoaded` | ✅ |
| Event `QBCore:Client:PlayerUnload` | ✅ |
| Event `QBCore:Client:SetJob` | ✅ |
| Event `QBCore:Player:SetPlayerData` | ✅ |
| Event `QBCore:Notify` | ✅ |
| `QBCore.Config` (Stub) | ✅ |
| `QBCore.Shared` (Jobs/Gangs/Items/Vehicles – Stub) | ✅ |
| oxmysql-Adapter (`DB.query / single / execute / scalar`) | ✅ Grundgerüst |

---

## 🗺️ Roadmap (noch fehlend)

| Feature | Priorität |
|---|---|
| Vollständige DB-Persistenz (PlayerData laden/speichern) | Hoch |
| Jobs/Gangs/Items aus der Datenbank in `QBCore.Shared` | Hoch |
| `citizenid` aus der Datenbank laden / generieren | Hoch |
| `Player.Functions.Save()` speichert in die DB | Hoch |
| `charinfo` aus der Datenbank laden | Hoch |
| `QBCore.Functions.CreateUseableItem` | Mittel |
| `QBCore.Functions.UseItem` | Mittel |
| `QBCore.Functions.AddItem` (global, nicht spielerbezogen) | Mittel |
| `QBCore.Functions.CanAddItem` | Mittel |
| `QBCore.Commands`-System | Mittel |
| `Player.Functions.GetVehicles` | Niedrig |
| ox_inventory-Brücke für Inventar-Operationen | Niedrig |
| `QBCore.Config.Whitelist` / ACE-basierte Berechtigungen | Niedrig |

Mitarbeit willkommen – siehe [`CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## 🏗️ Architektur

```
rgo_qb/
├── fxmanifest.lua          FiveM-Ressourcen-Manifest
├── server/
│   ├── db.lua              oxmysql-Adapter (dünne Wrapper)
│   └── main.lua            QBCore Shared Object, Callbacks, Spieler-Lifecycle
└── client/
    └── main.lua            Client-seitiges QBCore-Objekt, Callback-Routing
```

Die Ressource ist **reines Lua** – kein TypeScript- oder Build-Schritt erforderlich.

---

## 🔒 Sicherheitshinweise

- Alle `RegisterNetEvent`-Handler validieren `source` implizit durch FiveM's Net-Event-Routing.
- Geld- und Inventar-Operationen laufen **ausschließlich serverseitig** – Clients können Werte nicht direkt manipulieren.
- Füge in Produktionsumgebungen explizite Berechtigungsprüfungen in `CreateCallback`-Handlern für sensible Operationen hinzu.
