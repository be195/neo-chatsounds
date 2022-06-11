local MODIFIER = {}

MODIFIER.Name = "overlap"
MODIFIER.DefaultValue = 0

function MODIFIER:ParseArgs(args)
	local n = tonumber(args)
	if not n then return 0 end

	return math.max(0, n)
end

return MODIFIER