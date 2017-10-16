--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	sequencer.lua:
	
]]--

local RUNNING_STATE = 1
local STOP_STATE = 0
local NUM_SLOTS = 8

local sAction = ",start,stop,on,off"
local kvAction = {[""]=1, ["start"]=2, ["stop"]=3, ["on"]=4, ["off"]=5}
local tAction = {nil,"start","stop", "on", "off"}

local sOffset = ",1,2,3,4,8,15,30,60,120,240,480"
local kvOffset = {[""]=1, ["1"]=2, ["2"]=3, ["3"]=4, ["4"]=5, ["8"]=6, ["15"]=7, ["30"]=8, ["60"]=9, ["120"]=10, ["240"]=11, ["480"]=12}
local tOffset = {nil,1,2,3,4,8,15,30,60,120,240,480}

local function formspec(state, rules, endless)
	endless = endless == 1 and "true" or "false"
	local tbl = {"size[8,9.2]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0,0;Number(s)]label[2.1,0;Command]label[6.4,0;Offset/s]"}
		
	for idx, rule in ipairs(rules) do
		tbl[#tbl+1] = "field[0.2,"..(-0.2+idx)..";2,1;num"..idx..";;"..(rule.num or "").."]"
		tbl[#tbl+1] = "dropdown[2,"..(-0.4+idx)..";3.9,1;act"..idx..";"..sAction..";"..(rule.act or "").."]"
		tbl[#tbl+1] = "dropdown[6,"..(-0.4+idx)..";2,1;offs"..idx..";"..sOffset..";"..(rule.offs or "").."]"
	end
	tbl[#tbl+1] = "checkbox[0,8.5;endless;Run endless;"..endless.."]"
	tbl[#tbl+1] = "image_button[5,8.5;1,1;".. tubelib.state_button(state) ..";button;]"
	tbl[#tbl+1] = "image_button[7,8.5;1,1;tubelib_inv_button_help.png;help;]"
	
	return table.concat(tbl)
end

local function formspec_help()
	return "size[8,9.2]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[2,0;Sequencer Help]"..
		"label[0,1;Define a sequence of commands\nto control other machines.]"..
		"label[0,2.2;Numbers(s) are the node numbers,\nthe command shall sent to.]"..
		"label[0,3.4;The command 'start' can also be used\nto switch a node ON.]"..
		"label[0,4.6;Offset is the time to the\nnext line in seconds.]"..
		"label[0,5.8;If endless is set, the Sequencer\nrestarts again and again.]"..
		"label[0,7;The command ' ' does nothing,\nonly consuming the offset time.]"..
		"button[3,8;2,1;exit;close]"
end

local function stop_the_sequencer(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", STOP_STATE)
	meta:set_string("infotext", "Tubelib Sequencer "..number..": stopped")
	local rules = minetest.deserialize(meta:get_string("rules"))
	local endless = meta:get_int("endless") or 0
	meta:set_string("formspec", formspec(tubelib.STOPPED, rules, endless))
	minetest.get_node_timer(pos):stop()
	return false
end

local function get_next_slot(idx, rules, endless)
	idx = idx + 1
	if idx <= #rules and rules[idx].offs ~= 1 and rules[idx].num ~= "" then
		return idx
	elseif endless == 1 then
		return 1
	end
	return nil
end

local function restart_timer(pos, time)
	local timer = minetest.get_node_timer(pos)
	if timer:is_started() then
		timer:stop()
	end
	timer:start(time)
end	

local function check_rules(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local rules = minetest.deserialize(meta:get_string("rules"))
	if rules then
		local running = meta:get_int("running")
		local index = meta:get_int("index") or 1
		local number = meta:get_string("number")
		local endless = meta:get_int("endless") or 0
		local placer_name = meta:get_string("placer_name")
		local rule = rules[index]
		local offs = tOffset[rules[index].offs]
		tubelib.send_message(rule.num, placer_name, nil, tAction[rule.act], nil)
		index = get_next_slot(index, rules, endless)
		if index ~= nil and offs ~= nil and running == 1 then
			meta:set_string("infotext", "Tubelib Sequencer "..number..": running ("..index.."/"..NUM_SLOTS..")")
			meta:set_int("index", index)
			minetest.after(0, restart_timer, pos, offs)
			return false
		else
			return stop_the_sequencer(pos)
		end
	end
	return false
end

local function start_the_sequencer(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", 1)
	meta:set_int("index", 1)
	meta:set_string("infotext", "Tubelib Sequencer "..number..": running (1/"..NUM_SLOTS..")")
	local rules = minetest.deserialize(meta:get_string("rules"))
	local endless = meta:get_int("endless") or 0
	meta:set_string("formspec", formspec(tubelib.RUNNING, rules, endless))
	minetest.get_node_timer(pos):start(2)
	return false
end

local function 	on_receive_fields(pos, formname, fields, player)
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running")
	local placer_name = meta:get_string("placer_name")
	if placer_name ~= player:get_player_name() then
		return
	end
	
	if fields.help ~= nil then
		meta:set_string("formspec", formspec_help())
		return
	end
	
	local endless = meta:get_int("endless") or 0
	if fields.endless ~= nil then
		endless = fields.endless == "true" and 1 or 0
		meta:set_int("index", 1)
	end
	meta:set_int("endless", endless)
	
	local rules = minetest.deserialize(meta:get_string("rules"))
	if fields.exit ~= nil then
		meta:set_string("formspec", formspec(tubelib.state(running), rules, endless))
		return
	end

	for idx = 1,NUM_SLOTS do
		if fields["offs"..idx] ~= nil then
			rules[idx].offs = kvOffset[fields["offs"..idx]]
		end
		if fields["num"..idx] ~= nil and tubelib.check_numbers(fields["num"..idx]) then
			rules[idx].num = fields["num"..idx]
		end
		if fields["act"..idx] ~= nil then
			rules[idx].act = kvAction[fields["act"..idx]]
		end
	end
	meta:set_string("rules", minetest.serialize(rules))

	if fields.button ~= nil then
		if running > STOP_STATE then
			stop_the_sequencer(pos)
		else
			start_the_sequencer(pos)
		end
	elseif fields.num1 ~= nil then  -- any other change?
		stop_the_sequencer(pos)
	else
		local endless = meta:get_int("endless") or 0
		meta:set_string("formspec", formspec(tubelib.state(running), rules, endless))
	end
end

minetest.register_node("tubelib_addons2:sequencer", {
	description = "Tubelib Sequencer",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png^tubelib_addons2_sequencer.png',
	},
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local number = tubelib.add_node(pos, "tubelib_addons2:sequencer")
		local rules = {}
		for idx = 1,NUM_SLOTS do
			rules[idx] = {offs = 1, num = "", act = 1}
		end
		meta:set_string("placer_name", placer:get_player_name())
		meta:set_string("rules", minetest.serialize(rules))
		meta:set_string("number", number)
		meta:set_int("index", 1)
		meta:set_int("endless", 0)
		meta:get_int("running", STOP_STATE)
		meta:set_string("formspec", formspec(tubelib.STOPPED, rules, 0))
	end,

	on_receive_fields = on_receive_fields,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		local running = meta:get_int("running")
		if running ~= 1 then
			minetest.node_dig(pos, node, puncher, pointed_thing)
			tubelib.remove_node(pos)
		end
	end,
	
	on_timer = check_rules,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons2:sequencer",
	recipe = {
		{"tubelib:button", "default:mese_crystal", "default:mese_crystal"},
	},
})

minetest.register_lbm({
	label = "[Tubelib] Start Sequencer",
	name = "tubelib_addons2:sequencer",
	nodenames = {"tubelib_addons2:sequencer"},
	run_at_every_load = true,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		local running = meta:get_int("running")
		if running == 1 then
			minetest.after(2, check_rules, pos)
		end
	end
})
