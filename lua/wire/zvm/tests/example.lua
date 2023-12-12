CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	TestSuite.Compile("x: INC R0 JMP x",nil,CPUTest.RunCPU,CPUTest.CompileError)
end

function CPUTest.RunCPU()
	CPUTest.TestSuite.FlashData(CPUTest.VM,CPUTest.TestSuite.GetCompileBuffer()) -- upload compiled to virtual cpu
	CPUTest.VM.Clk = 1
	for i=0,4096 do
		CPUTest.VM:RunStep()
	end
	-- False = no error, True = error
	if CPUTest.VM.R0 == 4096 then
		CPUTest.TestSuite.FinishTest(false)
	else
		CPUTest.TestSuite.Error("R0 is not 4096! R0 is "..tostring(CPUTest.VM.R0))
		CPUTest.TestSuite.FinishTest(true)
	end
end

function CPUTest.CompileError(msg)
	CPUTest.TestSuite.Error("hit a compile time error "..msg)
	CPUTest.TestSuite.FinishTest(true)
end
