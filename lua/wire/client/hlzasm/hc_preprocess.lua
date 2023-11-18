--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- Preprocessor macro parser
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Load file
function HCOMP:LoadFile(filename)
  return file.Read("data/"..self.Settings.CurrentPlatform.."Chip/"..filename, "GAME") -- So we also get /addons/wire/data/
end

-- Save file
function HCOMP:SaveFile(filename,text)
  file.Write(self.Settings.CurrentPlatform.."Chip/"..filename,text)
end

-- Trim spaces at string sides
local function trimString(str)
  return string.gsub(str, "^%s*(.-)%s*$", "%1")
end




--------------------------------------------------------------------------------
-- Handle preprocessor macro
function HCOMP:ParsePreprocessMacro(lineText,macroPosition)
  -- Trim spaces
  local macroLine = trimString(lineText)

  -- Find out macro name and parameters
  local macroNameEnd = (string.find(macroLine," ") or 0)
  local macroName = trimString(string.sub(macroLine,2,macroNameEnd-1))
  local macroParameters = trimString(string.sub(macroLine,macroNameEnd+1))

  -- Stop parsing macros inside of a failed ifdef/ifndef
  if self.SkipToEndIf then
    if macroName == "endif" or macroName == "else" then
      if self.EndIfsToSkip > 0 then 
        self.EndIfsToSkip = self.EndIfsToSkip - 1
      else
        self.SkipToEndIf = false
        return self:ParsePreprocessMacro(lineText,macroPosition) -- Rerun function to parse endif/else correctly
      end
    end
    if macroName == "ifdef" or macroName == "ifndef" then
      self.EndIfsToSkip = self.EndIfsToSkip + 1
    end
    local InComment = false
    -- If this while loop hits end of file before #endif it won't produce an error, seems like the original behavior for ifdefs
    while self:getChar() ~= "" do
      if self:getChar() == '/' and not InComment then
        self:nextChar()
        if self:getChar() == '*' then
          self:nextChar()
          InComment = true
        end
      if self:getChar() == '*' then
        self:nextChar()
        if self:getChar() == '/' then
          self:nextChar()
          InComment = false
        end
      end
      end
      if (self.Code[1].Col == 1) and (self:getChar() == "#") and not InComment then
        self.Code[1].NextCharPos = self.Code[1].NextCharPos - 1 -- Exit to let tokenizer handle from here
        break
      end
      self:nextChar()
    end
    return
  end

  if macroName == "pragma" then
    local pragmaName = string.lower(trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1)))
    local pragmaCommand = trimString(string.sub(macroParameters,(string.find(macroParameters," ") or 0)+1))

    if pragmaName == "set" then
      local entryName = trimString(string.sub(pragmaCommand,1,(string.find(pragmaCommand," ") or 0)-1))
      local entryValue = trimString(string.sub(pragmaCommand,(string.find(pragmaCommand," ") or 0)+1))

      if entryValue == "true" then
        self.Settings[entryName] = true
      elseif entryValue == "false" then
        self.Settings[entryName] = false
      else
        self.Settings[entryName] = tonumber(entryValue) or entryValue
      end
    elseif pragmaName == "language" then
      if string.lower(pragmaCommand) == "hlzasm" then self.Settings.CurrentLanguage = "HLZASM" end
      if string.lower(pragmaCommand) == "zasm"   then self.Settings.CurrentLanguage = "ZASM"   end
    elseif pragmaName == "crt" then
      local crtFilename = "lib\\"..string.lower(pragmaCommand).."\\init.txt"
      local fileText = self:LoadFile(crtFilename)
      if fileText then
        table.insert(self.Code, 1, { Text = fileText, Line = 1, Col = 1, File = crtFilename, ParentFile = macroPosition.File, NextCharPos = 1 })
      else
        self:Error("Unable to include CRT library "..pragmaCommand,
          macroPosition.Line,macroPosition.Col,macroPosition.File)
      end

      self.Defines[string.upper(pragmaCommand)] = ""
      table.insert(self.SearchPaths,"lib\\"..string.lower(pragmaCommand))
    elseif pragmaName == "cpuname" then
      CPULib.CPUName = pragmaCommand
    elseif pragmaName == "searchpath" then
      table.insert(self.SearchPaths,pragmaCommand)
    elseif pragmaName == "silence" or pragmaName == "mute" then
        if pragmaCommand == "self" then
          self.SilencedFiles[macroPosition.File] = { Silenced = true, FromParent = false }
        elseif pragmaCommand == "includes" or pragmaCommand == "other" then
          self.SilencedParents[macroPosition.File] = true
        end
    elseif pragmaName == "allow" or pragmaName == "zap" then
    if not self.Settings.AutoBusyRegisters then
      self.Settings.AutoBusyRegisters = true
    end
    local StartRegister, EndRegister = string.match(macroParameters, "([^,%s]+)%s*,%s*([^,%s]+)")
    if StartRegister == nil then
      self:Error("Missing register range argument",
      macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
    local StartInd,EndInd = -1,-1
    for ind,reg in ipairs(self.RegisterName) do
      if reg == StartRegister then
        StartInd = ind
      end
      if reg == EndRegister then
        EndInd = ind
        break
      end
    end
    if StartInd ~= -1 and EndInd ~= -1 then
      table.insert(self.Settings.AutoBusyRegisterRanges,{false,StartInd,EndInd})
    else
      self:Error(StartRegister .. " to " .. EndRegister .. " is an invalid range!",
      macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
    elseif pragmaName == "disallow" or pragmaName == "preserve" then
    if not self.Settings.AutoBusyRegisters then
      self.Settings.AutoBusyRegisters = true
    end
    local StartRegister, EndRegister = string.match(macroParameters, "([^,%s]+)%s*,%s*([^,%s]+)")
    if StartRegister == nil then
      self:Error("Missing register range argument",
      macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
    local StartInd,EndInd = -1,-1
    for ind,reg in ipairs(self.RegisterName) do
      if reg == StartRegister then
        StartInd = ind
      end
      if reg == EndRegister then
        EndInd = ind
        break
      end
    end
      if StartInd ~= -1 and EndInd ~= -1 then
        table.insert(self.Settings.AutoBusyRegisterRanges,{true,StartInd,EndInd})
      else
        self:Error(StartRegister .. " to " .. EndRegister .. " is an invalid range!",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
      end
    end
  elseif macroName == "define" then -- #define
    local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
    local defineValue = string.sub(macroParameters,(string.find(macroParameters," ") or 0)+1)
    if tonumber(defineName) then
      self:Error("Bad idea to redefine numbers",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
    self.Defines[defineName] = defineValue
  elseif macroName == "undef" then -- #undef
    local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
    if tonumber(defineName) then
      self:Error("Bad idea to undefine numbers",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
	self.Defines[defineName] = nil
  elseif macroName == "ifdef" then -- #ifdef
    local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
    if self.Defines[defineName] then
      self.IFDEFLevel[#self.IFDEFLevel+1] = false
    else
      if self.Settings.NewIfDefs then
        self.SkipToEndIf = true
        self.EndIfsToSkip = 0
      end
      self.IFDEFLevel[#self.IFDEFLevel+1] = true
    end
  elseif macroName == "ifndef" then -- #ifndef
    local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
    if not self.Defines[defineName] then
      self.IFDEFLevel[#self.IFDEFLevel+1] = false
    else
      if self.Settings.NewIfDefs then
        self.SkipToEndIf = true
        self.EndIfsToSkip = 0
      end
      self.IFDEFLevel[#self.IFDEFLevel+1] = true
    end
  elseif macroName == "else" then -- #else
    if #self.IFDEFLevel == 0 then
      self:Error("Unexpected #else macro",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end

    self.IFDEFLevel[#self.IFDEFLevel] = not self.IFDEFLevel[#self.IFDEFLevel]
  elseif macroName == "endif" then -- #endif
    if #self.IFDEFLevel == 0 then
      self:Error("Unexpected #endif macro",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end

    self.IFDEFLevel[#self.IFDEFLevel] = nil
  elseif (macroName == "include") or
         (macroName == "#include##") then -- #include or ZASM2 compatible ##include##
    local symL,symR
    local fileName

    -- ZASM2 compatibility syntax support
    if macroName == "#include##" then
      symL,symR = "<",">"
      fileName = trimString(string.sub(macroParameters,1,-1))
    else
      symL,symR = string.sub(macroParameters,1,1),string.sub(macroParameters,-1,-1)
      fileName = trimString(string.sub(macroParameters,2,-2))
    end

    -- Full file name including the path to file
    local fullFileName
    if (symL == "\"") and (symR == "\"") then -- File relative to current one
      fullFileName = self.WorkingDir..fileName
    elseif (symL == "<") and (symR == ">") then -- File relative to root directory
      fullFileName = fileName
    else
      self:Error("Invalid syntax for #include macro (wrong brackets)",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end

    -- Search for file on search paths
    local fileText = self:LoadFile(fullFileName)
    if (symL == "<") and (symR == ">") and (not fileText) then
      for _,searchPath in pairs(self.SearchPaths) do
        if not fileText then
          fileText = self:LoadFile(searchPath.."\\"..fullFileName)
          fileName = searchPath.."\\"..fullFileName
        end
      end
    end

    -- Push this file on top of the stack
    if fileText then
      table.insert(self.Code, 1, { Text = fileText, Line = 1, Col = 1, File = fileName, ParentFile = macroPosition.File, NextCharPos = 1 })
    else
      self:Error("Cannot open file: "..fileName,
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
  else
    self:Error("Invalid macro: #"..macroName,
      macroPosition.Line,macroPosition.Col,macroPosition.File)
  end
end
