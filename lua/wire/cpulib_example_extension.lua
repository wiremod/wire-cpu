if not CPULib then
	include("wire/cpulib.lua")	
end

local myGPUExtension = {
	Platform = "GPU",
	Instructions = {{
		Name = "GPU_TEST1",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Sets Register X to constant 42",
		["OpFunc"] = function(self)
			-- The end value of the code in Dyn_EmitOperand will be assigned
			-- to the first/left hand register used in this instruction
			self:Dyn_EmitOperand("42")
		end
	},
	{
		Name = "GPU_TEST2",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Divides Register X by constant 24",
		["OpFunc"] = function(self)
			-- $1 and $2 refer to the first, and second operands of the instruction respectively
			self:Dyn_EmitOperand("$1/24")
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
		Description = "Divides Register X by constant 24",
		["OpFunc"] = function(self)
			-- $1 and $2 refer to the first, and second operands of the instruction respectively
			self:Dyn_EmitOperand("$1/24")
		end
	}}
}


local mySPUExtension = {
	Platform = "SPU",
	Instructions = {{
		Name = "SPU_TEST1",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Sets Register X to constant 42",
		["OpFunc"] = function(self)
			-- The end value of the code in Dyn_EmitOperand will be assigned
			-- to the first/left hand register used in this instruction
			self:Dyn_EmitOperand("42")
		end
	},
	{
		Name = "SPU_TEST2",
		Operands = 1,
		Version = 0.42,
		Flags = {"W1"}, -- writes first operand
		Op1Name = "X",
		Op2Name = "",
		Description = "Divides Register X by constant 24",
		["OpFunc"] = function(self)
			-- $1 and $2 refer to the first, and second operands of the instruction respectively
			self:Dyn_EmitOperand("$1/24")
		end
	}}
}

-- CPULib:RegisterExtension("gpu_test", myGPUExtension)
-- CPULib:RegisterExtension("spu_test", mySPUExtension)
-- CPULib:RegisterExtension("cpu_test", myCPUExtension)
