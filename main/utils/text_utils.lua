local richtext = require 'richtext.richtext'
local M = {}

--[[
EXAMPLE
	local text = "<size=3><outline=green>RichText</outline></size>\nLorem <color=0,0.5,0,1>ipsum </color><size=0.3><img=icons:icon_health/></size>dolor <color=red>sit </color><color=#ff00ffff>amet, </color><size=1.15><font=Nanum>consectetur </font></size>adipiscing elit. <b>Nunc </b>tincidunt <b><i>mattis</i> libero</b> <i>non viverra</i>.\n\nNullam ornare <size=0.3><img=icons:icon_food/></size>accumsan rhoncus.\n\nNunc placerat nibh a purus auctor, id scelerisque massa <size=2>rutrum.</size>"
	local words = richtext.create(text, "default", {width=300, valign=richtext.VALIGN_MIDDLE})
	for i, v in ipairs(words) do
		gui.set_parent(v.node, gui.get_node('root'))
	end
	pprint('num words:', #words)
]]
M.new_richtext = function(text, _params)
	local params = {valign=richtext.VALIGN_MIDDLE}
	for k, v in pairs(_params or {}) do params[k] = v end
	local node = gui.new_box_node(vmath.vector3(), vmath.vector3())
	local words, metrics = richtext.create(text, "normal_text", params)
	for i, v in ipairs(words) do
		gui.set_parent(v.node, node)
	end
	return node, metrics
end

M.show_gain_resource_text = function(position, text, params)
	local fconfig = params or {}
	fconfig.y_drift = fconfig.y_drift or -50
	fconfig.duration = fconfig.duration or 1
	fconfig.delay = fconfig.delay or 0
	local node = gui.new_box_node(position, vmath.vector3())
	local text_node_shadow = gui.new_text_node(vmath.vector3(5,-5,0), text)
	local text_node = gui.new_text_node(vmath.vector3(), text)
	gui.set_parent(text_node_shadow, node)
	gui.set_parent(text_node, node)
	gui.set_layer(node, fconfig.layer or '')
	gui.set_font(text_node, fconfig.font or 'heading_2')
	gui.set_font(text_node_shadow, fconfig.font or 'heading_2')
	gui.set_color(text_node, fconfig.color or vmath.vector4(1,0.7,0.2,1))
	gui.set_color(text_node_shadow, vmath.vector4(0,0,0,1))
	gui.set_position(node, position - vmath.vector3(0, fconfig.y_drift/2, 0))
	gui.animate(text_node_shadow, 'color.w', 0, fconfig.easing or gui.EASING_OUTCUBIC, fconfig.duration*0.25, fconfig.duration*0.75)
	gui.animate(text_node, 'color.w', 0, fconfig.easing or gui.EASING_OUTCUBIC, fconfig.duration*0.25, fconfig.duration*0.75)
	gui.animate(node, 'position.y', position + vmath.vector3(0, fconfig.y_drift/2, 0), fconfig.easing or gui.EASING_OUTQUINT, fconfig.duration, fconfig.delay, function()
		gui.delete_node(node)
	end)
	return node
end

M.show_evade_text = function(position, params)
	local text = 'Evaded!'
	local fconfig = params or {}
	fconfig.y_drift = fconfig.y_drift or 75
	fconfig.duration = fconfig.duration or 1
	fconfig.delay = fconfig.delay or 0
	local node = gui.new_box_node(position, vmath.vector3())
	local text_node_shadow = gui.new_text_node(vmath.vector3(5,-5,0), text)
	local text_node = gui.new_text_node(vmath.vector3(), text)
	gui.set_parent(text_node_shadow, node)
	gui.set_parent(text_node, node)
	gui.set_layer(node, fconfig.layer or '')
	gui.set_font(text_node, fconfig.font or 'heading_1')
	gui.set_font(text_node_shadow, fconfig.font or 'heading_1')
	gui.set_color(text_node_shadow, vmath.vector4(0,0,0,1))
	gui.set_position(node, position - vmath.vector3(0, fconfig.y_drift/2, 0))
	gui.animate(text_node_shadow, 'color.w', 0, fconfig.easing or gui.EASING_OUTCUBIC, fconfig.duration*0.25, fconfig.duration*0.75)
	gui.animate(text_node, 'color.w', 0, fconfig.easing or gui.EASING_OUTCUBIC, fconfig.duration*0.25, fconfig.duration*0.75)
	gui.animate(node, 'position.y', position + vmath.vector3(0, fconfig.y_drift/2, 0), fconfig.easing or gui.EASING_OUTQUINT, fconfig.duration, fconfig.delay, function()
		gui.delete_node(node)
	end)
	return node
end

M.show_damage_text = function(position, text, params)
	local fconfig = params or {}
	fconfig.y_drift = fconfig.y_drift or 75
	fconfig.duration = fconfig.duration or 1
	fconfig.delay = fconfig.delay or 0
	local node = gui.new_box_node(position, vmath.vector3())
	local text_node_shadow = gui.new_text_node(vmath.vector3(5,-5,0), text)
	local text_node = gui.new_text_node(vmath.vector3(), text)
	gui.set_parent(text_node_shadow, node)
	gui.set_parent(text_node, node)
	gui.set_layer(node, fconfig.layer or '')
	gui.set_font(text_node, fconfig.font or 'title')
	gui.set_font(text_node_shadow, fconfig.font or 'title')
	gui.set_color(text_node, vmath.vector4(1,0.2,0.2,1))
	gui.set_color(text_node_shadow, vmath.vector4(0,0,0,1))
	gui.set_position(node, position - vmath.vector3(0, fconfig.y_drift/2, 0))
	gui.animate(text_node_shadow, 'color.w', 0, fconfig.easing or gui.EASING_OUTCUBIC, fconfig.duration*0.25, fconfig.duration*0.75)
	gui.animate(text_node, 'color.w', 0, fconfig.easing or gui.EASING_OUTCUBIC, fconfig.duration*0.25, fconfig.duration*0.75)
	gui.animate(node, 'position.y', position + vmath.vector3(0, fconfig.y_drift/2, 0), fconfig.easing or gui.EASING_OUTQUINT, fconfig.duration, fconfig.delay, function()
		gui.delete_node(node)
	end)
	return node
end

return M