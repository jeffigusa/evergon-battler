local utils = require 'main.utils.utils'
local M = {}

M.new = function(prototype, team, position)
    local prototype_data = M.get_data(prototype)
    local combatant = {
        id=utils.get_uid(),
        prototype = prototype,
        hp = prototype_data.hp,
        max_hp = prototype_data.hp,
        statuses = {},
        team = team,
        target = nil,
        position = position,
        momentum = vmath.vector3(),
        advance_attempts = 0,
        facing = 'right',
        previous_position = nil,
        state = 'idle'
    }
    return combatant
end

M.get_data = function(prototype)
    return M.combatants[prototype]
end

M.combatants = {
    weak = {
        hp = 10,
        range = 200,
        attack = 2,
        defense = 1
    },
    normal = {},
    tough = {
        hp = 30,
    },
    strong = {
        attack = 5,
    },
}

local combatant_defaults = {
    hp = 20,
    attack = 3,
    attack_speed = 1,
    defense = 2,
    range = 60,
    move_speed = 150,
    radius = 40,
    tags = {}
}

for k, v in pairs(M.combatants) do
    for kd, vd in pairs(combatant_defaults) do
        if not v[kd] then
            if hash(type(vd)) == hash('table') then
                v[kd] = {}
            else
                v[kd] = vd
            end
        end
    end
end

return M