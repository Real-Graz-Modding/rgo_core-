--[[
    rgo_qb – Client: QBCore compatibility layer
    =============================================
    Provides the client-side QBCore shared object and callback routing.

    Usage (client script):
        local QBCore = exports['rgo_qb']:GetCoreObject()
        -- or legacy pattern:
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
--]]

-- ─── Pending server-callback results ─────────────────────────────────────────
-- cbId → resolve function
local PendingCallbacks = {}

-- Monotonic counter used to make callback IDs unique within the same tick.
local _cbCounter = 0
local function NextCbId(prefix)
    _cbCounter = _cbCounter + 1
    return ('%s_%s_%s'):format(prefix, GetGameTimer(), _cbCounter)
end

-- ─── Server callback helpers ─────────────────────────────────────────────────

---Trigger a server-side callback from the client.
---@param name string     registered callback name
---@param cb   function   called with the server response
---@param ...  any        extra args forwarded to the server
local function TriggerCallback(name, cb, ...)
    local cbId = NextCbId(name .. '_' .. GetPlayerServerId(PlayerId()))
    PendingCallbacks[cbId] = cb
    TriggerServerEvent('rgo_qb:triggerServerCallback', name, cbId, ...)
end

RegisterNetEvent('rgo_qb:serverCallbackResult', function(cbId, ...)
    local cb = PendingCallbacks[cbId]
    if cb then
        PendingCallbacks[cbId] = nil
        cb(...)
    end
end)

-- ─── Client callback routing ──────────────────────────────────────────────────

---@type table<string, function>
local ClientCallbacks = {}

---Register a client-side callback (called by TriggerCallback on the server).
---@param name string
---@param cb   function  handler(resolve, ...)
local function RegisterCallback(name, cb)
    ClientCallbacks[name] = cb
end

RegisterNetEvent('rgo_qb:triggerClientCallback', function(name, cbId, ...)
    local args    = { ... }
    local handler = ClientCallbacks[name]
    if not handler then
        print(('[rgo_qb] WARNING: No client callback registered for "%s"'):format(name))
        TriggerServerEvent('rgo_qb:clientCallbackResult', cbId)
        return
    end

    handler(function(...)
        TriggerServerEvent('rgo_qb:clientCallbackResult', cbId, ...)
    end, table.unpack(args))
end)

-- ─── Notification helper ──────────────────────────────────────────────────────

---@param text   string
---@param type   string  'primary'|'success'|'error'|'warning'  (QB notify types)
---@param length number  duration in ms
local function Notify(text, type, length)
    -- Fallback: use the GTA feed if no notification resource is present.
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(text))
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent('QBCore:Notify', function(text, type, length)
    Notify(text, type, length)
end)

-- ─── QBCore Shared Object (client) ───────────────────────────────────────────

local QBCore = {
    Version = '1.0.0-rgo_qb',

    -- Populated after QBCore:Player:SetPlayerData
    PlayerLoaded = false,
    PlayerData   = {
        source    = 0,
        name      = '',
        license   = '',
        citizenid = '',
        money     = { cash = 0, bank = 0, crypto = 0 },
        job       = { name = 'unemployed', label = 'Civilian', grade = { level = 0, name = 'Recruit', salary = 0 }, onduty = false, isboss = false },
        gang      = { name = 'none', label = 'No Gang', grade = { level = 0, name = 'Member' }, isboss = false },
        metadata  = {},
        inventory = {},
        charinfo  = {},
        permission = { primary = 'user', secondary = {} },
    },

    Functions = {
        TriggerCallback  = TriggerCallback,
        RegisterCallback = RegisterCallback,
        Notify           = Notify,

        -- Utility
        GetPlayerData = function()
            return QBCore.PlayerData
        end,
    },
}

-- Sync player data from server.
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data then
        QBCore.PlayerData   = data
        QBCore.PlayerLoaded = true
    end
end)

-- Player loaded / unloaded hooks.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.PlayerLoaded = true
end)

RegisterNetEvent('QBCore:Client:PlayerUnload', function()
    QBCore.PlayerLoaded = false
    QBCore.PlayerData   = {}
end)

-- Job update hook.
RegisterNetEvent('QBCore:Client:SetJob', function(job)
    QBCore.PlayerData.job = job
end)

-- ─── Public exports ───────────────────────────────────────────────────────────

---Export: exports['rgo_qb']:GetCoreObject()
exports('GetCoreObject', function()
    return QBCore
end)

---Legacy event: TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
AddEventHandler('QBCore:GetObject', function(cb)
    if type(cb) == 'function' then cb(QBCore) end
end)

-- Signal to the server that this client is ready.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('rgo_qb:playerReady')
    end
end)
