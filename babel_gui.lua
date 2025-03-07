local file_args = {...}

local babel = file_args[1]
local private = file_args[2]


--imported from helium library v0.5.x
--will probably directly request helium in the future - shared library is > monolithic code!
local he = {}
--a horizontally scrolling pane, which iup.list cannot do
he.hscroll = function(intable)
	local default = {
		expand = "YES",
		[1] = iup.hbox { },
	}
	
	for k, v in pairs(intable) do
		default[k] = v
	end
	
	local iup_element = default[1]
	default[1] = nil
	
	local imposter = public.primitives.clearframe {
		--used to get size of parent
		expand = "YES",
		iup.vbox {
			iup.hbox {
				iup.fill { },
			},
			iup.fill { },
		},
	}
	
	local content_frame = public.primitives.clearframe {
		cx = 0,
		cy = 0,
		iup_element,
	}
	
	local scroller
	scroller = public.primitives.hslider {
		scroll_event_cb = function()
			content_frame.cx = ((scroller:get_pos() * (content_frame.w - scroller.w)) / 100) * -1
			iup.Refresh(content_frame)
		end,
	}
	
	local cbox_area = iup.cbox {
		expand = "YES",
		content_frame,
	}
	
	default[1] = iup.vbox {
		cbox_area,
		scroller,
	}
	
	local root_frame = public.primitives.clearframe(default)
	root_frame.map_cb = function(self)
		if self.expand == "NO" then
			return
		end
		
		--todo: determine if cbox_area < frame size; hide scroller if true
		
		local root = imposter --iup.GetParent(self)
		local w = root.w
		local h = root.h
		self.size = tostring(w) .. "x" .. tostring(h)
		cbox_area.size = tostring(w) .. "x" .. tostring(h - Font.Default)
		scroller.size = tostring(w) .. "x" .. tostring(Font.Default)
		content_frame.size = tostring(content_frame.w) .. "x" .. tostring(h - Font.Default)
		private.cp("hscroller fit-to-parent feedback:")
		private.cp("	parent w: " .. tostring(w))
		private.cp("	parent h: " .. tostring(h))
		private.cp("	size: " .. tostring(self.size))
		iup.Refresh(self)
		private.cp("	size (post-refresh): " .. tostring(self.size))
	end
	
	local final_frame = iup.zbox {
		root_frame,
		default.expand == "YES" and imposter or nil,
	}
	
	return final_frame
end

--end helium





local flag_select = function()
	local current_langs = babel.get_langs_on_shelf()
	local flags = {}
	
	table.sort(current_langs, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	
	for index, lang_code in ipairs(current_langs) do
		flags[lang_code] = babel.get_lang_flag(lang_code)
	end
	
	
end

local create_config = function()
	
end

babel.open = function()
	
end