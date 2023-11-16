CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	-- Loads a file from the testing directory and returns it as a str
	local src = TestSuite:LoadFile("file_example.txt")
	TestSuite.Compile(src,nil,CPUTest.RunCPU,CPUTest.CompileError)
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
		print("R0 is not 4096! R0 is "..tostring(CPUTest.VM.R0))
		CPUTest.TestSuite.FinishTest(true)
	end
end

function CPUTest.CompileError()
	print('hit a compile time error')
	CPUTest.TestSuite.FinishTest(true)
end

