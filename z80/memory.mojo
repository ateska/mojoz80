from collections.vector import InlinedFixedVector

struct Memory:
	var Bytes: InlinedFixedVector[UInt8]

	fn __init__(inout self):
		self.Bytes = InlinedFixedVector[UInt8](65536)  # 64KB of memory

	fn loadROM(inout self, path: String) raises:
		# Load the ROM into the memory
		with open(path, "rb") as file:
			let rom = file.read()
			for i in range(len(rom)):
				self.Bytes[i] = ord(rom[i])

	fn get8(self, addr: UInt16) -> UInt8:
		return self.Bytes[int(addr)]

	fn get8s(self, addr: UInt16) -> Int8:
		var s = int(self.Bytes[int(addr)])
		if s >= 128:
			s -= 256
		return s

	fn set8(inout self, addr: UInt16, value: UInt8):
		self.Bytes[int(addr)] = value

	fn get16(self, addr: UInt16) -> UInt16:
		var v: UInt16 = self.Bytes[int(addr) + 1].cast[DType.uint16]() << 8
		v |= self.Bytes[int(addr)].cast[DType.uint16]()
		return v

	fn set16(inout self, addr: UInt16, value: UInt16):
		let v1 = value & 0xFF
		let v2 = (value >> 8) & 0xFF
		self.Bytes[int(addr)] = v1.cast[DType.uint8]()
		self.Bytes[int(addr)+1] = v2.cast[DType.uint8]()
