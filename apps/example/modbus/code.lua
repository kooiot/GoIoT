local Cmd = {}

local make_code = function(name, code)
	Cmd[name] = code
	Cmd[code] = name
end

-- Physical Discrete Inputs
make_code("ReadDisreteInputs", 0x02)
-- Internal Bits Or Physical coils
make_code("ReadCoils", 0x01)
make_code("WriteSingleCoil", 0x05)
make_code("WriteMultipleCoils", 0x0F)
-- Physical Input Registers
make_code("ReadInputRegister", 0x04)
-- Internal Registers Or Physical Ouput Registers
make_code("ReadHoldingRegisters", 0x03)
make_code("WriteSingleRegister", 0x06)
make_code("WriteMultipleRegisters", 0x10)
make_code("ReadWriteMultipleRegisters", 0x17)
make_code("MaskWriteRegister", 0x16)
make_code("ReadFIFOQueue", 0x18)
-- File record access
make_code("ReadFileRecord", 0x14)
make_code("WriteFileRecord", 0x15)
-- Diagnostics
make_code("ReadExceptionStatus", 0x07)
make_code("Diagnostic", 0x08)
make_code("GetComEventCounter", 0x0B)
make_code("GetComEventLog", 0x0C)
make_code("ReportServerID", 0x11)
make_code("ReadDeviceIndentification", 0x2B)
-- Other
make_code("EncapsulatedInterfaceTransport", 0x2B)
make_code("CANopenGeneralReference", 0x2B)

return Cmd

