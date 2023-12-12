CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	TestSuite.Compile("CPUGET R0,43 MOV [R0],1 MOV R1,[R0]",nil,CPUTest.RunCPU,CPUTest.CompileError)
end

function CPUTest.RunCPU()
	CPUTest.TestSuite.FlashData(CPUTest.VM,CPUTest.TestSuite.GetCompileBuffer()) -- upload compiled to virtual cpu
	local bus = CPUTest.TestSuite.CreateVirtualMemBus(4) -- get external ram device of size 4
	CPUTest.TestSuite.Initialize(CPUTest.VM,bus,nil) -- reinitialize the CPU with the membus
	CPUTest.VM.Clk = 1
	for i=0,16 do
		CPUTest.VM:RunStep()
	end

	-- False = no error, True = error
	if bus:ReadCell(0) == 1 then
		if CPUTest.VM.R1 == 1 then
			CPUTest.TestSuite.FinishTest(false)
		else
			CPUTest.TestSuite.Error("CPU failed to read the bus! R1 was "..tostring(CPUTest.VM.R1))
			CPUTest.TestSuite.FinishTest(true)
		end
	else
		CPUTest.TestSuite.Error("CPU failed to write to bus! "..tostring(bus:ReadCell(0)))
		CPUTest.TestSuite.FinishTest(true)
	end
end

function CPUTest.CompileError(msg)
	CPUTest.TestSuite.Error("hit a compile time error "..msg)
	CPUTest.TestSuite.FinishTest(true)
end
