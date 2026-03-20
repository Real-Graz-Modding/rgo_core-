# rgo_esx – ESX-Kompatibilitäts-Layer für rgo_core

`rgo_esx` ist eine **eigenständige FiveM-Ressource**, die sich als **`es_extended`** registriert und eine vollständige ESX 9.x-kompatible API auf Basis von `rgo_core` bereitstellt.

Bestehende ESX-Skripte laufen **ohne jede Änderung** – `es_extended` wird **nicht** benötigt.

---

## 📋 Inhaltsverzeichnis

1. [Voraussetzungen](#-voraussetzungen)
2. [Installation](#-installation)
3. [Keine Migration nötig](#-keine-migration-nötig)
4. [Server-API](#-server-api)
   - [Shared Object abrufen](#shared-object-abrufen)
   - [Spieler-Funktionen (xPlayer)](#spieler-funktionen-xplayer)
   - [Geld & Bank](#geld--bank)
   - [Inventar](#inventar)
   - [Job](#job)
   - [Callbacks](#callbacks)
   - [Befehle & Items](#befehle--items)
   - [Benachrichtigungen & UI](#benachrichtigungen--ui)
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

> **Wichtig:** `es_extended` (original ESX) wird **nicht** benötigt und darf **nicht** gleichzeitig installiert sein.

---

## 🚀 Installation

1. Stelle sicher, dass `rgo_core` bereits läuft → [README.md](../README.md)

2. Der Ordner `rgo_esx` ist bereits Teil des Repositories und wird beim txAdmin-Rezept automatisch eingerichtet.

3. Aktiviere die Ressource in der `server.cfg`:

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure rgo_core        # rgo_core
   ensure es_extended    # ESX-Kompatibilitäts-Layer
   ```

4. Server neu starten – fertig.

---

## ✨ Keine Migration nötig

Die Ressource registriert sich unter dem Namen **`es_extended`**. Alle bestehenden ESX-Skripte funktionieren daher sofort und **ohne eine einzige Codeänderung**:

```lua
-- ✅ Funktioniert unverändert
local ESX = exports['es_extended']:getSharedObject()

-- ✅ Legacy-Event funktioniert unverändert
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
```

---

## 📖 Server-API

### Shared Object abrufen

```lua
local ESX = exports['es_extended']:getSharedObject()
-- oder per Legacy-Event:
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
```

---

### Spieler-Funktionen (xPlayer)

```lua
local xPlayer = ESX.GetPlayerFromId(source)

-- Identifiers
xPlayer.source                       -- Netzwerk-ID (number)
xPlayer.identifier                   -- "license2:..."
xPlayer.name                         -- Spielername
xPlayer.getIdentifier()              -- "license2:..."

-- Aktionen
xPlayer.showNotification('Willkommen auf dem Server!')
xPlayer.kick('Grund')
xPlayer.triggerEvent('eventName', ...)
```

---

### Geld & Bank

```lua
-- Bargeld
xPlayer.getMoney()                   -- aktuelles Bargeld (number)
xPlayer.addMoney(500)                -- Bargeld hinzufügen
xPlayer.removeMoney(100)             -- Bargeld abziehen
xPlayer.setMoney(1000)               -- Bargeld setzen

-- Bankkonto
xPlayer.getBankMoney()               -- Kontostand (number)
xPlayer.addBankMoney(1000)           -- Gutschrift
xPlayer.removeBankMoney(500)         -- Abbuchung
xPlayer.setBankMoney(5000)           -- Kontostand setzen

-- Konten (generisch)
xPlayer.getAccount('bank')           -- { name, money, label }
xPlayer.addAccountMoney('bank', 500)
xPlayer.removeAccountMoney('bank', 100)
xPlayer.setAccountMoney('bank', 2000)
```

---

### Inventar

```lua
-- Item abrufen
local item = xPlayer.getInventoryItem('bread')
-- { name, count, label, weight }

-- Items hinzufügen / entfernen
xPlayer.addInventoryItem('bread', 2)
xPlayer.removeInventoryItem('bread', 1)

-- Prüfen ob Spieler Item tragen kann
local canCarry = xPlayer.canCarryItem('bread', 5)   -- true/false
```

---

### Job

```lua
-- Job lesen
local job = xPlayer.getJob()         -- { name, label, grade, gradeLabel }

-- Job setzen
xPlayer.setJob('police', 2)

-- Prüfungen
xPlayer.hasJob('police')             -- true/false
xPlayer.isInJob('police')            -- true/false (Alias)
```

---

### Callbacks

```lua
-- Server-Callback registrieren (wird vom Client ausgelöst)
ESX.RegisterServerCallback('meinScript:daten', function(source, resolve, reject, arg1)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return reject('Spieler nicht gefunden') end
    resolve({ money = xPlayer.getMoney(), arg = arg1 })
end)

-- Callback zum Client senden (Server→Client)
ESX.TriggerClientCallback('meinScript:clientPing', source, function(result)
    print('Antwort vom Client:', result.pong)
end, 'payload')
```

---

### Befehle & Items

```lua
-- Befehl registrieren
ESX.RegisterCommand('healmich', 'user', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.showNotification('Du wurdest geheilt!')
end, false, { help = 'Heilt den Spieler' })

-- Verwendbares Item registrieren
ESX.RegisterUsableItem('bandage', function(source, xPlayer)
    xPlayer.removeInventoryItem('bandage', 1)
    xPlayer.showNotification('Du hast einen Verband benutzt.')
    TriggerClientEvent('hospital:heal', source)
end)

-- Item als benutzt markieren (löst den registrierten Handler aus)
ESX.UseItem(source, 'bandage')
```

---

### Benachrichtigungen & UI

```lua
-- Benachrichtigung an einen Spieler senden
xPlayer.showNotification('Willkommen!')

-- Client-seitig (aus Server heraus triggern)
TriggerClientEvent('esx:showNotification', source, 'Nachricht hier')
```

---

### Hilfsfunktionen

```lua
-- Alle verbundenen Spieler-Sources
local sources = ESX.GetPlayers()              -- { 1, 3, 7, ... }

-- Spieler nach Identifier suchen
local xPlayer = ESX.GetPlayerFromIdentifier('license2:abc123')

-- Alle Spieler mit bestimmtem Job
local officers = ESX.GetExtendedPlayers('job', 'police')

-- Spieler nach Identifier-Typ suchen
local xPlayer = ESX.GetPlayerFromIdentifier('license2:abc123')

-- Prüfen ob Spieler geladen ist
local loaded = ESX.IsPlayerLoaded(source)     -- true/false

-- Konfiguration lesen
local config = ESX.GetConfig()
```

---

## 📖 Client-API

```lua
local ESX = exports['es_extended']:getSharedObject()

-- Server-Callback auslösen
ESX.TriggerServerCallback('meinScript:daten', function(result)
    print('Geld:', result.money)
end, 'meinArgument')

-- Client-Callback registrieren (wird vom Server via TriggerClientCallback aufgerufen)
ESX.RegisterClientCallback('meinScript:clientPing', function(resolve, payload)
    resolve({ pong = true, echo = payload })
end)

-- Spielerdaten lesen
local playerData = ESX.GetPlayerData()
-- { identifier, name, money, accounts, inventory, job, ... }
print(playerData.job.name, playerData.money)

-- Konfiguration lesen
local config = ESX.GetConfig()

-- HilfNotification (Hilfe-Anzeige oben links)
ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um zu interagieren')

-- Erweiterte Benachrichtigung
ESX.ShowAdvancedNotification('~SERVER~', 'Polizei', 'Du wirst verfolgt!', 'CHAR_CALL911', 1)

-- Timeout (wie setTimeout in JS)
ESX.SetTimeout(3000, function()
    print('3 Sekunden sind vergangen')
end)

-- Fahrzeug spawnen
ESX.Game.SpawnVehicle('adder', GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()), function(vehicle)
    print('Fahrzeug gespawnt:', vehicle)
end)
```

---

## 📡 Events

### Server-Events

| Event | Wann | Parameter |
|---|---|---|
| `esx:playerLoaded` | Spieler vollständig geladen | `source, xPlayer` |
| `esx:playerDropped` | Spieler disconnected | `source, reason` |
| `esx:setJob` | Job eines Spielers geändert | `source, job, lastJob` |

### Client-Events

| Event | Wann | Parameter |
|---|---|---|
| `esx:playerLoaded` | Charakter geladen (Client) | `playerData` |
| `esx:onPlayerDeath` | Spieler gestorben | `– ` |
| `esx:onPlayerSpawn` | Spieler gespawnt | `–` |
| `esx:showNotification` | Benachrichtigung anzeigen | `msg, type` |
| `esx:setJob` | Job aktualisiert | `job` |

---

## ✅ Vollständige Kompatibilitätstabelle

| Feature | Status | Hinweis |
|---|---|---|
| `exports['es_extended']:getSharedObject()` | ✅ | Keine Änderung nötig |
| `TriggerEvent('esx:getSharedObject', cb)` | ✅ | Legacy-Event |
| `ESX.GetPlayerFromId(source)` | ✅ | |
| `ESX.GetPlayers()` | ✅ | |
| `ESX.GetPlayerFromIdentifier(id)` | ✅ | |
| `ESX.GetExtendedPlayers(key, val)` | ✅ | z.B. alle Polizisten |
| `ESX.IsPlayerLoaded(source)` | ✅ | |
| `ESX.GetConfig()` | ✅ | |
| `ESX.RegisterServerCallback` | ✅ | |
| `ESX.TriggerServerCallback` (Client) | ✅ | |
| `ESX.TriggerClientCallback` (Server→Client) | ✅ | |
| `ESX.RegisterClientCallback` (Client) | ✅ | |
| `ESX.RegisterCommand` | ✅ | |
| `ESX.RegisterUsableItem` | ✅ | |
| `ESX.UseItem` | ✅ | |
| `xPlayer.source` / `.identifier` / `.name` | ✅ | |
| `xPlayer.getMoney / addMoney / removeMoney / setMoney` | ✅ | |
| `xPlayer.getBankMoney / addBankMoney / removeBankMoney / setBankMoney` | ✅ | |
| `xPlayer.getAccount / addAccountMoney / removeAccountMoney / setAccountMoney` | ✅ | |
| `xPlayer.getInventoryItem / addInventoryItem / removeInventoryItem / canCarryItem` | ✅ | In-Memory |
| `xPlayer.getJob / setJob / hasJob / isInJob` | ✅ | |
| `xPlayer.getIdentifier()` | ✅ | |
| `xPlayer.showNotification` | ✅ | |
| `xPlayer.kick` | ✅ | |
| `xPlayer.triggerEvent` | ✅ | |
| `ESX.GetPlayerData()` (Client) | ✅ | |
| `ESX.ShowHelpNotification` (Client) | ✅ | |
| `ESX.ShowAdvancedNotification` (Client) | ✅ | |
| `ESX.SetTimeout` (Client) | ✅ | |
| `ESX.Game.SpawnVehicle` (Client) | ✅ | |
| `ESX.Game.SpawnObject` (Client) | ✅ | |
| `ESX.Game.DeleteEntity` (Client) | ✅ | |
| Event `esx:playerLoaded` (Server + Client) | ✅ | |
| Event `esx:playerDropped` | ✅ | |
| Event `esx:setJob` | ✅ | |
| Event `esx:showNotification` | ✅ | |
| DB-Adapter (`MySQL.query / single / execute / scalar`) | ✅ | oxmysql-Wrapper |

---

## 🏗️ Architektur

```
rgo_esx/
├── fxmanifest.lua       → Ressourcename: "es_extended" (Version 1.9.4)
├── server/
│   ├── db.lua           oxmysql-Adapter (dünne Wrapper-Funktionen)
│   └── main.lua         ESX Shared Object, Callbacks, Spieler-Lifecycle
└── client/
    └── main.lua         Client-seitiges ESX-Objekt, Callback-Routing
```

Die Ressource ist **reines Lua** – kein Build-Schritt erforderlich.

---

## 🔒 Sicherheitshinweise

- Alle `RegisterNetEvent`-Handler validieren `source` durch FiveM's Net-Event-Routing.
- Geld- und Kontostand-Operationen laufen **ausschließlich serverseitig** – Clients können Werte nicht direkt manipulieren.
- Callbacks prüfen, ob `xPlayer` für die gegebene `source` existiert, bevor sie ausgeführt werden.
- Füge in Produktionsumgebungen explizite Berechtigungsprüfungen (z.B. `xPlayer.getGroup()`) in sensiblen Callback-Handlern hinzu.

