local S = minetest.get_translator("tt")
local COLOR_DEFAULT = "#d0ffd0"
local COLOR_DANGER = "#ffff00"
local COLOR_GOOD = "#00ff00"

tt = {}
tt.registered_snippets = {}

local function descriptive_dig_speed(time, group)
	if time <= 0 then
		return S("Digs @1 instantly", group)
	elseif time <= 0.35 then
		return S("Digs @1 insanely fast", group)
	elseif time <= 0.5 then
		return S("Digs @1 very fast", group)
	elseif time <= 0.7 then
		return S("Digs @1 fast", group)
	elseif time <= 1.0 then
		return S("Digs @1 at medium speed", group)
	elseif time <= 1.5 then
		return S("Digs @1 slowly", group)
	elseif time <= 2.0 then
		return S("Digs @1 very slowly", group)
	elseif time <= 10.0 then
		return S("Digs @1 painfully slowly", group)
	else
		return S("Digs @1 sluggishly", group)
	end
end

local function descriptive_punch_interval(time)
	if time <= 0 then
		return S("Instantanous punching")
	elseif time < 0.5 then
		return S("Insanely fast punching")
	elseif time < 0.7 then
		return S("Very fast punching")
	elseif time < 0.9 then
		return S("Fast punching")
	elseif time < 1.1 then
		return S("Medium speed punching")
	elseif time < 1.5 then
		return S("Slow punching")
	elseif time < 2.0 then
		return S("Very slow punching")
	elseif time < 3.0 then
		return S("Painfully slow punching")
	else
		return S("Sluggish punching")
	end
end

local function get_min_digtime(caps)
	local mintime
	local unique = true
	if caps.maxlevel and caps.maxlevel > 1 then
		unique = false
	end
	if caps.times then
		for r=1,3 do
			local time = caps.times[r]
			if caps.maxlevel and caps.maxlevel > 1 then
				time = time / caps.maxlevel
			end
			if (not mintime) or (time and time < mintime) then
				if time and mintime and (time < mintime) then
					unique = false
				end
				mintime = time
			end
		end
	end
	return mintime, unique
end

local function append_descs()
	for itemstring, def in pairs(minetest.registered_items) do
		if itemstring ~= "" and itemstring ~= "air" and itemstring ~= "ignore" and itemstring ~= "unknown" and def ~= nil and def.description ~= nil and def.description ~= "" and def._tt_ignore ~= true then
			local desc = def.description
			local orig_desc = desc
			-- Custom text
			if def._tt_help then
				desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, def._tt_help)
			end
			-- Tool info
			if def.tool_capabilities then
				-- Digging times
				local digs = ""
				local d
				if def.tool_capabilities.groupcaps then
					for group, caps in pairs(def.tool_capabilities.groupcaps) do
						local mintim, unique_mintime
						if caps.times then
							mintime, unique_mintime = get_min_digtime(caps)
							if mintime and (mintime > 0 and (not unique_mintime)) then
								d = S("Digs @1 blocks", group) .. "\n"
								d = d .. S("Minimum dig time: @1s", string.format("%.2f", mintime))
								digs = digs .. "\n" .. d
							elseif mintime and mintime == 0 then
								d = S("Digs @1 blocks instantly", group)
								digs = digs .. "\n" .. d
							end
						end
					end
					if digs ~= "" then
						desc = desc .. minetest.colorize(COLOR_DEFAULT, digs)
					end
				end
				-- Weapon stats
				if def.tool_capabilities.damage_groups then
					for group, damage in pairs(def.tool_capabilities.damage_groups) do
						local msg
						if group == "fleshy" then
							if damage >= 0 then
								msg = S("Damage: @1", damage)
							else
								msg = S("Healing: @1", math.abs(damage))
							end
						else
							if damage >= 0 then
								msg = S("Damage (@1): @2", group, damage)
							else
								msg = S("Healing (@1): @2", group, math.abs(damage))
							end
						end
						desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, msg)
					end
					local full_punch_interval = def.tool_capabilities.full_punch_interval
					if not full_punch_interval then
						full_punch_interval = 1
					end
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Full punch interval: @1s", full_punch_interval))
				end
			end
			-- Food
			if def._tt_food then
				desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Food item"))
				if def._tt_food_hp then
					local msg = S("+@1 food points", def._tt_food_hp)
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, msg)
				end
				-- NOTE: This is unused atm
				--[[if def._tt_food_satiation then
                                        if def._tt_food_satiation >= 0 then
						msg = S("+@1 satiation", def._tt_food_satiation)
					else
						msg = S("@1 satiation", def._tt_food_satiation)
					end
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, msg)
				end]]
			end
			-- Node info
			-- Damage-related
			do
				if def.damage_per_second then
					if def.damage_per_second > 0 then
						desc = desc .. "\n" .. minetest.colorize(COLOR_DANGER, S("Contact damage: @1 per second", def.damage_per_second))
					elseif def.damage_per_second < 0 then
						desc = desc .. "\n" .. minetest.colorize(COLOR_GOOD, S("Contact healing: @1 per second", math.abs(def.damage_per_second)))
					end
				end
				if def.drowning and def.drowning ~= 0 then
					desc = desc .. "\n" .. minetest.colorize(COLOR_DANGER, S("Drowning damage: @1", def.drowning))
				end
				local tmp = minetest.get_item_group(itemstring, "fall_damage_add_percent")
				if tmp > 0 then
					desc = desc .. "\n" .. minetest.colorize(COLOR_DANGER, S("Fall damage: +@1%", tmp))
				elseif tmp == -100 then
					desc = desc .. "\n" .. minetest.colorize(COLOR_GOOD, S("No fall damage"))
				elseif tmp < 0 then
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Fall damage: @1%", tmp))
				end
			end
			-- Movement-related node facts
			if minetest.get_item_group(itemstring, "disable_jump") == 1 and not def.climbable then
				if def.liquidtype == "none" then
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("No jumping"))
				else
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("No swimming upwards"))
				end
			end
			if def.climbable then
				if minetest.get_item_group(itemstring, "disable_jump") == 1 then
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Climbable (only downwards)"))
				else
					desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Climbable"))
				end
			end
			if minetest.get_item_group(itemstring, "slippery") >= 1 then
				desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Slippery"))
			end
			local tmp = minetest.get_item_group(itemstring, "bouncy")
			if tmp >= 1 then
				desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Bouncy (@1%)", tmp))
			end
			-- Node appearance
			tmp = def.light_source
			if tmp and tmp >= 1 then
				desc = desc .. "\n" .. minetest.colorize(COLOR_DEFAULT, S("Luminance: @1", tmp))
			end
			-- Custom functions
			for s=1, #tt.registered_snippets do
				local str, snippet_color = tt.registered_snippets[s](itemstring)
				if not snippet_color then
					snippet_color = COLOR_DEFAULT
				end
				if str then
					desc = desc .. "\n" .. minetest.colorize(snippet_color, str)
				end
			end

			minetest.override_item(itemstring, { description = desc, _tt_original_description = orig_desc })
		end
	end
end

tt.register_snippet = function(func)
	table.insert(tt.registered_snippets, func)
end

minetest.register_on_mods_loaded(append_descs)
