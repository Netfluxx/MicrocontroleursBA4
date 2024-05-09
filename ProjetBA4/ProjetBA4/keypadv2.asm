; file	kpd4x4_S.asm   target ATmega128L-4MHz-STK300		
; purpose keypad 4x4 acquisition and print
; uses four external interrupts and ports internal pull-up

; solutions based on the methodology presented in EE208-MICRO210_ESP-2024-v1.0.fm
;>alternate solutions also possible
; standalone solution/file; not meant as a modular solution and thus must be
;>adapted when used in a complex project
; solution based on interrupts detected on each row; not optimal but functional if
;>and external four-input gate is not available

; RAM Allocation
.dseg
current_code: .byte 1
correct_code: .byte 1
.cseg

.include "macros.asm"        ; include macro definitions
.include "definitions.asm"   ; include register/constant definitions

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
.org 0x000
    jmp reset
.org 0x0002
    jmp isr_row1    ; external interrupt INT0 = bit 0 du PORTD cable sur Row1
.org 0x0004
    jmp isr_row2    ; external interrupt INT1 = bit 1 du PORTD
.org 0x0006
    jmp isr_row3    ; external interrupt INT2 = bit 2 du PORTD
.org 0x0008
    jmp isr_row4    ; external interrupt INT3 = bit 3 du PORTD

; === interrupt service routines ===
isr_row1:
    INVP    PORTB, 0          ; Toggle led 0 for visual feedback
    _LDI    wr1, 0x00       
    _LDI    mask, 0b00000001  ; detected in row 1 on PIND0
    rjmp    column_detect
	

isr_row2:
    INVP    PORTB, 1		  ; Toggle led 1 for visual feedback
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
    _LDI    wr1, 0x02
    _LDI    mask, 0b00001000  ; detected in row 4 on PIND3
    rjmp    column_detect
	


; === Column Detection Routines ===
; Detecting the column: each column is pulled up then, one at a time, each column 
; is pulled low and if that forces the previously found row to also be pulled low
; then we have the right column

column_detect:
	OUTI KPDO, 0xff
col1:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0x7F	
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			
	brne	col2 ; check next col since this didn't pull the line low
	_LDI	wr0,0x00
	INVP	PORTB,4		;;debug
	_LDI wr2, 0xff
	rjmp isr_return
col2:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xBF	
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			
	brne	col3
	_LDI	wr0,0x01
	INVP	PORTB,5		;;debug
	_LDI wr2, 0xff
	rjmp isr_return
col3:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xDF	
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			
	brne	col4
	_LDI	wr0,0x02
	INVP	PORTB,6		;;debug
	_LDI wr2, 0xff
	rjmp isr_return
col4:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xEF	
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			
	brne	isr_return
	_LDI	wr0,0x03
	;INVP	PORTB,3		;;debug
	_LDI wr2, 0xff
	rjmp isr_return


isr_return:
	;reinitialize detection
    OUTI    KPDO,0x0f         ; drive bits 4-7 low = columns a 0V
	reti

.include "lcd.asm"
.include "printf.asm"

; FDEC	decimal number
; FHEX	hexadecimal number
; FBIN	binary number
; FFRAC	fixed fraction number
; FCHAR	single ASCII character
; FSTR	zero-terminated ASCII string

;TODO: Store code as a string in SRAM and change print_code to print the current code



; Initialization and configuration
.org 0x400

reset:  ;in : None, out: KPDD, KPDO, DDRB, EIMSK, EICRB, PORTB, mod: mask, w, _w, wr0, wr1, wr2, a0, b0, b3, r0, I flag
    LDSP    RAMEND
    rcall   LCD_init
    OUTI    KPDD,0xf0          ; port D bits 0-3 as input (DDR = 0), 4-7 as output (DDR = 1)
    OUTI    KPDO,0x0f          ; drive bits 4-7 low = Colonnes a 0V
    OUTI    DDRB,0xff          ; output for debug
    OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    OUTI    EICRB,0x00		   ; Condition d'interrupt au niveau bas pour int4-7 = colonnes
	INVP	PORTB, 7

    clr mask
	clr w
	clr _w
	clr wr2
	clr wr1
	clr wr0
	clr a0
	clr b0
	clr b3
	clr r0
	sei
    rcall clear_code
	jmp main



print_code:
    ;cpi     a0, '*'
    ;breq    clear_code         ; Branch if key == *
	;ldi a0, 'x'
	;PRINTF LCD
	;.db CR, CR, "Code:tst"
	;.db 0
	rcall LCD_putc
	clr wr2
    ret

clear_code:
    rcall   LCD_clear
	PRINTF LCD
	.db	CR, CR, "Code:#"
	.db 0
    ret

get_char: ;Lookup table index = 4*row + col
	ldi     b0, 4
    mul     wr1, b0          ; wr1 <-- detected row*4
    add     r0, wr0          ; r0  <-- detected row*4 + detected column
    mov     b0, r0           ; b0  <-- index of key (starts at 0)
    ldi     ZH, high(2*KeySet)
    ldi     ZL, low(2*KeySet)
    add     ZL, b0
	ldi		b3, 0x00
    adc     ZH, b3			 ; Adjust ZH with carry
    lpm     a0, Z  ; enregistre la valeur a l'adresse pointee par Z=r31:r30 dans a0
	;rcall LCD_putc
	rcall print_code
	ret

; === main program loop ===
main:

    ;OUTI    DDRB,0xff          ; output for debug
    ;OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    ;OUTI    EICRB,0x00		   ; Condition d'interrupt au niveau bas pour int4-7 = colonnes
	;OUTI	KPDO, 0xff
	ldi w, 0xff
	cp wr2, w
	brne get_char
	WAIT_MS 20
	;PRINTF LCD
	;.db CR, CR, FBIN, wr1, 0
    rjmp    main

;go_to_get_char:
	;INVP	PORTB, 5
	;call get_char
	;ret

; Keypad ASCII mapping table
KeySet:
.db '1', '2', '3', 'A'
.db '4', '5', '6', 'B'
.db '7', '8', '9', 'C'
.db '*', '0', '#', 'D'