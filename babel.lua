local babel_ver = "1.2.0"
local babel_path = lib.get_path("babel", babel_ver)

local settings_read_flag = false
local settings = {
	current_language = "",
	precache = "NO",
}

local langs = {
	'en',
	'es',
	'fr',
	'pt',
}

local babel = {} --public class table
local private = {} --private values passed to secondary modules

local lang_key = "null"

local private.bstr = function(id, val)
	return babel.fetch(lang_key, id, val)
end

local update_class
update_class = function()
	
	if not settings_read_flag then
		settings_read_flag = true
		
		for option, default in pairs(settings) do
			settings[option] = gkini.ReadString("babel", option, default)
		end
	end
	
	local class = {
		CCD1 = true,
		open = nil,
		config = nil,
		description = private.bstr(0, "Babel is a mod library for providing easy translation table support to other mods. To select your preferred language, open the Babel settings menu or select your preferred language from the smart-configuration tool provided by your LME environment. \nMods must provide a language table for your selected language, or a default fallback will be used instead. Babel itself provides English, Spanish, French, and Portuguese language tables by default, though more can be easily added if available."),
		manifest = {
			babel_path .. "/babel.lua", --core library
			babel_path .. "/babel.ini", --LME declaration
			babel_path .. "/lang/en.ini", --Babel English table
			babel_path .. "/lang/es.ini", --Babel Spanish table
			babel_path .. "/lang/fr.ini", --Babel French table
			babel_path .. "/lang/pt.ini", --Babel Portuguese table
			babel_path .. "/assets/flag_null.png", --language with no provided flag
			babel_path .. "/assets/flag_en.png", --english language selector flag
			babel_path .. "/assets/flag_es.png", --spanish language selector flag
			babel_path .. "/assets/flag_fr.png", --french language selector flag
			babel_path .. "/assets/flag_pt.png", --portuguese language selector flag
		},
		
		smart_config = {
			title = "Babel v" .. babel_ver .. " " .. private.bstr(0, "Smart-Configuration Menu"),
			cb = function(id, val)
				if id == "update_check" then
					Gamme.OpenWebBrowser("https://www.nexusmods.com/vendettaonline/mods/11")
				elseif settings[id] then
					settings[id] = val
					gkini.WriteString("Babel", id, val)
					update_class()
				end
			end,
			rule = {
				type = "rule",
			},
			spacer = {
				type = "spacer",
			},
			current_language = {
				"en",
				type = "dropdown",
				display = private.bstr(0, "Current Language") .. ":",
				default = 1,
			},
			precache = {
				[1] = settings.precache,
				type = "toggle",
				display = private.bstr(0, "Preload all language tables") .. ":",
			},
			update_check = {
				type = "action",
				display = "",
				align = "right",
				[1] = private.bstr(0, "Check for updates") .. "...",
			},
			
			"current_language",
			"precache",
			"rule",
			"spacer",
			"update_check",
		},
	}
	
	--update 'current_language' list
	for k, v in ipairs(langs) do
		class.smart_config.current_language[k] = v --adds the option
		if v == settings.current_language then
			class.smart_config.current_language.default = k --sets the current option
		end
	end
	
	--update public class
	for k, v in pairs(class) do
		babel[k] = v
	end
	
	lib.set_class("babel", babel_ver, babel)
end

local load_module = function(file_path)
	local valid_file_path = lib.find_file(babel_path .. file_path)
	if valid_file_path then
		lib.log_error("	loading sub_module " .. valid_file_path, "babel", babel_ver, 1)
		
		local file_f, err = loadfile(valid_file_path)
		
		if not file_f then
			lib.log_error("Failure loading sub_module: " .. tostring(err), "babel", babel_ver, 3)
		else
			file_f(babel, private)
		end
	else
		lib.log_error("Failure finding sub_module " .. file_path, "babel", babel_ver, 3)
	end
end



local tower = {}
--[[
	<shelf id> = {
		path = path to language tables (pre-v1.x feature, not used in favor of books storing custom location)
		<language book id> = {
			path = path to specific language
			|>If Precaching
			|0=Language Descriptor
			|1=String 1
			|2=String 2
			|...
			
			if precaching is enabled,  Babel will fill the book out when the book is created
				this can GREATLY increase user load times, depending on storage speeds and book sizes
			if precaching is disabled, Babel will fill the book out as each item is fetched
				fetching the same item will reference the cache instead of reading from file, which is slower
		},
		...
	}
]]--

babel.add_translation = function(path, lang_code)
	--adds a new language to Babel itself.
	local realfile = path .. lang_code .. ".ini"
	local status = babel.add_new_lang(lang_key, path, lang_code)
	
	if status then
		table.insert(langs, lang_code)
		langs[lang_code] = {
			path = path,
			file = lang_code .. ".ini"
			flag = gkini.ReadString2('babel', 'flag', 'flag_null.png', realfile),
		}
	end
end

babel.register_custom_lang = babel.add_translation
--this keyword will be deprecated eventually. use add_translation instead!

babel.add_new_lang = function(ref_id, path, lang)
	--[[
	used to add a new language to an existing shelf
	other mods must give an API to allow this, as ref_id is a key
	
	path: path/to/file (but don't include file itself)
	lang: language code/file name (do not include .ini)
	
	]]--
	
	if type(path) ~= "string" or type(lang) ~= "string" then
		return false, "bad argument format"
	end
	
	local realfile = path .. lang .. ".ini"
	
	if not gksys.IsExist(realfile) then
		lib.log_error("	\127FF0000Missing language book " .. lang .. "\127FFFFFF")
		return false, "book not found"
	end
	
	if not tower[ref_id] then
		return false, "invalid shelf ID"
	end
	
	if tower[ref_id][lang] then
		return false, "book already loaded"
	end
	
	lib.log_error("	loading book " .. lang)
	
	local book = {
		path = realfile
	}
	
	if settings.precache == "YES" then
		local mstime = gkmisc.GetGameTime()
		lib.log_error("	caching book...")
		
		local counter = -1
		while true do
			counter = counter + 1
			
			local output = gkini.ReadString2('babel', tostring(counter), "", realfile)
			if output == "" then
				break
			end
			book[counter] = output
		end
		
		lib.log_error("	language book had " .. tostring(counter) .. " lines to cache!")
		lib.log_error("	book generated in " .. tostring(gkmisc.GetGameTime() - mstime) .. "ms")
	end
	
	tower[ref_id][lang] = book
	
	return true
end

babel.register = function(path_string, lang_list)
	if type(path_string) ~= "string" or type(lang_list) ~= "table" then
		return false
	end
	
	lib.log_error("[Babel] Creating new shelf using " .. path_string)
	
	local key = lib.generate_key()
	local shelf = {
		path = path_string,
	}
	tower[key] = shelf
	
	
	local mstime = gkmisc.GetGameTime()
	
	for i=1, #lang_list do
		local lang_code = lang_list[i]
		if type(lang_code) == "string" then
			--if lang_code is not part of babel's supported langs, add it!
			
			babel.add_new_lang(key, path_string, lang_code)
		end
	end
	
	lib.log_error("	shelf generated in " .. tostring(gkmisc.GetGameTime() - mstime) .. "ms")
	
	tower[key] = shelf
	
	return key
end

babel.fetch = function(ref_id, str_id, def_str)
	if not tower[ref_id] then
		--this plugin doesn't have a shelf in the tower
		return def_str
	end
	
	if not tower[ref_id][settings.current_language] then
		--this plugin doesn't have this book on its shelf
		return def_str
	end
	
	
	if tower[ref_id][settings.current_language][str_id] then
		--the value was pre-cached
		return tower[ref_id][settings.current_language][str_id]
	else
		--not pre-cached, read file, cache result, and push
		local readval = gkini.ReadString2("babel", tostring(tonumber(str_id)), "", tower[ref_id][settings.current_language].path)
		if readval == "" then
			--value not found, use default fallback
			readval = def_str
		else
			--value found, cache and push
			tower[ref_id][settings.current_language][str_id] = readval
		end
		
		return readval
	end
end

babel.get_user_lang = function()
	return settings.current_language
end

babel.get_langs_on_shelf = function(ref_id)
	--returns the language books on a shelf. if shelf is false/nil, returns Babel's.
	if not ref_id then
		ref_id = lang_key
	end
	
	if not tower[ref_id] then
		return false, "invalid shelf ID"
	end
	
	local books = {}
	for k, _ in ipairs(tower[ref_id]) do
		if k ~= "path" then
			table.insert(books, k)
			books[k] = true
		end
	end
	
	return books
end

babel.get_lang_flag = function(lang_code)
	--[[
		gets the file path to a flag for the selected language code
		This is only used for languages that Babel supports (or are added to it)
	]]--
	if not langs[lang_code] then
		return false, "invalid book ID"
	end
	
	local lang_data = langs[lang_code]
	local flag_path = lang_data.path
	local flag_filename = lang_data.flag
	
	local filename = ""
	for _, v in ipairs {
		flag_path .. flag_filename, --flag is stored with provider
		tostring(IMAGE_DIR) .. flag_filename, --flag is stored with skin directory
		babel_path .. "assets/" .. flag_filename, --flag is stored with Babel's assets
		babel_path .. "assets/flag_null.png", --fallback to null flag
	} do
		if gksys.IsExist(v) then
			filename = v
			break
		end
	end
	
	return filename
end

babel.get_config = function(option)
	return settings[option]
end

babel.set_config = function(option, val)
	if not settings[option] then
		return false, "invalid option"
	end
	
	settings[option] = tostring(val)
end


lang_key = babel.register(bable_path .. "lang/", {'en', 'es', 'fr', 'pt'})