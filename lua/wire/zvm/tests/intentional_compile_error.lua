CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	TestSuite.Compile("MOV R0,",nil,CPUTest.RunCPU,CPUTest.CompileError)
end

function CPUTest.RunCPU()
	CPUTest.TestSuite.Error("Compiler did not error when it should have!")
	CPUTest.TestSuite.FinishTest(true)
end

function CPUTest.CompileError()
	CPUTest.TestSuite.FinishTest(false)
end
