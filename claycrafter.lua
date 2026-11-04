local S = core.get_translator(core.get_current_modname())
--
-- Formspecs
--

local function active_formspec(fuel_percent, item_percent)
	local formspec =
		"size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[current_name;src;2.75,0.5;1,1;]"..
		"list[current_name;fuel;2.75,2.5;1,1;]"..
		"image[2.75,1.5;1,1;claycrafter_claycrafter_water_bg.png^[lowpart:"..
		(100-fuel_percent)..":claycrafter_claycrafter_water_fg.png]"..
		"image[3.75,1.5;1,1;gui_claycrafter_arrow_bg.png^[lowpart:"..
		(item_percent)..":gui_claycrafter_arrow_fg.png^[transformR270]"..
		"list[current_name;dst;4.75,0.96;3,2;]"..
		"list[current_name;vessels;0,1.5;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		"listring[current_name;dst]"..
		"listring[current_player;main]"..
		"listring[current_name;src]"..
		"listring[current_player;main]"..
		"listring[current_name;vessels]"..
		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.25)
	return formspec
end

local inactive_formspec =
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[current_name;src;2.75,0.5;1,1;]"..
	"list[current_name;fuel;2.75,2.5;1,1;]"..
	"image[2.75,1.5;1,1;claycrafter_claycrafter_water_bg.png]"..
	"image[3.75,1.5;1,1;gui_claycrafter_arrow_bg.png^[transformR270]"..
	"list[current_name;dst;4.75,0.96;3,2;]"..
	"list[current_name;vessels;0,1.5;2,2;]"..
	"list[current_player;main;0,4.25;8,1;]"..
	"list[current_player;main;0,5.5;8,3;8]"..
	"listring[current_name;dst]"..
	"listring[current_player;main]"..
	"listring[current_name;src]"..
	"listring[current_player;main]"..
	"listring[current_name;vessels]"..
	"listring[current_player;main]"..
	default.get_hotbar_bg(0, 4.25)

--
-- Node callback functions that are the same for active and inactive claycrafter
--

local function can_dig(pos, player)
	local meta = core.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src") and inv:is_empty("vessels")
end

----------------------------------------------------------------
-- WATER CONTAINERS
----------------------------------------------------------------

local jc_special_water_cans = {
	["jc_special:water_can"] = 15,
	["jc_special:water_jumbo_can"] = 35,
	["jc_special:freshwater_can"] = 15,
}

local water_container_returns = {
	["jc_claycrafter:glass_of_water"] = {
		return_item = "vessels:drinking_glass",
		water = 1,
	},
	["farming:glass_water"] = {
		return_item = "vessels:drinking_glass",
		water = 1,
	},
	["bucket:bucket_water"] = {
		return_item = "bucket:bucket_empty",
		water = 4,
	},
	["bucket:bucket_river_water"] = {
		return_item = "bucket:bucket_empty",
		water = 4,
	},
}

local function is_jc_special_water_can(itemstack)
	return jc_special_water_cans[itemstack:get_name()] ~= nil
end

local function get_can_level(itemstack)
	return itemstack:get_meta():get_int("level")
end

local function get_fuel_time(itemstack)
	if is_jc_special_water_can(itemstack) then
		if get_can_level(itemstack) > 0 then
			return 3
		end

		return 0
	end

	local container = water_container_returns[itemstack:get_name()]
	if container then
		return container.water * 3
	end

	return 0
end

local function consume_can_charge(itemstack)
	local capacity = jc_special_water_cans[itemstack:get_name()]
	local level = get_can_level(itemstack)

	if not capacity or level <= 0 then
		return itemstack
	end

	level = level - 1
	itemstack:get_meta():set_int("level", level)

	if level == 0 then
		itemstack:set_wear(0)
	else
		local wear = 65536 - math.floor(level / capacity * 65535)

		if wear > 65535 then
			wear = 65535
		elseif wear < 1 then
			wear = 1
		end

		itemstack:set_wear(wear)
	end

	return itemstack
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if core.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "fuel" then -- "Water"
		if get_fuel_time(stack) > 0 then
			if inv:is_empty("src") then
				meta:set_string("infotext", S("Clay Crafter is empty") )
			end
			return stack:get_count()
		else
			return 0
		end
	elseif listname == "src" then
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	elseif listname == "vessels" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if core.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

--
-- Node definitions
--

core.register_node("jc_claycrafter:claycrafter", {
	description = S("Clay Crafter"),
	tiles = {
		"claycrafter_claycrafter_top.png", "claycrafter_claycrafter_bottom.png",
		"claycrafter_claycrafter_side.png", "claycrafter_claycrafter_side.png",
		"claycrafter_claycrafter_back.png", "claycrafter_claycrafter_front.png"
	},
	paramtype2 = "facedir",
	groups = {choppy = 1, oddly_breakable_by_hand = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take
})

core.register_node("jc_claycrafter:claycrafter_active", {
	description = S("Clay Crafter"),
	tiles = {
		"claycrafter_claycrafter_top.png", "claycrafter_claycrafter_bottom.png",
		"claycrafter_claycrafter_side.png", "claycrafter_claycrafter_back.png",
		"claycrafter_claycrafter_side.png",
		{
			image = "claycrafter_claycrafter_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			}
		}
	},
	paramtype2 = "facedir",
	light_source = 8,
	drop = "jc_claycrafter:claycrafter",
	groups = {choppy = 1, oddly_breakable_by_hand = 1, not_in_creative_inventory = 1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take
})

--
-- ABM
--

local function swap_node(pos, name)
	local node = core.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	core.swap_node(pos, node)
end

core.register_abm({
	nodenames = {"jc_claycrafter:claycrafter", "jc_claycrafter:claycrafter_active"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		--
		-- Initialize metadata
		--
		local meta = core.get_meta(pos)
		local fuel_time = meta:get_float("fuel_time") or 0
		local src_time = meta:get_float("src_time") or 0
		local fuel_totaltime = meta:get_float("fuel_totaltime") or 0

		--
		-- Initialize inventory
		--
		local inv = meta:get_inventory()
		for listname, size in pairs({
				src = 1,
				fuel = 1,
				dst = 6,
				vessels = 4
		}) do
			if inv:get_size(listname) ~= size then
				inv:set_size(listname, size)
			end
		end
		local srclist = inv:get_list("src")
		local fuellist = inv:get_list("fuel")

		--
		-- Cooking
		--
		local cooktime = 3
		local cookable = true

		if core.get_modpath("moreblocks") ~= nil then
			if inv:get_stack("src", 1):get_name() ~= "moreblocks:dirt_compressed" then
				cookable = false
			end
		else
			if inv:get_stack("src", 1):get_name() ~= "jc_claycrafter:compressed_dirt" then
				cookable = false
			end
		end

		-- Check if we have enough fuel to burn
		if fuel_time < fuel_totaltime then
			-- The claycrafter is currently active and has enough fuel
			if cookable then
				-- Pause fuel consumption if the output is full.
				if src_time + 1 >= cooktime and not inv:room_for_item("dst", ItemStack({name = "default:clay", count = 4})) then
					-- Wait until there is room for the output.
				else
					fuel_time = fuel_time + 1
					src_time = src_time + 1

					if src_time >= cooktime then
						inv:add_item("dst", ItemStack({name = "default:clay", count = 4}))
						inv:remove_item("src", inv:get_stack("src", 1):get_name())
						src_time = 0
					end
				end
			else
				fuel_time = fuel_time + 1
			end
		else
			-- Furnace ran out of fuel
			if cookable and inv:room_for_item("dst", ItemStack({name = "default:clay", count = 4})) then
				-- We need to get new fuel
				local fuel_stack = inv:get_stack("fuel", 1)

				if is_jc_special_water_can(fuel_stack) then
					if get_can_level(fuel_stack) > 0 then
						-- Consume one charge from the water can.
						fuel_stack = consume_can_charge(fuel_stack)
						inv:set_stack("fuel", 1, fuel_stack)

						fuel_totaltime = 3
						fuel_time = 0
					else
						-- Return the empty can to the vessels list.
						if inv:room_for_item("vessels", fuel_stack) then
							inv:remove_item("fuel", fuel_stack:get_name())
							inv:add_item("vessels", fuel_stack)
						end

						fuel_totaltime = 0
						fuel_time = 0
					end
				else
					local fueltime = get_fuel_time(fuel_stack)

					if fueltime == 0 then
						-- No valid fuel in fuel list
						fuel_totaltime = 0
						fuel_time = 0
						src_time = 0
					else
						-- Normal water fuel: return its empty container.
						local container = water_container_returns[fuel_stack:get_name()]

						if container and inv:room_for_item("vessels", ItemStack(container.return_item)) then
							inv:remove_item("fuel", fuel_stack:get_name())
							inv:add_item("vessels", ItemStack(container.return_item))

							fuel_totaltime = fueltime
							fuel_time = 0
						end
					end
				end
			elseif not cookable then
				-- No compressed dirt to process.
				fuel_totaltime = 0
				fuel_time = 0
				src_time = 0
			end
		end

		--
		-- Update formspec, infotext and node
		--
		local formspec = inactive_formspec
		local item_state = ""
		local item_percent = 0
		if cookable and cooktime > 0 then
			item_percent = math.floor(src_time / cooktime * 100)
			item_state = S("Yes")
		else
			if srclist[1]:is_empty() then
				item_state = S("Empty")
			else
				item_state = S("No water")
			end
		end

		local fuel_state = S("Empty")
		local active = S("inactive")
		if fuel_time < fuel_totaltime and fuel_totaltime ~= 0 then
			active = S("active")
			local fuel_percent = math.floor(fuel_time / fuel_totaltime * 100)
			fuel_state = S("In use")
			formspec = active_formspec(fuel_percent, item_percent)
			swap_node(pos, "jc_claycrafter:claycrafter_active")
		else
			if get_fuel_time(fuellist[1]) > 0 then
				fuel_state = S("Yes")
			end
			swap_node(pos, "jc_claycrafter:claycrafter")
		end

		local infotext = S("Clay Crafter @1 (Dirt: @2; Water: @3)", active, item_state, fuel_state)

		--
		-- Set meta values
		--
		meta:set_float("fuel_totaltime", fuel_totaltime)
		meta:set_float("fuel_time", fuel_time)
		meta:set_float("src_time", src_time)
		meta:set_string("formspec", formspec)
		meta:set_string("infotext", infotext)
	end
})
