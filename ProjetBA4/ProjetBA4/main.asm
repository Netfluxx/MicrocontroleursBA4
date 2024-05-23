;
; ProjetBA4.asm
;
; Created: 27/04/2024 11:15:23
; Author : Arno Laurie, Vincent Lellu
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
;current_code: .byte 4
current_code: .db "0000", 0
;correct_code: .byte 4
correct_code: .db "1235", 0

.cseg

.include "m128def.inc"
.include "macros.asm"
.include "definitions.asm"
.include "keypadv2.asm"
.include "servo_control.asm"


reset: 
	LDSP    RAMEND
	ldi w, 0x01
	sts current_state, w    ; reset the current state of the machine to 0x01

	rcall   LCD_init
	OUTI    KPDD,  0xf0          ; port D bits 0-3 as input (DDR = 0), 4-7 as output (DDR = 1)
	OUTI    KPDO,  0x0f          ; drive bits 4-7 low = Colonnes a 0V
	OUTI    DDRB,  0xff          ; output for debug
	OUTI    EIMSK, 0x0f         ; Enable external interrupts INT0-INT3
	OUTI    EICRB, 0x00     ; Condition d'interrupt au niveau bas pour int4-7 = colonnes
	OUTI	ADMUX,  3	   ; configure the servo as output
	clr w
	clr _w
	clr r2
	clr r1
	clr r14
	clr r15
	clr a0
	clr b0
	clr b1
	clr b3
	clr r0
	clr a3  ;a3 taille du code courant
	clr b1
	clr b2
	clr d0
	clr d1
	clr d2
	clr d3

	sei
	call servo_open
	call clear_code
	jmp main

;.include "test_routine.asm"

main: 
 ; a1 : FSM State
 ;state 0x01 : user must input code
 ;state 0x02 : user has inputted the correct code
 ;a3 = current code size in number of letters

 /*ldi w, 0x01
 CPSE a1, w ;skip next instruction if a1 == 0x01 (state 1)
 nop
 jmp kpd_main*/

 ldi w, 0x01
 cp a1, w
 breq FSM_state1 ;--> Waiting for correct code to be inputted by the user via the keypad	
 ldi w, 0x02
 cp a1, w
 breq FSM_state2 ;-->Correct code has been found, now open the servo

 rjmp main

FSM_state1:
	jmp kpd_main
FSM_state2:
	call servo_open
	jmp main
	