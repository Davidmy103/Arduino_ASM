;
; Software_UART.asm
;
; Created: 02/11/2022 14:43:09
; Author : David


.include "m328PBdef.inc"

.def temp =  r16

.org 0x00
	rjmp start


start:
	//init pins
	ldi temp, 0b00100000
	out DDRB, temp
	out PORTB, temp
	
loop:
	//code goes here
	//

	rjmp loop



soft_read_PortB_Pin12:	
	ldi r20, 9
rs_1:
	sbic PINB, 4
	rjmp rs_1
	rcall delay_05
rs_2:
	rcall delay_1	//every loop,from here, is 138 cycles 
	nop
	
	clc
	sbic PINB, 4		
	sec 
	dec r20
	breq rs_3
	ror r24		//<---- store the read byte in r24
	rjmp rs_2
rs_3:
	ret



soft_write_PortB_Pin13:		//write one byte to PORTB5
	ldi r20, 10
	com r24					//r24 -- tx_byte
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




//baud rate is set here(115200)
delay_1:				 
	ldi r16, 40 //<-------- = baud/3 - 6	// 115200 = 138 = 40
delay_check_1:				//     ^		//
	dec r16					//<-1cycle		//
	brne delay_check_1		//<-2cycle		//
	ret

	

delay_05:
	ldi r16, 19
delay_check_05:
	dec r16
	brne delay_check_05
	ret

