--[[
    rgo_core – lib/init.lua
    =======================
    Universeller Shared-Object-Loader.

    FIXES:
      • ox_lib ist OPTIONAL – kein harter Fehler wenn nicht vorhanden
      • Ox-Metatable funktioniert auch ohne ox_core (Graceful Degradation)
      • Andere Skripte können sicher require('@rgo_core.lib.init') aufrufen
--]]

if Ox then return Ox end

-- ─── ox_lib (optional) ────────────────────────────────────────────────────────

if not lib then
    if GetResourceState('ox_lib') == 'started' then
        local ok, chunk = pcall(LoadResourceFile, 'ox_lib', 'init.lua')
        if ok and chunk then
            pcall(load(chunk, '@@ox_lib/init.lua', 't'))
        end
    end
    -- Kein Fehler wenn ox_lib fehlt – rgo_core läuft auch ohne ox_lib
end

-- ─── Ox Shared Object ────────────────────────────────────────────────────────

---@type table
Ox = setmetatable({}, {
    __index = function(self, index)
        -- Versuche ox_core Export zu verwenden wenn verfügbar
        if GetResourceState('ox_core') == 'started' then
            self[index] = function(...)
                return exports.ox_core[index](nil, ...)
            end
        else
            -- Fallback: no-op Stub damit keine nil-Errors entstehen
            self[index] = function(...)
                -- silent no-op; ox_core ist nicht gestartet
            end
        end
        return self[index]
    end
})

-- ─── Kontext-spezifische Lib-Erweiterungen laden ─────────────────────────────

if lib and lib.context then
    -- ox_lib ist verfügbar → ox_core-spezifische Erweiterungen laden
    local ok, err = pcall(require, ('@ox_core.lib.%s.init'):format(lib.context))
    if not ok then
        -- Kein fataler Fehler; rgo_core läuft im standalone-Modus
    end
end

-- ─── Hilfsfunktionen ─────────────────────────────────────────────────────────

function Ox.GetGroup(name)
    local state = GlobalState['group.' .. name]
    return state
end

return Ox
