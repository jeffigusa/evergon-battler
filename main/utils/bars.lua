local M = {}

M.new = function (bar_node, fill_node, text_node, current, max)
    local bar
    bar = {
        max=max,
        node = bar_node,
        fill_node = fill_node,
        text_node = text_node,
        size=gui.get_size(bar_node),
        set_text=function(text) gui.set_text(text_node, text) end,
        -- params: {easing, duration}
        set_fill=function(value, _params)
            local params = _params or {}
            local width = bar.size.x * value/bar.max
            gui.animate(fill_node, 'size.x', width, params.easing or gui.EASING_LINEAR, params.duration or 0)
        end,
        set_max=function(value)
            bar.max = value
        end,
        set_width = function(width)
            gui.set(bar_node, 'size.x', width)
            bar.size.x = width
        end,
        show = function()
            gui.set_visible(bar_node, true)
            gui.set_visible(fill_node, true)
        end,
        hide = function()
            gui.set_visible(bar_node, false)
            gui.set_visible(fill_node, false)
        end
    }
    bar.set_fill(current)
    return bar
end

return M