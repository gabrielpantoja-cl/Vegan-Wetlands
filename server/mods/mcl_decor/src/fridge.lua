-- mcl_decor/src/fridge.lua

local S = ...
local F = core.formspec_escape
local C = core.colorize

local open_fridges = {}

local drop_content = mcl_util.drop_items_from_meta_container("main")

local function on_blast(pos)
	local node = core.get_node(pos)
	drop_content(pos, node)
	core.remove_node(pos)

	local above = vector.new(pos.x, pos.y+1, pos.z)
	core.remove_node(above)
end

-- Simple protection checking functions
local function protection_check_move(pos, from_list, from_index, to_list, to_index, count, player)
	local name = player:get_player_name()
	if core.is_protected(pos, name) then
		core.record_protection_violation(pos, name)
		return 0
	else
		return count
	end
end

local function protection_check_put_take(pos, listname, index, stack, player)
	local name = player:get_player_name()
	if core.is_protected(pos, name) then
		core.record_protection_violation(pos, name)
		return 0
	else
		return stack:get_count()
	end
end

local function fridge_open(pos, node, clicker)
	local name = core.get_meta(pos):get_string("name")

	if name == "" then
		name = S("Fridge")
	end

	local playername = clicker:get_player_name()

	core.show_formspec(playername,
		"mcl_decor:fridge_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
		table.concat({
			"formspec_version[4]",
			"size[11.75,10.425]",

			"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, name)) .. "]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
			"list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;0.375,0.75;9,3;]",
			"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
			"list[current_player;main;0.375,5.1;9,3;9]",

			mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
			"list[current_player;main;0.375,9.05;9,1;]",
			"listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]",
			"listring[current_player;main]",
		})
	)

	core.swap_node(pos, { name = "mcl_decor:fridge_open", param2 = node.param2 })
	open_fridges[playername] = pos
	core.sound_play({name="mcl_decor_fridge_open", gain=0.5}, {
		pos = pos,
		max_hear_distance = 16,
	}, true)
end

local function close_forms(pos)
	local formname = "mcl_decor:fridge_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
	local players = core.get_connected_players()
	for p = 1, #players do
		if vector.distance(players[p]:get_pos(), pos) <= 30 then
			core.close_formspec(players[p]:get_player_name(), formname)
		end
	end
end

local function update_after_close(pos)
	local node = core.get_node_or_nil(pos)
	if not node then return end
	if node.name == "mcl_decor:fridge_open" then
		core.swap_node(pos, { name = "mcl_decor:fridge", param2 = node.param2 })
		core.sound_play({name="mcl_decor_fridge_close", gain=0.5}, {
			pos = pos,
			max_hear_distance = 16,
		}, true)
	end
end

local function close_fridge(player)
	local name = player:get_player_name()
	local open = open_fridges[name]
	if open == nil then
		return
	end

	update_after_close(open)

	open_fridges[name] = nil
end


-- Reused constants
local FRIDGE_BOX = {
	type = "fixed",
	fixed = {
		{-8/16, -8/16, -5/16, 8/16, 24/16, 8/16},
	}
}

-- Dummy node
core.register_node("mcl_decor:fridge_top", {
	_doc_items_create_entry = false,
	drawtype = "airlike",
	tiles = {"blank.png"},
	groups = {not_in_creative_inventory = 1},
	use_texture_alpha = "clip",
	is_ground_content = false,
	pointable = false,
	collision_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -5/16, 8/16, 8/16, 8/16},
		}
	},
	sunlight_propagates = true,
	paramtype = "light",
})

local closed_def = {
	description = S("Fridge"),
	_tt_help = S("27 inventory slots"),
	_doc_items_longdesc = S("Fridges are containers which provide 27 inventory slots."),
	_doc_items_usagehelp = S("To access its inventory, rightclick it. When broken, the items will drop out."),
	tiles = {"mcl_decor_fridge.png"},
	inventory_image = "mcl_decor_fridge_inv.png",
	drawtype = "mesh",
	mesh = "mcl_decor_fridge.obj",
	paramtype = "light",
	paramtype2 = "4dir",
	is_ground_content = false,
	selection_box = FRIDGE_BOX,
	collision_box = FRIDGE_BOX,
	groups = {pickaxey=2, deco_block=1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 5,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 9 * 3)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		-- Use pointed node's on_rightclick function first, if present
		local rightclick = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
		if rightclick then
			return rightclick
		end

		local above = core.get_node_or_nil(vector.offset(pointed_thing.above, 0, 1, 0))
		-- Don't place fridge if no space available
		if not above or above.name ~= "air" then
			return itemstack
		end

		-- Finally, if all checks pass
		return core.item_place(itemstack, placer, pointed_thing)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		core.get_meta(pos):set_string("name", itemstack:get_meta():get_string("name"))
		local above = vector.new(pos.x, pos.y+1, pos.z)
		-- Place the dummy node
		core.set_node(above, {name="mcl_decor:fridge_top"})
	end,
	after_destruct = function(pos)
		-- Remove the dummy node
		core.remove_node(vector.new(pos.x, pos.y+1, pos.z))
	end,
	allow_metadata_inventory_move = protection_check_move,
	allow_metadata_inventory_take = protection_check_put_take,
	allow_metadata_inventory_put = protection_check_put_take,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		core.log("action", player:get_player_name() ..
			" moves stuff in fridge at " .. core.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		core.log("action", player:get_player_name() ..
			" moves stuff to fridge at " .. core.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		core.log("action", player:get_player_name() ..
			" takes stuff from fridge at " .. core.pos_to_string(pos))
	end,
	after_dig_node = drop_content,
	on_blast = on_blast,
	on_rightclick = fridge_open,
	on_destruct = close_forms,
}

local open_def = table.copy(closed_def)
open_def._doc_items_create_entry = false
open_def.groups.not_in_creative_inventory = 1
open_def.drop = "mcl_decor:fridge"

core.register_node("mcl_decor:fridge", closed_def)
core.register_node("mcl_decor:fridge_open", open_def)

core.register_craft({
	output = "mcl_decor:fridge",
	recipe = {
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
		{"mcl_nether:quartz", "group:ice", "mcl_nether:quartz"},
		{"mcl_nether:quartz", "mcl_core:iron_ingot", "mcl_nether:quartz"},
	}
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname:find("mcl_decor:fridge") == 1 and fields.quit then
		close_fridge(player)
	end
end)

core.register_on_leaveplayer(function(player)
	close_fridge(player)
end)
