local utils = require 'main.utils.basic_utils'
local Combatant = require 'main.combatant.combatant'
local M = {}

M.party = {}

M.day = 1

M.recruit = function(prototype)
    -- eventually swap this to a generic worker, and have the combatant data get generated in a different function to avoid combatant data from needing to be in the save file
    local combatant = Combatant.new(prototype, 'player')
    table.insert(M.party, combatant)
    table.sort(M.party, function(a, b) return a.prototype:sub(1,1) < b.prototype:sub(1,1) end)
end

M.update_party = function(new_party)
    M.party = new_party
end

return M