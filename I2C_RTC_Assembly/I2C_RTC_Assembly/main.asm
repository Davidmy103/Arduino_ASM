;
; I2C_RTC_Assembly.asm
;
; Created: 07/06/2022 15:26:37
; Author : David
;

.include "m328PBdef.inc"



.def temp	  = r16
.def temp2	  = r17
.def second  = r18
.def minute  =	r19
.def hour	  = r20
.def day	  = r21
.def month	  = r22
.def year	  = r23

.def twi_data = r24
.def read_data = r25



.equ _seconds	= 0x35
.equ _minutes	= 0x33
.equ _hours		= 0x10

.equ _day		= 0x09
.equ _month		= 0x06
.equ _year		= 0x22


.equ sec1	= 57724
.equ sec001 = 65527
.equ sec01  = 65457


.org 0x0000
start:
    
	cbi DDRC, 3 

	rcall uart_init
	rcall twi_init
	rcall init_RTC

//	rcall write_time_RTC
//	rcall write_date_RTC
l1:
	rcall read_time_RTC
	rcall read_date_RTC

	rcall uart_send
	//rcall delay_1
	rjmp l1




init_RTC:
	//write to control register
	rcall twi_start
	ldi twi_data, 0b11010000			;write address of RTC
	rcall twi_write						;send 1st byte
			
	ldi twi_data, 0x07					;set reg pointer to Control reg	
	rcall twi_write						

	ldi twi_data, 0b10010001			;enable SQW at freq 4kHz	
	rcall twi_write					
			
	rcall twi_stop					
	rcall delay
	ret


write_time_RTC:
	//write time to RTC
	rcall twi_start

	ldi twi_data, 0b11010000			;write address of RTC
	rcall twi_write		

	ldi twi_data, 0x00				;set pointer to SECONDS reg
	rcall twi_write

	ldi twi_data, _seconds
	rcall twi_write

	ldi twi_data, _minutes
	rcall twi_write
	
	ldi twi_data, _hours
	rcall twi_write

	rcall twi_stop
	rcall delay
	ret


write_date_RTC:
	//write date to RTC
	rcall twi_start

	ldi twi_data, 0b11010000			;write address of RTC
	rcall twi_write

	ldi twi_data, 0x04					;set pointer to DATE reg
	rcall twi_write

	ldi twi_data, _day
	rcall twi_write

	ldi twi_data, _month
	rcall twi_write
	
	ldi twi_data, _year
	rcall twi_write

	rcall twi_stop
	rcall delay
	ret



read_time_RTC:
	//read time of RTC
	rcall twi_start

	ldi twi_data, 0b11010000			;write address of RTC
	rcall twi_write

	ldi twi_data, 0x00				;set pointer to SECONDS reg
	rcall twi_write

	rcall twi_stop
	rcall twi_start

	ldi twi_data, 0b11010001			;read address of RTC
	rcall twi_write

	rcall twi_read						;read seoconds
	mov second, read_data				;store seconds
	rcall twi_read						;read minutes
	mov minute, read_data				;
	rcall twi_read_NACK					;read hour, return NACK
	mov hour, read_data					;

	rcall twi_stop
	rcall delay
	ret



read_date_RTC:
	//read date of RTC
	rcall twi_start

	ldi twi_data, 0b11010000			;write address of RTC
	rcall twi_write

	ldi twi_data, 0x04				;set pointer to DATE reg
	rcall twi_write

	rcall twi_stop
	rcall twi_start

	ldi twi_data, 0b11010001			;read address of RTC
	rcall twi_write

	rcall twi_read						;read day
	mov day, read_data					;store day
	rcall twi_read						;read month
	mov month, read_data				;
	rcall twi_read_NACK					;read year, return NACK
	mov year, read_data					;

	rcall twi_stop
	rcall delay
	ret



	//display the time and date on uart
	//uart init
uart_init:	
	ldi temp, 0b00000110
	sts UCSR0C, temp
	ldi temp, 0b10011000
	sts UCSR0B, temp
	ldi temp, 103
	sts UBRR0L, temp
	ret

uart_start:
	lds temp, UCSR0A
	sbrs temp, RXC0
//	rjmp uart_start
	lds temp, UDR0
	sts UDR0, temp
	ret

uart_send:

f1:	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp f1
	sts UDR0, second

f2:	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp f2
	sts UDR0, minute

f3:	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp f3
	sts UDR0, hour
	
f4:	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp f4
	sts UDR0, day

f5:	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp f5
	sts UDR0, month
	
f6:	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp f6
	sts UDR0, year
	ret









	//twi init 
twi_init:
	ldi temp, 0
	sts TWSR0, temp			;prescaler = 0
	ldi temp, 12			;division factor = 12
	sts TWBR0, temp			;SCK freq = 400kHz
	ldi temp, (1<<TWEN)	
	sts TWCR0, temp
	ret

twi_start:
	ldi temp, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	sts TWCR0, temp
d1:
	lds temp, TWCR0
	sbrs temp, TWINT
	rjmp d1
	ret

twi_write:
	sts TWDR0, twi_data
	ldi temp, (1<<TWINT) | (1<<TWEN)
	sts TWCR0, temp
d2:
	lds temp,TWCR0
	sbrs temp, TWINT
	rjmp d2
	ret

twi_stop:
	ldi temp, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)
	sts TWCR0, temp
	ret


twi_read:
	ldi temp, (1<<TWINT) | (1<<TWEA) | (1<<TWEN)
	sts TWCR0, temp
d3:
	lds temp, TWCR0
	sbrs temp, TWINT
	rjmp d3
	lds read_data, TWDR0			;store received byte
	ret


twi_read_NACK:
	ldi temp, (1<<TWINT) | (1<<TWEN)
	sts TWCR0, temp 
d4:
	lds temp, TWCR0
	sbrs temp, TWINT
	rjmp d4
	lds read_data, TWDR0
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



delay_1:
	ldi temp, high(sec1)
	sts TCNT1H, temp
	ldi temp, low(sec1)
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































