CPUTest = {}

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	TestSuite.Compile("MOV R0,6 ADD R0,R0 MUL R0,2",nil,CPUTest.CompileNext,CPUTest.CompileError)
	-- end result of the above code should be R0 = 24
end

function CPUTest.CompileNext()
	local buff = CPUTest.TestSuite.GetCompileBuffer()
	local IOBus = CPUTest.TestSuite.CreateVirtualIOBus(#buff+1) -- create an IOBus large enough to hold this code
	PrintTable(buff)
	CPUTest.IOBus = IOBus
	-- reverse the compiled code, the CPU will read them in reverse if it's in the IOBus
	-- because CS will be negative, and IP only increments
	-- ipairs won't index 0 and the cpu compile buffer uses 0
	for i=0,#buff do
		IOBus.InPorts[#buff-i] = buff[i]
	end
	IOBus.OldReadCell = IOBus.ReadCell
	IOBus.AccessLog = {}
	function IOBus:ReadCell(address)
		IOBus.AccessLog[#IOBus.AccessLog+1] = {"read address"..tostring(address),self:OldReadCell(address) or "no value"}
		return self:OldReadCell(address)
	end
	-- JMPF jumps to 0 IP, CS = (code length+1)*-1 because first index of IOBus is "cell -1" of extern read/write
	local generatedcode = "CMP R0,0 JNER -3 JMPF 0,"..(#buff+1)*-1
	CPUTest.TestSuite.Compile(generatedcode,nil,CPUTest.RunCPU,CPUTest.CompileError)
end

function CPUTest.RunCPU()
	CPUTest.TestSuite.FlashData(CPUTest.VM,CPUTest.TestSuite.GetCompileBuffer()) -- upload compiled to virtual cpu
	CPUTest.TestSuite.Initialize(CPUTest.VM,nil,CPUTest.IOBus) -- reinitialize the CPU with the IOBus
	CPUTest.VM.Clk = 1
	for i=0,32 do
		CPUTest.VM:RunStep()
	end

	-- False = no error, True = error
	if CPUTest.VM.R0 == 24 then
		CPUTest.TestSuite.FinishTest(false)
	else
		PrintTable(CPUTest.IOBus)
		print("R0 != 24, R0 = "..tostring(CPUTest.VM.R0))
		CPUTest.TestSuite.FinishTest(true)
	end
end

function CPUTest.CompileError()
	print('hit a compile time error')
	CPUTest.TestSuite.FinishTest(true)
end

