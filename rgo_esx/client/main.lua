--[[
    rgo_esx – Client: ESX compatibility layer
    ==========================================
    Provides the client-side ESX shared object and callback routing.

    Usage (client script):
        local ESX = exports['es_extended']:getSharedObject()
        -- or legacy pattern:
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
--]]

-- ─── Pending client callbacks ─────────────────────────────────────────────────
local PendingClientCallbacks = {}

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
        print(('[es_extended] WARNING: No client callback registered for "%s"'):format(name))
        TriggerServerEvent('rgo_esx:clientCallbackResult', cbId)
        return
    end

    handler(function(...)
        TriggerServerEvent('rgo_esx:clientCallbackResult', cbId, ...)
    end, table.unpack(args))
end)

-- ─── Notification helpers ──────────────────────────────────────────────────────

local function ShowNotification(msg, notifType)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, false)
end

local function ShowHelpNotification(msg, thisFrame, beep, duration)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandDisplayHelp(0, false, beep ~= false, duration or -1)
end

local function ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('[%s] %s: %s'):format(
        tostring(sender or ''), tostring(subject or ''), tostring(msg or '')
    ))
    EndTextCommandThefeedPostTicker(flash == true, true)
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

    -- Notifications
    ShowNotification         = ShowNotification,
    ShowHelpNotification     = ShowHelpNotification,
    ShowAdvancedNotification = ShowAdvancedNotification,

    -- Player data
    GetPlayerData = function()
        return ESX.PlayerData
    end,

    -- Config
    GetConfig = function()
        return {
            StartingAccountMoney = { bank = 5000 },
            Locale = 'en',
        }
    end,

    -- Utility
    Trace = function(msg)
        print('[es_extended] ' .. tostring(msg))
    end,

    SetTimeout = function(ms, cb)
        return SetTimeout(ms, cb)
    end,

    ClearTimeout = function(id)
        -- no-op (FiveM does not expose ClearTimeout natively)
    end,

    -- Job helpers
    GetPlayerJob = function()
        return ESX.PlayerData and ESX.PlayerData.job or {}
    end,

    -- Game object stubs (populated below to allow self-reference)
    Game = {},
}

-- Populate ESX.Game after ESX table is created so it can close over ESX.PlayerLoaded etc.
ESX.Game = {
    DeleteEntity = function(entity)
        if DoesEntityExist(entity) then
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end,

    SpawnVehicle = function(model, cb, coords, heading, isNetwork, netMissionEntity)
        model = type(model) == 'string' and GetHashKey(model) or model
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 100 do
            Wait(100)
            timeout = timeout + 1
        end
        if not HasModelLoaded(model) then
            if cb then cb(nil) end
            return
        end
        local c = coords or GetEntityCoords(PlayerPedId())
        local veh = CreateVehicle(model, c.x, c.y, c.z, heading or 0.0, isNetwork ~= false, netMissionEntity == true)
        SetModelAsNoLongerNeeded(model)
        if cb then cb(veh) end
        return veh
    end,

    SpawnObject = function(model, cb, coords, isNetwork)
        model = type(model) == 'string' and GetHashKey(model) or model
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 100 do
            Wait(100)
            timeout = timeout + 1
        end
        if not HasModelLoaded(model) then
            if cb then cb(nil) end
            return
        end
        local c = coords or GetEntityCoords(PlayerPedId())
        local obj = CreateObject(model, c.x, c.y, c.z, isNetwork ~= false, true, false)
        SetModelAsNoLongerNeeded(model)
        if cb then cb(obj) end
        return obj
    end,

    Utils = {
        GetClosestPlayer = function(coords, maxDistance)
            local ped = PlayerPedId()
            local myCoords = coords or GetEntityCoords(ped)
            local closestPlayer, closestDist = -1, maxDistance or 3.0

            for _, playerId in ipairs(GetActivePlayers()) do
                if playerId ~= PlayerId() then
                    local playerPed  = GetPlayerPed(playerId)
                    local playerCoords = GetEntityCoords(playerPed)
                    local dist = #(myCoords - playerCoords)
                    if dist < closestDist then
                        closestDist   = dist
                        closestPlayer = GetPlayerServerId(playerId)
                    end
                end
            end
            return closestPlayer, closestDist
        end,

        GetClosestVehicle = function(coords, maxDistance)
            local myCoords = coords or GetEntityCoords(PlayerPedId())
            local closestVehicle, closestDist = -1, maxDistance or 5.0
            local vehicles = GetGamePool('CVehicle')
            for _, veh in ipairs(vehicles) do
                local dist = #(myCoords - GetEntityCoords(veh))
                if dist < closestDist then
                    closestDist    = dist
                    closestVehicle = veh
                end
            end
            return closestVehicle, closestDist
        end,
    },
}

-- Populate PlayerData when the server reports the player is loaded.
RegisterNetEvent('esx:playerLoaded', function(playerData)
    ESX.PlayerLoaded = true
    ESX.PlayerData   = playerData
end)

-- ─── Public exports ───────────────────────────────────────────────────────────

exports('getSharedObject', function()
    return ESX
end)

AddEventHandler('esx:getSharedObject', function(cb)
    if type(cb) == 'function' then cb(ESX) end
end)

-- Signal to the server that this client is ready.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('rgo_esx:playerReady')
    end
end)
