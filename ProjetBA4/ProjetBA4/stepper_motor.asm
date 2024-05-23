; file	motor.asm   target ATmega128L-4MHz-STK300
; purpose stepper motor control


.equ	t1 	= 1500			; waiting period in micro-seconds
.equ	port_mot= PORTB		; port to which motor is connected

.macro	MOTOR
	ldi	w,@0
	out	port_mot,w			; output motor pin pattern
	rcall	wait			; wait period
.endmacro		
	

loop_stepper:
	MOTOR	0b0101			
	MOTOR	0b0001	
	MOTOR	0b1011
	MOTOR	0b1010
	MOTOR	0b1110
	MOTOR	0b0100
	subi	b1, 1
	brne	loop_stepper
	jmp main

loop_stepper_reverse:
	MOTOR	0b0100
	MOTOR	0b1110
	MOTOR	0b1010
	MOTOR	0b1011
	MOTOR	0b0001
	MOTOR	0b0101			

	subi	b1, 1
	brne	loop_stepper
	jmp main
	
wait:	WAIT_US	t1			; wait routine
	ret