if not CPULib then
	include("wire/cpulib.lua")	
end

local myGPUExtension = {
	Platform = "GPU",
	Instructions = {{
		Name = "EXT_TEST",
		Operands = 0,
		Version = 0.42,
		Flags = {},
		Op1Name = "",
		Op2Name = "",
		Description = "Basic test instruction, added by an extension.",
		["OpFunc"] = function(self)
			self:Dyn_Emit("print('test succeeded! Woohoo')")
		end
	}}
}

CPULib:RegisterExtension("basic_test", myGPUExtension)
