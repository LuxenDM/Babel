--[[
[metadata]
description=The tower is Babel's registry, which contains its shelves and books.
owner=babel|2.0.0
created=2026-04-09
]]--

local file_args = {...}
local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local game_supported = {
	'en', 'es', 'fr', 'pt', 'de', 'it', 'pl', 'tr', 'id', --these are the lang-codes supported by the game
	'jp', 'ru', 'uk', 'chinese (simplified)', 'chinese (traditional)', 'ko', 'ab', --these are supported by the game, but cannot be rendered by plugins (yet?)
}

local support = { --list of languages you can select directly in Babel
	en = {
		status = 2, --0: partial entry, missing info; 1: full entry; 2: official entry
		full = "English",
		flag = private.local_path .. "lang/en/flag.png",
		game_supported = true,
	},
}

local check_game_supported = function(code)
	for _, v in ipairs(game_supported) do
		if code == v then
			return true
		end
	end
	return false
end

local strip_file = function()

end

private.add_support = function(lang_code, ini_path)
	if type(lang_code) ~= "string" then
		private.cp("language implementation rejected; got invalid code of type " .. type(lang_code) .."; " .. tostring(lang_code), 3)
		return false, 'invalid_type'
	end
	local cur_status = support[lang_code] or -1
	if cur_status > 0 then
		return false, "already implemented"
	end
	local full = gkini.ReadString2("babel", "0", "", ini_path)
	if full == "" then
		support[lang_code] = {
			status = 0,
			full = lang_code,
			flag = private.local_path .. "lang/null_flag.png",
			game_supported = check_game_supported(lang_code),
		}
		return true
	else
		local flag = gkini.ReadString2("babel", "flag", "", ini_path)
		local folder_path = ini_path --todo: break down and get path, seperate from file
		support[lang_code] = {
			status = 1,
			full = full,
			flag = folder_path .. flag,
			game_supported = check_game_supported(lang_code),
		}
		return true
	end
end

private.mutate_support_entry = function(code, intab)
	local entry = support[code]
	for i, v in pairs(intab) do
		entry[i] = v
	end
end	

local registry = {} --list of external mod tables

--[[
local registry = {
	shelf_id = {
		path = "path/to/owner",
		locale_code = {
			path = "path/to/file.ini",
			[1] = 'precached entry'
			[2] = ...
		},
	}
}
]]--

babel.register = function(path_string, lang_list)
	private.cp("creating new shelf using " .. path_string)
	local key = lib.generate_key()
	local shelf = {
		path = path_string, --replace with path/to/owner (if possible?)
	}
	
	local mstime = gkmisc.GetGameTime()
	
	local excess_flag = false
	
	for i=1, #lang_list do
		local lang_code = lang_list[i]
		if type(lang_code) == "string" then
			--todo: if extension is present, don't hardcode-add it. only add if missing
			local lang_file = path_string .. lang_code .. ".ini"
			if gksys.IsExist(lang_file) then
				lib.log_error("	book " .. lang_code .. " present!")
				if not support[lang_code] then
					private.add_support(lang_code, lang_file)
				end
				
				shelf[lang_code] = {
					path = lang_file,
				}
				
				local counter = -1
				if config.precache == "YES" then
					while true do
						counter = counter + 1
						
						local output = gkini.ReadString2('babel', tostring(counter), "", lang_file)
						if output == "" then
							break
						end
						shelf[lang_code][counter] = output
					end
					lib.log_error("	language book had " .. tostring(counter) .. " lines to cache!")
				end
			else
				lib.log_error("	\127FF0000missing language book " .. lang_code .. "\127FFFFFF")
			end
		end
	end
	
	lib.log_error("	shelf generated in " .. tostring(gkmisc.GetGameTime() - mstime) .. "ms")
	
	tower[key] = shelf
	
	return key
end
