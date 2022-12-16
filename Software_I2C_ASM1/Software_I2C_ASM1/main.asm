;
; Hardware_I2C_A.asm
;
; Created: 11/06/2022 15:17:28
; Author : David
;
;RADI




.include "m328PBdef.inc"

.def temp	= r16
.def temp2	= r17
.def twi_data = r18
.def read_data  = r20
.def reset = r21
.def addrs = r22
.def temp3 = r23

.equ sec1	= 57724
.equ sec001 = 65527
.equ sec01  = 65457




.org 0x0000
main:	
	
	ldi reset, 0x00
	cbi DDRC, 3
	rcall uart_init
	rcall twi_init
	ldi addrs, 0x50

	ldi r16, 0xff
	out ddrc, r16
	out portc, r16


loop:

	rcall eeprom_write
	rcall eeprom_read
	
	nop
kk:	rjmp kk


	//RTC		- 0x68 
	//EEPROM	- 0x50
eeprom_write:
	rcall twi_start
	ldi twi_data, 0b10100000		;control byte (LSB is R/W) 
	rcall twi_write

	ldi twi_data, 0b00000000		;address of eeprom
	rcall twi_write
	ldi twi_data, 0b01010000
	rcall twi_write

	ldi twi_data, 0xF8
	rcall twi_write
	
	ldi twi_data, 0xD0
	rcall twi_write
	
	ldi twi_data, 0xAF
	rcall twi_write

	ldi twi_data, 0xC5
	rcall twi_write
	
	rcall twi_stop
	rcall delay
	ret


eeprom_read:
	rcall reset_value
	rcall twi_start
	
	ldi twi_data, 0b10100000		;control byte (LSB is R/W)
	rcall twi_write
	
//	ldi temp3, UDR0
	add temp3, addrs

	ldi twi_data, 0b00000000		;address of eeprom
	rcall twi_write					;
	mov twi_data, temp3			;
	rcall twi_write					;

	rcall twi_stop
	rcall twi_start

	ldi twi_data, 0b10100001 
	rcall twi_write

	rcall twi_read
	sts UDR0, read_data






	mov temp3, reset
	
	rcall twi_stop
	rcall delay
	ret




	
twi_init:
	ldi temp, 0
	sts TWSR0, temp									;prescaler = 0
	ldi temp, 72									;division factor = 12
	sts TWBR0, temp									;SCK freq = 400kHz
	ldi temp, (1<<TWEN)	
	sts TWCR0, temp
	ret

twi_start:
	ldi temp, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)	;send start condition
	sts TWCR0, temp										
d1:
	lds temp, TWCR0									;after start condition wait for 
	sbrs temp, TWINT								;TWINT to be set again
	rjmp d1								
	ret								

twi_write:
	sts TWDR0, twi_data								;write data to TWDR data reg									
	ldi temp, (1<<TWINT) | (1<<TWEN)				;send write condition												
	sts TWCR0, temp									;							
d2:
	lds temp,TWCR0									;after condition wait for TWINT							
	sbrs temp, TWINT								;								
	rjmp d2											;					
	ret																								

twi_stop:
	ldi temp, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)	;send stop condition															
	sts TWCR0, temp																
	ret


twi_read:
	ldi temp, (1<<TWINT) | (1<<TWEA) | (1<<TWEN)	;send read condition							
	sts TWCR0, temp									;	with ACK						
d3:
	lds temp, TWCR0									;wait for TWINT							
	sbrs temp, TWINT								;								
	rjmp d3											;					
	lds read_data, TWDR0								;TWDR(data register) is copyed in temp reg 
	ret												;	for later use


twi_read_NACK:
	ldi temp, (1<<TWINT) | (1<<TWEN)				;send read condition												
	sts TWCR0, temp 									;	with NACK								
d4:
	lds temp, TWCR0																
	sbrs temp, TWINT																
	rjmp d4																
	lds read_data, TWDR0																
	ret






reset_value:
	
	ldi addrs, 0x50


	ret



uart_start:
	lds temp, UCSR0A
	sbrs temp, RXC0
	rjmp uart_start
//	lds temp, UDR0
	lds temp3, UDR0
	ret

uart_init:
	ldi temp, (1<<UCSZ01)|(1<<UCSZ00)		;0b00000110 
	sts UCSR0C, temp
	ldi temp, (1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0)		;0b10011000
	sts UCSR0B, temp
	ldi temp, 103
	sts UBRR0L, temp
	ret

	


	//delay
delay:
	ldi temp, high(sec01)
	sts TCNT1H, temp
	ldi temp, low(sec01)
	sts TCNT1L, temp

	ldi temp2, 0b00000001
	sts TIFR1, temp2
	ldi temp2, 0b00000101
	sts TCCR1B, temp2

	rcall delay_check
	ret

delay_check:
	in temp2, TIFR1
	sbrs temp2, TOV1
	rjmp delay_check
	ldi temp2, (1<<TOV1)
	out TIFR1, temp2
	ldi temp2, 0x00
	sts TCCR1B, temp2
	ret


delay_001:
	ldi temp, high(sec001)
	sts TCNT1H, temp
	ldi temp, low(sec001)
	sts TCNT1L, temp

	ldi temp2, 0b00000001
	sts TIFR1, temp2
	ldi temp2, 0b00000101
	sts TCCR1B, temp2

	rcall delay_check1
	ret

delay_check1:
	in temp2, TIFR1
	sbrs temp2, TOV1
	rjmp delay_check
	ldi temp2, (1<<TOV1)
	out TIFR1, temp2
	ldi temp2, 0x00
	sts TCCR1B, temp2
	ret