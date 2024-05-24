; author arno


.equ	t1 	= 1500			; waiting period in micro-seconds
.equ	port_mot= PORTB		; port to which motor is connected

.macro	MOTOR
	ldi	w,@0
	out	port_mot,w			; output motor pin pattern
	rcall	wait			; wait period
.endmacro		
	

loop_stepper_open:
	MOTOR	0b0101			
	MOTOR	0b0001	
	MOTOR	0b1011
	MOTOR	0b1010
	MOTOR	0b1110
	MOTOR	0b0100
	subi	b1, 1
	brne	loop_stepper_open
	ldi a1, 0x04
	jmp main

loop_stepper_reverse_open:
	MOTOR	0b0100
	MOTOR	0b1110
	MOTOR	0b1010
	MOTOR	0b1011
	MOTOR	0b0001
	MOTOR	0b0101			

	subi	b1, 1
	brne	loop_stepper_open
	ldi a1, 0x04
	jmp main

loop_stepper_close:
	MOTOR	0b0101			
	MOTOR	0b0001	
	MOTOR	0b1011
	MOTOR	0b1010
	MOTOR	0b1110
	MOTOR	0b0100
	subi	b1, 1
	brne	loop_stepper_close
	rcall clear_code
	ldi a1, 0x01
	jmp main

loop_stepper_reverse_close:
	MOTOR	0b0100
	MOTOR	0b1110
	MOTOR	0b1010
	MOTOR	0b1011
	MOTOR	0b0001
	MOTOR	0b0101			

	subi	b1, 1
	brne	loop_stepper_close
	rcall clear_code
	ldi a1, 0x01
	jmp main
	
wait:	WAIT_US	t1			; wait routine
	ret