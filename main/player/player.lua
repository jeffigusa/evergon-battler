local Combatant = require 'main.combatant.combatant'
local M = {}

M.party = {}

M.recruit = function(prototype)
    -- eventually swap this to a generic worker, and have the combatant data get generated in a different function to avoid combatant data from needing to be in the save file
    local combatant = Combatant.new(prototype, 'player')
    table.insert(M.party, combatant)
end

return M