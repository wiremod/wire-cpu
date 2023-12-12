CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	TestSuite.Compile("MOV R0,1", nil, CPUTest.RunCPU, CPUTest.CompileError)
end

function CPUTest.RunCPU()
	local buff = CPUTest.TestSuite.GetCompileBuffer()
	local bus = CPUTest.TestSuite.CreateVirtualMemBus(#buff) -- get external ram device large enough to hold program
	CPUTest.TestSuite.FlashData(bus, buff) -- upload compiled to membus
	CPUTest.VM.RAMSize = 0
	CPUTest.VM.ROMSize = 0
	CPUTest.TestSuite.Initialize(CPUTest.VM, bus, nil) -- reinitialize the CPU with the membus
	CPUTest.VM.Clk = 1
	for i = 0, 16 do
		CPUTest.VM:RunStep()
	end

	-- False = no error, True = error
	if CPUTest.VM.R0 == 1 then
		CPUTest.TestSuite.FinishTest(false)
	else
		CPUTest.TestSuite.Error("CPU with no ram/rom failed to execute code from bus! R0 = " .. CPUTest.VM.R0)
		CPUTest.TestSuite.FinishTest(true)
	end
end

function CPUTest.CompileError(msg)
	CPUTest.TestSuite.Error("hit a compile time error " .. msg)
	CPUTest.TestSuite.FinishTest(true)
end
