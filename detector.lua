--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	detector.lua
	

]]--
minetest.register_node("tubelib_addons2:detector", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "jeija_node_detector_off.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = true,
	groups = {cracky=3},
	description="Tubelib Node Detector",
	mesecons = {receptor = {
		state = mesecon.state.off
	}},
	on_construct = node_detector_make_formspec,
	on_receive_fields = node_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = node_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("tubelib_addons2:detector_on", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "jeija_node_detector_on.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = true,
	groups = {cracky=3,not_in_creative_inventory=1},
	drop = 'mesecons_detector:node_detector_off',
	mesecons = {receptor = {
		state = mesecon.state.on
	}},
	on_construct = node_detector_make_formspec,
	on_receive_fields = node_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = node_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = 'mesecons_detector:node_detector_off',
	recipe = {
		{"default:steel_ingot", "group:mesecon_conductor_craftable", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_abm({
	nodenames = {"mesecons_detector:node_detector_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if not node_detector_scan(pos) then return end

		node.name = "mesecons_detector:node_detector_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos)
	end,
})

minetest.register_abm({
	nodenames = {"mesecons_detector:node_detector_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if node_detector_scan(pos) then return end

		node.name = "mesecons_detector:node_detector_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos)
	end,
})
