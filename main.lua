if isdeclared('lib') and type(lib) == "table" and lib[0] == "LME" then
	if not lib.is_exist('babel') then
		lib.register('plugins/Babel/babel.ini')
	end
end