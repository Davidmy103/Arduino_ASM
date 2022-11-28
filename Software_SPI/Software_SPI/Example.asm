;
; Example.asm
; 
;
; Created: 20/06/2022 10:39:50
; Author : David
;




.include "m328PBdef.inc"

.macro	cs_low
	cbi PORTB, cs
.endm

.macro cs_high
	sbi PORTB, cs
.endm

.macro	clk_high
	sbi PORTB, clk
.endm

.macro	clk_low
	cbi PORTB, clk
.endm

.macro	di_high
	sbi PORTB, di
.endm

.macro  di_low
    cbi PORTB, di
.endm



.def temp		= r16
.def temp2		= r17
.def data		= r18
.def uart_data	= r19
.def count		= r20
.def count2		= r21
.def byte_count = r22
.def checker	= r23
.def spi_data	= r24

.equ clk	= 5
.equ cs		= 2
.equ di		= 4
.equ do		= 3


.equ I_write_enable		= 0x06
.equ I_write_disable	= 0x04
.equ I_read_data		= 0x03
.equ I_fast_read		= 0x0B
.equ I_chip_erase		= 0x60
.equ I_page_program		= 0x02
.equ I_read_UID			= 0x4B


.org 0x0000
rjmp start

.org 0x001C
rjmp timerInterrupt_ISR

start:
	cli
	sbi DDRB, clk
	sbi PINB, do
	sbi PORTB, cs

	rcall init_spi
	rcall uart_init
	clr uart_data


//	MAIN PROGRAM START

main:
	
	rcall uart_start
	mov temp2, uart_data 

	cp temp2, I_write_enable
	breq write_enable

	cp temp2, I_write_disable
	breq write_disable

	cp temp2, I_read_data
	breq read_instruction

	cp temp2, I_fast_read
	breq fast_read

	cp temp2, I_chip_erase
	breq chip_erase

	cp temp2, I_page_program
	breq page_program

	cp temp2, I_read_UID
	breq read_UID


	


	rjmp main



read_UID:
	rcall enable_spi
	rcall timer0_interrupt_init		;start_isr
	sei

	//instrunction
	ldi spi_data, 0x4B
	rcall write_instruction

	//dummy bytes
	ldi count, 32
	rcall dummy_bytes

	//data
	ldi count, 64
	rcall read_spi

	rcall stop_isr	
	rcall disable_spi

	ldi ZL, low(0x0100)
	ldi ZH, high(0x0100)
	ldi count, 8
write_uart_read_UID:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp write_uart_read_UID
	sts UDR0, Z+
	dec count
	brne write_uart
	ret


chip_erase:
	rcall enable_spi
	rcall timer0_interrupt_init		
	sei

	//instrunction
	ldi spi_data, 0x60
	rcall write_instruction

	rcall stop_isr
	rcall disable_spi
	ret




write_enable:
	rcall enable_spi
	rcall timer0_interrupt_init		
	sei

	//instrunction
	ldi spi_data, 0x06
	rcall write_instruction

	rcall stop_isr
	rcall disable_spi
	ret




write_disable:
	rcall enable_spi
	rcall timer0_interrupt_init		
	sei

	//instrunction
	ldi spi_data, 0x04
	rcall write_instruction

	rcall stop_isr
	rcall disable_spi
	ret



fast_read:
	rcall enable_spi
	rcall timer0_interrupt_init		;start_isr
	sei

	//instrunction
	ldi spi_data, 0x0b
	rcall write_instruction


	//addr
	ldi spi_data, 0x10
	rcall write_instruction

	ldi spi_data, 0x00
	rcall write_instruction
	
	ldi spi_data, 0x00
	rcall write_instruction


	//dummy bytes
	ldi count, 8
	rcall dummy_bytes
	 

	//data
	ldi count, 64			//8byte * 8bits = 64bits
	rcall read_spi

	//end spi communication
	rcall stop_isr
	rcall disable_spi
	
	
	ldi ZL, low(0x0100)
	ldi ZH, high(0x0100)
	ldi count, 8
write_uart_fastRead:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp write_uart_fastRead
	sts UDR0, Z+
	dec count
	brne write_uart
	ret

	
	
	



	
page_program:
	rcall enable_spi
	rcall timer0_interrupt_init		;start_isr
	sei

	//instrunction
	ldi spi_data, 0x02
	rcall write_instruction


	//addr
	ldi spi_data, 0x10
	rcall write_instruction

	ldi spi_data, 0x00
	rcall write_instruction
	
	ldi spi_data, 0x00
	rcall write_instruction


	//data
	ldi spi_data, 0xA1
	rcall write_instruction
	ldi spi_data, 0xA2
	rcall write_instruction
	ldi spi_data, 0xA3
	rcall write_instruction
	ldi spi_data, 0xA4
	rcall write_instruction
	ldi spi_data, 0xA5
	rcall write_instruction
	ldi spi_data, 0xA6
	rcall write_instruction
	ldi spi_data, 0xA7
	rcall write_instruction
	ldi spi_data, 0xA8
	rcall write_instruction


	rcall stop_isr
	nop
	nop
	rcall disable_spi
	ret

































read_instruction:
	rcall enable_spi				  
	rcall timer0_interrupt_init		 
	sei

	//instruction 
	ldi spi_data, 0x03
	rcall write_instruction

	//addr
	ldi spi_data, 0x10
	rcall write_instruction
	ldi spi_data, 0x00
	rcall write_instruction
	ldi spi_data, 0x00
	rcall write_instruction


	//read data
	ldi count, 64					 
	rcall read_spi					 
	rcall stop_isr					 
	rcall disable_spi				 


	ldi ZL, low(0x0100)				 
	ldi ZH, high(0x0100)			 
	ldi count, 8					  
write_uart:							
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp write_uart
	sts UDR0, Z+
	dec count					
	brne write_uart				
	ret



read_spi:
	ldi ZL, low(0x0100)			 
	ldi ZH, high(0x0100)		  

	clr data
	ldi byte_count, 8
wi22:
	clc
	sbic PINB, do
	sec 

	rol data

	dec byte_count
	breq reset

do_done2:

clk_loop32:
	in checker, PORTB
	sbrs checker, clk
	rjmp clk_loop32

	lsl checker
	lsl checker 
	lsl checker 

	brcs clk_loop22
	rjmp clk_done2 

clk_loop22:
	sbic PORTB, clk
	rjmp clk_loop22
	nop

clk_done2:
	dec count
	brne wi22
	ret

reset:
	st Z+, data					  
	ldi byte_count, 8			 
	clr data
	rjmp do_done2
	ret





write_instruction:
	ldi count,  8 

wi:
	lsl spi_data

wi2:brcc set_di_low
	di_high
	
	rjmp di_done

set_di_low:
	di_low
	nop

di_done:
	nop


clk_loop:
	in checker, PORTB
	sbrs checker, clk
	rjmp clk_loop

	lsl checker
	lsl checker 
	lsl checker 

	brcs clk_loop2
	rjmp clk_done 

clk_loop2:
	sbic PORTB, clk
	rjmp clk_loop2
	nop

clk_done:
	dec count
	brne wi
	ret




dummy_bytes:	
	nop
wi1:
	lsl spi_data

wi12:brcc set_di_low1
	di_high
	
	rjmp di_done1

set_di_low1:
	di_low
	nop

di_done1:
	nop


clk_loop1:
	in checker, PORTB
	sbrs checker, clk
	rjmp clk_loop1

	lsl checker
	lsl checker 
	lsl checker 

	brcs clk_loop12
	rjmp clk_done1

clk_loop12:
	sbic PORTB, clk
	rjmp clk_loop12
	nop

clk_done1:
	dec count
	brne wi1
	ret




	
timerInterrupt_ISR:			
	sbis PORTB, clk
	rjmp set_clk_high

	cbi PORTB, clk
	reti


set_clk_high:
	sbi PORTB, clk
	reti

stop_isr:
	ldi temp, 0x00
	sts TCCR0A, temp
	cbi PORTB, clk
	ret


timer0_interrupt_init:
	ldi temp, 199
	out OCR0A, temp
	ldi temp, (1<<WGM01)
	out TCCR0A, temp
	ldi temp, 0x01
	out TCCR0B, temp		 

	ldi temp, (1<<OCIE0A)
	sts TIMSK0, temp		 
	ret
	

enable_spi:
	clk_low
	di_low
	cs_low
	ret

disable_spi:
	cs_high
	ret

init_spi:
	cs_high
	sbi DDRB, cs
	clk_low
	sbi DDRB, clk
	di_low
	sbi DDRB, di
	cbi DDRB, do
	ret

uart_init:
	ldi temp, 0b00000110
	sts UCSR0C,temp
	ldi temp, 0b00011000
	sts UCSR0B, temp
	ldi temp, 8				 
	sts UBRR0L, temp
	ret

	
uart_start:
	lds temp, UCSR0A
	sbrs temp, RXC0
	rjmp uart_start
	lds uart_data, UDR0
	ret








