--[[
    rgo_esx – Server: ESX compatibility layer
    ==========================================
    Provides:
      • exports['es_extended']:getSharedObject()      (server export)
      • TriggerEvent('esx:getSharedObject', cb)        (legacy event pattern)
      • ESX.RegisterServerCallback / TriggerClientCallback
      • ESX.GetPlayerFromId / GetPlayers / GetPlayerFromIdentifier / GetExtendedPlayers
      • ESX.RegisterCommand / RegisterUsableItem / UseItem
      • xPlayer wrapper with full ESX 9.x API surface
      • Lifecycle events: esx:playerLoaded, esx:playerDropped, esx:setJob
--]]

-- ─── Internals ────────────────────────────────────────────────────────────────

-- Capture FiveM natives before any wrappers shadow them
local _RegisterCommand = RegisterCommand

---@type table<number, table>   source → xPlayer
local Players = {}

---@type table<string, function> name → handler
local ServerCallbacks = {}

---@type table<string, function> item name → usable handler
local UsableItems = {}

-- ESX config stub (mirrors es_extended Config table)
local ESXConfig = {
    StartingAccountMoney = { bank = 5000 },
    Locale = 'en',
    EnableDebug = false,
    Multichar = false,
}

-- Monotonic counter used to make callback IDs unique within the same tick.
local _cbCounter = 0
local function NextCbId(prefix)
    _cbCounter = _cbCounter + 1
    return ('%s_%s_%s'):format(prefix, GetGameTimer(), _cbCounter)
end

-- ─── xPlayer factory ─────────────────────────────────────────────────────────

---Build a minimal xPlayer wrapper around a connected player.
---@param source number
---@return table
local function BuildXPlayer(source)
    -- Basic identity from FiveM natives
    local identifiers = {}
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            local kind = id:match('^([^:]+):')
            if kind then identifiers[kind] = id end
        end
    end

    local license = identifiers['license2'] or identifiers['license'] or ('license:unknown_' .. tostring(source))

    -- Stub account/inventory/job structures (ESX 9.x defaults)
    local accounts = {
        { name = 'money',       label = 'Cash',         money = 0 },
        { name = 'bank',        label = 'Bank',         money = ESXConfig.StartingAccountMoney.bank },
        { name = 'black_money', label = 'Black Money',  money = 0 },
    }

    local job = { name = 'unemployed', label = 'Civilian', grade = 0, grade_label = 'Civilian', grade_salary = 0 }
    local inventory = {}

    local xPlayer = {
        source      = source,
        identifier  = license,
        name        = GetPlayerName(source) or 'Unknown',
        accounts    = accounts,
        inventory   = inventory,
        job         = job,
        loadout     = {},
        _loaded     = false,
        _group      = 'user',
        _metadata   = {},
    }

    -- ── Account helpers ────────────────────────────────────────────────────

    function xPlayer.getAccount(name)
        for _, acc in ipairs(xPlayer.accounts) do
            if acc.name == name then return acc end
        end
    end

    function xPlayer.addAccountMoney(name, amount)
        local acc = xPlayer.getAccount(name)
        if acc then acc.money = acc.money + math.max(0, amount) end
    end

    function xPlayer.removeAccountMoney(name, amount)
        local acc = xPlayer.getAccount(name)
        if acc then acc.money = math.max(0, acc.money - amount) end
    end

    function xPlayer.setAccountMoney(name, amount)
        local acc = xPlayer.getAccount(name)
        if acc then acc.money = math.max(0, amount) end
    end

    -- Convenience wrappers for the primary 'money' account
    function xPlayer.getMoney()      return xPlayer.getAccount('money') and xPlayer.getAccount('money').money or 0 end
    function xPlayer.addMoney(n)     xPlayer.addAccountMoney('money', n) end
    function xPlayer.removeMoney(n)  xPlayer.removeAccountMoney('money', n) end
    function xPlayer.setMoney(n)     xPlayer.setAccountMoney('money', n) end

    -- Convenience wrappers for the 'bank' account
    function xPlayer.getBankMoney()      return xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0 end
    function xPlayer.addBankMoney(n)     xPlayer.addAccountMoney('bank', n) end
    function xPlayer.removeBankMoney(n)  xPlayer.removeAccountMoney('bank', n) end
    function xPlayer.setBankMoney(n)     xPlayer.setAccountMoney('bank', n) end

    -- ── Identifier helper ──────────────────────────────────────────────────

    function xPlayer.getIdentifier()
        return xPlayer.identifier
    end

    -- ── Inventory helpers ──────────────────────────────────────────────────

    function xPlayer.getInventoryItem(name)
        for _, item in ipairs(xPlayer.inventory) do
            if item.name == name then return item end
        end
        return { name = name, count = 0, label = name, weight = 0 }
    end

    function xPlayer.addInventoryItem(name, count)
        local safeCount = math.max(0, count)
        if safeCount == 0 then return end
        local item = xPlayer.getInventoryItem(name)
        if item.count == 0 and item.weight == 0 then
            table.insert(xPlayer.inventory, { name = name, count = safeCount, label = name, weight = 0 })
        else
            item.count = item.count + safeCount
        end
    end

    function xPlayer.removeInventoryItem(name, count)
        for i, item in ipairs(xPlayer.inventory) do
            if item.name == name then
                item.count = math.max(0, item.count - count)
                if item.count == 0 then table.remove(xPlayer.inventory, i) end
                return true
            end
        end
        return false
    end

    function xPlayer.canCarryItem(name, count)
        return true
    end

    function xPlayer.getLoadout()
        return xPlayer.loadout
    end

    -- ── Job helpers ────────────────────────────────────────────────────────

    function xPlayer.getJob()
        return xPlayer.job
    end

    function xPlayer.setJob(name, grade)
        xPlayer.job = {
            name         = name,
            label        = name,
            grade        = grade or 0,
            grade_label  = tostring(grade or 0),
            grade_salary = 0,
        }
        TriggerClientEvent('esx:setJob', source, xPlayer.job)
        TriggerEvent('esx:setJob', source, xPlayer.job)
    end

    function xPlayer.hasJob(name, grade)
        if grade then
            return xPlayer.job.name == name and xPlayer.job.grade >= grade
        end
        return xPlayer.job.name == name
    end

    function xPlayer.isInJob(name)
        return xPlayer.job.name == name
    end

    -- ── Group / permission helpers ─────────────────────────────────────────

    function xPlayer.getGroup()
        return xPlayer._group
    end

    function xPlayer.setGroup(group)
        xPlayer._group = group
    end

    function xPlayer.getPermissions()
        return {}
    end

    -- ── Metadata helpers ──────────────────────────────────────────────────

    function xPlayer.get(key)
        return xPlayer._metadata[key]
    end

    function xPlayer.set(key, value)
        xPlayer._metadata[key] = value
    end

    -- ── Notification / kick helpers ───────────────────────────────────────

    function xPlayer.showNotification(msg, type)
        TriggerClientEvent('esx:showNotification', source, msg, type or 'inform')
    end

    function xPlayer.kick(reason)
        DropPlayer(source, reason or 'Kicked')
    end

    function xPlayer.triggerEvent(eventName, ...)
        TriggerClientEvent(eventName, source, ...)
    end

    -- ── Coords helpers (stubs) ────────────────────────────────────────────

    function xPlayer.getCoords(vector)
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            local c = GetEntityCoords(ped)
            return { x = c.x, y = c.y, z = c.z }
        end
        return { x = 0.0, y = 0.0, z = 0.0 }
    end

    return xPlayer
end

-- ─── Player lifecycle ─────────────────────────────────────────────────────────

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    -- xPlayer wird erst bei playerReady vollständig aufgebaut,
    -- um Race-Conditions beim Start zu vermeiden.
    -- Wir registrieren nur einen leeren Slot.
    local source = source
    -- Kein BuildXPlayer hier – nur Slot reservieren
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if source and Players[source] then
        TriggerEvent('esx:playerDropped', source, reason)
        Players[source] = nil
    end
end)

-- playerLoaded trigger – fires when a client signals it is ready.
RegisterNetEvent('rgo_esx:playerReady', function()
    local source = source
    if not Players[source] then
        Players[source] = BuildXPlayer(source)
    end

    local xPlayer = Players[source]
    xPlayer._loaded = true

    TriggerEvent('esx:playerLoaded', source, xPlayer)
    TriggerClientEvent('esx:playerLoaded', source, {
        identifier = xPlayer.identifier,
        name       = xPlayer.name,
        accounts   = xPlayer.accounts,
        inventory  = xPlayer.inventory,
        job        = xPlayer.job,
        loadout    = xPlayer.loadout,
    })
end)

-- ─── Server Callbacks ─────────────────────────────────────────────────────────

---Register a named server callback.
---@param name string        unique callback name
---@param cb   function      handler(source, resolve, reject, ...)
local function RegisterServerCallback(name, cb)
    ServerCallbacks[name] = cb
end

RegisterNetEvent('rgo_esx:triggerServerCallback', function(name, cbId, ...)
    local source = source
    local args   = { ... }

    local handler = ServerCallbacks[name]
    if not handler then
        print(('[es_extended] WARNING: No server callback registered for "%s"'):format(name))
        TriggerClientEvent('rgo_esx:serverCallbackResult', source, cbId, false)
        return
    end

    local function resolve(...)
        TriggerClientEvent('rgo_esx:serverCallbackResult', source, cbId, true, ...)
    end

    local function reject(err)
        TriggerClientEvent('rgo_esx:serverCallbackResult', source, cbId, false, err)
    end

    handler(source, resolve, reject, table.unpack(args))
end)

---Route a server-initiated callback to a specific client.
local function TriggerClientCallback(name, source, cb, ...)
    local cbId      = NextCbId(name .. '_' .. source)
    local eventName = 'rgo_esx:clientCallbackResult_' .. cbId
    TriggerClientEvent('rgo_esx:triggerClientCallback', source, name, cbId, ...)

    local listener
    listener = AddEventHandler(eventName, function(...)
        cb(...)
        RemoveEventHandler(listener)
        listener = nil
    end)

    SetTimeout(30000, function()
        if listener then
            RemoveEventHandler(listener)
            listener = nil
        end
    end)
end

RegisterNetEvent('rgo_esx:clientCallbackResult', function(cbId, ...)
    local args = { ... }
    TriggerEvent('rgo_esx:clientCallbackResult_' .. cbId, table.unpack(args))
end)

-- ─── Usable items – handle trigger from client ────────────────────────────────

RegisterNetEvent('rgo_esx:useItem', function(name)
    local source  = source
    local handler = UsableItems[name]
    if handler then
        local xPlayer = Players[source]
        if xPlayer then handler(source, xPlayer) end
    end
end)

-- ─── ESX Shared Object ────────────────────────────────────────────────────────

local ESX = {
    -- ESX version string – reported by ox_lib version checks (must be >= 1.6.0)
    version = '1.9.4',

    -- Player accessors
    GetPlayerFromId = function(source)
        return Players[source]
    end,

    GetPlayerFromIdentifier = function(identifier)
        for _, xPlayer in pairs(Players) do
            if xPlayer.identifier == identifier then return xPlayer end
        end
    end,

    GetPlayers = function()
        local result = {}
        for source in pairs(Players) do
            result[#result + 1] = source
        end
        return result
    end,

    GetExtendedPlayers = function(key, val)
        local result = {}
        for _, xPlayer in pairs(Players) do
            if not key or xPlayer[key] == val then
                result[#result + 1] = xPlayer
            end
        end
        return result
    end,

    IsPlayerLoaded = function(source)
        return Players[source] ~= nil and Players[source]._loaded == true
    end,

    -- Callback API
    RegisterServerCallback = RegisterServerCallback,
    TriggerClientCallback  = TriggerClientCallback,

    -- Command registration (wraps FiveM native RegisterCommand)
    RegisterCommand = function(name, group, cb, arguments, description, allowConsole)
        if type(group) == 'function' then
            -- Called as RegisterCommand(name, cb, arguments, description) – no group
            cb, arguments, description, allowConsole = group, cb, arguments, description
            group = 'user'
        end
        _RegisterCommand(name, function(source, args, rawCommand)
            local xPlayer = Players[source]
            if source ~= 0 and not xPlayer then return end
            cb(source, args, rawCommand)
        end, allowConsole == true)
    end,

    -- Usable items
    RegisterUsableItem = function(name, cb)
        UsableItems[name] = cb
    end,

    UseItem = function(source, name)
        local handler = UsableItems[name]
        if handler then
            local xPlayer = Players[source]
            if xPlayer then handler(source, xPlayer) end
        end
    end,

    -- Direct inventory shortcuts (operate on a player by source)
    AddInventoryItem = function(source, name, count)
        local xPlayer = Players[source]
        if xPlayer then xPlayer.addInventoryItem(name, count) end
    end,

    RemoveInventoryItem = function(source, name, count)
        local xPlayer = Players[source]
        if xPlayer then xPlayer.removeInventoryItem(name, count) end
    end,

    -- Config
    GetConfig = function()
        return ESXConfig
    end,

    -- Utility
    Trace = function(msg)
        print('[es_extended] ' .. tostring(msg))
    end,
}

-- ─── Public exports ───────────────────────────────────────────────────────────

exports('getSharedObject', function()
    return ESX
end)

AddEventHandler('esx:getSharedObject', function(cb)
    if type(cb) == 'function' then cb(ESX) end
end)

print('[es_extended] ESX compatibility layer started (v1.9.4)')
