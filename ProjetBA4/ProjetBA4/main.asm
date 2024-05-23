;
; ProjetBA4.asm
;
; Created: 27/04/2024 11:15:23
; Author : Arno Laurie
;


; SRAM Allocation
; === interrupt vector table ===
.org 0x0000
    jmp reset
.org 0x0002
    jmp isr_row1    ; external interrupt INT0 = bit 0 du PORTD cable sur Row1
.org 0x0004
    jmp isr_row2    ; external interrupt INT1 = bit 1 du PORTD
.org 0x0006
    jmp isr_row3    ; external interrupt INT2 = bit 2 du PORTD
.org 0x0008
    jmp isr_row4    ; external interrupt INT3 = bit 3 du PORTD


.dseg
current_state: .byte 1
current_code: .byte 4
;correct_code: .byte 4
correct_code: .db "1234", 0

.cseg

.include "macros.asm"
.include "definitions.asm"
.include "keypadv2.asm"


reset: 
 LDSP    RAMEND
 ldi w, 0x01
 sts current_state, w    ; reset the current state of the machine to 0x01

    rcall   LCD_init
    OUTI    KPDD,0xf0          ; port D bits 0-3 as input (DDR = 0), 4-7 as output (DDR = 1)
    OUTI    KPDO,0x0f          ; drive bits 4-7 low = Colonnes a 0V
    OUTI    DDRB,0xff          ; output for debug
    OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    OUTI    EICRB,0x00     ; Condition d'interrupt au niveau bas pour int4-7 = colonnes

 clr w
 clr _w
 clr r2
 clr r1
 clr r14
 clr r15
 clr a0
 clr b0
 clr b3
 clr r0
 clr a3  ;a3 taille du code courant

 sei
 call clear_code
 jmp main

;.include "test_routine.asm"

main:  ;modifies a1, a2, a3
 ;state 0x01 : user must input code
 ;state 0x02 : user has inputted the correct code
 ;a3 = current code size in number of letters
 

 lds a1, current_state
 ldi a2, 0x01
 CPSE a1, a2 ;skip next instruction if a1 == 0x01 (state 1)
 nop
 jmp kpd_main

 rjmp main
