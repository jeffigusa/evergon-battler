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
        stance = 'aggressive'
    }
    M.reset(unit)
    return unit
end

M.reset = function(unit)
    unit.target = nil
    unit.position = nil
    unit.momentum = vmath.vector3()
    unit.advance_attempts = 0
    unit.facing = 'right'
    unit.previous_position = nil
    unit.state = 'idle'
    unit.stance = nil
end

M.get_data = function(prototype)
    return M.units[prototype]
end

M.units = json.decode(sys.load_resource('/res/units.json')) M[""] = nil

return M