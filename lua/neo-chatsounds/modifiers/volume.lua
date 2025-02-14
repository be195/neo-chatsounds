local MODIFIER = {}

MODIFIER.Name = "volume"
MODIFIER.LegacySyntax = "^"
MODIFIER.DefaultValue = 1

function MODIFIER:ParseArgs(args)
	local volume = tonumber(args)
	if volume then return math.abs(volume) end

	return 1
end

function MODIFIER:LegacyParseArgs(args)
	local volume = tonumber(args)
	if volume then return math.abs(volume / 100) end

	return 1
end

function MODIFIER:GetValue()
	if not self.Value then return self.DefaultValue end
	if isfunction(self.ExpressionFn) then
		local _, ret = pcall(self.ExpressionFn)
		if not isnumber(ret) then return self.DefaultValue end

		return math.abs(ret)
	end

	return self.Value
end

function MODIFIER:OnStreamThink(stream)
	stream:SetVolume(self:GetValue())
end

return MODIFIER