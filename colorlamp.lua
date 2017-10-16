--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	colorlamp.lua:
	
]]--

local function switch_on(pos, node)
	node.name = "tubelib_addons2:lamp_on"
	minetest.swap_node(pos, node)
end	

local function switch_off(pos, node)
	node.name = "tubelib_addons2:lamp"
	minetest.swap_node(pos, node)
end	

minetest.register_node("tubelib_addons2:lamp", {
	description = "Tubelib Color Lamp",
	tiles = {
		'tubelib_lamp.png',
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons2:lamp")			-- <<=== tubelib
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Tubelib Color Lamp "..number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node)
		end
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)										-- <<=== tubelib
	end,

	paramtype = 'light',
	light_source = 0,	
	groups = {cracky=1},
	is_ground_content = false,
})

minetest.register_node("tubelib_addons2:lamp_on", {
	description = "Tubelib Color Lamp",
	tiles = {
		'tubelib_lamp.png^[colorize:#00FF00:255',
	},

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_off(pos, node)
		end
	end,

	paramtype = 'light',
	light_source = LIGHT_MAX,	
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_craft({
	output = "tubelib_addons2:lamp 4",
	recipe = {
		{"wool:green", 		"wool:red",  			"wool:blue"},
		{"tubelib:tube1", 	"default:coal_lump",	""},
		{"group:wood", 		"",  					"group:wood"},
	},
})

tubelib.register_node("tubelib_addons2:lamp", {"tubelib_addons2:lamp_on"}, {
	on_pull_item = nil,			-- lamp has no inventory
	on_push_item = nil,			-- lamp has no inventory
	on_unpull_item = nil,		-- lamp has no inventory
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "start" then
			switch_on(pos, node)
		elseif topic == "stop" then
			switch_off(pos, node)
		end
	end,
})		

