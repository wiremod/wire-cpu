--------------------------------------------------------------------------------
-- Library for making and running automated tests for Zyelios Virtual Machine Programs
--
--
--------------------------------------------------------------------------------

TESTING = true
include("wire/cpulib.lua")
include("wire/client/hlzasm/hc_compiler.lua")


ZVMTestSuite = {
	TestFiles = {},
	TestQueue = {},
	TestStatuses = {}
}
local testDirectory = "wire/zvm/tests"
-- Make this dynamic, search directory under zvm/tests/ and run every lua in there
function ZVMTestSuite.RunAll()
	local files,directories = file.Find(testDirectory..'/*.lua',"LUA","nameasc")
	ZVMTestSuite.TestFiles = files or {}
	ZVMTestSuite.TestQueue = {}
	ZVMTestSuite.TestStatuses = {}
	for ind,i in ipairs(ZVMTestSuite.TestFiles) do -- copy with reversed indexes so we can use cheap popping
		ZVMTestSuite.TestQueue[(#ZVMTestSuite.TestFiles)+1-ind] = i
	end
	print(#ZVMTestSuite.TestFiles.." tests loaded")
	PrintTable(ZVMTestSuite.TestFiles)
	ZVMTestSuite.RunNextTest()
	print("Game needs to be unpaused in order to run the tests (estimated time to completion "..((#ZVMTestSuite.TestQueue)*0.25).." seconds)")
end

function ZVMTestSuite.FinishTest(fail)
	local finalFail = false
	if fail == nil then
		finalFail = true
	else
		finalFail = fail
	end
	ZVMTestSuite.TestStatuses[#ZVMTestSuite.TestStatuses+1] = finalFail -- auto fail on return nil
	ZVMTestSuite.TestQueue[#ZVMTestSuite.TestQueue] = nil
	local passed, failed = 0, 0
	if #ZVMTestSuite.TestQueue > 0 then
		timer.Simple(0.125,ZVMTestSuite.RunNextTest)
	else
		for ind,i in ipairs(ZVMTestSuite.TestFiles) do
			if ZVMTestSuite.TestStatuses[ind] then
				failed = failed + 1
				print("Error in "..i)
			else
				passed = passed + 1
				print(i.." passed tests")
			end
		end
		local passmod, errormod = "",""
		if passed > 1 then
			passmod = "s"
		end
		if failed > 1 then
			errormod = "s"
		end
		print(failed.." Failed test"..errormod..", "..passed.." Passed test"..passmod)
	end
end

function ZVMTestSuite.RunNextTest()
	local curVM = CPULib.VirtualMachine()
	curVM.Frequency = 2000
	print("Running "..ZVMTestSuite.TestQueue[#ZVMTestSuite.TestQueue])
	ZVMTestSuite.AddVirtualFunctions(curVM)
	include(testDirectory..'/'..ZVMTestSuite.TestQueue[#ZVMTestSuite.TestQueue])
	CPUTest:RunTest(curVM,ZVMTestSuite)
end

function ZVMTestSuite.Compile(SourceCode,FileName,SuccessCallback,ErrorCallback,TargetPlatform)
	ZVMTestSuite.CompileArgs = {
		SourceCode = SourceCode,
		FileName = FileName,
		SuccessCallback = SuccessCallback,
		ErrorCallback = ErrorCallback,
		TargetPlatform = TargetPlatform
	}
	-- Needs to delay next compile otherwise it'll halt if a test compiles two or more programs.
	timer.Simple(0.125,ZVMTestSuite.StartCompileInternal)
end

function ZVMTestSuite.StartCompileInternal()
	local SourceCode = ZVMTestSuite.CompileArgs.SourceCode
	local FileName = ZVMTestSuite.CompileArgs.FileName
	local SuccessCallback = ZVMTestSuite.CompileArgs.SuccessCallback
	local ErrorCallback = ZVMTestSuite.CompileArgs.ErrorCallback
	local TargetPlatform = ZVMTestSuite.CompileArgs.TargetPlatform
	CPULib.Compile(SourceCode,FileName,SuccessCallback,ErrorCallback,TargetPlatform)
end

function ZVMTestSuite.GetCompileBuffer()
	return CPULib.Buffer
end

function ZVMTestSuite.CreateVirtualMemBus(MembusSize)
	local virtualMemBus = {Size = MembusSize}
	function virtualMemBus:ReadCell(Address)
		if Address <= self.Size and Address > -1 then
			return virtualMemBus[Address]
		end
	end
	function virtualMemBus:WriteCell(Address,Value)
		if Address <= self.Size and Address > -1 then
			virtualMemBus[Address] = Value
			return true
		end
		return false
	end
	return virtualMemBus
end

function ZVMTestSuite.CreateVirtualIOBus(IOBusSize)
	local virtualIOBus = {InPorts = {},OutPorts = {}, Size = IOBusSize-1}
	function virtualIOBus:ReadCell(Address)
		if Address <= self.Size and Address > -1 then
			return self.InPorts[Address]
		end
	end
	function virtualIOBus:WriteCell(Address,Value)
		if Address <= self.Size and Address > -1 then
			self.OutPorts[Address] = Value
			return true
		end
		return false
	end
	return virtualIOBus
end

function ZVMTestSuite.AddVirtualFunctions(VM)
	function VM:FlashData(data)
		ZVMTestSuite:FlashData(self,data)
	end
	function VM:RunStep()
		ZVMTestSuite:Run(self)
	end
	function VM:TriggerInput(iname,name)
		ZVMTestSuite.TriggerInput(self,iname,name)
	end
	function VM:SignalError(errorcode)
		self.Error = errorcode
	end
end

function ZVMTestSuite.FlashData(VM,data)
	if VM.Reset then
		VM:Reset()
	end
	for k,v in pairs(data) do
		VM:WriteCell(k,tonumber(v) or 0)
		if VM.ROMSize then
			if (k >= 0) and (k < VM.ROMSize) then
				VM.ROM[k] = tonumber(v) or 0
			end
		end
	end
end

-- Execute ZCPU virtual machine
function ZVMTestSuite:Run(VM)
	-- Calculate time-related variables
	local CurrentTime = CurTime()
	local DeltaTime = math.min(1/30,CurrentTime - (VM.PreviousTime or 0))
	VM.PreviousTime = CurrentTime

	-- Check if need to run till specific instruction
	if VM.BreakpointInstructions then
		VM.TimerDT = DeltaTime
		VM.CPUIF = VM
		VM:Step(8,function(VM)
			VM:Dyn_Emit("if (VM.CPUIF.Clk and not VM.CPUIF.VMStopped) and (VM.CPUIF.OnVMStep) then")
				VM:Dyn_EmitState()
				VM:Emit("VM.CPUIF.OnVMStep()")
			VM:Emit("end")
			VM:Emit("if VM.CPUIF.BreakpointInstructions[VM.IP] then")
				VM:Dyn_EmitState()
				VM:Emit("VM.CPUIF.OnBreakpointInstruction(VM.IP)")
				VM:Emit("VM.CPUIF.VMStopped = true")
				VM:Emit("VM.TMR = VM.TMR + "..VM.PrecompileInstruction)
				VM:Emit("VM.CODEBYTES = VM.CODEBYTES + "..VM.PrecompileBytes)
				VM:Emit("if true then return end")
			VM:Emit("end")
			VM:Emit("if VM.CPUIF.LastInstruction and ((VM.IP > VM.CPUIF.LastInstruction) or VM.CPUIF.ForceLastInstruction) then")
				VM:Dyn_EmitState()
				VM:Emit("VM.CPUIF.ForceLastInstruction = nil")
				VM:Emit("VM.CPUIF.OnLastInstruction()")
				VM:Emit("VM.CPUIF.VMStopped = true")
				VM:Emit("VM.TMR = VM.TMR + "..VM.PrecompileInstruction)
				VM:Emit("VM.CODEBYTES = VM.CODEBYTES + "..VM.PrecompileBytes)
				VM:Emit("if true then return end")
			VM:Emit("end")
		end)
		VM.CPUIF = nil
	else
		-- How many steps VM must make to keep up with execution
		local Cycles = math.max(1,math.floor(VM.Frequency*DeltaTime*0.5))
		VM.TimerDT = (DeltaTime/Cycles)

		while (Cycles > 0) and (VM.Clk) and (not VMStopped) and (VM.Idle == 0) do
			-- Run VM step
			local previousTMR = VM.TMR
			VM:Step()
			Cycles = Cycles - math.max(1, VM.TMR - previousTMR)
		end
	end

	-- Update VM timer
	VM.TIMER = VM.TIMER + DeltaTime

	-- Reset idle register
	VM.Idle = 0
end

function ZVMTestSuite.TriggerInput(VM, iname, value)
	if iname == "Clk" then
		VM.Clk = (value >= 1)
		if VM.Clk then
			VM.VMStopped = false
		end
	elseif iname == "Frequency" then
		if value > 0 then VM.Frequency = math.floor(value) end
	elseif iname == "Reset" then   --VM may be nil
		if VM.HWDEBUG ~= 0 then
			VM.DBGSTATE = math.floor(value)
			if (value > 0) and (value <= 1.0) then VM:Reset() end
		else
			if value >= 1.0 then VM:Reset() end
		end
		-- Wire_TriggerOutput(VM, "Error", 0)
	elseif iname == "Interrupt" then
		if (value >= 32) and (value < 256) then
			if (VM.Clk and not VM.VMStopped) then VM:ExternalInterrupt(math.floor(value)) end
		end
	end
end

function ZVMTestSuite.Initialize(VM,Membus,IOBus)
	-- CPU platform settings
	VM.Clk = false -- whether the Clk input is on
	VM.VMStopped = false -- whether the VM has halted itself (e.g. by running off the end of the program)
	VM.Frequency = 2000
	-- Create virtual machine
	VM.VM = CPULib.VirtualMachine()
	VM.SerialNo = CPULib.GenerateSN("CPU")
	VM:Reset()

	VM.SignalError = function(VM,errorCode)
		Wire_TriggerOutput(VM, "Error", errorCode)
	end
	VM.SignalShutdown = function(VM)
		VM.VMStopped = true
	end
	VM.ExternalWrite = function(VM,Address,Value)
		if Address >= 0 then -- Use MemBus
			local MemBusSource = Membus
			if MemBusSource then
				if MemBusSource.ReadCell then
					local result = MemBusSource:WriteCell(Address-VM.RAMSize,Value)
					if result then return true
					else VM:Interrupt(7,Address) return false
					end
				else VM:Interrupt(8,Address) return false
				end
			else VM:Interrupt(7,Address) return false
			end
		else -- Use IOBus
			local IOBusSource = IOBus
			if IOBusSource then
				if IOBusSource.ReadCell then
					local result = IOBusSource:WriteCell(-Address-1,Value)
					if result then return true
					else VM:Interrupt(10,-Address-1) return false
					end
				else VM:Interrupt(8,Address+1) return false
				end
			else return true
			end
		end
	end
	VM.ExternalRead = function(VM,Address)
		if Address >= 0 then -- Use MemBus
			local MemBusSource = Membus
			if MemBusSource then
				if MemBusSource.ReadCell then
					local result = MemBusSource:ReadCell(Address-VM.RAMSize)
					if isnumber(result) then return result
					else VM:Interrupt(7,Address) return
					end
				else VM:Interrupt(8,Address) return
				end
			else VM:Interrupt(7,Address) return
			end
		else -- Use IOBus
			local IOBusSource = IOBus
			if IOBusSource then
				if IOBusSource.ReadCell then
					local result = IOBusSource:ReadCell(-Address-1)
					if isnumber(result) then return result
					else VM:Interrupt(10,-Address-1) return
					end
				else VM:Interrupt(8,Address+1) return
				end
			else return 0
			end
		end
	end

	local oldReset = VM.Reset
	VM.Reset = function(...)
		if VM.Clk and VM.VMStopped then
			--VM:NextThink(CurTime())
		end
		VM.VMStopped = false
		return oldReset(...)
	end
end


concommand.Add("ZCPU_RUN_AUTO_TESTS",ZVMTestSuite.RunAll,nil,"runs zcpu tests")
