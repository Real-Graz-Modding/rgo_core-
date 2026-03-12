--[[
    rgo_esx – Client: ESX compatibility layer
    ==========================================
    Provides the client-side ESX shared object and callback routing.

    Usage (client script):
        local ESX = exports['rgo_esx']:getSharedObject()
        -- or legacy pattern:
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
--]]

-- ─── Pending client callbacks ─────────────────────────────────────────────────
-- cbId → resolve function
local PendingClientCallbacks = {}

-- Monotonic counter used to make callback IDs unique within the same tick.
local _cbCounter = 0
local function NextCbId(prefix)
    _cbCounter = _cbCounter + 1
    return ('%s_%s_%s'):format(prefix, GetGameTimer(), _cbCounter)
end

-- ─── Server callback helpers ─────────────────────────────────────────────────

local function TriggerServerCallback(name, cb, ...)
    local cbId = NextCbId(name .. '_' .. GetPlayerServerId(PlayerId()))
    PendingClientCallbacks[cbId] = cb
    TriggerServerEvent('rgo_esx:triggerServerCallback', name, cbId, ...)
end

RegisterNetEvent('rgo_esx:serverCallbackResult', function(cbId, success, ...)
    local cb = PendingClientCallbacks[cbId]
    if cb then
        PendingClientCallbacks[cbId] = nil
        cb(...)
    end
end)

-- ─── Client callback routing ──────────────────────────────────────────────────

---@type table<string, function>
local ClientCallbacks = {}

local function RegisterClientCallback(name, cb)
    ClientCallbacks[name] = cb
end

RegisterNetEvent('rgo_esx:triggerClientCallback', function(name, cbId, ...)
    local args = { ... }
    local handler = ClientCallbacks[name]
    if not handler then
        print(('[rgo_esx] WARNING: No client callback registered for "%s"'):format(name))
        TriggerServerEvent('rgo_esx:clientCallbackResult', cbId)
        return
    end

    handler(function(...)
        TriggerServerEvent('rgo_esx:clientCallbackResult', cbId, ...)
    end, table.unpack(args))
end)

-- ─── Notification helper ──────────────────────────────────────────────────────

local function ShowNotification(msg, notifType)
    -- Fallback to simple subtitle if no notification resource is available.
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent('esx:showNotification', function(msg, notifType)
    ShowNotification(msg, notifType)
end)

-- ─── ESX Shared Object (client) ───────────────────────────────────────────────

local ESX = {
    -- ESX version string – reported by ox_lib version checks (must be >= 1.6.0)
    version = '1.9.4',

    -- Populated after esx:playerLoaded
    PlayerLoaded = false,
    PlayerData   = {},

    -- Callback API
    TriggerServerCallback  = TriggerServerCallback,
    RegisterClientCallback = RegisterClientCallback,

    -- Notification
    ShowNotification = ShowNotification,

    -- Utility
    Trace = function(msg)
        print('[rgo_esx] ' .. tostring(msg))
    end,
}

-- Populate PlayerData when the server reports the player is loaded.
RegisterNetEvent('esx:playerLoaded', function(playerData)
    ESX.PlayerLoaded = true
    ESX.PlayerData   = playerData
end)

-- ─── Public exports ───────────────────────────────────────────────────────────

---Export: exports['rgo_esx']:getSharedObject()
exports('getSharedObject', function()
    return ESX
end)

---Legacy event: TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
AddEventHandler('esx:getSharedObject', function(cb)
    if type(cb) == 'function' then cb(ESX) end
end)

-- Signal to the server that this client is ready.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('rgo_esx:playerReady')
    end
end)
