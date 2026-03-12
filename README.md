# rgo_core

Ein modernes FiveM-Framework von Real-Graz-Modding, basierend auf ox_core.

![](https://img.shields.io/github/contributors/Real-Graz-Modding/rgo_core-?logo=github)
![](https://img.shields.io/github/v/release/Real-Graz-Modding/rgo_core-?logo=github)

---

## 📋 Inhaltsverzeichnis

1. [Voraussetzungen](#-voraussetzungen)
2. [Installation](#-installation)
   - [1. Datenbank einrichten](#1-datenbank-einrichten)
   - [2. Dateien herunterladen und kopieren](#2-dateien-herunterladen-und-kopieren)
   - [3. server.cfg konfigurieren](#3-servercfg-konfigurieren)
   - [4. Framework bauen (Build)](#4-framework-bauen-build)
4. [Konfiguration (Convars)](#-konfiguration-convars)
5. [Optionale Brücken (Bridges)](#-optionale-brücken-bridges)
6. [Kompatibilitäts-Layer](#-kompatibilitäts-layer)
   - [rgo_esx – ESX-Skripte verwenden](#rgo_esx--esx-skripte-verwenden)
   - [rgo_qb – QBCore-Skripte verwenden](#rgo_qb--qbcore-skripte-verwenden)
7. [Third-Party-Ressourcen](#-third-party-ressourcen)
8. [Lizenz](#-lizenz)

---

## ✅ Voraussetzungen

Stelle sicher, dass folgende Komponenten vorhanden sind, **bevor** du mit der Installation beginnst:

| Komponente | Mindestversion | Hinweis |
|---|---|---|
| FiveM Server Artifact | **12913+** | [Herunterladen](https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/) |
| OneSync | aktiviert | In `server.cfg` via `set onesync on` |
| [oxmysql](https://github.com/overextended/oxmysql/releases/latest) | latest | Datenbankbrücke für FiveM |
| [ox_lib](https://github.com/overextended/ox_lib/releases/latest) | latest | Hilfsbibliothek, **muss vor rgo_core gestartet werden** |
| MariaDB / MySQL | 10.6+ / 8.0+ | Lokaler oder externer Datenbankserver |
| [Node.js](https://nodejs.org/) | **22+** | Nur für den Build-Schritt nötig |
| [Bun](https://bun.sh/) | latest | Package Manager & Build-Runner |

---

## 🚀 Installation

### 1. Datenbank einrichten

1. Öffne deinen Datenbankmanager (z. B. HeidiSQL, phpMyAdmin oder die MySQL-Konsole).
2. Führe die Datei **`sql/install.sql`** aus dem Repository aus.  
   Sie erstellt automatisch alle benötigten Tabellen (`users`, `characters`, `vehicles`, `accounts`, `ox_groups`, etc.).

   ```bash
   mysql -u root -p < sql/install.sql
   ```

3. Notiere dir Datenbankname, Benutzer und Passwort – du brauchst sie gleich.

---

### 2. Dateien herunterladen und kopieren

```bash
# In dein resources-Verzeichnis wechseln
cd /pfad/zu/deinem/server/resources

# Repository klonen
git clone https://github.com/Real-Graz-Modding/rgo_core- rgo_core

# In das Verzeichnis wechseln und Abhängigkeiten installieren
cd rgo_core
bun install
```

> **Alternativer Download:** Lade die ZIP-Datei vom [Releases-Tab](https://github.com/Real-Graz-Modding/rgo_core-/releases) herunter, entpacke sie und benenne den Ordner in `rgo_core` um.

---

### 3. server.cfg konfigurieren

Füge folgende Zeilen in deine `server.cfg` ein.  
Die Reihenfolge der `ensure`-Befehle ist **wichtig**:

```cfg
# ── Datenbankverbindung ─────────────────────────────────────────────────────
set mysql_connection_string "host=127.0.0.1;database=overextended;user=root;password=DeinPasswort"

# ── OneSync aktivieren ──────────────────────────────────────────────────────
set onesync on

# ── Ressourcen in der richtigen Reihenfolge starten ─────────────────────────
ensure oxmysql
ensure ox_lib
ensure rgo_core

# ── Optionale Kompatibilitäts-Layer (ESX / QBCore) ──────────────────────────
# ensure rgo_esx    # ESX-Skripte aktivieren
# ensure rgo_qb     # QBCore-Skripte aktivieren

# ── Optionale Brücken ────────────────────────────────────────────────────────
# ensure npwd
# ensure ox_inventory
```

> 💡 **Tipp:** `mysql_connection_string` unterstützt auch URI-Format:  
> `"mysql://root:DeinPasswort@127.0.0.1/overextended"`

---

### 4. Framework bauen (Build)

Das Framework enthält TypeScript-Quellcode, der vor dem ersten Start kompiliert werden muss:

```bash
cd /pfad/zu/resources/rgo_core
bun run build
```

Beim nächsten Änderungen am Quellcode kann mit `bun run watch` automatisch neu gebaut werden.  
Der Build erzeugt eine `fxmanifest.lua` und kompilierten JS-Code – **beides ist für den Serverbetrieb nötig**.

---

## ⚙️ Konfiguration (Convars)

Alle Werte können in der `server.cfg` mit `set` gesetzt werden.

| Convar | Standard | Beschreibung |
|---|---|---|
| `mysql_connection_string` | – | **Pflicht.** Verbindungsstring zur MariaDB/MySQL-Datenbank |
| `onesync` | `off` | **Pflicht.** Auf `on` setzen |
| `ox:characterSlots` | `1` | Anzahl der Charaktere pro Spieler |
| `ox:plateFormat` | `........` | Format für Fahrzeugkennzeichen (8 Zeichen, `.` = beliebig) |
| `ox:defaultVehicleStore` | `impound` | Standard-Fahrzeuglager |
| `ox:createDefaultAccount` | `1` | Automatisch ein Bankkonto für neue Charaktere anlegen |
| `ox:deathSystem` | `1` | Eingebautes Tod-System aktivieren |
| `ox:characterSelect` | `1` | Eingebaute Charakterauswahl aktivieren |
| `ox:spawnLocation` | `[-258.211,-293.077,21.6132,206.0]` | Standard-Spawn-Position `[x, y, z, heading]` |
| `ox:hospitalBlips` | `1` | Krankenhaus-Blips auf der Karte anzeigen |
| `ox:debug` | `0` | Debug-Modus aktivieren (auch automatisch aktiv bei `sv_lan 1`) |
| `ox:callbackTimeout` | `10000` | Timeout für Callbacks in ms (im Debug-Modus: 1 200 000) |

**Beispiel `server.cfg`:**

```cfg
set mysql_connection_string "host=127.0.0.1;database=overextended;user=root;password=geheim"
set onesync on
set ox:characterSlots 2
set ox:plateFormat "AANNNNNN"
set ox:spawnLocation "[-258.211, -293.077, 21.6132, 206.0]"
```

---

## 🔌 Optionale Brücken (Bridges)

rgo_core unterstützt folgende Third-Party-Ressourcen out-of-the-box:

### ox_inventory

Automatische Integration für Spielerinventare.  
Starte `ox_inventory` **nach** `rgo_core` in deiner `server.cfg`:

```cfg
ensure rgo_core
ensure ox_inventory
```

### NPWD (New Phone Who Dis)

Automatische Integration für In-Game-Handys mit Telefonnummer aus der Datenbank.  
Starte `npwd` **nach** `rgo_core`:

```cfg
ensure rgo_core
ensure npwd
```

---

## 🔄 Kompatibilitäts-Layer

### rgo_esx – ESX-Skripte verwenden

Mit `rgo_esx` können bestehende ESX-Skripte **ohne oder mit minimalen Änderungen** auf rgo_core laufen.

```cfg
ensure rgo_core
ensure rgo_esx
```

Bestehende Skripte, die `exports['es_extended']:getSharedObject()` aufrufen, benötigen **eine einzige Änderung**:

```lua
-- Vorher
ESX = exports['es_extended']:getSharedObject()

-- Nachher
ESX = exports['rgo_esx']:getSharedObject()
```

Skripte, die das Legacy-Event nutzen, **funktionieren unverändert**:

```lua
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
```

➡️ Vollständige Anleitung: **[rgo_esx/README.md](rgo_esx/README.md)**

---

### rgo_qb – QBCore-Skripte verwenden

Mit `rgo_qb` können bestehende QBCore-Skripte **ohne oder mit minimalen Änderungen** auf rgo_core laufen.

```cfg
ensure rgo_core
ensure rgo_qb
```

Bestehende Skripte, die `exports['qb-core']:GetCoreObject()` aufrufen, benötigen **eine einzige Änderung**:

```lua
-- Vorher
QBCore = exports['qb-core']:GetCoreObject()

-- Nachher
QBCore = exports['rgo_qb']:GetCoreObject()
```

Skripte, die das Legacy-Event nutzen, **funktionieren unverändert**:

```lua
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
```

➡️ Vollständige Anleitung: **[rgo_qb/README.md](rgo_qb/README.md)**

---

## 📦 Third-Party-Ressourcen

Wenn du eine eigene Ressource für dieses Framework veröffentlichst, verwende **nicht** das Präfix `ox`.  
Das führt zu Verwechslungen mit den offiziellen Overextended-Ressourcen und kann Konflikte verursachen.

---

## 📄 Lizenz

Copyright © 2024 Overextended <https://github.com/overextended>

Dieses Programm ist freie Software: Du kannst es unter den Bedingungen der  
**GNU Lesser General Public License**, wie von der Free Software Foundation veröffentlicht,  
entweder Version 3 der Lizenz oder (nach deiner Wahl) einer späteren Version weiterverteilen  
und/oder modifizieren.

Weitere Details: <https://www.gnu.org/licenses/>
