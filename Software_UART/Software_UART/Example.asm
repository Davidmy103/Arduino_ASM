/*
 * Example.asm
 *
 *  Created: 23/11/2022 09:06:25
 *   Author: David
 */ 


.include "m328PBdef.inc"



.def temp =  r16

.org 0x00
	rjmp start


start:
	//init pins
	ldi temp, 0b00100000
	out DDRB, temp
	out PORTB, temp
	


main:
	rcall soft_read_PortD_Pin1		//when this is done the data will be in r24
	inc r24							//change the data
	rcall soft_write_PortB_Pin13	//then just send the new data to Pin13 
	

	rjmp main









soft_read_PortD_Pin1:		
	ldi r20, 9
rs_1:
	sbic PIND, 1			//make sure to change where this instruction is checking(PIND insted of PINB)
	rjmp rs_1
	rcall delay_05
rs_2:
	rcall delay_1	
	nop
	
	clc
	sbic PIND, 1			//here too	
	sec 
	dec r20
	breq rs_3
	ror r24		
	rjmp rs_2
rs_3:
	ret





soft_write_PortB_Pin13:		
	ldi r20, 10
	com r24		
	sec
w_0:
	brcc w_1
	cbi PORTB, 5
	rjmp w_2
w_1:
	sbi PORTB, 5
	nop
w_2:
	rcall delay_1
	nop
	lsr r24
	dec r20
	brne w_0
	ret

