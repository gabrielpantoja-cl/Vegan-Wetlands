
-- translation and protector radius

local S = core.get_translator("protector")
local radius = protector.radius

-- hud settings

local hud = {}
local hud_timer = 0
local hud_interval = (tonumber(core.settings:get("protector_hud_interval")) or 4)
local hud_style = core.has_feature("hud_def_type_field")

if hud_interval > 0 then

core.register_globalstep(function(dtime)

	hud_timer = hud_timer + dtime

	if hud_timer < hud_interval then return end

	hud_timer = 0

	for _, player in pairs(core.get_connected_players()) do

		local name = player:get_player_name()
		local pos = vector.round(player:get_pos())
		local hud_text = ""

		local protectors = core.find_nodes_in_area(
				{x = pos.x - radius , y = pos.y - radius , z = pos.z - radius},
				{x = pos.x + radius , y = pos.y + radius , z = pos.z + radius},
				{"protector:protect","protector:protect2", "protector:protect_hidden"})

		if #protectors > 0 then

			local npos = protectors[1]
			local meta = core.get_meta(npos)
			local nodeowner = meta:get_string("owner")
			local members =  meta:get_string("members"):split(" ")

			hud_text = S("Owner: @1", nodeowner)

			if #members > 0 then
				hud_text = hud_text .. " [" .. #members .. "]"
			end
		end

		if not hud[name] then

			hud[name] = {}

			local hud_tab = {
				name = "Protector Area",
				number = 0xFFFF22,
				position = {x = 0, y = 0.95},
				offset = {x = 8, y = -8},
				text = hud_text,
				scale = {x = 200, y = 60},
				alignment = {x = 1, y = -1},
			}

			if hud_style then
				hud_tab["type"] = "text"
			else
				hud_tab["hud_elem_type"] = "text"
			end

			hud[name].id = player:hud_add(hud_tab)

			return
		else
			player:hud_change(hud[name].id, "text", hud_text)
		end
	end
end)

core.register_on_leaveplayer(function(player)
	hud[player:get_player_name()] = nil
end)

end -- END hud_interval > 0
