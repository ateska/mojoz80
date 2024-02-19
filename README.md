# mojoz80

Implementation of Zilog Z80 CPU in Mojo 🔥

*Work-in-progress !!!* - many instructions are not yet implemented.


## How to run

1) Prepare ROM:

`z80asm -o simple.rom ./z80progs/simple.asm`

_Note: You can use for example ZX Spectrum ROM._


2) Run the emulator

`mojo main.mojo`


## References

* [Z80 documentation](https://www.zilog.com/docs/z80/um0080.pdf)
* [Z80 instruction set](https://clrhome.org/table/)
* http://www.primrosebank.net/computers/zxspectrum/docs/CompleteSpectrumROMDisassemblyThe.pdf
