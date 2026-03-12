--[[
    rgo_esx – Server: ESX compatibility layer
    ==========================================
    Provides:
      • exports['rgo_esx']:getSharedObject()         (server export)
      • TriggerEvent('esx:getSharedObject', cb)       (legacy event pattern)
      • ESX.RegisterServerCallback / TriggerClientCallback
      • ESX.GetPlayerFromId / GetPlayers / GetPlayerFromIdentifier
      • xPlayer wrapper with minimal ESX 9.x API surface
      • Lifecycle events: esx:playerLoaded, esx:playerDropped, esx:setJob

    NOTE: This is an MVP.  See rgo_esx/README.md for the full compatibility
    matrix and roadmap.
--]]

-- ─── Internals ────────────────────────────────────────────────────────────────

---@type table<number, table>   source → xPlayer
local Players = {}

---@type table<string, function> name → handler
local ServerCallbacks = {}

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
        { name = 'bank',        label = 'Bank',         money = 0 },
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
        -- internal flag
        _loaded     = false,
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

    -- ── Inventory helpers ──────────────────────────────────────────────────

    function xPlayer.getInventoryItem(name)
        for _, item in ipairs(xPlayer.inventory) do
            if item.name == name then return item end
        end
        return { name = name, count = 0, label = name, weight = 0 }
    end

    function xPlayer.addInventoryItem(name, count)
        local item = xPlayer.getInventoryItem(name)
        if item.count == 0 and item.weight == 0 then
            -- item not yet in player inventory – add stub entry
            table.insert(xPlayer.inventory, { name = name, count = count, label = name, weight = 0 })
        else
            item.count = item.count + math.max(0, count)
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
        -- Stub: always allow.  Replace with weight/slot logic as needed.
        return true
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

    -- ── Group / permission stub ────────────────────────────────────────────

    function xPlayer.getGroup()
        return 'user'
    end

    function xPlayer.getPermissions()
        return {}
    end

    -- ── Notification helper ───────────────────────────────────────────────

    function xPlayer.showNotification(msg, type)
        TriggerClientEvent('esx:showNotification', source, msg, type or 'inform')
    end

    function xPlayer.kick(reason)
        DropPlayer(source, reason or 'Kicked')
    end

    return xPlayer
end

-- ─── Player lifecycle ─────────────────────────────────────────────────────────

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    Players[source] = BuildXPlayer(source)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if Players[source] then
        TriggerEvent('esx:playerDropped', source, reason)
        Players[source] = nil
    end
end)

-- playerLoaded trigger – fires when a client signals it is ready.
-- Other resources can listen to 'esx:playerLoaded'.
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
        print(('[rgo_esx] WARNING: No server callback registered for "%s"'):format(name))
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
---@param name   string
---@param source number
---@param cb     function   server-side handler called with client response
---@param ...    any        extra args forwarded to the client
local function TriggerClientCallback(name, source, cb, ...)
    local cbId    = NextCbId(name .. '_' .. source)
    local eventName = 'rgo_esx:clientCallbackResult_' .. cbId
    TriggerClientEvent('rgo_esx:triggerClientCallback', source, name, cbId, ...)

    -- One-shot listener for the response
    local listener
    listener = AddEventHandler(eventName, function(...)
        cb(...)
        RemoveEventHandler(listener)
        listener = nil
    end)

    -- Timeout: clean up the listener after 30 seconds if the client never responds.
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

-- ─── ESX Shared Object ────────────────────────────────────────────────────────

local ESX = {
    version = '9.0.2.0-rgo_esx',

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

    -- Callback API
    RegisterServerCallback  = RegisterServerCallback,
    TriggerClientCallback   = TriggerClientCallback,

    -- Utility
    Trace = function(msg)
        print('[rgo_esx] ' .. tostring(msg))
    end,
}

-- ─── Public exports ───────────────────────────────────────────────────────────

---Export: exports['rgo_esx']:getSharedObject()
exports('getSharedObject', function()
    return ESX
end)

---Legacy event: TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
AddEventHandler('esx:getSharedObject', function(cb)
    if type(cb) == 'function' then cb(ESX) end
end)

print('[rgo_esx] ESX compatibility layer started (MVP v1.0.0)')
