local M = {}

M.new = function (bar_node, fill_node, text_node, current, max)
    local bar
    bar = {
        max=max,
        nodes={bar=bar_node,fill=fill_node,text=text_node},
        size=gui.get_size(bar_node),
        set_text=function(text) gui.set_text(bar.nodes.text, text) end,
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
        end
    }
    bar.set_fill(current)
    return bar
end

return M