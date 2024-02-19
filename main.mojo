from z80 import CPU

def main():
	cpu = CPU()
	cpu.Memory.loadROM("48.rom")
	cpu.run()
	cpu.print_registers()
	print("Finished.")
