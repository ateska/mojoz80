
from collections.dict import Dict, KeyElement

from .memory import Memory
from .registers import Registers


struct CPU:
	var Registers: Registers
	var Memory: Memory
	
	var T: Int  # T Cycle counter
	var M: Int  # Machine Cycle counter
	var I: Int  # Instruction Cycle counter

	var InteruptMode: Int
	var IFF1: Bool
	var IFF2: Bool

	fn __init__(inout self):
		self.Registers = Registers()
		self.Memory = Memory()
		self.T = 0
		self.M = 0
		self.I = 0

		self.InteruptMode = 0

		# Interrupt enable flip-flops
		self.IFF1 = False  # Disables interrupt from being accepted
		self.IFF2 = False  # Temporary storage location for IFF1


	fn tick(inout self, t: Int, m: Int):
		self.T += t
		self.M += m

	fn op_code_fetch(inout self) -> Int:
		var opcode = self.Memory.get8(self.Registers.PC)
		self.Registers.PC += 1
		self.tick(4, 1)

		var prefix: Int = 0
		if (opcode == 0xCB) or (opcode == 0xED) or (opcode == 0xDD) or (opcode == 0xFD):
			prefix = int(opcode) << 8
			opcode = self.Memory.get8(self.Registers.PC)
			self.Registers.PC += 1

		var r = self.Registers.R
		r = (r & 0x80) | ((r + 1) & 0x7F)
		self.Registers.R = r

		self.I += 1

		return prefix + int(opcode)


	fn run(inout self):
		while True:
			try:
				let halt = self.step()
				if halt:
					break
			except:
				print("Exception when running")
				break


	fn step(inout self) raises -> Bool:
		let original_pc = self.Registers.PC
		let opcode = self.op_code_fetch()

		if opcode == 0x00: # NOP
			pass

		elif opcode == 0x76:  # HALT
			# IMPORTANT: Position of this `elif` for HALT is important, it "overrides" with "LD r, r'" instruction
			print("=== HALTED", "I:", self.I, "T:", self.T, "M:", self.M)
			return True

		elif opcode == 0xF3:  # DI
			self.IFF1 = False
			self.IFF2 = False

		elif opcode == 0xFB:  # EI
			self.IFF1 = True
			self.IFF2 = True

		elif opcode == 0xED46:  # IM 0
			self.InteruptMode = 0  # Set Interrupt Mode 0
			self.tick(4, 1)

		elif opcode == 0xED56:  # IM 1
			self.InteruptMode = 1  # Set Interrupt Mode 1
			self.tick(4, 1)

		elif opcode == 0xED5E:  # IM 2
			self.InteruptMode = 2  # Set Interrupt Mode 2
			self.tick(4, 1)

		elif opcode == 0x0A:  # LD A, (BC)
			self.Registers.A = self.Memory.get8(self.Registers.BC)
			self.tick(3, 1)

		elif opcode == 0x1A:  # LD A, (DE)
			self.Registers.A = self.Memory.get8(self.Registers.DE)
			self.tick(3, 1)

		elif opcode == 0x3A:  # LD A, (NN)
			let nn = self.Memory.get16(self.Registers.PC)
			self.Registers.PC += 2
			self.Registers.A = self.Memory.get8(nn)
			self.tick(9, 3)

		elif opcode == 0x02:  # LD (BC), A
			self.Memory.set8(self.Registers.BC, self.Registers.A)
			self.tick(3, 1)

		elif opcode == 0x12:  # LD (DE), A
			self.Memory.set8(self.Registers.DE, self.Registers.A)
			self.tick(3, 1)

		elif opcode == 0x32:  # LD (NN), A
			let nn = self.Memory.get16(self.Registers.PC)
			self.Registers.PC += 2
			self.Memory.set8(nn, self.Registers.A)
			self.tick(9, 3)

		elif opcode_match(opcode, 0b00000110, 0b11000111):  # LD r, n
			let n = self.Memory.get8(self.Registers.PC)
			self.Registers.PC += 1

			let reg = (opcode & 0b00111000) >> 3
			if reg != 0b110:
				self.Registers.set_reg8(reg, n)
				self.tick(3, 1)
			
			else:  # LD (HL), n
				self.Memory.set8(self.Registers.HL, n)
				self.tick(6, 2)

		elif opcode_match(opcode, 0b01000110, 0b11000111):  # LD r, (HL)
			let v = self.Memory.get8(self.Registers.HL)
			let reg = (opcode & 0b00111000) >> 3
			if reg != 0b110:
				self.Registers.set_reg8(reg, v)
				self.tick(3, 1)

		elif opcode == 0x22:  # LD (nn), HL
			let nn = self.Memory.get16(self.Registers.PC)
			self.Registers.PC += 2
			self.Memory.set16(nn, self.Registers.HL)
			self.tick(4, 3+3+3+3)

		elif opcode_match(opcode, 0b01000000, 0b11000000):  # LD r, r'
			let regd = (opcode >> 3) & 0x07
			let regs = opcode & 0x07

			var v: UInt8
			if regs != 0b110:
				v = self.Registers.get_reg8(regs)
			else:  # LD r, (HL)
				v = self.Memory.get8(self.Registers.HL)
				self.tick(3, 1)

			if regd != 0b110:
				self.Registers.set_reg8(regd, v)
			else:  # LD (HL), r
				self.Memory.set8(self.Registers.HL, v)
				self.tick(3, 1)

		elif opcode_match(opcode, 0b10101000, 0b11111000):  # XOR r
			let r = opcode & 0x07
			let v = self.Registers.get_reg8(r)
			self.Registers.A = self.Registers.A ^ v

		elif opcode == 0xC3:  # JP nn
			let nn = self.Memory.get16(self.Registers.PC)
			self.Registers.PC = nn
			self.tick(6, 2)

		elif opcode == 0xD3:  # OUT (n), A
			let n = self.Memory.get8(self.Registers.PC)
			self.Registers.PC += 1
			# TODO: Output A to n I/O port
			self.tick(2, 7)

		elif opcode_match(opcode, 0b00001011, 0b11001111):  # DEC ss
			let ss = (opcode & 0b00110000) >> 4
			self.Registers.set_reg16(ss, self.Registers.get_reg16(ss) - 1)
			self.tick(0, 2)
			# Flags are not affected

		elif opcode == 0x35:  # DEC (HL)
			var v = self.Memory.get8(self.Registers.HL)
			v -= 1
			self.Memory.set8(self.Registers.HL, v)
			self.tick(2, 4 + 3)
			# TODO: Flags

		elif opcode_match(opcode, 0b00000011, 0b11001111):  # INC ss
			let ss = (opcode & 0b00110000) >> 4
			self.Registers.set_reg16(ss, self.Registers.get_reg16(ss) + 1)
			self.tick(0, 2)
			# Flags are not affected

		elif opcode == 0x34:  # INC (HL)
			var v = self.Memory.get8(self.Registers.HL)
			v += 1
			self.Memory.set8(self.Registers.HL, v)
			self.tick(2, 4 + 3)
			# TODO: Flags

		elif opcode == 0xD9:  # EXX
			self.Registers.exx()

		elif opcode_match(opcode, 0b10111000, 0b11111000):  # CP r
			let r = opcode & 0x07
			let v = self.Registers.A - self.Registers.get_reg8(r)
			self.Registers.F.S = v & 0x80 == 0x80  # S is set if result is negative; otherwise, it is reset.
			self.Registers.F.Z = v == 0  # Z is set if result is 0; otherwise, it is reset.
			self.Registers.F.H = v & 0x0F != 0x00  # H is set if borrow from bit 4; otherwise, it is reset.
			# TODO: P/V is set if overflow; otherwise, it is reset.
			self.Registers.F.N = True  # N is set.
			self.Registers.F.C = True  # C is set if borrow; otherwise, it is reset.

		elif opcode_match(opcode, 0b10100000, 0b11111000):  # AND r
			let r = opcode & 0x07
			self.Registers.A &= self.Registers.get_reg8(r)
			self.Registers.F.S = self.Registers.A & 0x80 == 0x80  #S is set if result is negative; otherwise, it is reset.
			self.Registers.F.Z = self.Registers.A == 0  #Z is set if result is 0; otherwise, it is reset.
			self.Registers.F.H = True  # H is set.
			# TODO P/V is reset if overflow; otherwise, it is reset.
			self.Registers.F.N = False  # N is reset.
			self.Registers.F.C = False  # C is reset.

		elif opcode == 0x20:  # JR NZ, e
			let e = self.Memory.get8s(self.Registers.PC)
			self.Registers.PC += 1
			self.tick(1, 3)
			if not self.Registers.F.Z:
				self.Registers.PC += int(e)
				self.tick(1, 5)	

		elif opcode == 0x28:  # JR Z, e
			let e = self.Memory.get8s(self.Registers.PC)
			self.Registers.PC += 1
			self.tick(1, 3)
			if self.Registers.F.Z:
				self.Registers.PC += int(e)
				self.tick(1, 5)	

		elif opcode == 0x30:  # JR NC, e
			let e = self.Memory.get8s(self.Registers.PC)
			self.Registers.PC += 1
			self.tick(1, 3)
			if not self.Registers.F.C:
				self.Registers.PC += int(e)
				self.tick(1, 5)	

		elif opcode == 0x38:  # JR C, e
			let e = self.Memory.get8s(self.Registers.PC)
			self.Registers.PC += 1
			self.tick(1, 3)
			if self.Registers.F.C:
				self.Registers.PC += int(e)
				self.tick(1, 5)	

		elif opcode == 0xED57:  # LD A, I
			self.Registers.A = self.Registers.I
			self.tick(5, 1)

			self.Registers.F.S = self.Registers.I & 0x80 == 0x80  # S is set if the I Register is negative; otherwise, it is reset.
			self.Registers.F.Z = self.Registers.I == 0  # Z is set if the I Register is 0; otherwise, it is reset.
			self.Registers.F.H = False  # H is reset.
			self.Registers.F.PV = self.IFF2
			self.Registers.F.N = False  # N is reset.
			# TODO: If an interrupt occurs during execution of this instruction, the Parity flag contains a 0.

		elif opcode == 0xED5F:  # LD A, R
			self.Registers.A = self.Registers.R
			self.tick(5, 1)

			self.Registers.F.S = self.Registers.R & 0x80 == 0x80  # S is set if, R-Register is negative; otherwise, it is reset.
			self.Registers.F.Z = self.Registers.R == 0  # Z is set if the R Register is 0; otherwise, it is reset.
			self.Registers.F.H = False  # H is reset.
			self.Registers.F.PV = self.IFF2
			self.Registers.F.N = False  # N is reset.
			# TODO: If an interrupt occurs during execution of this instruction, the parity flag contains a 0.

		elif opcode == 0xED47:  # LD I, A
			self.Registers.I = self.Registers.A
			self.tick(5, 1)

		elif opcode == 0xED4F:  # LD R, A
			self.Registers.R = self.Registers.A
			self.tick(5, 1)

		elif opcode_match(opcode, 0b00000001, 0b11001111):  # LD dd, nn
			let nn = self.Memory.get16(self.Registers.PC)
			self.Registers.PC += 2
			let dd = (opcode & 0b00110000) >> 4
			self.Registers.set_reg16(dd, nn)
			self.tick(6, 1)

		elif opcode == 0xED44:  # NEG
			self.Registers.F.PV = self.Registers.A == 0x80  # P/V is set if Accumulator was 80h before operation; otherwise, it is reset.
			self.Registers.F.C = self.Registers.A != 0x00  # C is set if Accumulator was not 00h before operation; otherwise, it is reset.
			self.Registers.A = -self.Registers.A
			self.Registers.F.S = self.Registers.A & 0x80 == 0x80  # S is set if result is negative; otherwise, it is reset.
			self.Registers.F.Z = self.Registers.A == 0  # Z is set if result is 0; otherwise, it is reset.
			self.Registers.F.H = self.Registers.A & 0x0F != 0x00  # H is set if borrow from bit 4; otherwise, it is reset.
			self.Registers.F.N = True  # N is set.
			self.tick(4, 1)

		elif opcode_match16(opcode, 0b11101101_01000010, 0b1111_1111_1100_1111):  # SBC HL, ss
			let ss = (opcode & 0b00110000) >> 4
			let ssv = self.Registers.get_reg16(ss)
			let cy = 1 if self.Registers.F.C else 0
			let hl = self.Registers.HL
			self.Registers.HL = hl - ssv - cy

			self.Registers.F.S = self.Registers.HL & 0x80 == 0x80  # S is set if result is negative; otherwise, it is reset.
			self.Registers.F.Z = self.Registers.HL == 0  #Z is set if result is 0; otherwise, it is reset.
			self.Registers.F.H = self.Registers.HL & 0x0800 != 0x0000   # H is set if borrow from bit 12; otherwise, it is reset.
			# TODO: P/V is set if overflow; otherwise, it is reset.
			self.Registers.F.N = True  # N is set.
			self.Registers.F.C = True  # TODO: C is set if borrow; otherwise, it is reset.

			self.tick(3, 4+4+3)

		elif opcode_match16(opcode, 0b1110_1101_0100_0011, 0b1111_1111_1100_1111):  # LD (nn), dd
			let dd = (opcode & 0b00110000) >> 4
			let ddv = self.Registers.get_reg16(dd)
			self.Memory.set16(self.Registers.PC, ddv)
			self.tick(5, 4+3+3+3+3)

		elif opcode_match(opcode, 0b0000_1001, 0b1100_1111):  # ADD HL, ss
			let ss = (opcode & 0b00110000) >> 4
			let ssv = self.Registers.get_reg16(ss)
			self.Registers.HL += ssv

			# S is not affected.
			# Z is not affected.
			# TODO: H is set if carry from bit 11; otherwise, it is reset.
			# P/V is not affected.
			self.Registers.F.N = True  # N is set.
			# TODO: C is set if carry from bit 15; otherwise, it is reset.

			self.tick(2, 4+3)

		else:
			print("!!! Unsuported opcode", tohex(opcode), "at", tohex(original_pc), "/", original_pc)
			return True

		return False


	fn print_registers(inout self):
		print("=== CPU Registers")
		print("A:", self.Registers.A)
		print("F:",
			"S: 1" if self.Registers.F.S else "S: 0",
			"Z: 1" if self.Registers.F.Z else "Z: 0",
			# "R1: 1" if self.Registers.F.R1 else "R1: 0",
			"H: 1" if self.Registers.F.H else "H: 0",
			# "R2: 1" if self.Registers.F.R2 else "R2: 0",
			"PV: 1" if self.Registers.F.PV else "PV: 0",
			"N: 1" if self.Registers.F.N else "N: 0",
			"C: 1" if self.Registers.F.C else "C: 0"
		)
		print("BC:", self.Registers.BC, " B:", self.Registers.BC >> 8, " C:", self.Registers.BC & 0x00FF)
		print("DE:", self.Registers.DE, " D:", self.Registers.DE >> 8, " E:", self.Registers.DE & 0x00FF)
		print("HL:", self.Registers.HL, " H:", self.Registers.HL >> 8, " L:", self.Registers.HL & 0x00FF)
		print("SP:", self.Registers.SP)
		print("PC:", tohex(self.Registers.PC), "/", self.Registers.PC)
		print("---")


fn opcode_match(opcode: Int, value: UInt8, mask: UInt8) -> Bool:
	if opcode > 0xFF:
		return False
	else:
		return (opcode & mask) == value


fn opcode_match16(opcode: Int, value: UInt16, mask: UInt16) -> Bool:
	if opcode < 0x100:
		return False
	else:
		return (opcode & mask) == value


fn tohex(value: Int) -> String:
	var v = value
	var ret: String = ""
	while v > 0:
		let c = v % 16
		v = v >> 4
		if c < 10:
			ret = str(c) + ret
		else:
			ret = chr(65 + c - 10) + ret

	return ("0x" + ret) if ret != "" else "0x0"

fn tohex(value: UInt16) -> String:
	var v = int(value)
	return tohex(v)
	