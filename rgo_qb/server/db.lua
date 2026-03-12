--[[
    rgo_qb – Server: oxmysql adapter skeleton
    ===========================================
    Thin wrapper around oxmysql exports so the rest of rgo_qb only calls
    local helpers.  In MVP this just exposes the four most common operations;
    extend as needed.
--]]

local DB = {}

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

return DB
