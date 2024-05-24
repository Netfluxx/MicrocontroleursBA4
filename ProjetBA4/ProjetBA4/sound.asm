/*
 * sound.asm
 *
 *  Created: 01/05/2024 22:12:22
 *   Author: vincent
 */ 
sound : 
	mov b1,b0
	clr b0
	clr a1
	tst a0
	breq sound_off

sound1:
	mov w,a0
	rcall wait9us
	nop
	dec w
	brne PC-3
	INVP PORTE,SPEAKER //commande qui donne le son ? Port E
	sub b0,a0
	sbc b1,a1
	brcc sound1
	ret

sound_off:
	ldi a0,1
	rcall wait9us 
	sub b0,a0
	sbc b1,a1
	brcc PC-3
	ret

wait9us: 
	rjmp PC+1
	rjmp PC+1


wait8us: rcall wait4us

wait4us: rcall wait2us

wait2us: nop 
		ret

zelda: 
	.db so2, fam2, rem2, do2 , la2, si2
	.db 0 ; odd number of byte -> assembler will do padding

zelda_inv: 	
	.db	si2,la2,do2,rem2,fam2,so2
	.db 0 	

		
.equ	do	= 100000/517	; (517 Hz)
.equ	dom	= do*944/1000	; do major
.equ	re	= do*891/1000
.equ	rem	= do*841/1000	; re major
.equ	mi	= do*794/1000
.equ	fa	= do*749/1000
.equ	fam	= do*707/1000	; fa major
.equ	so	= do*667/1000
.equ	som	= do*630/1000	; so major
.equ	la	= do*595/1000
.equ	lam	= do*561/1000	; la major
.equ	si	= do*530/1000

.equ	do2	= do/2
.equ	dom2	= dom/2
.equ	re2	= re/2
.equ	rem2	= rem/2
.equ	mi2	= mi/2
.equ	fa2	= fa/2
.equ	fam2	= fam/2
.equ	so2	= so/2
.equ	som2	= som/2
.equ	la2	= la/2
.equ	lam2	= lam/2
.equ	si2	= si/2

.equ	do3	= do/4
.equ	dom3	= dom/4
.equ	re3	= re/4
.equ	rem3	= rem/4
.equ	mi3	= mi/4
.equ	fa3	= fa/4
.equ	fam3	= fam/4
.equ	so3	= so/4
.equ	som3	= som/4
.equ	la3	= la/4
.equ	lam3	= lam/4
.equ	si3	= si/4	

play_TPU: 
	lpm
	adiw zl,1
	tst r0 
	breq PC+5
	mov a0,r0
	ldi b0,50
	rcall sound
	rjmp play_TPU
	ret

play_wrong_sound: 
	rcall sound1
	WAIT_MS 30
	rcall sound1
	WAIT_MS 30
	rcall sound1
	WAIT_MS 30
	rcall sound1
	WAIT_MS 30
	ret