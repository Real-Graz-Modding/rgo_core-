<div align="center">

# rgo_core

**Ein modernes, leistungsstarkes FiveM-Framework von Real-Graz-Modding – basierend auf ox_core.**  
Vollständig kompatibel mit ESX- und QBCore-Skripten. **Kein Umschreiben. Kein Neulernen. Einfach starten.**

[![GitHub contributors](https://img.shields.io/github/contributors/Real-Graz-Modding/rgo_core-?logo=github&style=flat-square)](https://github.com/Real-Graz-Modding/rgo_core-/graphs/contributors)
[![GitHub release](https://img.shields.io/github/v/release/Real-Graz-Modding/rgo_core-?logo=github&style=flat-square)](https://github.com/Real-Graz-Modding/rgo_core-/releases/latest)
[![License: LGPL v3](https://img.shields.io/badge/License-LGPL_v3-blue.svg?style=flat-square)](https://www.gnu.org/licenses/lgpl-3.0)
[![FiveM](https://img.shields.io/badge/FiveM-Artifact%2012913%2B-orange?style=flat-square)](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/)

</div>

---

## 📋 Inhaltsverzeichnis

1. [Was ist rgo_core?](#-was-ist-rgo_core)
2. [Architektur auf einen Blick](#️-architektur-auf-einen-blick)
3. [Highlights & Features](#-highlights--features)
4. [Voraussetzungen](#-voraussetzungen)
5. [Installation](#-installation)
   - [txAdmin-Rezept (empfohlen)](#-txadmin-rezept-empfohlen)
   - [Manuelle Installation](#-manuelle-installation)
   - [Aus dem Quellcode bauen](#️-aus-dem-quellcode-bauen)
6. [Konfiguration (Convars)](#️-konfiguration-convars)
7. [Framework-Kompatibilität](#-framework-kompatibilität)
   - [ESX-Skripte (es_extended)](#-esx-skripte-es_extended)
   - [QBCore-Skripte (QBCore)](#-qbcore-skripte-qbcore)
   - [Standalone-Skripte](#-standalone-skripte)
   - [Andere Frameworks (vRP, ND, …)](#-andere-frameworks-vrp-nd-)
8. [Native ox_core API (Lua)](#-native-ox_core-api-lua)
9. [Datenbank-Schema](#️-datenbank-schema)
10. [Optionale Brücken (Bridges)](#-optionale-brücken-bridges)
11. [Projektstruktur](#-projektstruktur)
12. [Häufige Fragen & Fehlersuche (FAQ)](#-häufige-fragen--fehlersuche-faq)
13. [Sicherheit](#-sicherheit)
14. [Performance-Tipps](#-performance-tipps)
15. [Mitarbeit](#-mitarbeit)
16. [Hinweis zu eigenen Ressourcen](#-hinweis-zu-eigenen-ressourcen)
17. [Lizenz](#-lizenz)

---

## 🤔 Was ist rgo_core?

**rgo_core** ist ein vollwertiges FiveM-Rollenspiel-Framework für GTA V-Multiplayer-Server. Es wurde auf Basis von [ox_core](https://github.com/overextended/ox_core) entwickelt und von Real-Graz-Modding speziell für Communities erweitert, die von ESX oder QBCore migrieren – oder beides gleichzeitig nutzen wollen.

### Das Problem, das rgo_core löst

Wer von ESX oder QBCore auf ein modernes Framework umsteigen möchte, steht vor einem riesigen Problem: **Hunderte bestehende Ressourcen müssten neu geschrieben werden.** Das kostet Monate und birgt enorme Fehlerquellen.

rgo_core löst dieses Problem mit zwei eingebauten **Kompatibilitäts-Layern**:

- 🟢 **`rgo_esx`** – startet als Ressource namens `es_extended`. Alle ESX-Skripte funktionieren **unverändert**.
- 🔵 **`rgo_qb`** – startet als Ressource namens `QBCore`. Alle QBCore-Skripte funktionieren **unverändert**.

Beide Layer können gleichzeitig aktiv sein.

### Was rgo_core im Kern bietet

- **Modernes TypeScript-Kern** – kompiliert zu hochoptimiertem JavaScript für maximale Performance.
- **Characterauswahl & Spawn-System** – eingebaut, sofort funktionsfähig.
- **Fahrzeug-System** – mit VIN-Tracking, Lagerort-Verwaltung und Datenbankanbindung.
- **Bankkonto-System** – mehrere Kontotypen (persönlich, geteilt, Gruppen).
- **Gruppen-System** – flexible Jobs/Gangs über eine einheitliche Gruppen-Tabelle.
- **ox_inventory-Integration** – nahtlose Inventar-Verwaltung.
- **pma-voice** – Proximity-Voice direkt integriert.
- **oxmysql** – moderne, asynchrone Datenbankabfragen.
- **ox_lib** – Hilfsbibliothek für Animationen, Progress-Bars, Kontextmenüs und mehr.

---

## 🏗️ Architektur auf einen Blick

```
┌─────────────────────────────────────────────────────────────────┐
│                         FiveM Server                            │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                      ox_core (rgo_core)                  │   │
│  │  TypeScript / JavaScript – Kern des Frameworks           │   │
│  │  • Spieler, Charaktere, Fahrzeuge, Konten, Gruppen       │   │
│  └──────────────┬─────────────────┬───────────────────────┘   │
│                 │                 │                             │
│  ┌──────────────▼──┐   ┌──────────▼────────────┐              │
│  │  es_extended    │   │   QBCore               │              │
│  │  (rgo_esx)      │   │   (rgo_qb)             │              │
│  │  ESX 9.x API    │   │   QBCore 1.3 API       │              │
│  └──────────────┬──┘   └──────────┬────────────┘              │
│                 │                 │                             │
│  ┌──────────────▼─────────────────▼───────────────────────┐   │
│  │              Deine Ressourcen / Skripte                 │   │
│  │  (ESX-Skripte, QBCore-Skripte, eigene Ressourcen)       │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  oxmysql   ox_lib   ox_inventory   pma-voice             │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

Der Datenfluss:
1. Spieler verbindet sich → ox_core erstellt/lädt Charakter-Daten aus der Datenbank.
2. `rgo_esx` / `rgo_qb` mappen ox_core-Daten auf das ESX/QBCore-API-Format.
3. Bestehende Skripte rufen ESX/QBCore-Funktionen auf – ohne es zu merken.
4. Alle Geld- und Inventar-Operationen laufen **ausschließlich serverseitig**.

---

## ✨ Highlights & Features

| Feature | Details |
|---|---|
| 🔄 **ESX-Kompatibilität** | ESX 9.x API vollständig – bestehende Skripte laufen **ohne Änderung** |
| 🔄 **QBCore-Kompatibilität** | QBCore 1.3 API vollständig – bestehende Skripte laufen **ohne Änderung** |
| ⚡ **txAdmin-Rezept** | Vollautomatische Installation in **unter 5 Minuten** |
| 🗄️ **oxmysql** | Moderne, async Datenbankabfragen mit Verbindungs-Pooling |
| 📦 **ox_inventory** | Slot-basiertes Inventar – SQL wird automatisch eingerichtet |
| 🎙️ **pma-voice** | Proximity-Voice mit Kanälen und Megafon-Unterstützung |
| 🔒 **Serverseitig** | Alle sensiblen Operationen (Geld, Inventar) nur am Server |
| 🌍 **22 Sprachen** | Lokalisierungs-Dateien für DE, EN, FR, IT, ES, RU, TR und mehr |
| ⚙️ **TypeScript-Kern** | Stark typisierter, moderner JavaScript-Stack |
| 🚗 **Fahrzeug-VIN** | Eindeutige Fahrzeug-IDs mit vollem Datenbanktracking |
| 💰 **Bankkonto-System** | Persönliche, geteilte und Gruppen-Konten |
| 👥 **Gruppen-System** | Flexibles Job/Gang-System über ox_groups-Tabelle |
| 🔌 **Erweiterbar** | Bridges für NPWD (New Phone Who Dis) und ox_inventory |

---

## ✅ Voraussetzungen

Stelle sicher, dass alle folgenden Komponenten vorhanden sind, **bevor** du rgo_core installierst.

| Komponente | Mindestversion | Link / Hinweis |
|---|---|---|
| FiveM Server Artifact | **12913+** | [Download](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) |
| OneSync | aktiviert | `set onesync on` in `server.cfg` |
| MariaDB **oder** MySQL | MariaDB 10.6+ / MySQL 8.0+ | Lokaler oder externer DB-Server |
| [oxmysql](https://github.com/overextended/oxmysql/releases/latest) | latest | Datenbank-Brücke (automatisch installiert) |
| [ox_lib](https://github.com/overextended/ox_lib/releases/latest) | latest | Hilfsbibliothek (automatisch installiert) |
| [Node.js](https://nodejs.org/) | **22+** | **Nur** für manuelle Builds aus dem Quellcode |
| [Bun](https://bun.sh/) | latest | **Nur** für manuelle Builds aus dem Quellcode |

> ℹ️ Beim **txAdmin-Rezept** werden oxmysql, ox_lib, ox_inventory und pma-voice automatisch heruntergeladen und eingerichtet. Node.js und Bun werden **nicht** benötigt.

> ⚠️ **OneSync ist Pflicht.** Ohne `set onesync on` in der `server.cfg` startet rgo_core nicht.

---

## 🚀 Installation

### 🎯 txAdmin-Rezept (empfohlen)

> **Das ist der einfachste Weg.** Fertig in unter 5 Minuten, kein manuelles Einrichten.

#### Schritt 1 – Rezept-URL eingeben

1. Öffne txAdmin und klicke auf **„Setup Server"** → **„Custom Template"**.
2. Gib folgende Rezept-URL ein und bestätige:
   ```
   https://raw.githubusercontent.com/Real-Graz-Modding/rgo_core-/main/recipe.yaml
   ```

#### Schritt 2 – Assistent durchführen

txAdmin fragt nach:
- **Datenbankverbindung** – Host, Name, Benutzername, Passwort
- **Servername** – erscheint in der Serverliste
- **FiveM-Lizenzschlüssel** – von [keymaster.fivem.net](https://keymaster.fivem.net/)

#### Schritt 3 – Was das Rezept automatisch installiert

Das Rezept lädt alle folgenden Ressourcen herunter und richtet sie ein:

| Ressource | Verzeichnis | Funktion |
|---|---|---|
| rgo_core (Framework) | `[rgo]/ox_core` | Kern-Framework |
| rgo_esx (ESX-Layer) | `[rgo]/es_extended` | ESX-Kompatibilität |
| rgo_qb (QBCore-Layer) | `[rgo]/QBCore` | QBCore-Kompatibilität |
| oxmysql | `[ox]/oxmysql` | Datenbankanbindung |
| ox_lib | `[ox]/ox_lib` | Hilfsbibliothek |
| ox_inventory | `[ox]/ox_inventory` | Inventarsystem |
| pma-voice | `pma-voice` | Proximity-Voice |
| screenshot-basic | `[cfx]/screenshot-basic` | Screenshot-API |
| CFX-Standard-Ressourcen | `[cfx]` | mapmanager, chat, spawnmanager, … |

Das SQL-Schema (Tabellen `users`, `characters`, `vehicles`, `accounts`, …) wird automatisch importiert.

#### Schritt 4 – Kompatibilitäts-Layer aktivieren

In der generierten `server.cfg` sind ESX- und QBCore-Layer **standardmäßig auskommentiert**.  
Entferne die `#`-Kommentarzeichen, um sie zu aktivieren:

```cfg
# Nur ESX-Layer:
ensure es_extended

# Oder nur QBCore-Layer:
ensure QBCore

# Oder beide gleichzeitig:
ensure es_extended
ensure QBCore
```

---

### 🔧 Manuelle Installation

#### Schritt 1 – Dateien herunterladen

**Variante A – mit Git (empfohlen):**

```bash
# In das resources-Verzeichnis deines Servers wechseln
cd /pfad/zu/deinem/server/resources

# Unterordner für rgo anlegen
mkdir -p [rgo]
cd [rgo]

# Repository klonen (enthält rgo_core, rgo_esx und rgo_qb)
git clone https://github.com/Real-Graz-Modding/rgo_core- ox_core

# ESX-Kompatibilitäts-Layer einrichten
cp -r ox_core/rgo_esx es_extended

# QBCore-Kompatibilitäts-Layer einrichten
cp -r ox_core/rgo_qb QBCore
```

**Variante B – ohne Git:**

1. Lade die neueste Version vom [Releases-Tab](https://github.com/Real-Graz-Modding/rgo_core-/releases) herunter.
2. Entpacke das Archiv nach `resources/[rgo]/ox_core`.
3. Kopiere `resources/[rgo]/ox_core/rgo_esx` nach `resources/[rgo]/es_extended`.
4. Kopiere `resources/[rgo]/ox_core/rgo_qb` nach `resources/[rgo]/QBCore`.

#### Schritt 2 – Abhängigkeiten herunterladen

Lade die folgenden Ressourcen manuell herunter und entpacke sie in `resources/[ox]/`:

| Ressource | Download |
|---|---|
| oxmysql | [Neueste Version](https://github.com/overextended/oxmysql/releases/latest/download/oxmysql.zip) |
| ox_lib | [Neueste Version](https://github.com/overextended/ox_lib/releases/latest/download/ox_lib.zip) |
| ox_inventory | [Neueste Version](https://github.com/overextended/ox_inventory/releases/latest/download/ox_inventory.zip) |

#### Schritt 3 – Datenbank einrichten

> ⚠️ **Wichtig:** Die Datei `sql/install.sql` enthält bereits ein `CREATE DATABASE`-Statement. Bearbeite die Datei **zuerst**, um den Datenbanknamen anzupassen.

**3a – Datenbanknamen anpassen:**

Öffne `resources/[rgo]/ox_core/sql/install.sql` in einem Texteditor und ersetze alle Vorkommen von `overextended` durch deinen gewünschten Datenbanknamen (z.B. `rgo_server`).

Unter Linux/macOS mit `sed`:
```bash
sed -i 's/overextended/rgo_server/g' resources/[rgo]/ox_core/sql/install.sql
```

**3b – Framework-Tabellen anlegen:**

```bash
mysql -u root -p < resources/[rgo]/ox_core/sql/install.sql
```

**3c – ox_inventory-Tabellen anlegen:**

```bash
mysql -u root -p < resources/[ox]/ox_inventory/ox_inventory.sql
```

#### Schritt 4 – server.cfg konfigurieren

Erstelle oder ergänze deine `server.cfg` mit folgendem Inhalt:

```cfg
# ── Netzwerk ──────────────────────────────────────────────────────────────────
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"
sv_maxclients 48

# ── Server-Identität ──────────────────────────────────────────────────────────
sv_hostname "Mein rgo_core Server"
sv_licenseKey "dein_lizenzschluessel_von_keymaster"

# ── Datenbank ──────────────────────────────────────────────────────────────────
# Verbindungsstring (Key=Value-Format):
set mysql_connection_string "host=127.0.0.1;database=rgo_server;user=fivem;password=geheimesPasswort"
# Alternativ als URI:
# set mysql_connection_string "mysql://fivem:geheimesPasswort@127.0.0.1/rgo_server"

# ── OneSync (Pflicht!) ────────────────────────────────────────────────────────
set onesync on

# ── rgo_core Einstellungen ────────────────────────────────────────────────────
set ox:characterSlots 1
# set ox:plateFormat "........"
# set ox:createDefaultAccount 1
# set ox:deathSystem 1
# set ox:characterSelect 1
# set ox:spawnLocation "[-258.211, -293.077, 21.6132, 206.0]"
# set ox:hospitalBlips 1

# ── Standard CFX-Ressourcen ───────────────────────────────────────────────────
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap

# ── Kern-Abhängigkeiten (Reihenfolge wichtig!) ────────────────────────────────
ensure oxmysql
ensure ox_lib
ensure ox_core          # rgo_core Kern-Framework

# ── Inventar ──────────────────────────────────────────────────────────────────
ensure ox_inventory

# ── Voice ─────────────────────────────────────────────────────────────────────
ensure pma-voice

# ── Kompatibilitäts-Layer (aktivieren, was du brauchst) ───────────────────────
# ensure es_extended    # ESX-Skripte unterstützen
# ensure QBCore         # QBCore-Skripte unterstützen

# ── Deine eigenen Ressourcen ──────────────────────────────────────────────────
# ensure meine_ressource
```

---

### 🛠️ Aus dem Quellcode bauen

> Dies ist nur nötig, wenn du den TypeScript-Quellcode von rgo_core selbst veränderst.  
> Voraussetzungen: **Node.js 22+** und **Bun (latest)** installiert.

```bash
# Im rgo_core-Verzeichnis:
cd resources/[rgo]/ox_core

# Abhängigkeiten installieren
bun install

# Framework einmalig bauen (erzeugt dist/client.js und dist/server.js)
bun run build

# Automatisch bei jeder Änderung neu bauen (Entwicklungsmodus)
bun run watch
```

> 💡 Im normalen Betrieb (ohne Quellcode-Änderungen) ist kein Build-Schritt nötig –  
> die fertig gebauten `dist/client.js` und `dist/server.js` sind bereits im Repository enthalten.

---

## ⚙️ Konfiguration (Convars)

Alle Einstellungen können in der `server.cfg` mit `set` gesetzt werden. Sie werden beim Serverstart eingelesen.

### Pflicht-Convars

| Convar | Beispiel | Beschreibung |
|---|---|---|
| `mysql_connection_string` | `"host=127.0.0.1;..."` | **Pflicht.** Verbindungsstring zur MariaDB/MySQL-Datenbank |
| `onesync` | `on` | **Pflicht.** Muss auf `on` gesetzt werden |

### Optionale Convars

| Convar | Standard | Beschreibung |
|---|---|---|
| `ox:characterSlots` | `1` | Maximale Anzahl an Charakteren pro Spieler |
| `ox:plateFormat` | `........` | Format für Kennzeichen – `.` = beliebiges Zeichen, `A` = Buchstabe, `N` = Ziffer |
| `ox:defaultVehicleStore` | `impound` | Standard-Lagerort für abgestellte Fahrzeuge |
| `ox:createDefaultAccount` | `1` | Automatisch ein Bankkonto für neue Charaktere anlegen |
| `ox:deathSystem` | `1` | Eingebautes Tod-/Bewusstlos-System aktivieren |
| `ox:characterSelect` | `1` | Eingebaute Charakterauswahl beim Einloggen aktivieren |
| `ox:spawnLocation` | `[-258.211,-293.077,21.6132,206.0]` | Standard-Spawnpunkt `[x, y, z, heading]` |
| `ox:hospitalBlips` | `1` | Krankenhaus-Blips auf der Karte anzeigen |
| `ox:debug` | `0` | Debug-Ausgaben aktivieren (automatisch aktiv bei `sv_lan 1`) |
| `ox:callbackTimeout` | `10000` | Callback-Timeout in Millisekunden |

### Vollständiges Konfigurations-Beispiel

```cfg
set mysql_connection_string "host=127.0.0.1;database=rgo_server;user=fivem;password=geheimesPasswort"
set onesync on

# Spieler dürfen 2 Charaktere haben
set ox:characterSlots 2

# Kennzeichen-Format: 2 Buchstaben, 4 Ziffern, 2 Buchstaben (z.B. "AB1234CD")
set ox:plateFormat "AANNNNAA"

# Standard-Features aktivieren
set ox:createDefaultAccount 1
set ox:deathSystem 1
set ox:characterSelect 1

# Spawn beim Krankenhaus (Sandy Shores)
set ox:spawnLocation "[1839.76, 3672.67, 34.28, 210.0]"
```

### Kennzeichen-Format-Platzhalter

| Platzhalter | Bedeutet |
|---|---|
| `.` | Beliebiges Zeichen (Buchstabe oder Ziffer) |
| `A` | Buchstabe (A-Z) |
| `N` | Ziffer (0-9) |
| `^` | Beliebiges Zeichen (gleichbedeutend mit `.`) |

---

## 🔄 Framework-Kompatibilität

rgo_core liefert drei vollständig funktionierende Kompatibilitäts-Layer mit. Jeder Layer emuliert das jeweilige Framework so vollständig, dass bestehende Skripte **ohne eine einzige Codeänderung** laufen.

### 🟢 ESX-Skripte (`es_extended`)

Die Ressource `rgo_esx` registriert sich als **`es_extended`**. Bestehende ESX-Skripte merken den Unterschied nicht.

**Aktivieren:**

```cfg
ensure ox_core
ensure es_extended
```

**Kein Code-Änderung nötig:**

```lua
-- ✅ Beide Patterns funktionieren unverändert
local ESX = exports['es_extended']:getSharedObject()
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
```

**Schnellreferenz Server-API:**

```lua
local ESX = exports['es_extended']:getSharedObject()

-- Spieler abrufen
local xPlayer = ESX.GetPlayerFromId(source)

-- Geld
xPlayer.getMoney()                    -- Bargeld
xPlayer.addMoney(500)
xPlayer.removeMoney(100)
xPlayer.setMoney(1000)
xPlayer.getBankMoney()                -- Kontostand
xPlayer.addBankMoney(1000)
xPlayer.removeBankMoney(500)

-- Inventar
xPlayer.addInventoryItem('bread', 2)
xPlayer.removeInventoryItem('bread', 1)
local item = xPlayer.getInventoryItem('bread')   -- { name, count, label }

-- Job
xPlayer.getJob()                      -- { name, label, grade, grade_label }
xPlayer.setJob('police', 2)
xPlayer.hasJob('police')              -- true/false

-- Aktionen
xPlayer.showNotification('Willkommen!')
xPlayer.kick('Grund')
xPlayer.triggerEvent('meinEvent', daten)

-- Server-Suche
ESX.GetPlayers()                      -- alle Sources
ESX.GetPlayerFromIdentifier('license2:abc123')
ESX.GetExtendedPlayers('job', 'police')
ESX.IsPlayerLoaded(source)

-- Befehle & Items
ESX.RegisterCommand('test', 'user', function(source, args) end, false)
ESX.RegisterUsableItem('bandage', function(source, xPlayer) end)

-- Callbacks
ESX.RegisterServerCallback('name', function(source, resolve, reject, ...) end)
ESX.TriggerClientCallback('name', source, function(result) end, ...)
```

**Schnellreferenz Client-API:**

```lua
local ESX = exports['es_extended']:getSharedObject()

-- Spielerdaten
local pd = ESX.GetPlayerData()
print(pd.job.name, pd.money)

-- Callbacks
ESX.TriggerServerCallback('name', function(result) end, ...)
ESX.RegisterClientCallback('name', function(resolve, ...) end)

-- Notifications
ESX.ShowNotification('Nachricht')
ESX.ShowHelpNotification('Drücke ~INPUT_CONTEXT~ um zu interagieren')
ESX.ShowAdvancedNotification('~SERVER~', 'Polizei', 'Du wirst gesucht!', 'CHAR_CALL911', 1)

-- Utility
ESX.Game.SpawnVehicle('adder', GetEntityCoords(PlayerPedId()), 0.0, function(veh) end)
ESX.Game.SpawnObject('prop_barrel_02a', GetEntityCoords(PlayerPedId()), function(obj) end)
ESX.Game.DeleteEntity(entity)
ESX.Game.Utils.GetClosestPlayer()      -- gibt serverId, distance zurück
ESX.SetTimeout(3000, function() end)
```

➡️ **Vollständige Dokumentation:** [rgo_esx/README.md](rgo_esx/README.md)

---

### 🔵 QBCore-Skripte (`QBCore`)

Die Ressource `rgo_qb` registriert sich als **`QBCore`**. Bestehende QBCore-Skripte merken den Unterschied nicht.

**Aktivieren:**

```cfg
ensure ox_core
ensure QBCore
```

**Kein Code-Änderung nötig:**

```lua
-- ✅ Beide Patterns funktionieren unverändert
local QBCore = exports['QBCore']:GetCoreObject()
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
```

**Schnellreferenz Server-API:**

```lua
local QBCore = exports['QBCore']:GetCoreObject()

-- Spieler abrufen
local Player = QBCore.Functions.GetPlayer(source)
local pd = Player.PlayerData

pd.citizenid                          -- "STRT000001"
pd.license                            -- "license2:..."
pd.charinfo                           -- { firstname, lastname, phone, ... }
pd.metadata                           -- { hunger, thirst, stress, ... }

-- Geld
Player.Functions.GetMoney('cash')
Player.Functions.AddMoney('cash', 500)
Player.Functions.RemoveMoney('bank', 100)
Player.Functions.SetMoney('cash', 1000)

-- Inventar
Player.Functions.HasItem('bandage')
Player.Functions.AddItem('bread', 3)
Player.Functions.RemoveItem('bread', 1)
Player.Functions.GetItemByName('bandage')

-- Job & Gang
Player.Functions.SetJob('police', 2)
Player.Functions.SetGang('ballas', 1)

-- Aktionen
Player.Functions.Notify('Willkommen!', 'success', 3000)
Player.Functions.Kick('Grund')
Player.TriggerEvent('meinEvent', daten)

-- Server-Suche
QBCore.Functions.GetPlayer(source)
QBCore.Functions.GetPlayers()
QBCore.Functions.GetPlayerByCitizenId('STRT000001')
QBCore.Functions.GetPlayerByPhone('0660123456')
QBCore.Functions.GetPlayerByJob('police')
QBCore.Functions.IsPlayerLoaded(source)

-- Berechtigungen
QBCore.Functions.HasPermission(source, 'admin')
QBCore.Functions.AddPermission(source, 'mod')
QBCore.Functions.RemovePermission(source, 'mod')

-- Befehle & Items
QBCore.Functions.RegisterCommand('test', function(source, args) end, false)
QBCore.Functions.RegisterUsableItem('bandage', function(source, Player) end)

-- Callbacks
QBCore.Functions.CreateCallback('name', function(source, resolve, reject, ...) end)
QBCore.Functions.TriggerCallback('name', source, function(result) end, ...)
```

**Schnellreferenz Client-API:**

```lua
local QBCore = exports['QBCore']:GetCoreObject()

-- Spielerdaten
local pd = QBCore.PlayerData
-- oder:
pd = QBCore.Functions.GetPlayerData()
print(pd.citizenid, pd.job.name, pd.money.cash)

-- Inventar
QBCore.Functions.HasItem('bandage')
QBCore.Functions.GetItems()
QBCore.Functions.GetItemByName('bandage')

-- Callbacks
QBCore.Functions.TriggerCallback('name', function(result) end, ...)
QBCore.Functions.RegisterCallback('name', function(resolve, ...) end)

-- UI
QBCore.Functions.DrawText('Drücke E zum Interagieren', { x = 0.5, y = 0.9 })
QBCore.Functions.GetCoords()         -- aktuelle Spieler-Koordinaten

-- Notifications
QBCore.Functions.Notify('Nachricht', 'success', 3000)
```

➡️ **Vollständige Dokumentation:** [rgo_qb/README.md](rgo_qb/README.md)

---

### 🟡 Standalone-Skripte

Ressourcen, die **kein** ESX oder QBCore benötigen, funktionieren direkt mit rgo_core ohne jede Anpassung. Dazu gehören zum Beispiel:

- `pma-voice` (Voice-Chat)
- `screenshot-basic` (Screenshots)
- Minispiele, Minijobs ohne Framework-Abhängigkeit
- Eigene Lua/JS-Ressourcen

Diese Ressourcen benötigen nur, dass der FiveM-Server läuft – kein `ensure es_extended` oder `ensure QBCore` nötig.

---

### 🟠 Andere Frameworks (vRP, ND, …)

rgo_core kommt derzeit mit eingebauten Layern für **ESX** und **QBCore** – die zwei am weitesten verbreiteten FiveM-Frameworks. Andere Frameworks werden folgendermaßen behandelt:

| Framework | Status | Hinweis |
|---|---|---|
| **ESX** (`es_extended`) | ✅ eingebaut | `rgo_esx` – vollständige API-Kompatibilität |
| **QBCore** | ✅ eingebaut | `rgo_qb` – vollständige API-Kompatibilität |
| **ox_core nativ** | ✅ eingebaut | rgo_core IS ox_core – native Ressourcen laufen direkt |
| **Standalone** | ✅ nativ | Kein Layer nötig |
| **vRP** | 🔜 Community | Eigener Layer per Pull Request möglich |
| **ND Framework** | 🔜 Community | Eigener Layer per Pull Request möglich |
| **QBX-Core** | 🔜 Community | Eigener Layer per Pull Request möglich |

**Eigenen Compatibility-Layer erstellen:**  
Das Muster ist simpel – kopiere `rgo_esx/` oder `rgo_qb/` als Vorlage und implementiere die gewünschte API.  
Die Grundstruktur ist immer gleich:

```
rgo_meinframework/
├── fxmanifest.lua       → name = 'meinframework'
├── server/
│   ├── db.lua           oxmysql-Adapter
│   └── main.lua         SharedObject, Spieler-Lifecycle, API
└── client/
    └── main.lua         Client-seitiges SharedObject
```

---

## 📚 Native ox_core API (Lua)

Wenn du eigene Ressourcen für rgo_core schreibst, kannst du die **native ox_core Lua-API** verwenden. Diese ist leistungsfähiger als die ESX/QBCore-Layer und direkt im `lib/`-Verzeichnis des Frameworks verfügbar.

> ℹ️ Die native API ist die bevorzugte Methode für **neue Ressourcen**. ESX/QBCore-Layer sind für Migration bestehender Skripte gedacht.

### Setup in deiner Ressource

```lua
-- In deinem Skript (server oder client):
-- ox_lib und ox_core müssen als dependency deklariert sein (fxmanifest.lua):
-- dependencies { 'ox_core', 'ox_lib' }

local Ox = exports.ox_core
```

### Spieler (Server)

```lua
-- Spieler nach Source-ID
local player = exports.ox_core:GetPlayer(source)

-- Spieler nach userId
local player = exports.ox_core:GetPlayerFromUserId(userId)

-- Spieler nach charId
local player = exports.ox_core:GetPlayerFromCharId(charId)

-- Alle Spieler (optional mit Filter)
local players = exports.ox_core:GetPlayers()
local officers = exports.ox_core:GetPlayers({ job = 'police' })

-- Spieler nach beliebigem Filter
local player = exports.ox_core:GetPlayerFromFilter({ charId = 42 })

-- Eigenschaften eines Spielers
player.source      -- Netzwerk-ID
player.userId      -- Datenbank-ID
player.charId      -- Charakter-ID
player.identifier  -- "license2:..."
player.username    -- Spielername

-- Methoden (über ox_core:CallPlayer)
player:getGroup('police')         -- Grade in der Gruppe
player:getGroupByType('job')      -- Aktiver Job
player:getAccount()               -- Bank-Kontoobjekt
player:getCoords()                -- Aktuelle Position (vector3)
player:getState()                 -- Player state bag
```

### Fahrzeuge (Server)

```lua
-- Fahrzeug nach verschiedenen Kriterien abrufen
local vehicle = exports.ox_core:GetVehicleFromEntity(entityId)
local vehicle = exports.ox_core:GetVehicleFromNetId(netId)
local vehicle = exports.ox_core:GetVehicleFromVin('EXAMPLEVIN123456')

-- Alle Fahrzeuge (optional mit Filter)
local vehicles = exports.ox_core:GetVehicles()
local policeVehicles = exports.ox_core:GetVehicles({ group = 'police' })

-- Fahrzeug erstellen (in der DB registrieren)
local vehicle = exports.ox_core:CreateVehicle({
    model  = 'adder',
    plate  = 'RGO1234',
    owner  = charId,        -- optional
    group  = 'police',      -- optional
}, coords, heading)

-- Fahrzeug aus DB spawnen
local vehicle = exports.ox_core:SpawnVehicle(dbId, coords, heading)

-- Eigenschaften
vehicle.vin    -- eindeutige VIN
vehicle.plate  -- Kennzeichen
vehicle.model  -- Modell-Hash
vehicle.entity -- Entity-ID
```

### Konten / Bank (Server)

```lua
-- Konto eines Charakters
local account = exports.ox_core:GetCharacterAccount(charId)

-- Konto einer Gruppe
local account = exports.ox_core:GetGroupAccount(groupName)

-- Konto per ID
local account = exports.ox_core:GetAccount(accountId)

-- Neues Konto erstellen
local account = exports.ox_core:CreateAccount(owner, label)
```

---

## 🗄️ Datenbank-Schema

Das Framework legt beim ersten Start (oder nach SQL-Import) folgende Tabellen an:

| Tabelle | Beschreibung |
|---|---|
| `users` | Verbindet FiveM-Identifiers (license2, steam, discord) mit einer `userId` |
| `characters` | Charakter-Daten (Name, Geburtsdatum, Position, Gesundheit) |
| `character_inventory` | JSON-Inventar pro Charakter (wenn ox_inventory **nicht** verwendet wird) |
| `ox_groups` | Gruppen-Definitionen (Jobs, Gangs, Organisationen) |
| `ox_group_grades` | Rang-Definitionen pro Gruppe |
| `character_groups` | Zuordnung von Charakteren zu Gruppen mit aktivem Rang |
| `vehicles` | Registrierte Fahrzeuge mit VIN, Kennzeichen, Besitzer, Zustand |
| `ox_inventory` | Inventar-Daten (verwendet von ox_inventory) |
| `ox_statuses` | Status-Definitionen (Hunger, Durst, Stress) |
| `ox_licenses` | Führerschein- und Waffenschein-Definitionen |
| `character_licenses` | Zuordnung von Lizenzen zu Charakteren |
| `accounts` | Bankkonten (persönlich, geteilt, Gruppen, inaktiv) |
| `account_roles` | Berechtigungsrollen für Konten |
| `accounts_access` | Zugriffsrechte auf Konten |
| `accounts_transactions` | Transaktions-Historie |
| `accounts_invoices` | Rechnungs-System |

### Beziehungsdiagramm

```
users ──────< characters ──────< character_groups >────── ox_groups
                  │                                            │
                  ├──────< vehicles                   ox_group_grades
                  │
                  ├──────< character_licenses ──> ox_licenses
                  │
                  ├──────< character_inventory
                  │
                  └──────> accounts ──< accounts_access
                                   ├──< accounts_transactions
                                   └──< accounts_invoices
```

### Beispiel-Datenbankabfrage mit oxmysql

```lua
-- Asynchron (empfohlen)
local rows = exports.oxmysql:query_async(
    'SELECT * FROM characters WHERE userId = ?',
    { userId }
)

-- Mit Callback
exports.oxmysql:single(
    'SELECT charId FROM characters WHERE stateId = ?',
    { 'ABC1234' },
    function(row)
        if row then print('CharID:', row.charId) end
    end
)
```

---

## 🔌 Optionale Brücken (Bridges)

### ox_inventory

ox_inventory ersetzt das einfache JSON-Inventar durch ein vollwertiges Slot-basiertes System.

**Installation:**
```cfg
ensure ox_core
ensure ox_inventory   # Nach ox_core, vor allen Ressourcen die es nutzen
```

Nach dem Start von ox_inventory werden Inventardaten automatisch in der `ox_inventory`-Tabelle gespeichert statt in `character_inventory`.

### NPWD (New Phone Who Dis)

rgo_core enthält eine eingebaute Bridge für NPWD.

**Installation:**
```cfg
ensure ox_core
ensure npwd
```

Die Bridge (`server/bridge/npwd.ts`) verbindet rgo_core-Charakterdaten mit dem NPWD-Telefonsystem.

### pma-voice

```cfg
ensure pma-voice   # Startet nach ox_core
```

pma-voice funktioniert out-of-the-box ohne weitere Konfiguration.

---

## 📁 Projektstruktur

```
rgo_core-/
│
├── client/                    TypeScript-Quellcode (Client-Seite)
│   ├── index.ts               Einstiegspunkt, Event-Handler
│   ├── player/                Spieler-Logik (Status, Spawn)
│   ├── vehicle/               Fahrzeug-Logik und Parser
│   └── config.ts              Client-Konfiguration
│
├── server/                    TypeScript-Quellcode (Server-Seite)
│   ├── accounts/              Bankkonto-System
│   └── bridge/                Brücken zu externen Ressourcen (npwd, ox_inventory)
│
├── common/                    Gemeinsame Daten (Fahrzeuge, Waffen, Konfiguration)
│   ├── data/
│   │   ├── vehicles.json      Fahrzeug-Daten
│   │   ├── vehicleStats.json  Fahrzeug-Statistiken
│   │   └── hospitals.json     Krankenhaus-Positionen
│   └── vehicles.ts            Fahrzeug-Hilfsfunktionen
│
├── dist/                      Kompilierter JavaScript-Code (wird von fxmanifest.lua geladen)
│   ├── client.js              Client-Bundle
│   └── server.js              Server-Bundle
│
├── lib/                       Lua-Hilfsbibliotheken (werden in anderen Ressourcen verwendet)
│   ├── init.lua               Initialisierung von Ox (Hauptbibliothek)
│   ├── client/
│   │   ├── index.ts           TypeScript-Deklarationen
│   │   ├── player.lua         OxPlayer-Klasse (Client)
│   │   └── player.ts          TypeScript-Typen
│   └── server/
│       ├── player.lua         OxPlayer-Klasse (Server) + Ox.GetPlayer usw.
│       ├── vehicle.lua        OxVehicle-Klasse (Server)
│       └── account.lua        OxAccount-Klasse (Server)
│
├── locales/                   Übersetzungs-Dateien (22 Sprachen)
│   ├── de.json                Deutsch
│   ├── en.json                Englisch
│   └── …                     (ar, bg, cs, da, es, et, fr, hu, it, jp, lt, nl, no, pl, ro, ru, sk, tr, zh-cn, zh-tw)
│
├── sql/
│   └── install.sql            Datenbank-Schema für rgo_core (alle Tabellen)
│
├── recipe/
│   └── server.cfg             server.cfg-Vorlage für das txAdmin-Rezept
│
├── rgo_esx/                   ESX-Kompatibilitäts-Layer
│   ├── fxmanifest.lua         → Ressourcename: "es_extended" (ESX v1.9.4)
│   ├── server/
│   │   ├── db.lua             oxmysql-Adapter
│   │   └── main.lua           ESX Shared Object, Callbacks, Spieler-Lifecycle
│   └── client/
│       └── main.lua           Client-seitiges ESX-Objekt, Notifications, Game-Utils
│
├── rgo_qb/                    QBCore-Kompatibilitäts-Layer
│   ├── fxmanifest.lua         → Ressourcename: "QBCore" (v1.3.0)
│   ├── server/
│   │   ├── db.lua             oxmysql-Adapter
│   │   └── main.lua           QBCore Shared Object, Callbacks, Spieler-Lifecycle
│   └── client/
│       └── main.lua           Client-seitiges QBCore-Objekt, Event-Sync
│
├── recipe.yaml                txAdmin-Rezept (automatische Installation)
├── fxmanifest.lua             FiveM-Ressourcen-Manifest
├── build.js                   Build-Skript (Bun)
├── package.json               Node.js-Projekt
├── biome.json                 Code-Formatter/Linter-Konfiguration
└── .editorconfig              Editor-Konfiguration
```

---

## ❓ Häufige Fragen & Fehlersuche (FAQ)

### ❌ „Could not find resource `ox_core`"

**Ursache:** Die Ressource wurde nicht korrekt installiert oder falsch benannt.  
**Lösung:** Stelle sicher, dass:
- Das Verzeichnis `resources/[rgo]/ox_core` existiert und eine `fxmanifest.lua` enthält.
- `ensure ox_core` in der `server.cfg` vorhanden ist.
- Keine Tipp-Fehler im Verzeichnisnamen vorliegen.

---

### ❌ „Failed to establish MySQL connection"

**Ursache:** Die Datenbankverbindung konnte nicht hergestellt werden.  
**Lösung:**
1. Prüfe den Verbindungsstring in der `server.cfg`:
   ```cfg
   set mysql_connection_string "host=127.0.0.1;database=rgo_server;user=fivem;password=geheimesPasswort"
   ```
2. Stelle sicher, dass der Datenbankbenutzer auf die Datenbank zugreifen darf:
   ```sql
   GRANT ALL PRIVILEGES ON rgo_server.* TO 'fivem'@'127.0.0.1';
   FLUSH PRIVILEGES;
   ```
3. Kontrolliere, ob MariaDB/MySQL läuft: `systemctl status mariadb`
4. Kontrolliere, ob der Datenbankname korrekt ist und die Tabellen angelegt wurden.

---

### ❌ „OneSync is required" oder Server startet nicht

**Ursache:** OneSync ist nicht aktiviert.  
**Lösung:** Füge `set onesync on` in die `server.cfg` ein.

---

### ❌ ESX-Skript meldet „es_extended not found"

**Ursache:** Der ESX-Kompatibilitäts-Layer ist nicht aktiviert.  
**Lösung:** Füge `ensure es_extended` **nach** `ensure ox_core` in der `server.cfg` ein.

---

### ❌ QBCore-Skript meldet „QBCore not found"

**Ursache:** Der QBCore-Kompatibilitäts-Layer ist nicht aktiviert.  
**Lösung:** Füge `ensure QBCore` **nach** `ensure ox_core` in der `server.cfg` ein.

---

### ❌ Datenbank-Fehler beim SQL-Import (manuelle Installation)

**Ursache:** Der Datenbankname in `sql/install.sql` ist `overextended` (Standard).  
**Lösung:** Ersetze `overextended` in der SQL-Datei durch deinen Datenbanknamen:
```bash
sed -i 's/overextended/rgo_server/g' sql/install.sql
mysql -u root -p < sql/install.sql
```

---

### ❌ `bun run build` schlägt fehl

**Ursache:** Node.js oder Bun nicht installiert oder veraltete Version.  
**Lösung:**
```bash
# Node.js Version prüfen (muss 22+ sein)
node --version

# Bun installieren
curl -fsSL https://bun.sh/install | bash

# Dann neu bauen
bun install
bun run build
```

---

### ❌ Spieler spawnt nicht / Charakterauswahl erscheint nicht

**Mögliche Ursachen und Lösungen:**

1. `ox:characterSelect` auf `1` setzen: `set ox:characterSelect 1`
2. `ox:spawnLocation` korrekt angeben (muss ein gültiges JSON-Array sein):
   ```cfg
   set ox:spawnLocation "[-258.211, -293.077, 21.6132, 206.0]"
   ```
3. Sicherstellen, dass `spawnmanager` und `basic-gamemode` laufen.

---

### ❓ Kann ich ESX und QBCore gleichzeitig nutzen?

**Ja!** Beide Layer können gleichzeitig aktiv sein:

```cfg
ensure ox_core
ensure es_extended
ensure QBCore
```

Jeder Layer läuft vollständig unabhängig voneinander.

---

### ❓ Muss ich ox_core oder es_extended heißen?

Nein. Die Ressourcennamen werden durch die `fxmanifest.lua`-`name`-Felder definiert:
- `rgo_core` → Ressource heißt `ox_core` (über `name 'rgo_core'` und `ensure ox_core`)
- `rgo_esx` → Ressource heißt `es_extended` (über `name 'es_extended'`)
- `rgo_qb` → Ressource heißt `QBCore` (über `name 'QBCore'`)

Das bedeutet: **Bestehende `ensure`-Einträge in der `server.cfg` müssen nicht geändert werden.**

---

### ❓ Werden Charakter-Daten persistent gespeichert?

In der aktuellen Version werden grundlegende Charakter-Daten (Position, Gesundheit) in der Datenbank gespeichert. Für vollständiges Geld- und Job-Persistenz empfehlen wir, die ESX- oder QBCore-Layer mit ox_inventory zu kombinieren.

---

## 🔒 Sicherheit

### Grundprinzipien

- **Keine Client-Authority.** Alle geldrelevanten und inventarrelevanten Operationen laufen ausschließlich serverseitig. Clients können Werte nicht direkt manipulieren.
- **Source-Validierung.** Alle `RegisterNetEvent`-Handler prüfen, ob der `source` (Spieler) gültig ist, bevor Code ausgeführt wird.
- **Kein vertrautes `source` aus Client-Events.** In FiveM wird `source` automatisch durch das Netzwerk-System gesetzt – Clients können den Wert nicht fälschen.

### Empfehlungen für eigene Ressourcen

```lua
-- ✅ Immer source aus dem Event-Parameter verwenden, nicht aus Client-Daten
RegisterNetEvent('meinEvent:action', function(amount)
    local source = source   -- sicher: von FiveM gesetzt
    if amount <= 0 or amount > 100000 then return end  -- Wert validieren!
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    xPlayer.addMoney(amount)
end)

-- ❌ Niemals: client-seitig gesendete source akzeptieren
RegisterNetEvent('meinEvent:bad', function(fakeSrc, amount)
    ESX.GetPlayerFromId(fakeSrc):addMoney(amount)  -- UNSICHER!
end)
```

### Verbindungsstring absichern

- Verwende einen **dedizierten Datenbankbenutzer** mit minimalen Rechten (nur die rgo_core-Datenbank).
- Speichere das Passwort **niemals** in öffentlichen Git-Repositories.
- Nutze `.gitignore`, um `server.cfg` von Commits auszuschließen.

### Rate-Limiting für Callbacks

```lua
-- Einfaches Rate-Limiting-Beispiel
local lastCall = {}
ESX.RegisterServerCallback('transfer:money', function(source, resolve, reject, amount, target)
    local now = GetGameTimer()
    if lastCall[source] and (now - lastCall[source]) < 2000 then
        return reject('Zu schnell!')
    end
    lastCall[source] = now
    -- ... eigentliche Logik
end)
```

---

## ⚡ Performance-Tipps

### Threads minimieren

```lua
-- ❌ Schlechter Stil: dauerhafter Thread mit kurzem Intervall
CreateThread(function()
    while true do
        Wait(0)
        -- etwas prüfen
    end
end)

-- ✅ Besser: Event-gesteuert oder mit größerem Intervall
CreateThread(function()
    while true do
        Wait(1000)  -- 1x pro Sekunde statt 60x
        -- etwas prüfen
    end
end)
```

### Datenbank-Abfragen bündeln

```lua
-- ❌ Mehrere einzelne Abfragen
for _, charId in ipairs(charIds) do
    local row = exports.oxmysql:single_async('SELECT * FROM characters WHERE charId = ?', { charId })
end

-- ✅ Eine Abfrage mit IN-Klausel
local rows = exports.oxmysql:query_async(
    'SELECT * FROM characters WHERE charId IN (?)',
    { charIds }
)
```

### ox_lib für UI verwenden

ox_lib bietet optimierte UI-Komponenten (Kontextmenüs, Progress-Bars, Input-Dialoge) die speziell für ox_core optimiert sind:

```lua
-- Progress-Bar
lib.progressBar({
    duration = 3000,
    label    = 'Wird geheilt...',
    canCancel = true,
}, function(cancelled)
    if not cancelled then
        TriggerServerEvent('hospital:applyHeal')
    end
end)
```

---

## 🤝 Mitarbeit

Bugs melden, Features vorschlagen oder Code beisteuern – alle Beiträge sind herzlich willkommen!  
Bitte lies zuerst die **[CONTRIBUTING.md](CONTRIBUTING.md)**.

---

## 📦 Hinweis zu eigenen Ressourcen

Wenn du eine eigene Ressource für rgo_core veröffentlichst, verwende **nicht** das Präfix `ox_`.  
Das Präfix ist für offizielle [Overextended](https://github.com/overextended)-Ressourcen reserviert und führt zu Verwechslungen.

Verwende stattdessen ein eigenes Präfix, z.B. `rgo_`, `meinserver_` oder einen ressourcenspezifischen Namen.

---

## 📄 Lizenz

Copyright © Real-Graz-Modding  
Basiert auf [ox_core](https://github.com/overextended/ox_core) © Overextended

Dieses Programm ist freie Software gemäß der  
**GNU Lesser General Public License v3.0** (oder neuer).  
Details: <https://www.gnu.org/licenses/lgpl-3.0.html>

