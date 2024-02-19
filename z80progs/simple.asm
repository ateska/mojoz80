; Compile by z80asm -o simple.rom ./z80progs/simple.asm

        org 0x0000    ; Optional: Start address for the code
        LD A, 77      ; Load 0 into register A
        NEG
        LD B, 88
        LD C, 99
        LD D, A
        HALT          ; Halt the CPU
