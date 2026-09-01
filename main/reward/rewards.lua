local utils = require 'main.utils.basic_utils'
local Combatant = require 'main.combatant.combatant'

local M = {}

-- returns n unique unit prototypes
M.get_recruit_options = function(n)
    local r = {}
    local options = Combatant.combatants -- TODO: remove enemy unit types from the pool
    local combatants = utils.unique_randoms_from(options, n)
    for i, v in ipairs(combatants) do table.insert(r, v.prototype) end
    utils.shuffle(r)
    return r
end

return M