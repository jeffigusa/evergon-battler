local utils = require 'main.utils.basic_utils'
local Unit = require 'main.unit.unit'

local M = {}

-- returns n unique unit prototypes
M.get_recruit_options = function(n)
    local r = {}
    local options = Unit.units -- TODO: remove enemy unit types from the pool
    local units = utils.unique_randoms_from(options, n)
    for i, v in ipairs(units) do table.insert(r, v.prototype) end
    utils.shuffle(r)
    return r
end

return M