# rgo_esx – ESX-Kompatibilitäts-Layer für rgo_core

`rgo_esx` ist eine **eigenständige FiveM-Ressource**, die eine ESX 9.0.2.0-kompatible  
API-Oberfläche auf Basis von `rgo_core` bereitstellt.  
Damit können bestehende ESX-Skripte **ohne oder mit minimalen Änderungen** weiterhin  
verwendet werden – ohne dass `es_extended` installiert sein muss.

---

## ✅ Voraussetzungen

| Abhängigkeit | Mindestversion |
|---|---|
| [rgo_core](https://github.com/Real-Graz-Modding/rgo_core-) | – |
| [oxmysql](https://github.com/overextended/oxmysql/releases/latest) | latest |
| FiveM Server Artifact | 12913+ |

> **Hinweis:** `es_extended` wird **nicht** benötigt.

---

## 🚀 Installation

1. Stelle sicher, dass `rgo_core` bereits installiert und konfiguriert ist  
   → Anleitung: [README.md](../README.md)

2. Kopiere den Ordner `rgo_esx` in dein `resources`-Verzeichnis auf dem Server  
   (er ist bereits Teil des `rgo_core`-Repositories).

3. Füge folgende Zeilen in deine `server.cfg` ein – **in dieser Reihenfolge**:

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure rgo_core
   ensure rgo_esx
   ```

4. Starte deinen Server neu.

---

## 🔄 Migration bestehender ESX-Skripte

Skripte, die `exports['es_extended']:getSharedObject()` aufrufen, benötigen  
**eine einzige Code-Änderung**:

```lua
-- Vorher
ESX = exports['es_extended']:getSharedObject()

-- Nachher
ESX = exports['rgo_esx']:getSharedObject()
```

Skripte, die das **Legacy-Event** verwenden, funktionieren **unverändert**:

```lua
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
```

---

## 📖 Verwendung

### Server-seitig

```lua
local ESX = exports['rgo_esx']:getSharedObject()

-- Server-Callback registrieren
ESX.RegisterServerCallback('meineRessource:getDaten', function(source, resolve, reject, arg1)
    resolve({ wert = arg1 .. '_verarbeitet' })
end)

-- Spieler-Wrapper abrufen
local xPlayer = ESX.GetPlayerFromId(source)
if xPlayer then
    print(xPlayer.identifier)           -- license2:...
    print(xPlayer.getMoney())           -- Bargeld
    xPlayer.addMoney(500)
    xPlayer.setJob('police', 2)
    xPlayer.showNotification('Willkommen!')
end

-- Alle verbundenen Spieler-Sources abrufen
local sources = ESX.GetPlayers()   -- { 1, 3, 7, ... }
```

### Client-seitig

```lua
local ESX = exports['rgo_esx']:getSharedObject()

-- Server-Callback auslösen
ESX.TriggerServerCallback('meineRessource:getDaten', function(result)
    print(result.wert)
end, 'hallo')

-- Client-Callback registrieren (wird vom Server via TriggerClientCallback aufgerufen)
ESX.RegisterClientCallback('meineRessource:clientPing', function(resolve, payload)
    resolve({ pong = true, echo = payload })
end)
```

---

## ✅ Bereits kompatibel (MVP)

| Feature | Status |
|---|---|
| `exports['rgo_esx']:getSharedObject()` | ✅ |
| `TriggerEvent('esx:getSharedObject', cb)` | ✅ |
| `ESX.RegisterServerCallback` | ✅ |
| `ESX.TriggerServerCallback` (Client) | ✅ |
| `ESX.TriggerClientCallback` (Server→Client) | ✅ |
| `ESX.RegisterClientCallback` (Client) | ✅ |
| `ESX.GetPlayerFromId` | ✅ |
| `ESX.GetPlayers` | ✅ |
| `ESX.GetPlayerFromIdentifier` | ✅ |
| `xPlayer.identifier` / `.source` / `.name` | ✅ |
| `xPlayer.getMoney / addMoney / removeMoney / setMoney` | ✅ |
| `xPlayer.getAccount / addAccountMoney / removeAccountMoney / setAccountMoney` | ✅ |
| `xPlayer.getInventoryItem / addInventoryItem / removeInventoryItem / canCarryItem` | ✅ (In-Memory) |
| `xPlayer.getJob / setJob` | ✅ |
| `xPlayer.showNotification` | ✅ |
| `xPlayer.kick` | ✅ |
| `xPlayer.getGroup` (Stub) | ✅ |
| Event `esx:playerLoaded` (Server + Client) | ✅ |
| Event `esx:playerDropped` | ✅ |
| Event `esx:setJob` | ✅ |
| Event `esx:showNotification` | ✅ |
| oxmysql-Adapter (`DB.query / single / execute / scalar`) | ✅ Grundgerüst |

---

## 🗺️ Roadmap (noch fehlend)

| Feature | Priorität |
|---|---|
| Vollständige DB-Persistenz (Spieler, Konten, Inventar laden/speichern) | Hoch |
| Job- und Gruppen-Definitionen aus der Datenbank | Hoch |
| `xPlayer.getLoadout / addWeapon / removeWeapon` | Mittel |
| `xPlayer.getPermissions` / Admin-Gruppen-Prüfungen | Mittel |
| Verwendbare Items (`ESX.RegisterUsableItem`) | Mittel |
| `ESX.RegisterCommand` | Mittel |
| Society / Billing / Addon-Account / Addon-Inventory | Niedrig |
| ox_inventory-Brücke für Inventar-Operationen | Niedrig |
| Vollständiger ESX 9.x Event-Surface (alle `esx:*`-Events) | Laufend |

Mitarbeit willkommen – siehe [`CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## 🏗️ Architektur

```
rgo_esx/
├── fxmanifest.lua          FiveM-Ressourcen-Manifest
├── server/
│   ├── db.lua              oxmysql-Adapter (dünne Wrapper)
│   └── main.lua            ESX Shared Object, Callbacks, Spieler-Lifecycle
└── client/
    └── main.lua            Client-seitiges ESX-Objekt, Callback-Routing
```

Die Ressource ist **reines Lua** – kein TypeScript- oder Build-Schritt erforderlich.

---

## 🔒 Sicherheitshinweise

- Alle `RegisterNetEvent`-Handler validieren `source` implizit durch FiveM's Net-Event-Routing.
- Geld- und Konto-Operationen laufen **ausschließlich serverseitig** – Clients können Werte nicht direkt manipulieren.
- Füge in Produktionsumgebungen explizite Berechtigungsprüfungen in `RegisterServerCallback`-Handlern für sensible Operationen hinzu.

