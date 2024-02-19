struct Flags:
	var S: Bool  # Sign
	var Z: Bool  # Zero
	var R1: Bool  # Reserved
	var H: Bool  # Half carry
	var R2: Bool  # Reserved
	var PV: Bool  # Parity/Overflow
	var N: Bool  # Add/Subtract
	var C: Bool  # Carry

	fn __init__(inout self):
		self.S = False
		self.Z = False
		self.R1 = False
		self.H = False
		self.R2 = False
		self.PV = False
		self.N = False
		self.C = False


struct Registers:
	var A: UInt8  # Accumulator
	var F: Flags  # Flags
	var BC: UInt16  # B and C registers
	var DE: UInt16  # D and E registers
	var HL: UInt16  # H and L registers

	# Alternative registers
	var Aalt: UInt8
	var Falt: Flags
	var BCalt: UInt16
	var DEalt: UInt16
	var HLalt: UInt16

	var SP: UInt16  # Stack Pointer
	var PC: UInt16  # Program Counter

	var IX: UInt16  # Index X
	var IY: UInt16  # Index Y

	var I: UInt8  # Interrupt vector
	var R: UInt8  # Memory refresh


	fn __init__(inout self):
		self.A = 0
		self.F = Flags()
		self.BC = 0
		self.DE = 0
		self.HL = 0

		self.Aalt = 0
		self.Falt = Flags()
		self.BCalt = 0
		self.DEalt = 0
		self.HLalt = 0

		self.SP = 0
		self.PC = 0

		self.IX = 0
		self.IY = 0

		self.I = 0
		self.R = 0


	fn get_reg8(self, r: Int) raises -> UInt8:
		if r == 0b000:
			return (self.BC >> 8).cast[DType.uint8]()
		elif r == 0b001:
			return (self.BC & 0x00FF).cast[DType.uint8]()
		elif r == 0b010:
			return (self.DE >> 8).cast[DType.uint8]()
		elif r == 0b011:
			return (self.DE & 0x00FF).cast[DType.uint8]()
		elif r == 0b100:
			return (self.HL >> 8).cast[DType.uint8]()
		elif r == 0b101:
			return (self.HL & 0x00FF).cast[DType.uint8]()
		elif r == 0b111:
			return self.A
		else:
			print("Invalid register number: ", r)
			raise Error("Invalid register number")

	fn set_reg8(inout self, r: Int, value: UInt8) raises:
		if r == 0b000:
			self.BC = self.BC & 0x00FF | (value.cast[DType.uint16]() << 8)
		elif r == 0b001:
			self.BC = self.BC & 0xFF00 | value.cast[DType.uint16]()
		elif r == 0b010:
			self.DE = self.DE & 0x00FF | (value.cast[DType.uint16]() << 8)
		elif r == 0b011:
			self.DE = self.DE & 0xFF00 | value.cast[DType.uint16]()
		elif r == 0b100:
			self.HL = self.HL & 0x00FF | (value.cast[DType.uint16]() << 8)
		elif r == 0b101:
			self.HL = self.HL & 0xFF00 | value.cast[DType.uint16]()
		elif r == 0b111:
			self.A = value
		else:
			print("Invalid register number: ", r)
			raise Error("Invalid register number")


	fn set_reg16(inout self, dd: Int, value: UInt16):
		if dd == 0b00:
			self.BC = value
		elif dd == 0b01:
			self.DE = value
		elif dd == 0b10:
			self.HL = value
		elif dd == 0b11:
			self.SP = value


	fn get_reg16(self, ss: Int) -> UInt16:
		if ss == 0b00:
			return self.BC
		elif ss == 0b01:
			return self.DE
		elif ss == 0b10:
			return self.HL
		elif ss == 0b11:
			return self.SP
		else:
			return 0

	fn exx(inout self):
		self.BC, self.BCalt = self.BCalt, self.BC
		self.DE, self.DEalt = self.DEalt, self.DE
		self.HL, self.HLalt = self.HLalt, self.HL
