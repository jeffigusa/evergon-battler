local utils = require 'main.utils.basic_utils'
local Unit = require 'main.unit.unit'
local M = {}

M.party = {}

M.day = 1

M.recruit = function(prototype)
    -- eventually swap this to a generic worker, and have the unit data get generated in a different function to avoid unit data from needing to be in the save file
    local unit = Unit.new(prototype, 'player')
    table.insert(M.party, unit)
    table.sort(M.party, function(a, b) return a.prototype:sub(1,1) < b.prototype:sub(1,1) end)
end

M.update_party = function(new_party)
    M.party = new_party
end

return M