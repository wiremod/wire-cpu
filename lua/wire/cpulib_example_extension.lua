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

local myCPUExtension = {
	Platform = "CPU",
	Instructions = {{
		Name = "CPU_TEST1",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Sets Register X to constant 42",
		["OpFunc"] = function(self)
			-- The end value of the code in Dyn_EmitOperand will be assigned
			-- to the first/left hand register used in this instruction
			self:Dyn_Emit("print('cpu_test $1')")
			self:Dyn_EmitOperand("42")
		end
	},
	{
		Name = "CPU_TEST2",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Sets Register X to constant 24",
		["OpFunc"] = function(self)
			-- The end value of the code in Dyn_EmitOperand will be assigned
			-- to the first/left hand register used in this instruction
			self:Dyn_EmitOperand("24")
		end
	}}
}


CPULib:RegisterExtension("basic_test", myGPUExtension)
CPULib:RegisterExtension("cpu_test", myCPUExtension)
