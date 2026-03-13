--[[
    rgo_esx – imports.lua
    =====================
    Legacy compatibility shim für Resources die
        shared_scripts { '@es_extended/imports.lua' }
    oder
        server_scripts { '@es_extended/imports.lua', 'server/main.lua' }
    in ihrem fxmanifest.lua stehen haben.

    FIXES:
      • Sicherer ESX-Load mit Retry-Loop – kein nil-Error mehr beim Start
      • Funktioniert auf Server- UND Client-Seite
      • ESX ist nach diesem File IMMER gesetzt (niemals nil)
--]]

-- Verhindere doppeltes Laden in derselben Resource-Umgebung
if ESX ~= nil then return end

-- ─── Hilfsfunktion: Export sicher abrufen ─────────────────────────────────────

local function safeGetSharedObject()
    local ok, result = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok and type(result) == 'table' then
        return result
    end
    return nil
end

-- ─── Versuche ESX zu laden (mit Retry falls Resource noch startet) ────────────

ESX = safeGetSharedObject()

if ESX == nil then
    -- Resource läuft noch hoch – warte auf das Ready-Event und retry
    local retries = 0
    local maxRetries = 20  -- max 2 Sekunden (20 × 100 ms)

    while ESX == nil and retries < maxRetries do
        Wait(100)
        retries = retries + 1
        ESX = safeGetSharedObject()
    end
end

-- ─── Absoluter Fallback: minimales ESX-Stub-Objekt ────────────────────────────
-- Schützt vor nil-Errors in Skripten die früh auf ESX zugreifen,
-- auch wenn es_extended nicht gestartet ist.

if ESX == nil then
    if IsDuplicityVersion() then
        print('^1[es_extended/imports.lua] WARNUNG: ESX konnte nicht geladen werden. ^7'
            .. 'Stelle sicher, dass "es_extended" (rgo_esx) VOR dieser Resource startet.')
    else
        print('^1[es_extended/imports.lua] WARNUNG: ESX konnte nicht geladen werden (Client). ^7')
    end

    -- Minimales Stub damit ESX.xxx-Zugriffe nicht crashen
    ESX = setmetatable({
        version = '1.9.4',
        _stub   = true,
    }, {
        __index = function(t, k)
            rawset(t, k, function(...)
                print(('[es_extended] STUB: ESX.%s() aufgerufen, aber ESX ist nicht geladen!'):format(tostring(k)))
            end)
            return rawget(t, k)
        end,
    })
end
