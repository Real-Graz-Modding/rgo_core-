# rgo_qb – QBCore-Kompatibilitäts-Layer für rgo_core

`rgo_qb` ist eine **eigenständige FiveM-Ressource**, die sich als **`QBCore`** registriert und eine vollständige QBCore-kompatible API auf Basis von `rgo_core` bereitstellt.

Bestehende QBCore-Skripte laufen **ohne jede Änderung** – `qb-core` wird **nicht** benötigt.

---

## 📋 Inhaltsverzeichnis

1. [Voraussetzungen](#-voraussetzungen)
2. [Installation](#-installation)
3. [Keine Migration nötig](#-keine-migration-nötig)
4. [Server-API](#-server-api)
   - [Shared Object abrufen](#shared-object-abrufen)
   - [Spieler-Funktionen (Player)](#spieler-funktionen-player)
   - [Geld & Bank](#geld--bank)
   - [Inventar](#inventar)
   - [Job & Gang](#job--gang)
   - [Callbacks](#callbacks)
   - [Befehle & Items](#befehle--items)
   - [Hilfsfunktionen](#hilfsfunktionen)
5. [Client-API](#-client-api)
6. [Events](#-events)
7. [Vollständige Kompatibilitätstabelle](#-vollständige-kompatibilitätstabelle)
8. [Architektur](#️-architektur)
9. [Sicherheitshinweise](#-sicherheitshinweise)

---

## ✅ Voraussetzungen

| Abhängigkeit | Mindestversion |
|---|---|
| [rgo_core](https://github.com/Real-Graz-Modding/rgo_core-) | latest |
| [oxmysql](https://github.com/overextended/oxmysql/releases/latest) | latest |
| FiveM Server Artifact | 12913+ |

> **Wichtig:** `qb-core` wird **nicht** benötigt und darf **nicht** gleichzeitig installiert sein.

---

## 🚀 Installation

1. Stelle sicher, dass `rgo_core` bereits läuft → [README.md](../README.md)

2. Der Ordner `rgo_qb` ist bereits Teil des Repositories und wird beim txAdmin-Rezept automatisch eingerichtet.

3. Aktiviere die Ressource in der `server.cfg`:

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure ox_core     # rgo_core
   ensure QBCore      # QBCore-Kompatibilitäts-Layer
   ```

4. Server neu starten – fertig.

---

## ✨ Keine Migration nötig

Die Ressource registriert sich unter dem Namen **`QBCore`**. Alle bestehenden QBCore-Skripte funktionieren daher sofort und **ohne eine einzige Codeänderung**:

```lua
-- ✅ Funktioniert unverändert
local QBCore = exports['QBCore']:GetCoreObject()

-- ✅ Legacy-Event funktioniert unverändert
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
```

---

## 📖 Server-API

### Shared Object abrufen

```lua
local QBCore = exports['QBCore']:GetCoreObject()
-- oder per Legacy-Event:
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
```

---

### Spieler-Funktionen (Player)

```lua
local Player = QBCore.Functions.GetPlayer(source)
if not Player then return end

-- PlayerData
local pd = Player.PlayerData
pd.citizenid                         -- "STRT000001"
pd.license                           -- "license2:..."
pd.name                              -- Spielername
pd.charinfo                          -- { firstname, lastname, phone, ... }
pd.metadata                          -- { hunger, thirst, ... }

-- Aktionen
Player.Functions.Notify('Willkommen!', 'success', 3000)
Player.Functions.Kick('Grund')
Player.Functions.Save()
Player.TriggerEvent('eventName', ...)
```

---

### Geld & Bank

```lua
-- Bargeld
Player.Functions.GetMoney('cash')           -- aktueller Betrag
Player.Functions.AddMoney('cash', 500)      -- hinzufügen
Player.Functions.RemoveMoney('cash', 100)   -- abziehen
Player.Functions.SetMoney('cash', 1000)     -- direkt setzen

-- Bankkonto
Player.Functions.GetMoney('bank')
Player.Functions.AddMoney('bank', 2000)
Player.Functions.RemoveMoney('bank', 500)
Player.Functions.SetMoney('bank', 5000)
```

---

### Inventar

```lua
-- Items prüfen / lesen
Player.Functions.HasItem('bandage')                -- true/false
Player.Functions.GetItemByName('bandage')          -- { name, count, label }

-- Items hinzufügen / entfernen
Player.Functions.AddItem('bread', 3)
Player.Functions.RemoveItem('bread', 1)

-- Metadaten eines Items
Player.Functions.GetItemBySlot(1)                  -- Item in Slot 1
```

---

### Job & Gang

```lua
-- Job lesen
local job = Player.Functions.GetJob()
-- { name, label, grade, gradeLabel }

-- Job setzen
Player.Functions.SetJob('police', 2)

-- Gang lesen / setzen
local gang = Player.Functions.GetGang()
Player.Functions.SetGang('ballas', 1)
```

---

### Callbacks

```lua
-- Server-Callback registrieren (wird vom Client ausgelöst)
QBCore.Functions.CreateCallback('meinScript:daten', function(source, resolve, reject, arg1)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return reject('Spieler nicht gefunden') end
    resolve({ citizenid = Player.PlayerData.citizenid, arg = arg1 })
end)

-- Callback zum Client senden (Server→Client)
QBCore.Functions.TriggerCallback('meinScript:clientPing', source, function(result)
    print('Antwort vom Client:', result.pong)
end, 'payload')
```

---

### Befehle & Items

```lua
-- Befehl registrieren
QBCore.Functions.RegisterCommand('healmich', function(source, args, rawCommand)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.Notify('Du wurdest geheilt!', 'success')
end, false)

-- Verwendbares Item registrieren
QBCore.Functions.RegisterUsableItem('bandage', function(source, Player)
    Player.Functions.RemoveItem('bandage', 1)
    Player.Functions.Notify('Du hast einen Verband benutzt.', 'success')
    TriggerClientEvent('hospital:heal', source)
end)

-- Item als benutzt markieren (löst registrierten Handler aus)
QBCore.Functions.UseItem(source, 'bandage')
```

---

### Hilfsfunktionen

```lua
-- Spieler suchen
local Player = QBCore.Functions.GetPlayer(source)
local Player = QBCore.Functions.GetPlayerByCitizenId('STRT000001')
local Player = QBCore.Functions.GetPlayerByPhone('0660123456')

-- Listen
local sources = QBCore.Functions.GetPlayers()         -- alle Sources
local allPlayers = QBCore.Functions.GetAllPlayers()   -- alle Player-Objekte
local officers = QBCore.Functions.GetPlayerByJob('police')  -- alle Polizisten

-- Prüfungen
local loaded = QBCore.Functions.IsPlayerLoaded(source)   -- true/false
local id = QBCore.Functions.GetIdentifier(source)        -- "license2:..."

-- Benachrichtigung senden
QBCore.Functions.Notify(source, 'Nachricht hier', 'success', 3000)
```

---

## 📖 Client-API

```lua
local QBCore = exports['QBCore']:GetCoreObject()

-- Server-Callback auslösen
QBCore.Functions.TriggerCallback('meinScript:daten', function(result)
    print('citizenid:', result.citizenid)
end, 'meinArgument')

-- Client-Callback registrieren (wird vom Server via TriggerCallback aufgerufen)
QBCore.Functions.RegisterCallback('meinScript:clientPing', function(resolve, payload)
    resolve({ pong = true, echo = payload })
end)

-- Eigene Spielerdaten lesen
local pd = QBCore.PlayerData
-- oder:
local pd = QBCore.Functions.GetPlayerData()
print(pd.citizenid, pd.job.name, pd.money.cash)

-- Item prüfen
local hasItem = QBCore.Functions.HasItem('bandage')     -- true/false
local items = QBCore.Functions.GetItems()               -- alle eigenen Items

-- UI / Text
QBCore.Functions.DrawText('Drücke E zum Interagieren', { x = 0.5, y = 0.9 })

-- Koordinaten des eigenen Spielers
local coords = QBCore.Functions.GetCoords()             -- vector3
```

---

## 📡 Events

### Server-Events

| Event | Wann | Parameter |
|---|---|---|
| `QBCore:Server:OnPlayerLoaded` | Spieler vollständig geladen | `Player` |
| `QBCore:Server:PlayerUnload` | Spieler disconnected | `source` |
| `QBCore:Server:SetJob` | Job eines Spielers geändert | `source, job` |

### Client-Events

| Event | Wann | Parameter |
|---|---|---|
| `QBCore:Client:OnPlayerLoaded` | Charakter geladen (Client) | `–` |
| `QBCore:Client:PlayerUnload` | Verbindung getrennt | `–` |
| `QBCore:Client:SetJob` | Job aktualisiert | `job` |
| `QBCore:Player:SetPlayerData` | PlayerData aktualisiert | `PlayerData` |
| `QBCore:Client:UpdateObject` | QBCore-Objekt neu geladen | `–` |
| `QBCore:Notify` | Benachrichtigung anzeigen | `data` |

---

## ✅ Vollständige Kompatibilitätstabelle

| Feature | Status | Hinweis |
|---|---|---|
| `exports['QBCore']:GetCoreObject()` | ✅ | Keine Änderung nötig |
| `TriggerEvent('QBCore:GetObject', cb)` | ✅ | Legacy-Event |
| `QBCore.Functions.GetPlayer(source)` | ✅ | |
| `QBCore.Functions.GetPlayers()` | ✅ | |
| `QBCore.Functions.GetAllPlayers()` | ✅ | |
| `QBCore.Functions.GetPlayerByCitizenId(cid)` | ✅ | |
| `QBCore.Functions.GetPlayerByPhone(phone)` | ✅ | |
| `QBCore.Functions.GetPlayerByJob(job)` | ✅ | |
| `QBCore.Functions.IsPlayerLoaded(source)` | ✅ | |
| `QBCore.Functions.GetIdentifier(source)` | ✅ | |
| `QBCore.Functions.Notify(source, msg, type, len)` | ✅ | |
| `QBCore.Functions.CreateCallback` | ✅ | |
| `QBCore.Functions.TriggerCallback` (Server→Client) | ✅ | |
| `QBCore.Functions.TriggerCallback` (Client→Server) | ✅ | |
| `QBCore.Functions.RegisterCallback` (Client) | ✅ | |
| `QBCore.Functions.RegisterCommand` | ✅ | |
| `QBCore.Functions.RegisterUsableItem` | ✅ | |
| `QBCore.Functions.UseItem` | ✅ | |
| `QBCore.Functions.HasPermission / AddPermission / RemovePermission` | ✅ | Stub |
| `Player.PlayerData` (citizenid, license, name, money, job, gang, metadata, charinfo) | ✅ | |
| `Player.Functions.GetMoney / AddMoney / RemoveMoney / SetMoney` | ✅ | cash & bank |
| `Player.Functions.GetJob / SetJob` | ✅ | |
| `Player.Functions.GetGang / SetGang` | ✅ | |
| `Player.Functions.AddItem / RemoveItem / HasItem / GetItemByName` | ✅ | In-Memory |
| `Player.Functions.GetMetaData / SetMetaData` | ✅ | |
| `Player.Functions.Notify / Kick / Save` | ✅ | |
| `Player.TriggerEvent` | ✅ | |
| `QBCore.PlayerData` (Client) | ✅ | |
| `QBCore.Functions.GetPlayerData()` (Client) | ✅ | |
| `QBCore.Functions.HasItem(name)` (Client) | ✅ | |
| `QBCore.Functions.GetItems()` (Client) | ✅ | |
| `QBCore.Functions.DrawText` (Client) | ✅ | |
| `QBCore.Functions.GetCoords()` (Client) | ✅ | |
| `QBCore.Config` | ✅ | Stub |
| `QBCore.Shared` (Jobs/Gangs/Items/Vehicles) | ✅ | Stub |
| `QBCore.Commands` / `QBCore.UsableItems` | ✅ | |
| Event `QBCore:Server:OnPlayerLoaded` | ✅ | |
| Event `QBCore:Server:PlayerUnload` | ✅ | |
| Event `QBCore:Server:SetJob` | ✅ | |
| Event `QBCore:Client:OnPlayerLoaded` | ✅ | |
| Event `QBCore:Client:PlayerUnload` | ✅ | |
| Event `QBCore:Client:SetJob` | ✅ | |
| Event `QBCore:Player:SetPlayerData` | ✅ | |
| Event `QBCore:Client:UpdateObject` | ✅ | |
| Event `QBCore:Notify` | ✅ | |
| DB-Adapter (`MySQL.query / single / execute / scalar`) | ✅ | oxmysql-Wrapper |

---

## 🏗️ Architektur

```
rgo_qb/
├── fxmanifest.lua       → Ressourcename: "QBCore" (Version 1.3.0)
├── server/
│   ├── db.lua           oxmysql-Adapter (dünne Wrapper-Funktionen)
│   └── main.lua         QBCore Shared Object, Callbacks, Spieler-Lifecycle
└── client/
    └── main.lua         Client-seitiges QBCore-Objekt, Callback-Routing
```

Die Ressource ist **reines Lua** – kein Build-Schritt erforderlich.

---

## 🔒 Sicherheitshinweise

- Alle `RegisterNetEvent`-Handler validieren `source` durch FiveM's Net-Event-Routing.
- Geld- und Inventar-Operationen laufen **ausschließlich serverseitig** – Clients können Werte nicht direkt manipulieren.
- Callbacks prüfen, ob `Player` für die gegebene `source` existiert, bevor sie ausgeführt werden.
- Füge in Produktionsumgebungen explizite Berechtigungsprüfungen (z.B. `QBCore.Functions.HasPermission`) in sensiblen Callback-Handlern hinzu.
