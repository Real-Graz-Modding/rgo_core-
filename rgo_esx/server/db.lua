--[[
    rgo_esx – Server: oxmysql adapter
    ====================================
    Thin wrapper around oxmysql exports so the rest of rgo_esx only calls
    local helpers.  Exposes generic query helpers AND ESX-specific helpers
    that back the groups-cache and player-data persistence.
--]]

local DB = {}

-- ─── Generic helpers ─────────────────────────────────────────────────────────

--- Execute a parameterised query and return the result set.
---@param query  string   SQL query with `?` placeholders
---@param params table    ordered list of parameter values
---@param cb     function optional callback; when nil the call blocks (sync)
---@return table|nil
function DB.query(query, params, cb)
    if cb then
        exports.oxmysql:query(query, params, cb)
    else
        return exports.oxmysql:query_async(query, params or {})
    end
end

--- Execute a query that is expected to return a single row.
---@param query  string
---@param params table
---@param cb     function|nil
---@return table|nil
function DB.single(query, params, cb)
    if cb then
        exports.oxmysql:single(query, params, cb)
    else
        return exports.oxmysql:single_async(query, params or {})
    end
end

--- Execute an INSERT/UPDATE/DELETE and return the affected row count / insert id.
---@param query  string
---@param params table
---@param cb     function|nil
---@return number|nil
function DB.execute(query, params, cb)
    if cb then
        exports.oxmysql:execute(query, params, cb)
    else
        return exports.oxmysql:execute_async(query, params or {})
    end
end

--- Execute a query and return the scalar value of the first column of the first row.
---@param query  string
---@param params table
---@param cb     function|nil
---@return any
function DB.scalar(query, params, cb)
    if cb then
        exports.oxmysql:scalar(query, params, cb)
    else
        return exports.oxmysql:scalar_async(query, params or {})
    end
end

-- ─── ESX-specific helpers ────────────────────────────────────────────────────

--- Load all groups (jobs) and their grades from the database.
--- Returns a table keyed by group name:
---   { [name] = { name, label, grades = { [grade] = gradeLabel } } }
---@return table
function DB.loadGroups()
    local rows = exports.oxmysql:query_async([[
        SELECT og.name, og.label, ogg.grade, ogg.label AS grade_label
        FROM ox_groups og
        LEFT JOIN ox_group_grades ogg ON ogg.`group` = og.name
        ORDER BY og.name, ogg.grade
    ]], {})

    local result = {}
    if rows then
        for _, row in ipairs(rows) do
            if not result[row.name] then
                result[row.name] = { name = row.name, label = row.label, grades = {} }
            end
            if row.grade then
                result[row.name].grades[row.grade] = row.grade_label
            end
        end
    end
    return result
end

--- Resolve a player's most-recently-played charId from their license identifier.
--- `license` is the full FiveM identifier string, e.g. "license2:abc123".
--- The `users.license2` column stores only the hash part ("abc123").
---@param license string   full identifier, e.g. "license2:abc123"
---@return number|nil
function DB.getCharId(license)
    -- Strip the "license2:" or "license:" prefix to get just the hash.
    local hash = license:match('^[^:]+:(.+)$') or license
    local row = exports.oxmysql:single_async([[
        SELECT c.charId
        FROM characters c
        JOIN users u ON u.userId = c.userId
        WHERE u.license2 = ? AND c.deleted IS NULL
        ORDER BY c.lastPlayed DESC
        LIMIT 1
    ]], { hash })
    return row and row.charId
end

--- Load a player's active job (group) from character_groups.
--- Returns a row with: name, grade, job_label, grade_label  or nil.
---@param charId number
---@return table|nil
function DB.getPlayerJob(charId)
    return exports.oxmysql:single_async([[
        SELECT cg.name, cg.grade, og.label AS job_label,
               COALESCE(ogg.label, CAST(cg.grade AS CHAR)) AS grade_label
        FROM character_groups cg
        JOIN ox_groups og ON og.name = cg.name
        LEFT JOIN ox_group_grades ogg
            ON ogg.`group` = cg.name AND ogg.grade = cg.grade
        WHERE cg.charId = ? AND cg.isActive = 1
        LIMIT 1
    ]], { charId })
end

--- Load a player's default personal bank account.
--- Returns a row with: id, balance  or nil.
---@param charId number
---@return table|nil
function DB.getPlayerBankAccount(charId)
    return exports.oxmysql:single_async(
        'SELECT id, balance FROM accounts WHERE owner = ? AND isDefault = 1 LIMIT 1',
        { charId }
    )
end

--- Upsert a player's active job in character_groups.
--- Clears the previous active group and sets the new one as active.
---@param charId    number
---@param groupName string
---@param grade     number
function DB.setPlayerJob(charId, groupName, grade)
    -- Clear all active flags for this character first
    exports.oxmysql:execute_async(
        'UPDATE character_groups SET isActive = 0 WHERE charId = ? AND isActive = 1',
        { charId }
    )
    -- Upsert the new job row using row alias syntax (compatible with MySQL 8.0.19+ and MariaDB 10.3+)
    exports.oxmysql:execute_async([[
        INSERT INTO character_groups (charId, name, grade, isActive)
        VALUES (?, ?, ?, 1) AS new_row
        ON DUPLICATE KEY UPDATE grade = new_row.grade, isActive = 1
    ]], { charId, groupName, grade or 1 })
end

--- Persist an account balance change to the accounts table.
---@param accountId number
---@param balance   number
function DB.setAccountBalance(accountId, balance)
    exports.oxmysql:execute_async(
        'UPDATE accounts SET balance = ? WHERE id = ?',
        { balance, accountId }
    )
end

return DB
