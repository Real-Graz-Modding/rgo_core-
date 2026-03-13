--[[
    rgo_core – lib/bridge.lua
    ==========================
    Universeller Framework-Bridge-Loader.

    Stellt ESX UND QBCore gleichzeitig als globale Variablen bereit.
    Alte Skripte die ESX.xxx oder QBCore.Functions.xxx aufrufen
    funktionieren damit ohne jede Änderung.

    Verwendung in anderen Resources:
        shared_scripts { '@rgo_core/lib/bridge.lua' }
        -- danach sind ESX und QBCore global verfügbar
--]]

-- ─── ESX laden ────────────────────────────────────────────────────────────────

if not ESX then
    local function tryESX()
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        return (ok and type(obj) == 'table') and obj or nil
    end

    ESX = tryESX()

    if not ESX then
        local retries = 0
        while not ESX and retries < 30 do
            Wait(100)
            retries = retries + 1
            ESX = tryESX()
        end
    end

    if not ESX then
        ESX = setmetatable({ version = '1.9.4', _stub = true }, {
            __index = function(t, k)
                rawset(t, k, function() end)
                return rawget(t, k)
            end
        })
    end
end

-- ─── QBCore laden ─────────────────────────────────────────────────────────────

if not QBCore then
    local function tryQB()
        local ok, obj = pcall(function()
            return exports['QBCore']:GetCoreObject()
        end)
        return (ok and type(obj) == 'table') and obj or nil
    end

    QBCore = tryQB()

    if not QBCore then
        local retries = 0
        while not QBCore and retries < 30 do
            Wait(100)
            retries = retries + 1
            QBCore = tryQB()
        end
    end

    if not QBCore then
        QBCore = setmetatable({ Version = '1.3.0', _stub = true, Functions = {}, Shared = {} }, {
            __index = function(t, k)
                rawset(t, k, function() end)
                return rawget(t, k)
            end
        })
        QBCore.Functions = setmetatable({}, {
            __index = function(t, k)
                rawset(t, k, function() end)
                return rawget(t, k)
            end
        })
    end
end
