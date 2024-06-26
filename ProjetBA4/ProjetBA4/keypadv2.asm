
; file kpd4x4_S.asm   target ATmega128L-4MHz-STK300  
; purpose keypad 4x4 acquisition and print
; uses four external interrupts and ports internal pull-up

; solutions based on the methodology presented in EE208-MICRO210_ESP-2024-v1.0.fm
;>alternate solutions also possible
; standalone solution/file; not meant as a modular solution and thus must be
;>adapted when used in a complex project
; solution based on interrupts detected on each row; not optimal but functional if
;>and external four-input gate is not available

;===== USED REGISTERS =====
;r1, r2, r14, r15, r16, r17, a0

; === definitions ===
.equ    KPDD = DDRD
.equ    KPDO = PORTD
.equ    KPDI = PIND

.equ    KPD_DELAY = 30   ; msec, debouncing keys of keypad

.def    wr0 = r2        ; detected column in hex
.def    wr1 = r1        ; detected row in hex
.def    mask = r14      ; row mask indicating which row has been detected in bin
.def    wr2 = r15       ; semaphore: must enter LCD display routine, unary: 0 or other

; === interrupt vector table ===
;.org 0x0000
;    jmp reset
;.org 0x0002
;    jmp isr_row1    ; external interrupt INT0 = bit 0 du PORTD cable sur Row1
;.org 0x0004
;    jmp isr_row2    ; external interrupt INT1 = bit 1 du PORTD
;.org 0x0006
;    jmp isr_row3    ; external interrupt INT2 = bit 2 du PORTD
;.org 0x0008
;    jmp isr_row4    ; external interrupt INT3 = bit 3 du PORTD

; === interrupt service routines ===
isr_row1:
    INVP    PORTB, 0          ; Toggle led 0 for visual feedback
    _LDI    wr1, 0x00       
    _LDI    mask, 0b00000001  ; detected in row 1 on PIND0
    rjmp    column_detect
 

isr_row2:
    INVP    PORTB, 1    ; Toggle led 1 for visual feedback
    _LDI    wr1, 0x01
    _LDI    mask, 0b00000010 ; detected in row 2 on PIND1
    rjmp    column_detect
 

isr_row3:
    INVP    PORTB, 2          ; Toggle led 2 for visual feedback
    _LDI    wr1, 0x02
    _LDI    mask, 0b00000100  ; detected in row 3 on PIND2
    rjmp    column_detect
 

isr_row4:
    INVP    PORTB, 3          ; Toggle led 3 for visual feedback
    _LDI    wr1, 0x03
    _LDI    mask, 0b00001000  ; detected in row 4 on PIND3
    rjmp    column_detect
 


; === Column Detection Routines ===
; Detecting the column: each column is pulled up then, one at a time, each column 
; is pulled low and if that forces the previously found row to also be pulled low
; then we have the right column

column_detect:
 OUTI KPDO, 0xff
col1:
 WAIT_MS KPD_DELAY
 OUTI KPDO,0x7F 
 WAIT_MS KPD_DELAY
 in  w,KPDI
 and  w,mask
 tst  w   
 brne col2
 _LDI wr0,0x03
 _LDI wr2, 0xff
 rjmp isr_return
col2:
 WAIT_MS KPD_DELAY
 OUTI KPDO,0xBF 
 WAIT_MS KPD_DELAY
 in  w,KPDI
 and  w,mask
 tst  w   
 brne col3
 _LDI wr0,0x02
 _LDI wr2, 0xff
 rjmp isr_return
col3:
 WAIT_MS KPD_DELAY
 OUTI KPDO,0xDF 
 WAIT_MS KPD_DELAY
 in  w,KPDI
 and  w,mask
 tst  w   
 brne col4
 _LDI wr0,0x01
 _LDI wr2, 0xff
 rjmp isr_return
col4:
 WAIT_MS KPD_DELAY
 OUTI KPDO,0xEF 
 WAIT_MS KPD_DELAY
 in  w,KPDI
 and  w,mask
 tst  w   
 brne isr_return
 _LDI wr0,0x00
 _LDI wr2, 0xff
 rjmp isr_return

isr_return:
	;reinitialize column detection
    OUTI    KPDO,0x0f         ; drive bits 4-7 low = columns a 0V
	reti

.include "lcd.asm"
.include "printf.asm"


; Initialization and configuration
.org 0x400

print_code:
    cpi     a0, '*'
    breq    clear_code       ; Branch if key == *
	clr wr2
	rcall LCD_putc
    ret

clear_code:
	clr a3
	clr c0
	clr c1
	clr c2
	clr c3
    rcall   LCD_clear
 PRINTF LCD
 .db CR, CR, "Code:"
 .db 0
	clr wr2
    rjmp kpd_main

get_char: ;Lookup table index = 4*row + col
	ldi     b0, 4
    mul     wr1, b0          ; wr1 <-- detected row*4, result is stored in r0
    add     r0, wr0          ; r0  <-- detected row*4 + detected column
    mov     b0, r0           ; b0  <-- index of key (starts at 0)
    ldi     ZH, high(2*KeySet)
    ldi     ZL, low(2*KeySet)
    add     ZL, b0
	ldi		w, 0x00
    adc     ZH, w    ; Adjust ZH with carry
    lpm     a0, Z    ; enregistre la valeur a l'adresse pointee par Z=r31:r30 dans a0
	
	//go to main or somewhere else if code len is 4
	rcall print_code
	clz
	cpi a3, 0
	breq first_letter
	cpi a3, 1
	breq second_letter
	cpi a3, 2
	breq third_letter
	cpi a3, 3
	breq fourth_letter

	;rcall print_code
	;rcall display_current_code

first_letter:
	mov c0, a0
	subi a3, -1
	rjmp kpd_main
second_letter:
	mov c1, a0
	subi a3, -1
	rjmp kpd_main
third_letter:
	mov c2, a0
	subi a3, -1
	rjmp kpd_main
fourth_letter:
	mov c3, a0
	subi a3, -1
	rjmp test_code

; === main program loop ===
kpd_main:
	 _CPI wr2, 0xff
	 breq get_char
	 rjmp kpd_main

.macro TESTKEY
	ldi w, @0
	cp @1, w
	breq PC+2
	jmp kpd_main
	;WAIT_MS 500
	;INVP PORTB, 7
	;WAIT_MS 500
	.endmacro

 test_code:	;password = 1221
	TESTKEY '1', c0
	TESTKEY '2', c1
	TESTKEY '2', c2
	TESTKEY '1', c3
	
	ldi a1, 0x02 ; change FSM state to 0x02
	rjmp main

; Keypad ASCII mapping table
KeySet:
.db '1', '2', '3', 'A'
.db '4', '5', '6', 'B'
.db '7', '8', '9', 'C'
.db '*', '0', '#', 'D'