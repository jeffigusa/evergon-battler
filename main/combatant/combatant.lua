local utils = require 'main.utils.basic_utils'
local M = {}

M.new = function(prototype, team)
    local prototype_data = M.get_data(prototype)
    local combatant = {
        id=utils.get_uid(),
        prototype = prototype,
        hp = prototype_data.hp,
        max_hp = prototype_data.hp,
        statuses = {},
        team = team,
    }
    M.reset(combatant)
    return combatant
end

M.reset = function(combatant)
    combatant.target = nil
    combatant.position = nil
    combatant.momentum = vmath.vector3()
    combatant.advance_attempts = 0
    combatant.facing = 'right'
    combatant.previous_position = nil
    combatant.state = 'idle'
end

M.get_data = function(prototype)
    return M.combatants[prototype]
end

M.combatants = {
    ranged = {
        name = 'ranged',
        hp = 10,
        is_ranged = true,
        range = 300,
        attack = 3,
        defense = 1,
        attack_animation = 'ranged_1_attack',
        idle_animation = 'ranged_1_idle',
        projectile_animation = 'projectile_ranged_1',
        projectile_launch_delay = 0.5,
        projectile_speed = 400
    },
    normal = {
        name = 'normal',
        attack_animation = 'melee_1_attack',
        idle_animation = 'melee_1_idle'
    },
    defensive = {
        name = 'defensive',
        hp = 40,
        attack_animation = 'defensive_1_attack',
        idle_animation = 'defensive_1_idle',
        attack_speed = 0.8,
        difficulty = 2
    },
}

local combatant_defaults = {
    hp = 30,
    attack = 3,
    attack_speed = 1,
    defense = 2,
    range = 50,
    move_speed = 150,
    radius = 40,
    tags = {},
    difficulty = 1
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