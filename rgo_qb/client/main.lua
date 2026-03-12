--[[
    rgo_qb – Client: QBCore compatibility layer
    =============================================
    Provides the client-side QBCore shared object and callback routing.

    Usage (client script):
        local QBCore = exports['QBCore']:GetCoreObject()
        -- or legacy pattern:
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
--]]

-- ─── Pending server-callback results ─────────────────────────────────────────
local PendingCallbacks = {}

-- Capture FiveM natives before any wrappers shadow them
local _DrawText = DrawText

local _cbCounter = 0
local function NextCbId(prefix)
    _cbCounter = _cbCounter + 1
    return ('%s_%s_%s'):format(prefix, GetGameTimer(), _cbCounter)
end

-- ─── Server callback helpers ─────────────────────────────────────────────────

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

local function RegisterCallback(name, cb)
    ClientCallbacks[name] = cb
end

RegisterNetEvent('rgo_qb:triggerClientCallback', function(name, cbId, ...)
    local args    = { ... }
    local handler = ClientCallbacks[name]
    if not handler then
        print(('[QBCore] WARNING: No client callback registered for "%s"'):format(name))
        TriggerServerEvent('rgo_qb:clientCallbackResult', cbId)
        return
    end

    handler(function(...)
        TriggerServerEvent('rgo_qb:clientCallbackResult', cbId, ...)
    end, table.unpack(args))
end)

-- ─── Notification helper ──────────────────────────────────────────────────────

local function Notify(text, type, length)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(text))
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent('QBCore:Notify', function(text, type, length)
    Notify(text, type, length)
end)

-- ─── QBCore Shared Object (client) ───────────────────────────────────────────

local QBCore = {
    Version = '1.3.0-rgo_qb',

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

    Config = {
        Locale = 'en',
        Money  = { MoneyTypes = { cash = 500, bank = 5000, crypto = 0 } },
    },

    Shared = {
        Jobs     = {},
        Gangs    = {},
        Items    = {},
        Vehicles = {},
    },

    Commands    = {},
    UsableItems = {},

    Functions = {
        TriggerCallback  = TriggerCallback,
        RegisterCallback = RegisterCallback,
        Notify           = Notify,

        -- Player data
        GetPlayerData = function()
            return QBCore.PlayerData
        end,

        -- Inventory helpers (client-side, reads from synced PlayerData)
        HasItem = function(item, amount)
            for _, v in ipairs(QBCore.PlayerData.inventory or {}) do
                if v.name == item then
                    return v.amount >= (amount or 1)
                end
            end
            return false
        end,

        GetItemByName = function(item)
            for _, v in ipairs(QBCore.PlayerData.inventory or {}) do
                if v.name == item then return v end
            end
        end,

        GetItems = function()
            return QBCore.PlayerData.inventory or {}
        end,

        -- UI helpers
        DrawText = function(text, coords)
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.55)
            SetTextColour(255, 255, 255, 215)
            SetTextDropShadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentString(tostring(text))
            _DrawText(coords and coords.x or 0.5, coords and coords.y or 0.5)
        end,

        -- Utility
        GetCoords = function(entity)
            local c = GetEntityCoords(entity or PlayerPedId())
            return { x = c.x, y = c.y, z = c.z }
        end,
    },
}

-- Sync player data from server.
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data then
        QBCore.PlayerData   = data
        QBCore.PlayerLoaded = true
        TriggerEvent('QBCore:Client:UpdateObject')
    end
end)

-- Player loaded / unloaded hooks.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.PlayerLoaded = true
    TriggerEvent('QBCore:Client:UpdateObject')
end)

RegisterNetEvent('QBCore:Client:PlayerUnload', function()
    QBCore.PlayerLoaded = false
    QBCore.PlayerData   = {}
end)

-- Job update hook.
RegisterNetEvent('QBCore:Client:SetJob', function(job)
    QBCore.PlayerData.job = job
    TriggerEvent('QBCore:Client:UpdateObject')
end)

-- ─── Public exports ───────────────────────────────────────────────────────────

exports('GetCoreObject', function()
    return QBCore
end)

AddEventHandler('QBCore:GetObject', function(cb)
    if type(cb) == 'function' then cb(QBCore) end
end)

-- Signal to the server that this client is ready.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('rgo_qb:playerReady')
    end
end)
