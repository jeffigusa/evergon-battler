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
        target = nil,
        position = nil,
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
    ranged = {
        hp = 10,
        is_ranged = true,
        range = 200,
        attack = 2,
        defense = 1,
        attack_animation = 'ranged_1_attack',
        idle_animation = 'ranged_1_idle',
        projectile_animation = 'projectile_ranged_1',
        projectile_launch_delay = 0.5,
        projectile_speed = 400
    },
    normal = {
        attack_animation = 'melee_1_attack',
        idle_animation = 'melee_1_idle'
    },
    tough = {
        hp = 30,
        attack_animation = 'melee_1_attack',
        idle_animation = 'melee_1_idle'
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
    range = 50,
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