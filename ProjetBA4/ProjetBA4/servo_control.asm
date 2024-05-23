servo_open:
	push r23
	ldi r23, 0x20
loop_open:
	P1 PORTE, SERVO1
	WAIT_US 1300
	P0 PORTE, SERVO1
	WAIT_US 18700
	DJNZ r23, loop_open
	pop r23
	ret

servo_close:
	push r23
	ldi r23, 0x20
loop_close:
	P1 PORTE, SERVO1
	WAIT_US 300
	P0 PORTE, SERVO1
	WAIT_US 19700
	DJNZ r23, loop_close
	pop r23
	ret