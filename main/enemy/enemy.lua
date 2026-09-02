local utils = require 'main.utils.basic_utils'
local Unit = require 'main.unit.unit'
local M = {}

M.enemies = {}
M.add_enemy = function(prototype)
    local unit = Unit.new(prototype, 'enemy')
    table.insert(M.enemies, unit)
end
M.get_random_party = function(day)
    local party = {}
    local difficulty_points = 3 + day
    for i = 1, 999 do
        if difficulty_points <= 0 then break end
        local random_unit_data = utils.random_from(Unit.units)
        local x = 500 + math.random(0, 200)
        local y = 0 + math.random(-300, 300)
        local random_position = vmath.vector3(x,y,0)
        local unit = Unit.new(random_unit_data.name, 'enemy')
        unit.position=random_position
        table.insert(party, unit)
        difficulty_points = difficulty_points - random_unit_data.difficulty
    end
    return party
end

return M