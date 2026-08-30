local M = {}

local User = {
    is_dragging = false,
    is_pressing = false
}

local get_picked = function(instance, x, y) local r = {} for k, v in ipairs(instance.mygui.interactables) do if v.enabled and gui.pick_node(v.node, x, y) then table.insert(r,v) end end return r end
local get_unpicked = function(instance, x, y) local r = {} for k, v in ipairs(instance.mygui.interactables) do if not gui.pick_node(v.node, x, y) then table.insert(r,v) end end return r end
local get_picked_unpicked = function(instance, x, y) local p, u = {}, {} for k, v in ipairs(instance.mygui.interactables) do if v.enabled and gui.pick_node(v.node, x, y) then table.insert(p,v) else table.insert(u, v) end end return p, u end
local get_all = function(instance) return instance.mygui.interactables end
local filter_type = function(interactables, interactable_type)
    local r = {}
    for k, v in pairs(interactables) do if v['is_'..interactable_type] then table.insert(r, v) end end
    return r
end
local get_all_type = function(instance, interactable_type) return filter_type(get_all(instance), interactable_type) end
local get_topmost = function(interactables, layer_hierarchy)
    local get_layer_i = function(node)
        for i, v in ipairs(layer_hierarchy) do
            if gui.get_layer(node) == hash(v) and gui.is_enabled(node) then return i end
        end
        return 0
    end
    local r = {}
    for _, v in ipairs(interactables) do
        if gui.is_enabled(v.node) then
            if not r.node then r=v end
            local layer_i_new = get_layer_i(v.node)
            local layer_i_old = get_layer_i(r.node)
            if layer_i_new > layer_i_old or (layer_i_new==layer_i_old and gui.get_index(v.node) > gui.get_index(r.node)) then r=v end
        end
    end
    return r
end
local get_pressed = function(instance) for i, v in pairs(get_all(instance)) do if v.is_pressed then return v end end end
local get_dragging = function(instance) for i, v in pairs(get_all(instance)) do if v.is_dragging then return v end end end
M.get_absolute_position = function(node) local parent = gui.get_parent(node) if parent then return M.get_absolute_position(parent) + gui.get_position(node) end return gui.get_position(node) end
local register = function(instance, interactable) table.insert(instance.mygui.interactables, 1, interactable) end
local unregister = function(instance, interactable) for i, v in ipairs(instance.mygui.interactables) do if v == interactable then table.remove(instance.mygui.interactables, i) return end end end

-- outputs an interactable
local create_interactable = function(instance, node)
    local r = {}
    local f = function() end
    r.id = gui.get_id(node)
    r.node = node
    r.enabled = true
    r.enable = function() r.enabled = true end
    r.disable = function() r.enabled = false end

    r.is_dragging = false
    r.is_pressed = false
    r.is_hovered = false
    r.is_dragged_over = false
    r.pressed_position = nil
    r.dragstart_distance = 10

    r.on_hover = f
    r.on_unhover = f
    r.on_press = f
    r.on_release = f
    r.on_dragstart = f
    r.on_drag = f
    r.on_drop = f
    r.on_receive_drop = f
    r.on_dragover = f
    r.on_dragleave = f

    r.animations = {
        reset=f,
        hovered=f,
        pressed=f,
        dragstart=f,
        dragover=f,
        dragleave=f,
        dragend=f,
        drag=f
    }

    r.remove = function() unregister(instance, r) end

    return r
end

local hover = function(interactable)
    interactable.is_hovered = true
    interactable.animations.hovered()
    interactable.on_hover()
end
local unhover = function(interactable)
    interactable.is_hovered = false
    interactable.animations.reset()
    interactable.on_unhover()
end

local handle
handle = {
    move_cursor = function(instance, action_id, action)
        local picked, unpicked = get_picked_unpicked(instance, action.x, action.y)
        if User.is_dragging and get_dragging(instance) then
            handle.drag(instance, action_id, action)
        else
            local pressed = get_pressed(instance)
            if pressed and pressed.is_draggable and not pressed.is_dragging and pressed.pressed_position and vmath.length_sqr(pressed.pressed_position - vmath.vector3(action.x, action.y, 0)) > pressed.dragstart_distance^2 then
                pressed.on_dragstart()
                pressed.is_dragging = true
                User.is_dragging = true
                instance.drag = {draggable=pressed}
                handle.drag(instance, action_id, action)
            end
            local topmost_picked = get_topmost(picked, instance.mygui.layer_hierarchy)
            for i, v in ipairs(picked) do
                if v==topmost_picked or v.ignore_z then
                    if not v.is_hovered then hover(v) end
                end
                if v ~= topmost_picked and not v.ignore_z then table.insert(unpicked, v) end
            end
            for i, v in ipairs(unpicked) do if v.is_hovered then unhover(v) end end
        end
    end,
    press = function(instance, action_id, action)
        local picked = get_picked(instance, action.x, action.y)
        if #picked == 0 then return end
        local something_was_pressed = false
        for i, v in ipairs(picked) do
            if v.is_hovered and (v.is_button or v.is_draggable) then
                v.is_pressed = true
                v.animations.pressed()
                v.pressed_position = vmath.vector3(action.x, action.y, 0)
                v.on_press()
                something_was_pressed = true
                break
            end
        end
        User.is_pressing = true
        return something_was_pressed
    end,
    release = function(instance, action_id, action)
        local all = get_all(instance)
        local dragging, droptarget
        local picked_droptargets = {}
        for k, v in pairs(all) do
            if v.is_pressed then
                v.animations.reset()
                if gui.pick_node(v.node, action.x, action.y) and not v.is_dragging then
                    v.on_click({x=action.x,y=action.y})
                end
                v.pressed_position = nil
                v.is_pressed = false
            end
            v.on_release()
            if v.is_droptarget and v.is_dragged_over then
                v.animations.dragleave()
                table.insert(picked_droptargets, v)
            end
            if v.is_dragging then
                instance.drag={}
                v.is_dragging = false
                dragging = v
                v.on_release()
                v.animations.reset()
            end
        end
        droptarget = get_topmost(picked_droptargets, instance.mygui.layer_hierarchy)
        if not droptarget.node then droptarget = nil end
        if dragging and droptarget then
            droptarget.on_receive_drop({dragged=dragging})
        end
        if dragging then
            dragging.on_drop(droptarget)
        end

        for k, v in pairs(all) do
            v.is_hovered = false
            v.is_pressed = false
            v.is_dragged_over = false
        end
        User.is_dragging = false
        User.is_pressing = false
        timer.delay(0, false, function()
            handle.move_cursor(instance, action_id, action)
        end)
    end,
    drag = function(instance, action_id, action)
        local dragged = get_dragging(instance)
        local absolute_position = M.get_absolute_position(dragged.node)
        local offset = absolute_position - gui.get_position(dragged.node)
        local position = vmath.vector3(action.x, action.y, 0) - offset
        gui.set_position(dragged.node, position)
        dragged.on_drag()

        -- hook topmost drop target
        local drop_targets = get_all_type(instance, 'droptarget')
        local picked = get_picked(instance, action.x, action.y)
        local picked_droptargets = filter_type(picked, 'droptarget')
        if #picked_droptargets > 0 then
            local topmost_droptarget = get_topmost(picked_droptargets, instance.mygui.layer_hierarchy)
            if not instance.drag.droptarget or topmost_droptarget ~= instance.drag.droptarget then
                instance.drag.droptarget = topmost_droptarget
                topmost_droptarget.is_dragged_over = true
                topmost_droptarget.animations.dragover()
                topmost_droptarget.on_dragover(dragged)
            end
        else
            instance.drag.droptarget = nil
        end
        for i, v in ipairs(drop_targets) do
            if v.is_dragged_over and v~= instance.drag.droptarget then
                v.is_dragged_over = false
                v.animations.dragleave()
                v.on_dragleave()
            end
        end
    end
}

M.handle_input = function(instance, action_id, action)
    if not instance.mygui.enabled then return end
    if action_id == hash('click') and action.pressed then
        return handle.press(instance, action_id, action)
    elseif action_id == hash('click') and action.released then
        return handle.release(instance, action_id, action)
    elseif action.x and (action.dx~=0 or action.dy~=0) then
        handle.move_cursor(instance, action_id, action)
    end
end

-- must provide layer_hierarchy = {layer names as strings}
M.new = function(instance, layer_hierarchy)
    instance.mygui = {
        enabled = true,
        focused=nil,
        layer_hierarchy=layer_hierarchy,
        interactables={},
        enable=function(self) self.enabled=true end,
        disable=function(self) self.enabled=false end,
        handle_input = function(action_id, action) M.handle_input(instance, action_id, action) end,
        create_button = function(node, callback) return M.create_button(instance, node, callback) end,
        create_draggable = function(node, params) return M.create_draggable(instance, node, params) end,
        create_droptarget = function(node, params) return M.create_droptarget(instance, node, params) end,
    }

    return instance.mygui
end

M.create_button = function(instance, node, callback, _params)
    local button = create_interactable(instance, node)
    for k, v in pairs(_params or {}) do button[k] = v end
    button.on_click = function(v) callback(v) end
    button.is_button = true
    register(instance, button)
    return button
end

M.create_draggable = function(instance, node, _params)
    local draggable = create_interactable(instance, node)
    for k, v in pairs(_params or {}) do draggable[k] = v end
    draggable.is_draggable = true
    register(instance, draggable)
    return draggable
end

M.create_droptarget = function(instance, node, _params)
    local droptarget = create_interactable(instance, node)
    for k, v in pairs(_params or {}) do droptarget[k] = v end
    droptarget.is_droptarget = true
    register(instance, droptarget)
    return droptarget
end

return M