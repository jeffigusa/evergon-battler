local utils = require 'main.utils.basic_utils'
local M = {}

M.screen = {}

M.handle_window_resized = function()
    local device, standard = {}, {}
    device.x, device.y = window.get_size()
    standard.x, standard.y = gui.get_width(), gui.get_height()
    M.screen.x_ratio = math.max(device.x / device.y * standard.y / standard.x, 1)
    M.screen.y_ratio = math.max(device.y / device.x * standard.x / standard.y, 1)
    M.screen.deadspace_offset = {
        x=standard.x * (M.screen.x_ratio - 1) / 2,
        y=standard.y * (M.screen.y_ratio - 1) / 2,
    }
end

-- Take a gui box element and subdivide it into a grid of areas. Area = {size=, position=(screen position)}
M.subdivide_area = function(gui_box_node, rows, cols)
    local num_cols = cols or 1
    local num_rows = rows or 1
    local size = gui.get_size(gui_box_node)
    local position = M.get_absolute_position(gui_box_node)
    local col_width = size.x / num_cols
    local row_height = size.y / num_rows
    local areas = {}
    for i = 1, (num_rows or 1) do
        for j = 1, (num_cols or 1) do
            local area = {}
            local x = size.x/2 - (j - 1/2) * col_width
            local y = -size.y/2 + (i - 1/2) * row_height
            area.position = vmath.vector3(position.x + x, position.y + y, 0)
            area.size = vmath.vector3(col_width, row_height, 0)
            table.insert(areas, 1, area)
        end
    end
    return areas
end

M.distribute_nodes_x = function(nodes, width)
    local spacing = width/#nodes
    for i, node in ipairs(nodes) do
        local x = -width/2 + spacing/2 + (i-1)*spacing
        gui.set(node, 'position.x', x)
    end
end

M.distribute_nodes_y = function(nodes, height)
    local spacing = height/#nodes
    for i, node in ipairs(nodes) do
        local y = -height/2 + spacing/2 + (i-1)*spacing
        gui.set(node, 'position.y', y)
    end
end

M.get_absolute_position = function(node)
    local position = gui.get_position(node)
    local parent = gui.get_parent(node)
    if parent then
        position = position + M.get_absolute_position(parent)
    end
    return position
end

-- move a node to the position of another node. the node being moved will be removed of its parent
M.move_to_node = function(node, to_node)
    gui.set_parent(node, to_node)
    gui.set_position(node, vmath.vector3())
    gui.set_parent(node, nil, true)
end

M.input_position_to_world = function(position)
    local r = position
    if M.screen.x_ratio > 1 then
        r.x = r.x * M.screen.x_ratio
    else
        r.y = r.y * M.screen.y_ratio
    end
    return r
end

M.set_texture = function(node, texture, flipbook)
    gui.set_texture(node, texture)
    gui.play_flipbook(node, flipbook)
end

M.set_texture_with_default_placeholder = function(node, texture, flipbook, placeholder_flipbook)
    gui.set_texture(node, texture)
    if pcall(gui.play_flipbook, node, flipbook) then
        gui.play_flipbook(node, flipbook)
    else
        gui.play_flipbook(node, placeholder_flipbook)
    end
end

M.text_counter_tick = function(text_node, num_current, num_end, _params)
    local params = _params or {}
    local current = num_current
    local mode = (num_end - num_current) / math.abs(num_end-num_current)
    local my_timer
    my_timer = timer.delay(params.dt or 0.1, true, function()
        if (mode == 1 and current < num_end) or (mode == -1 and current > num_end) then
            current= current + (params.interval or 1) * mode
            if (mode==1) then current = math.min(current, num_end)
            else current = math.max(current, num_end) end
            gui.set_text(text_node, current)
        else
            timer.cancel(my_timer)
            if params.callback then params.callback() end
        end
    end)
end


-- WIP
M.fit_text = function(text_node, _size)
    local size = _size or gui.get_size(text_node)
    local function fit_iterate()
        local dimensions = gui.get_text_metrics_from_node(text_node)
        local x_ratio = math.min(size.x/dimensions.width, 1)
        local y_ratio = math.min(size.y/dimensions.height, 1)
        local shrink_by = math.min(x_ratio, y_ratio)
        gui.set(text_node, 'scale', vmath.vector3(shrink_by))
        gui.set(text_node, 'size.x', size.x / shrink_by)
        gui.set(text_node, 'size.y', size.y / shrink_by)
    end
    fit_iterate()
end


return M