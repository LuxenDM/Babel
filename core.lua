
local babel_ver = "1.2.0"
local babel_path = lib.get_path("babel", babel_ver)

local settings = {
	current_language = gkini.ReadString("Babel", "current_language", ""),
	precache = gkini.ReadString("Babel", "precache", "NO"),
	[1] = 'current_language',
	[2] = 'precache',
}

if settings.current_language == "" then
	settings.current_language = gkini.ReadString("Vendetta", "locale", "en")
	gkini.WriteString("Babel", "current_language", settings.current_language)
end

for i=1, #settings do
	lib.log_error("	" .. (settings[i] or "???") .. " >> " .. (settings[settings[i]] or "???"))
end
	
if settings.precache == "YES" then
	lib.log_error("	\127FFAAAAprecache language tables is enabled; delays depend on storage speed and size of tables to load...\127FFFFFF")
end



local supported_lang = {
	--languages must be supported to be selected, or added with babel.new_lang
	'en',
	'es',
	'fr',
	'pt',
}

local babel_key = "0"

local function update_config() end

local babel = {
	CCD1 = true, --Common Content Descriptor version 1
	open = nil,
	config = nil,
	smart_config = {
		title = "",
		cb = function(id, val)
			if settings[id] then
				settings[id] = val
				gkini.WriteString("Babel", id, val)
				update_config()
			end
		end,
		rule = {
			type = "rule",
		},
		spacer = {
			type = "spacer",
		},
		mod_header = {
			type = "header",
			display = "Babel",
		},
		mod_ver_disp = {
			type = "text",
			display = "Version " .. lib.get_latest("babel"),
			align = "center",
		},
		mod_descriptor = {
			type = "text",
			display = "Multi-language support for mods",
		},
		current_language = {
			'en',
			'es',
			'fr',
			'pt',
			type = "dropdown",
			display = "Current Language: ",
			default = 1,
		},
		precache = {
			[1] = settings.precache,
			type = "toggle",
			display = "Preload all language tables:",
		},
		[1] = 'mod_header',
		[2] = 'mod_ver_disp',
		[3] = 'mod_descriptor',
		[4] = 'rule',
		[5] = 'spacer',
		
		[6] = 'current_language',
		[7] = 'precache',
	},
	commands={'babel'},
	manifest={
		"plugins/Babel/main.lua",
		"plugins/Babel/core.lua",
		"plugins/Babel/babel.ini",
		"plugins/Babel/lang/en.ini",
		"plugins/Babel/lang/es.ini",
		"plugins/Babel/lang/fr.ini",
		"plugins/Babel/lang/pt.ini",
	},
	description=[[
Babel is a mod library meant to allow other mods to provide custom translation tables for their own interfaces. To select your preferred language, use /babel to open the settings menu. Mods must support the language you choose, or they will instead use their default text.
	]],
	
	--babel class functions:
	register = nil,
	add_new_lang = nil,
	fetch = nil,
	get_user_lang = nil,
	register_custom_lang = nil,
}

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

local babel_ref_key = 0

babel.register = function(path_string, lang_list)
	if type(path_string) ~= "string" or type(lang_list) ~= "table" then
		return false
	end
	
	lib.log_error("[Babel] Creating new shelf using " .. path_string)
	
	local key = lib.generate_key()
	local shelf = {
		path = path_string,
	}
	
	local mstime = gkmisc.GetGameTime()
	
	local excess_flag = false
	
	for i=1, #lang_list do
		local lang_code = lang_list[i]
		if type(lang_code) == "string" then
			if gksys.IsExist(path_string .. lang_code .. ".ini") then
				local lang_file = path_string .. lang_code .. ".ini"
				lib.log_error("	book " .. lang_code .. " present!")
				shelf[lang_code] = {
					path = lang_file,
				}
				
				local counter = -1
				if settings.precache == "YES" then
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

babel.add_new_lang = function(ref_id, path, lang)
	--[[
	used to add a new language to an existing shelf
	other mods must give an API to allow this, as ref_id is a key
	
	path: path/to/file (but don't include file itself)
	lang: language code/file name (do not include .ini)
	
	]]--
	
	if type(path) ~= "string" or type("lang") ~= "string" then
		return false
	end
	
	local realfile = path .. lang .. ".ini"
	
	if tower[ref_id] and not tower[ref_id][lang] and gksys.IsExist(realfile) then
		lib.log_error("[Babel] Updating shelf with new language book!")
		lib.log_error("	book provided is " .. lang)
		
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
	else
		return false
	end
end

babel.fetch = function(ref_id, str_id, def_str)
	if tower[ref_id] then
		if tower[ref_id][settings.current_language] then
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
		else
			--language not supported by this mod
			return def_str
		end
	else
		--this plugin doesn't have a shelf in the tower
		return def_str
	end
end

babel.get_user_lang = function()
	return settings.current_language
end

babel.register_custom_lang = function(path, custom_lang)
	--[[
	add a new language to select in Babel's preferred language list
	if a language is not added, it cannot be viewed!
	
	add_new_lang modifies existing shelves, but only if that mod has an API to get its shelf reference ID or provides its own function.
	register_lang can be assumed to be Babel's such function.
	]]--
	
	if type(custom_lang) ~= "string" or type(path) ~= "string" then
		--either this wasn't given a language to add, or the language is already added
		return
	end
	
	local status = babel.add_new_lang(babel_ref_key, path, custom_lang)
	
	if status == true then
		
		lib.log_error("[Babel] Language registered as selectable for user!")
		table.insert(supported_lang, custom_lang)
		table.insert(babel.smart_config.current_language, custom_lang)
		
		--update smart_config in case the user's preferred language is this one
		for k, v in ipairs(supported_lang) do
			if v == settings.current_language then
				babel.smart_config.current_language.default = k
			end
		end
		
		if babel_key ~= "0" then 
			--re-push class to update ccd1
			lib.unlock_class("babel", "0", babel_key)
			lib.set_class("babel", "0", babel)
			lib.lock_class("babel", "0", babel_key)
		end
		
	end
end











babel.open = function()
	
	local warn = iup.label {
		title = babel.fetch(babel_ref_key, 4, "Precaching language tables will greatly increase loading times!"),
		visible = "NO",
	}
	
	local cache_select = 1
	local cache_list = iup.list {
		dropdown = "YES",
		value = 1,
		[1] = "NO",
		[2] = "YES",
		action = function(self, t, i, c)
			if c == 1 then
				cache_select = i
				if i == 1 then
					warn.visible = "NO"
				else
					warn.visible = "YES"
				end
			end
		end,
	}
	
	local lang_select = 1
	local lang_list = iup.list {
		dropdown = "YES",
		value = '1',
		[1] = "WWWWWWWW",
		action = function(self, t, i, c)
			if c == 1 then
				lang_select = i
			end
		end,
	}
	
	for k,v in ipairs(supported_lang) do
		lang_list[k] = v
		if v == settings.current_language then
			lang_list.value = k
			lang_select = k
		end
	end
	
	local diag = iup.dialog {
		topmost = "YES",
		fullscreen = "YES",
		bgcolor = "0 0 0 100 *",
		iup.vbox {
			iup.fill { },
			iup.hbox {
				iup.fill { },
				iup.stationsubframe {
					iup.vbox {
						iup.hbox {
							iup.label {
								title = babel.fetch(babel_ref_key, 1, "Babel configuration"),
							},
							iup.fill { },
							iup.button {
								title = babel.fetch(babel_ref_key, 5, "Close"),
								action = function(self)
									HideDialog(self)
									iup.Destroy(iup.GetDialog(self))
								end,
							},
						},
						iup.stationsubsubframe {
							iup.vbox {
								iup.label {
									title = babel.fetch(babel_ref_key, 6, "Please select a language preference below:"),
								},
								iup.fill {
									size = "%2",
								},
								iup.hbox {
									iup.fill { },
									lang_list,
								},
								iup.fill {
									size = "%6",
								},
								iup.hbox {
									iup.label {
										title = babel.fetch(babel_ref_key, 3, "Do precaching?"),
									},
									iup.fill { },
									cache_list,
								},
								iup.hbox {
									iup.fill { },
									warn,
								},
								iup.hbox {
									iup.fill { },
									iup.button {
										title = babel.fetch(babel_ref_key, 2, "Apply?"),
										action = function(self)
											lib.log_error("[Babel] saving new config settings!")
											local binchoice = {"NO", "YES"}
											settings.precache = binchoice[cache_select]
											settings.current_language = supported_lang[lang_select]
											
											for i=1, #settings do
												gkini.WriteString("Babel", settings[i], settings[settings[i]])
												lib.log_error("	" .. settings[i] .. " >> " .. settings[settings[i]])
											end
											
											HideDialog(self)
											iup.Destroy(iup.GetDialog(self))
										end,
									},
								},
								iup.fill {
									size = "%1",
								},
							},
						},
					},
				},
				iup.fill { },
			},
			iup.fill { },
		},
	}
	
	diag:map()
	diag:show()
end

babel.config = babel.open

--load officially supported langs into Babel
babel_ref_key = babel.register('plugins/Babel/lang/', {'en', 'es', 'fr', 'pt'})

for k, v in ipairs(supported_lang) do
	if v == settings.current_language then
		babel.smart_config.current_language.default = k
	end
end









update_config = function()
	--declared local above
	lib.unlock_class("babel", "0", babel_key)
	
	babel.smart_config.mod_ver_disp.display = babel.fetch(babel_ref_key, 7, "Version ") .. lib.get_latest("babel")
	babel.smart_config.mod_descriptor.display = babel.fetch(babel_ref_key, 8, "Multi-language support for mods")
	babel.smart_config.current_language.display = babel.fetch(babel_ref_key, 9, "Current Language: ")
	babel.smart_config.precache.display = babel.fetch(babel_ref_key, 3, "Preload language tables: ")
	babel.description = babel.fetch(babel_ref_key, 10, babel.description)
	
	for k, v in ipairs(supported_lang) do
		if v == settings.current_language then
			babel.smart_config.current_language.default = k
		end
	end
	
	babel.smart_config.precache[1] = settings.precache
	
	lib.set_class("babel", "0", babel)
	lib.lock_class("babel", "0", babel_ref_key)
end

lib.set_class('babel', '0', babel)

RegisterUserCommand("babel", babel.open)

update_config()