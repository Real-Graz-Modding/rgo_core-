--[[
    rgo_qb – Server: QBCore compatibility layer
    =============================================
    Provides:
      • exports['rgo_qb']:GetCoreObject()              (server export)
      • TriggerEvent('QBCore:GetObject', cb)            (legacy event pattern)
      • QBCore.Functions.GetPlayer / GetPlayers / GetPlayerByCitizenId
      • QBCore.Functions.CreateCallback / TriggerCallback (server→client routing)
      • QBCore.Functions.Notify / HasPermission / AddPermission / RemovePermission
      • Player wrapper (PlayerData, money, job, inventory, kick, notify)
      • Lifecycle events:
          QBCore:Server:OnPlayerLoaded  (server)
          QBCore:Server:PlayerUnload    (server)
          QBCore:Server:SetJob          (server)

    NOTE: This is an MVP.  See rgo_qb/README.md for the full compatibility
    matrix and roadmap.
--]]

-- ─── Internals ────────────────────────────────────────────────────────────────

---@type table<number, table>   source → Player
local Players = {}

---@type table<string, function> name → handler
local ServerCallbacks = {}

-- Monotonic counter used to make callback IDs unique within the same tick.
local _cbCounter = 0
local function NextCbId(prefix)
    _cbCounter = _cbCounter + 1
    return ('%s_%s_%s'):format(prefix, GetGameTimer(), _cbCounter)
end

-- ─── Player factory ───────────────────────────────────────────────────────────

---Build a minimal QBCore Player wrapper around a connected player.
---@param source number
---@return table
local function BuildPlayer(source)
    -- Collect all identifiers
    local identifiers = {}
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            local kind = id:match('^([^:]+):')
            if kind then identifiers[kind] = id end
        end
    end

    local license = identifiers['license2'] or identifiers['license'] or ('license:unknown_' .. tostring(source))

    -- Deterministic citizenid stub – TODO: replace with DB-driven generation so IDs
    -- are stable across reconnects and source reuse is handled correctly.
    local citizenid = ('STRT' .. string.format('%06d', source))

    -- QB money types
    local money = { cash = 0, bank = 0, crypto = 0 }

    -- QB job structure
    local job = {
        name       = 'unemployed',
        label      = 'Civilian',
        grade      = { level = 0, name = 'Recruit', salary = 0 },
        onduty     = false,
        isboss     = false,
    }

    -- QB gang structure (stub)
    local gang = {
        name  = 'none',
        label = 'No Gang',
        grade = { level = 0, name = 'Member' },
        isboss = false,
    }

    -- QB metadata stub
    local metadata = {
        hunger    = 100,
        thirst    = 100,
        stress    = 0,
        isdead    = false,
        inlaststand = false,
        armor     = 0,
        ishandcuffed = false,
        tracker   = false,
        lastEdit  = os.date('%Y-%m-%d %H:%M:%S'),
    }

    -- PlayerData table (matches QB structure scripts read directly)
    local PlayerData = {
        source     = source,
        name       = GetPlayerName(source) or 'Unknown',
        license    = license,
        citizenid  = citizenid,
        money      = money,
        job        = job,
        gang       = gang,
        position   = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
        metadata   = metadata,
        inventory  = {},
        items      = {},
        charinfo   = {
            firstname  = 'Unknown',
            lastname   = 'Player',
            birthdate  = '01-01-2000',
            gender     = 0,
            nationality = 'Unknown',
            phone      = '0000000',
            account    = '000000000',
        },
        permission = { primary = 'user', secondary = {} },
    }

    -- ── Functions ──────────────────────────────────────────────────────────

    local Functions = {}

    -- Money
    function Functions.GetMoney(type)
        return PlayerData.money[type] or 0
    end

    function Functions.AddMoney(type, amount, reason)
        if PlayerData.money[type] ~= nil then
            PlayerData.money[type] = PlayerData.money[type] + math.max(0, amount)
            TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
        end
    end

    function Functions.RemoveMoney(type, amount, reason)
        if PlayerData.money[type] ~= nil then
            PlayerData.money[type] = math.max(0, PlayerData.money[type] - amount)
            TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
        end
    end

    function Functions.SetMoney(type, amount, reason)
        if PlayerData.money[type] ~= nil then
            PlayerData.money[type] = math.max(0, amount)
            TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
        end
    end

    -- Job
    function Functions.GetJob()
        return PlayerData.job
    end

    function Functions.SetJob(name, grade)
        local gradeLevel = tonumber(grade) or 0
        PlayerData.job = {
            name   = name,
            label  = name,
            grade  = { level = gradeLevel, name = tostring(gradeLevel), salary = 0 },
            onduty = true,
            isboss = false,
        }
        TriggerClientEvent('QBCore:Client:SetJob', source, PlayerData.job)
        TriggerEvent('QBCore:Server:SetJob', source, PlayerData.job)
        TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
    end

    -- Gang
    function Functions.GetGang()
        return PlayerData.gang
    end

    function Functions.SetGang(name, grade)
        local gradeLevel = tonumber(grade) or 0
        PlayerData.gang = {
            name   = name,
            label  = name,
            grade  = { level = gradeLevel, name = tostring(gradeLevel) },
            isboss = false,
        }
        TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
    end

    -- Inventory
    function Functions.GetItemByName(item)
        for _, v in ipairs(PlayerData.inventory) do
            if v.name == item then return v end
        end
    end

    function Functions.HasItem(item, amount)
        local entry = Functions.GetItemByName(item)
        return entry ~= nil and entry.amount >= (amount or 1)
    end

    function Functions.AddItem(item, amount, slot, info)
        local entry = Functions.GetItemByName(item)
        if entry then
            entry.amount = entry.amount + math.max(0, amount or 1)
        else
            table.insert(PlayerData.inventory, {
                name   = item,
                amount = amount or 1,
                info   = info or {},
                label  = item,
                slot   = slot or (#PlayerData.inventory + 1),
            })
        end
        TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
        return true
    end

    function Functions.RemoveItem(item, amount, slot)
        for i, v in ipairs(PlayerData.inventory) do
            if v.name == item then
                v.amount = math.max(0, v.amount - (amount or 1))
                if v.amount == 0 then table.remove(PlayerData.inventory, i) end
                TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
                return true
            end
        end
        return false
    end

    -- Metadata
    function Functions.GetMetaData(key)
        return key and PlayerData.metadata[key] or PlayerData.metadata
    end

    function Functions.SetMetaData(key, value)
        PlayerData.metadata[key] = value
        TriggerClientEvent('QBCore:Player:SetPlayerData', source, PlayerData)
    end

    -- Notifications
    function Functions.Notify(text, type, length)
        TriggerClientEvent('QBCore:Notify', source, text, type or 'primary', length or 5000)
    end

    -- Kick
    function Functions.Kick(reason)
        DropPlayer(source, reason or 'Kicked')
    end

    -- Stub save (no-op until DB persistence is wired)
    function Functions.Save()
        -- TODO: persist PlayerData to database via DB helpers
    end

    -- ── Assemble the Player object ─────────────────────────────────────────

    local Player = {
        PlayerData = PlayerData,
        Functions  = Functions,
        -- Internal flag
        _loaded    = false,
    }

    return Player
end

-- ─── Player lifecycle ─────────────────────────────────────────────────────────

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    Players[source] = BuildPlayer(source)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if Players[source] then
        TriggerEvent('QBCore:Server:PlayerUnload', source)
        Players[source] = nil
    end
    -- Clean up any permissions for this source.
    Permissions[source] = nil
end)

-- playerLoaded trigger – fires when a client signals it is ready.
RegisterNetEvent('rgo_qb:playerReady', function()
    local source = source
    if not Players[source] then
        Players[source] = BuildPlayer(source)
    end

    local Player = Players[source]
    Player._loaded = true

    TriggerEvent('QBCore:Server:OnPlayerLoaded', source, Player)
    TriggerClientEvent('QBCore:Client:OnPlayerLoaded', source)
    TriggerClientEvent('QBCore:Player:SetPlayerData', source, Player.PlayerData)
end)

-- ─── Server Callbacks ─────────────────────────────────────────────────────────

---Register a named server callback.
---@param name string     unique callback name
---@param cb   function   handler(source, resolve, reject, ...)
local function CreateCallback(name, cb)
    ServerCallbacks[name] = cb
end

---Trigger a server callback from the server side (routes to a specific client).
---@param name   string
---@param source number
---@param cb     function  server-side handler for the client response
---@param ...    any
local function TriggerCallback(name, source, cb, ...)
    local cbId      = NextCbId(name .. '_' .. source)
    local eventName = 'rgo_qb:clientCallbackResult_' .. cbId
    TriggerClientEvent('rgo_qb:triggerClientCallback', source, name, cbId, ...)

    local listener
    listener = AddEventHandler(eventName, function(...)
        cb(...)
        RemoveEventHandler(listener)
        listener = nil
    end)

    -- Timeout: clean up after 30 s if the client never responds.
    SetTimeout(30000, function()
        if listener then
            RemoveEventHandler(listener)
            listener = nil
        end
    end)
end

-- Handle callbacks triggered from clients.
RegisterNetEvent('rgo_qb:triggerServerCallback', function(name, cbId, ...)
    local source = source
    local args   = { ... }

    local handler = ServerCallbacks[name]
    if not handler then
        print(('[rgo_qb] WARNING: No server callback registered for "%s"'):format(name))
        TriggerClientEvent('rgo_qb:serverCallbackResult', source, cbId)
        return
    end

    local function resolve(...)
        TriggerClientEvent('rgo_qb:serverCallbackResult', source, cbId, ...)
    end

    local function reject(err)
        TriggerClientEvent('rgo_qb:serverCallbackResult', source, cbId)
        print(('[rgo_qb] Callback "%s" rejected: %s'):format(name, tostring(err)))
    end

    handler(source, resolve, reject, table.unpack(args))
end)

RegisterNetEvent('rgo_qb:clientCallbackResult', function(cbId, ...)
    local args = { ... }
    TriggerEvent('rgo_qb:clientCallbackResult_' .. cbId, table.unpack(args))
end)

-- ─── Permission stubs ─────────────────────────────────────────────────────────

local Permissions = {}   -- source → set of permission strings

local function HasPermission(source, permission)
    if not Permissions[source] then return false end
    return Permissions[source][permission] == true
end

local function AddPermission(source, permission)
    if not Permissions[source] then Permissions[source] = {} end
    Permissions[source][permission] = true
end

local function RemovePermission(source, permission)
    if Permissions[source] then Permissions[source][permission] = nil end
end


-- ─── QBCore Shared Object ─────────────────────────────────────────────────────

local QBCore = {
    Version = '1.0.0-rgo_qb',
    Config  = {
        Locale     = 'en',
        Money      = { MoneyTypes = { cash = 500, bank = 5000, crypto = 0 } },
        Server     = { name = 'rgo Server', discord = '', cfxid = '', prefix = '/' },
        MaxPlayers = 64,
    },
    Shared = {
        Jobs   = {},
        Gangs  = {},
        Items  = {},
        Vehicles = {},
    },

    Functions = {
        -- Player accessors
        GetPlayer = function(source)
            return Players[source]
        end,

        GetPlayers = function()
            local result = {}
            for src in pairs(Players) do
                result[#result + 1] = src
            end
            return result
        end,

        GetPlayerByCitizenId = function(citizenid)
            for _, Player in pairs(Players) do
                if Player.PlayerData.citizenid == citizenid then return Player end
            end
        end,

        GetPlayerByPhone = function(phone)
            for _, Player in pairs(Players) do
                if Player.PlayerData.charinfo and Player.PlayerData.charinfo.phone == phone then
                    return Player
                end
            end
        end,

        -- Callbacks
        CreateCallback  = CreateCallback,
        TriggerCallback = TriggerCallback,

        -- Permissions
        HasPermission    = HasPermission,
        AddPermission    = AddPermission,
        RemovePermission = RemovePermission,

        IsOptin = function(source)
            return false
        end,

        -- Notifications
        Notify = function(source, text, type, length)
            TriggerClientEvent('QBCore:Notify', source, text, type or 'primary', length or 5000)
        end,

        -- Utility
        GetIdentifier = function(source, idType)
            for i = 0, GetNumPlayerIdentifiers(source) - 1 do
                local id = GetPlayerIdentifier(source, i)
                if id and id:match('^' .. (idType or 'license') .. ':') then return id end
            end
        end,

        GetCoords = function(entity)
            local coords = GetEntityCoords(entity)
            return { x = coords.x, y = coords.y, z = coords.z }
        end,
    },
}

-- ─── Public exports ───────────────────────────────────────────────────────────

---Export: exports['rgo_qb']:GetCoreObject()
exports('GetCoreObject', function()
    return QBCore
end)

---Legacy event: TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
AddEventHandler('QBCore:GetObject', function(cb)
    if type(cb) == 'function' then cb(QBCore) end
end)

print('[rgo_qb] QBCore compatibility layer started (MVP v1.0.0)')
