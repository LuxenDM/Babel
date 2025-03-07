local file_args = {...}

local babel = file_args[1]
babel.charset = {}
local private = file_args[2]

--[[
	this file is for future planned content:
	
	character glyph loading:
		mapping new glyphs to proper char code
		OR mapping non-char glyphs to random char code
		
	string decoding:
		replaces placeholders with glyphs by name or ID, returns complete string
		useful if expected character codes are out-of-order
		
		example:
			input: ni%{UNI, Latin Small Letter N with Tilde}%{UNI, Latin Small Letter O with Acute}
			output: niñó
			
			%{}
			Initiates a lookup
			
			UNI: character table to look in
			Latin Small Letter N with Tilde: character ID in table
]]--

local glyph_tracker = {
	_WAITING = {
		--list of requested character IDs that cannot be added yet
	},
	_CHAR_INFO = {
		--[[
			lists each character and extended info about each, such as
			
			mod providing
			image path
			time provided
			positioning info within sprite sheet (if applicable)
			requested character ID
			actual character ID
			...
		]]--
	},
	ID = {
		--list of unique names and their ids
		--provider.name = char_id
	},
	UNI = {
		--list of unicode characters by official unicode name
		--uni_name = char_id
	},
	EMOTE = {
		--list of emotes by text representation
		--emote-representation = char_id
	},
}

local heights = {14,16,18,19,20,22,23,24,25,26,28,31,39,52,72}
if iup.GetFontGlyphHeights then
	heights = {
		iup.GetFontGlyphHeights(),
	}
end

babel.charset.add_new_glyph = function(glyph_table)
	local default = {
		provider = nil,
		unique_name = nil,
		unicode_name = nil,
		emote = nil,
		requested_id = 129,
			--we can't ACTUALLY force this except with out-of-order loading and a prayer
			--project for a future day, implementing that.
		img_path = babel.path .. "assets/char_null.png",
		position = {
			u0 = 0,
			v0 = 0,
			u1 = (69/128),
			v1 = 1,
		},
	}
	
	for k, v in pairs(glyph_table) do
		default[k] = v
	end
	
	if not default.provider then
		return false, "no provider given"
	end
	
	if not default.unique_name then
		return false, "no name given"
	end
	
	local texture_id = iup.AddFontTexture(default.img_path)
	local actual_char = iup.AddFontGlyph(texture_id) --todo: this is what we should defer
	
	default.creation_date = os.date()
	default.creation_time = os.time()
	default.texture_id = texture_id
	default.actual_id = actual_char
	
	for index, font_height in ipairs(heights) do
		local advance = font_height * (10 / 128)
		local height_specific_table = {
			texid = texture_id,
			advance = advance,
			tracking = font_height * (69 / 128) + (advance * 2),
			totalwidth = font_height * (69 / 128),
			height = font_height,
			u0 = default.u0,
			v0 = default.v0,
			u1 = default.u1,
			v1 = default.v1,
		}
			
		iup.UpdateFontGlyph(actual_char, {height_specific_table})
	end
	
	glyph_tracker['_CHAR_INFO'][actual_char] = default
	glyph_tracker.ID[default.provider .. "." .. default.unique_name] = actual_char
	
	--todo: don't allow overwrites of existing chars here
	if default.unicode_name then
		glyph_tracker.UNI[default.unicode_name] = actual_char
	end
	
	if default.emote then
		glyph_tracker.EMOTE[default.emote] = actual_char
	end
	
	lib.log_error("[Babel] Created new font glyph at character ID " .. string.char(actual_char), 1)
	lib.log_error("	glyph file path: " .. default.img_path, 1)
	
	return actual_char
end

