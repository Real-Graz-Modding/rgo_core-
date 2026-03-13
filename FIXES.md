# rgo_core – Fix-Dokumentation

## Behobene Fehler

### 1. `ESX nil` / `attempt to index a nil value (global 'ESX')`
**Ursache:** `@es_extended/imports.lua` wurde in anderen Resources eingebunden, aber:
- Die Datei fehlte im `files {}`-Block des `rgo_esx/fxmanifest.lua`
- Kein Retry-Mechanismus wenn `es_extended` noch nicht vollständig gestartet war

**Fix:**
- `rgo_esx/imports.lua` → sicherer Load mit Retry-Loop (20× à 100ms) + Stub-Fallback
- `rgo_esx/fxmanifest.lua` → `imports.lua` in `files {}` eingetragen

---

### 2. `Failed to load script @es_extended/imports.lua`
**Ursache:** Die Datei war nicht im `files {}`-Block des Manifests → FiveM konnte sie nicht als shared file bereitstellen.

**Fix:** `files { 'imports.lua', ... }` in `rgo_esx/fxmanifest.lua` ergänzt.

---

### 3. `ox_lib must be started before this resource` (lib/init.lua)
**Ursache:** `lib/init.lua` warf einen harten Fehler wenn `ox_lib` nicht gestartet war.

**Fix:** `ox_lib` und `ox_core` sind jetzt **optional** – kein harter Fehler, stattdessen Graceful Degradation mit Stubs.

---

### 4. Race-Condition bei `playerConnecting`
**Ursache:** `BuildXPlayer(source)` wurde in `playerConnecting` aufgerufen – zu diesem Zeitpunkt sind Identifier noch nicht vollständig verfügbar.

**Fix:** Player wird erst in `rgo_esx:playerReady` / `rgo_qb:playerReady` vollständig aufgebaut.

---

### 5. Harte `oxmysql`-Dependency
**Ursache:** `rgo_esx/fxmanifest.lua` und `rgo_qb/fxmanifest.lua` hatten `oxmysql` als harte Dependency → Server startet nicht ohne oxmysql.

**Fix:** Dependency entfernt. oxmysql wird zur Laufzeit verwendet (in `server/db.lua`), aber ist kein Pflicht-Dependency mehr.

---

### 6. Kein dualer ESX+QBCore-Support für alte Skripte
**Ursache:** Fehlte ein universeller Bridge-Loader.

**Fix:** `lib/bridge.lua` erstellt – einbinden mit:
```lua
shared_scripts { '@rgo_core/lib/bridge.lua' }
```
Danach sind `ESX` und `QBCore` global verfügbar (mit Retry + Stub-Fallback).

---

## server.cfg – Empfohlene Start-Reihenfolge

```cfg
# 1. Datenbank
ensure oxmysql

# 2. rgo_core (Basis-Framework)
ensure rgo_core

# 3. Compatibility-Layer (MUSS nach rgo_core, VOR allen anderen Resources starten)
ensure es_extended    # → rgo_esx Ordner
ensure QBCore         # → rgo_qb Ordner

# 4. Deine eigenen Resources
ensure rgo_ticketpanel
ensure mein_esx_script
ensure mein_qb_script
```

---

## Migration bestehender ESX-Skripte

### Variante A – imports.lua (unverändert, läuft sofort):
```lua
-- fxmanifest.lua deiner Resource (KEINE Änderung nötig)
shared_scripts { '@es_extended/imports.lua' }
-- ESX ist danach global verfügbar
```

### Variante B – rgo_core Bridge (empfohlen für neue Skripte):
```lua
-- fxmanifest.lua
shared_scripts { '@rgo_core/lib/bridge.lua' }
-- ESX UND QBCore sind danach global verfügbar
```
