<div align="center">

# rgo_core

**Ein modernes FiveM-Framework von Real-Graz-Modding, basierend auf ox_core.**  
Vollständig kompatibel mit ESX- und QBCore-Skripten – kein Umschreiben nötig.

[![GitHub contributors](https://img.shields.io/github/contributors/Real-Graz-Modding/rgo_core-?logo=github&style=flat-square)](https://github.com/Real-Graz-Modding/rgo_core-/graphs/contributors)
[![GitHub release](https://img.shields.io/github/v/release/Real-Graz-Modding/rgo_core-?logo=github&style=flat-square)](https://github.com/Real-Graz-Modding/rgo_core-/releases/latest)
[![License: LGPL v3](https://img.shields.io/badge/License-LGPL_v3-blue.svg?style=flat-square)](https://www.gnu.org/licenses/lgpl-3.0)
[![FiveM](https://img.shields.io/badge/FiveM-Artifact%2012913%2B-orange?style=flat-square)](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/)

</div>

---

## 📋 Inhaltsverzeichnis

1. [Highlights](#-highlights)
2. [Voraussetzungen](#-voraussetzungen)
3. [Installation](#-installation)
   - [txAdmin-Rezept (empfohlen)](#-txadmin-rezept-empfohlen)
   - [Manuelle Installation](#-manuelle-installation)
4. [Konfiguration (Convars)](#️-konfiguration-convars)
5. [Kompatibilitäts-Layer](#-kompatibilitäts-layer)
   - [ESX-Skripte (es_extended)](#-esx-skripte-es_extended)
   - [QBCore-Skripte (QBCore)](#-qbcore-skripte-qbcore)
6. [Optionale Brücken](#-optionale-brücken-bridges)
7. [Projektstruktur](#-projektstruktur)
8. [Mitarbeit](#-mitarbeit)
9. [Lizenz](#-lizenz)

---

## ✨ Highlights

| Feature | Details |
|---|---|
| 🔄 **ESX-Kompatibilität** | Bestehende ESX-Skripte laufen **ohne jede Änderung** |
| 🔄 **QBCore-Kompatibilität** | Bestehende QBCore-Skripte laufen **ohne jede Änderung** |
| ⚡ **txAdmin-Rezept** | Vollautomatische Installation in wenigen Klicks |
| 🗄️ **oxmysql** | Moderne, asynchrone Datenbankabfragen |
| 📦 **ox_inventory** | Nahtlose Integration – SQL wird automatisch eingerichtet |
| 🎙️ **pma-voice** | Proximity-Voice direkt inklusive |
| 🔒 **Serverseitig** | Alle Geld- und Inventar-Operationen laufen nur am Server |

---

## ✅ Voraussetzungen

| Komponente | Mindestversion | Link |
|---|---|---|
| FiveM Server Artifact | **12913+** | [Download](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) |
| OneSync | aktiviert | `set onesync on` in `server.cfg` |
| MariaDB / MySQL | 10.6+ / 8.0+ | Lokaler oder externer Datenbankserver |
| [oxmysql](https://github.com/overextended/oxmysql/releases/latest) | latest | Datenbankbrücke (wird vom Rezept installiert) |
| [ox_lib](https://github.com/overextended/ox_lib/releases/latest) | latest | Hilfsbibliothek (wird vom Rezept installiert) |
| [Node.js](https://nodejs.org/) | **22+** | Nur für manuelle Builds aus dem Quellcode |
| [Bun](https://bun.sh/) | latest | Nur für manuelle Builds aus dem Quellcode |

> ℹ️ Bei der **txAdmin-Rezept-Installation** werden oxmysql, ox_lib, ox_inventory und pma-voice automatisch heruntergeladen. Node.js und Bun werden nicht benötigt.

---

## 🚀 Installation

### 🎯 txAdmin-Rezept (empfohlen)

> **Fertig in unter 5 Minuten.** Keine manuellen Schritte nötig.

1. Öffne txAdmin und wähle **„Setup Server"** → **„Custom Template"**.
2. Gib folgende Rezept-URL ein:
   ```
   https://raw.githubusercontent.com/Real-Graz-Modding/rgo_core-/main/recipe.yaml
   ```
3. Folge dem Assistenten: Datenbankverbindung eingeben, Servername setzen, Lizenzschlüssel eintragen.
4. txAdmin installiert automatisch und richtet ein:
   - ✅ rgo_core (Framework)
   - ✅ oxmysql, ox_lib, ox_inventory (SQL-Schema wird automatisch importiert)
   - ✅ pma-voice, screenshot-basic
   - ✅ Standard-CFX-Ressourcen (mapmanager, chat, spawnmanager, …)
   - ✅ ESX-Layer (`es_extended`) und QBCore-Layer (`QBCore`) – standardmäßig deaktiviert

> 💡 **Kein Build-Schritt nötig** – das Rezept lädt direkt das fertige Repository herunter.

---

### 🔧 Manuelle Installation

#### 1. Dateien herunterladen

```bash
# In dein resources-Verzeichnis wechseln
cd /pfad/zu/deinem/server/resources

# Repository klonen (enthält rgo_core, rgo_esx und rgo_qb)
git clone https://github.com/Real-Graz-Modding/rgo_core- ox_core

# Abhängigkeiten installieren und Framework bauen
cd ox_core
bun install
bun run build
```

> **Ohne Git:** Lade die neuste Version vom [Releases-Tab](https://github.com/Real-Graz-Modding/rgo_core-/releases) herunter, entpacke sie in `resources/ox_core`.

#### 2. Datenbank einrichten

```bash
# Framework-Tabellen anlegen
mysql -u root -p deine_datenbank < sql/install.sql

# ox_inventory-Tabellen anlegen (owned_vehicles, licenses, etc.)
mysql -u root -p deine_datenbank < pfad/zu/ox_inventory/ox_inventory.sql
```

#### 3. server.cfg konfigurieren

```cfg
# ── Datenbankverbindung ───────────────────────────────────────────────────────
set mysql_connection_string "host=127.0.0.1;database=deine_datenbank;user=root;password=DeinPasswort"
# Alternativ als URI:
# set mysql_connection_string "mysql://root:DeinPasswort@127.0.0.1/deine_datenbank"

# ── OneSync (Pflicht) ─────────────────────────────────────────────────────────
set onesync on

# ── Ressourcen (Reihenfolge wichtig!) ────────────────────────────────────────
ensure oxmysql
ensure ox_lib
ensure ox_core        # rgo_core Haupt-Framework

ensure ox_inventory   # Inventar-System

# ── Kompatibilitäts-Layer (ESX und/oder QBCore aktivieren) ───────────────────
# ensure es_extended  # ESX-Skripte unterstützen
# ensure QBCore       # QBCore-Skripte unterstützen

ensure pma-voice
```

#### 4. Neu bauen nach Änderungen

```bash
cd /pfad/zu/resources/ox_core
bun run build         # einmaliger Build
# oder:
bun run watch         # automatisch bei jeder Änderung neu bauen
```

---

## ⚙️ Konfiguration (Convars)

Alle Werte können in der `server.cfg` mit `set` gesetzt werden.

| Convar | Standard | Beschreibung |
|---|---|---|
| `mysql_connection_string` | – | **Pflicht.** Verbindungsstring zur MariaDB/MySQL-Datenbank |
| `onesync` | `off` | **Pflicht.** Muss auf `on` gesetzt werden |
| `ox:characterSlots` | `1` | Maximale Anzahl an Charakteren pro Spieler |
| `ox:plateFormat` | `........` | Format für Kennzeichen (8 Stellen, `.` = beliebiges Zeichen) |
| `ox:defaultVehicleStore` | `impound` | Lagerort für abgestellte Fahrzeuge |
| `ox:createDefaultAccount` | `1` | Bankkonto automatisch für neue Charaktere anlegen |
| `ox:deathSystem` | `1` | Eingebautes Tod-/Bewusstlos-System aktivieren |
| `ox:characterSelect` | `1` | Eingebaute Charakterauswahl beim Einloggen aktivieren |
| `ox:spawnLocation` | `[-258.211,-293.077,21.6132,206.0]` | Standard-Spawnpunkt `[x, y, z, heading]` |
| `ox:hospitalBlips` | `1` | Krankenhaus-Blips auf der Karte anzeigen |
| `ox:debug` | `0` | Debug-Ausgaben aktivieren (wird bei `sv_lan 1` automatisch aktiviert) |
| `ox:callbackTimeout` | `10000` | Callback-Timeout in Millisekunden |

**Vollständiges Konfigurationsbeispiel:**

```cfg
set mysql_connection_string "host=127.0.0.1;database=rgo_server;user=fivem;password=sicheresPasswort"
set onesync on

set ox:characterSlots 2
set ox:plateFormat "AANNNNNN"
set ox:createDefaultAccount 1
set ox:deathSystem 1
set ox:characterSelect 1
set ox:spawnLocation "[-258.211, -293.077, 21.6132, 206.0]"
```

---

## 🔄 Kompatibilitäts-Layer

rgo_core liefert zwei vollständige Kompatibilitäts-Layer mit, die als eigenständige Ressourcen installiert werden. Bestehende ESX- und QBCore-Skripte laufen **ohne jede Codeänderung**.

### 🟢 ESX-Skripte (`es_extended`)

Die Ressource registriert sich unter dem Namen **`es_extended`** – genau so, wie bestehende ESX-Skripte es erwarten.

**In `server.cfg` aktivieren:**

```cfg
ensure ox_core
ensure es_extended   # ESX-Kompatibilitäts-Layer aktivieren
```

**Keine Änderungen nötig in bestehenden Skripten:**

```lua
-- ✅ Funktioniert direkt – keine Änderung nötig
local ESX = exports['es_extended']:getSharedObject()

-- ✅ Legacy-Event funktioniert ebenfalls unverändert
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
```

**Unterstützte API-Highlights (Server):**

```lua
local ESX = exports['es_extended']:getSharedObject()

-- Spieler-Wrapper
local xPlayer = ESX.GetPlayerFromId(source)
xPlayer.getMoney()                   -- Bargeld
xPlayer.addMoney(500)
xPlayer.getBankMoney()               -- Kontostand
xPlayer.addBankMoney(1000)
xPlayer.setJob('police', 2)
xPlayer.hasJob('police')             -- true/false
xPlayer.getIdentifier()              -- "license2:..."
xPlayer.showNotification('Willkommen!')

-- Befehle & Items
ESX.RegisterCommand('test', function(source, args) end)
ESX.RegisterUsableItem('bandage', function(source, xPlayer) end)

-- Callbacks
ESX.RegisterServerCallback('meinScript:daten', function(source, resolve, reject)
    resolve({ ok = true })
end)

-- Hilfsfunktionen
ESX.GetPlayers()                     -- alle verbundenen Sources
ESX.GetExtendedPlayers('job', 'police')  -- alle Polizisten
ESX.IsPlayerLoaded(source)           -- true/false
ESX.GetConfig()                      -- Konfigurationstabelle
```

➡️ Vollständige Dokumentation: **[rgo_esx/README.md](rgo_esx/README.md)**

---

### 🔵 QBCore-Skripte (`QBCore`)

Die Ressource registriert sich unter dem Namen **`QBCore`** – genau so, wie bestehende QBCore-Skripte es erwarten.

**In `server.cfg` aktivieren:**

```cfg
ensure ox_core
ensure QBCore        # QBCore-Kompatibilitäts-Layer aktivieren
```

**Keine Änderungen nötig in bestehenden Skripten:**

```lua
-- ✅ Funktioniert direkt – keine Änderung nötig
local QBCore = exports['QBCore']:GetCoreObject()

-- ✅ Legacy-Event funktioniert ebenfalls unverändert
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
```

**Unterstützte API-Highlights (Server):**

```lua
local QBCore = exports['QBCore']:GetCoreObject()

-- Spieler-Wrapper
local Player = QBCore.Functions.GetPlayer(source)
Player.PlayerData.citizenid          -- "STRT000001"
Player.Functions.GetMoney('cash')    -- Bargeld
Player.Functions.AddMoney('bank', 1000)
Player.Functions.SetJob('police', 2)
Player.Functions.HasItem('bandage')  -- true/false
Player.Functions.Notify('Willkommen!', 'success', 3000)

-- Befehle & Items
QBCore.Functions.RegisterCommand('test', function(source, args) end)
QBCore.Functions.RegisterUsableItem('bandage', function(source, Player) end)

-- Suche
QBCore.Functions.GetPlayerByJob('police')   -- alle Polizisten
QBCore.Functions.IsPlayerLoaded(source)     -- true/false

-- Callbacks
QBCore.Functions.CreateCallback('meinScript:daten', function(source, resolve, reject)
    resolve({ ok = true })
end)
```

➡️ Vollständige Dokumentation: **[rgo_qb/README.md](rgo_qb/README.md)**

---

## 🔌 Optionale Brücken (Bridges)

### ox_inventory

rgo_core integriert sich nahtlos mit ox_inventory. Das SQL-Schema (`owned_vehicles`, `licenses`, etc.) wird beim txAdmin-Rezept automatisch importiert.

Bei manueller Installation:
```cfg
ensure ox_core
ensure ox_inventory
```

### NPWD (New Phone Who Dis)

```cfg
ensure ox_core
ensure npwd
```

---

## 📁 Projektstruktur

```
rgo_core-/
├── client/                  TypeScript-Quellcode (Client)
├── server/                  TypeScript-Quellcode (Server)
├── common/                  Gemeinsame Daten (Fahrzeuge, Waffen, etc.)
├── dist/                    Kompilierter JS-Code (wird von fxmanifest.lua geladen)
├── lib/                     Lua-Hilfsbibliotheken
├── locales/                 Übersetzungen
├── sql/
│   └── install.sql          Datenbank-Schema für rgo_core
├── recipe/
│   └── server.cfg           server.cfg-Vorlage für das txAdmin-Rezept
├── rgo_esx/                 ESX-Kompatibilitäts-Layer
│   ├── fxmanifest.lua       → Ressource heißt "es_extended"
│   ├── server/main.lua      ESX Shared Object, Callbacks, Spieler
│   └── client/main.lua      Client-seitiges ESX-Objekt
├── rgo_qb/                  QBCore-Kompatibilitäts-Layer
│   ├── fxmanifest.lua       → Ressource heißt "QBCore"
│   ├── server/main.lua      QBCore Shared Object, Callbacks, Spieler
│   └── client/main.lua      Client-seitiges QBCore-Objekt
├── recipe.yaml              txAdmin-Rezept
├── fxmanifest.lua           FiveM-Ressourcen-Manifest
└── package.json             Node.js-Projekt
```

---

## 🤝 Mitarbeit

Bugs melden, Features vorschlagen oder Code beisteuern – alle Beiträge sind willkommen!  
Bitte lies zuerst die **[CONTRIBUTING.md](CONTRIBUTING.md)**.

---

## 📦 Hinweis zu eigenen Ressourcen

Wenn du eine eigene Ressource für rgo_core veröffentlichst, verwende **nicht** das Präfix `ox_`.  
Das Präfix ist für offizielle [Overextended](https://github.com/overextended)-Ressourcen reserviert und führt sonst zu Verwechslungen.

---

## 📄 Lizenz

Copyright © Real-Graz-Modding  
Basiert auf [ox_core](https://github.com/overextended/ox_core) © Overextended

Dieses Programm ist freie Software gemäß der  
**GNU Lesser General Public License v3.0** (oder neuer).  
Details: <https://www.gnu.org/licenses/lgpl-3.0.html>
