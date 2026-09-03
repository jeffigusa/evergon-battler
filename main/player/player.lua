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
    pprint('added unit:', unit)
end

M.update_party = function(combat_units)
    for i, v in ipairs(combat_units) do
        local unit = utils.search(M.party, function(w) return w.id == v.id end)

        -- update hp
        unit.hp = v.hp
    end

    -- units that did not survive receive wounded status. if already wounded, remove
    local unit_died_in_combat = function(unit) return not utils.contains(combat_units, function(v) return unit.id == v.id end) end
    utils.remove_all(M.party, function(v) return Unit.has_status('wounded', v) and unit_died_in_combat(v) end)
    for i, unit in ipairs(M.party) do
        if unit_died_in_combat(unit) then Unit.apply_status('wounded', unit) unit.hp = math.ceil(unit.max_hp * 0.1) print('unit was wounded') end
    end
end

return M