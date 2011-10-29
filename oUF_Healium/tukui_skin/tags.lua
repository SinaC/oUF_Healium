local H, C, L, oUF = unpack(select(2, ...))

local utf8sub = function(string, i, dots)
	if not string then return end
	local bytes = string:len()
	if (bytes <= i) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = string:byte(pos)
			if (c > 0 and c <= 127) then
				pos = pos + 1
			elseif (c >= 192 and c <= 223) then
				pos = pos + 2
			elseif (c >= 224 and c <= 239) then
				pos = pos + 3
			elseif (c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if (len == i) then break end
		end

		if (len == i and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and '...' or '')
		else
			return string
		end
	end
end

oUF.Tags.Events['oUF_Healium:namemedium'] = 'UNIT_NAME_UPDATE'
oUF.Tags.Methods['oUF_Healium:namemedium'] = function(unit)
	local name = UnitName(unit)
	return utf8sub(name, 15, true)
end

-- oUF.Tags = tags
-- oUF.TagEvents = tagEvents

-- oUF.Tags = {
	-- Methods = tags,
	-- Events = tagEvents,
	-- SharedEvents = unitlessEvents,

-- }