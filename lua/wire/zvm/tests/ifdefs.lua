CPUTest = {}

--not x and y = 14, name "Test Y"
-- x and y = 11, name "Test Y"
-- x and not y = 1, name "Test Y"

-- culling update
-- not x and y = 12, name "Test Y"
-- x and y = 11, name "Test X and Y"
-- x and not y = 1, name "Test X"


CPUTest.ExpectedVariations1 = {"X","Y","X and Y","Y","Y","Y"} -- CPU Name vars
CPUTest.ExpectedVariations2 = {1,12,11,1,14,11}
CPUTest.ResultVariations1 = {}
CPUTest.ResultVariations2 = {}

CPUTest.Variations1 = {"true","false"}
CPUTest.Variations2 = {"#define x\n","#define y\n","#define x\n#define y\n"}
CPUTest.Variation1Index = 1
CPUTest.Variation2Index = 1

function CPUTest:RunTest(VM,TestSuite)
	CPUTest.VM = VM
	CPUTest.TestSuite = TestSuite
	-- Loads a file from the testing directory and returns it as a str
	CPUTest.Src = TestSuite:LoadFile("ifdefs.txt")
	CPUTest.CompileNext()
end

function CPUTest.CompileNext()
	local cursrc
	if CPUTest.Variation1Index <= #CPUTest.Variations1 then
		cursrc = "#pragma set NewIfDefs "..CPUTest.Variations1[CPUTest.Variation1Index].."\n"
	else
		return CPUTest.CompareResults()
	end
	if CPUTest.Variation2Index <= #CPUTest.Variations2 then
		cursrc = cursrc..CPUTest.Variations2[CPUTest.Variation2Index].."\n"..CPUTest.Src
		CPUTest.TestSuite.Compile(cursrc,nil,CPUTest.LogResults,CPUTest.CompileError)
	else
		CPUTest.Variation1Index = CPUTest.Variation1Index + 1
		CPUTest.Variation2Index = 1
		CPUTest.CompileNext()
	end
end

function CPUTest.LogResults()
	CPUTest.ResultVariations1[CPUTest.Variation2Index+#CPUTest.Variations2*(CPUTest.Variation1Index-1)] = CPUTest.TestSuite.GetCPUName() or "ERROR"
	CPUTest.ResultVariations2[CPUTest.Variation2Index+#CPUTest.Variations2*(CPUTest.Variation1Index-1)] = #CPUTest.TestSuite.GetCompileBuffer()+1 or "ERROR"
	CPUTest.Variation2Index = CPUTest.Variation2Index + 1
	CPUTest.CompileNext()
end

function CPUTest.CompareResults()
	local fail,results1,results2 = false,{},{}
	for ind,i in ipairs(CPUTest.ExpectedVariations1) do
		if CPUTest.ResultVariations1[ind] == "Test "..i then
				results1[ind] = true
			else
				fail = true
				results1[ind] = false
		end
	end
	for ind,i in ipairs(CPUTest.ExpectedVariations2) do
		if CPUTest.ResultVariations2[ind] == i then
			results2[ind] = true
		else
			fail = true
			results2[ind] = false
		end
	end
	if fail then
		CPUTest.TestSuite.Error('Unexpected test results!')
		PrintTable({CPUTest.ResultVariations1,results1,CPUTest.ResultVariations2,results2})
		CPUTest.TestSuite.FinishTest(true)
	else
		CPUTest.TestSuite.FinishTest(false)
	end
end

function CPUTest.CompileError(msg)
	CPUTest.TestSuite.Error('hit a compile time error '..msg)
	CPUTest.TestSuite.FinishTest(true)
end

