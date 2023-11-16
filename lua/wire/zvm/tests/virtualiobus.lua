CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	TestSuite.Compile("MOV PORT0,1 MOV R0,PORT0",nil,CPUTest.RunCPU,CPUTest.CompileError)
end

function CPUTest.RunCPU()
	CPUTest.TestSuite.FlashData(CPUTest.VM,CPUTest.TestSuite.GetCompileBuffer()) -- upload compiled to virtual cpu
	local IOBus = CPUTest.TestSuite.CreateVirtualIOBus(4) -- get external IO device of size 4
	CPUTest.TestSuite.Initialize(CPUTest.VM,nil,IOBus) -- reinitialize the CPU with the IOBus
	IOBus.InPorts[0] = 24
	CPUTest.VM.Clk = 1
	for i=0,16 do
		CPUTest.VM:RunStep()
	end

	-- False = no error, True = error
	if IOBus:ReadCell(0) == 24 then
		if IOBus.OutPorts[0] == 1 then
			if CPUTest.VM.R0 == 24 then
				CPUTest.TestSuite.FinishTest(false)
			else
				CPUTest.TestSuite.Error("CPU failed to read input port! R0 = "..CPUTest.VM.R0)
				CPUTest.TestSuite.FinishTest(true)
			end
		else
			CPUTest.TestSuite.Error("CPU failed to write to output port! Port0 = "..IOBus.OutPorts[0])
		end
	else
		CPUTest.TestSuite.Error("CPU wrote to input ports! "..tostring(IOBus:ReadCell(0)))
		CPUTest.TestSuite.FinishTest(true)
	end
end

function CPUTest.CompileError(msg)
	CPUTest.TestSuite.Error('hit a compile time error '..msg)
	CPUTest.TestSuite.FinishTest(true)
end
