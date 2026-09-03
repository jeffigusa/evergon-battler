local utils = require 'main.utils.basic_utils'

local M = {}

M.database = json.decode(sys.load_resource('/res/terrain.json')) M[""] = nil

M.get_data = function(terrain_type)
    return M.database[terrain_type]
end

M.new = function(prototype)
    local prototype_data = M.get_data(prototype)
    local terrain = {
        id=utils.get_uid(),
        prototype = prototype,
    }

    return terrain
end

M.get_random_terrains = function()
    local r = {}
    for i = 1, 3 do
        local terrain_data = utils.random_from(M.database)
        local terrain = M.new(terrain_data.name)
        local w,h = terrain_data.size_x, terrain_data.size_y
        local hitbox_w = terrain_data.hitbox_x
        local hitbox_h = terrain_data.hitbox_y
        for attempt = 1, 1000 do
            local x = math.random(-400, 400)
            local y = math.random(-400 + h/2, 400 -h/2)
            local overlaps = false
            for _, v in ipairs(r) do
                local existing_terrain_data = M.get_data(v.prototype)
                if overlaps then utils.boxes_overlap({x=x,y=y,w=hitbox_w,h=hitbox_h}, {x=v.x,y=v.y,w=existing_terrain_data.hitbox_x.w,h=existing_terrain_data.hitbox_h}) break end
            end
            if not overlaps then
                terrain.x = x
                terrain.y = y
                terrain.w = w
                terrain.h = h
                table.insert(r, terrain)
                break
            end
        end
        
        table.insert(r, terrain)
    end
    return r
end

return M