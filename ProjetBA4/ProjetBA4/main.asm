;
; ProjetBA4.asm
;
; Created: 26/04/2024 11:15:23
; Author : Arno Laurie, Vincent Lellu
;


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
.org ADCCaddr 
	jmp ADCCaddr_sra

ADCCaddr_sra:
	ldi r23,0x01
	reti

;========== SRAM Allocation ========
.dseg
current_state: .byte 1
.cseg

.include "m128def.inc"
.include "macros.asm"
.include "definitions.asm"
.include "keypadv2.asm"
.include "stepper_motor.asm"
.include "sound.asm"


reset: 
	LDSP    RAMEND
	ldi w, 0x01
	sts current_state, w    ; reset the current state of the machine to 0x01

	rcall   LCD_init
	OUTI    KPDD,  0xf0          ; port D bits 0-3 as input (DDR = 0), 4-7 as output (DDR = 1)
	OUTI    KPDO,  0x0f          ; drive bits 4-7 low = Colonnes a 0V
	//OUTI    DDRB,  0xff          ; output for debug
	OUTI    EIMSK, 0x0f         ; Enable external interrupts INT0-INT3
	OUTI    EICRB, 0x00			; Condition d'interrupt au niveau bas pour int4-7 = colonnes
	OUTI	DDRB,0x0f		    ; make motor port output
	OUTI	ADMUX,3
	OUTI ADCSR, (1<<ADEN)+(1+ADIE)+6
	sbi DDRE, SPEAKER			//Buzzer au port E


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
	clr a3
	ldi b1, 0x60 ; stepper motor counter
	clr b2
	clr d0
	clr d1
	clr d2
	clr d3

	sei
	
	call clear_code
	jmp main



main: 
	; used registers
	; b1 : stepper motor countdown counter
	; a1 : FSM State
	; a3 = current code size in number of letters

	;state 0x01 : user must input code
	;state 0x02 : user has inputted the correct code
	ldi w, 0x01
	cp a1, w
	breq FSM_state1 ;--> Waiting for correct code to be inputted by the user via the keypad	
	ldi w, 0x02
	cp a1, w
	breq FSM_state2 ;-->Correct code has been found, now open the servo and play zelda
	ldi w, 0x03
	cp a1,w
	breq FSM_state3 ;-->Wrong code has been inputted, now play wrong sound and clear code
	ldi w, 0x04
	cp a1,w
	breq FSM_state4 ;-->servo is open and waiting to close 
	rjmp main

FSM_state1:
	jmp kpd_main

FSM_state2:
	ldi zl,low(2*zelda)
	ldi zh,high(2*zelda)
	breq PC+3
	cpi b1, 0x00
	call play_TPU
	call loop_stepper_reverse_open
	rjmp main

FSM_state3: 
	call play_wrong_sound
	call clear_code
	rjmp main

FSM_state4: 
	ldi zl,low(2*zelda_inv)
	ldi zh,high(2*zelda_inv)
	clr r23
	sbi ADCSR, ADSC
	WB0 r23,0
	in c0, ADCL 
	in c1, ADCH
	ldi r16,255
	cp r16,c0
	brne FSM_state4
	rcall play_TPU
	call loop_stepper_reverse_close
	rjmp main 
