local utils = require 'main.utils.basic_utils'
local M = {}

M.new = function(prototype, team)
    local prototype_data = M.get_data(prototype)
    local unit = {
        id=utils.get_uid(),
        prototype = prototype,
        hp = prototype_data.hp,
        max_hp = prototype_data.hp,
        statuses = {},
        team = team,
    }
    return unit
end

M.has_status = function(status_name, unit) for i, v in ipairs(unit.statuses) do if hash(v.name) == hash(status_name) then return true end end end
M.apply_status = function(status_name, unit, duration)
    local status = {
        name = status_name,
        duration = duration
    }
    table.insert(unit.statuses, status)
end
M.remove_status = function(status_name, unit)
    utils.remove_all(unit.statuses, function(v) return hash(v.name) == hash(status_name) end)
end

M.get_data = function(prototype)
    return M.units[prototype]
end

M.units = json.decode(sys.load_resource('/res/units.json')) M[""] = nil

return M