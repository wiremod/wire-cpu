CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	-- Loads a file from the testing directory and returns it as a str
	local src = TestSuite:LoadFile("includes_1.txt")
	TestSuite.Compile(src,nil,CPUTest.RunCPU,CPUTest.CompileError)
end

function CPUTest.RunCPU()
	CPUTest.TestSuite.FlashData(CPUTest.VM,CPUTest.TestSuite.GetCompileBuffer()) -- upload compiled to virtual cpu
	CPUTest.VM.Clk = 1
	for i=0,16 do
		CPUTest.VM:RunStep()
	end
	-- False = no error, True = error
	if CPUTest.VM.R0 == 2 then
		CPUTest.TestSuite.FinishTest(false)
	else
		CPUTest.TestSuite.Error("R0 is not 2! R0 is "..tostring(CPUTest.VM.R0))
		CPUTest.TestSuite.FinishTest(true)
	end
end

function CPUTest.CompileError(msg)
	CPUTest.TestSuite.Error("hit a compile time error "..msg)
	CPUTest.TestSuite.FinishTest(true)
end
