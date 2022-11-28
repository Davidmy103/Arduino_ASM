;
; Software_SPI_Assembly.asm
;
; Created: 17/06/2022 08:40:39
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


.org 0x0000
rjmp start

.org 0x001C
rjmp timerInterrupt_ISR

start:
	cli
	
	sbi DDRB, clk
	sbi PINB, do
	sbi PORTB, cs

	
main:
	
	//code goes here

	rjmp main


//main instructions 
	

//READ_INSTRUCTION 03h (normal read)
//this instruction first send the hex numb for the instruction, that is defined in the datasheet 
//	for this flash (W25Q16JV), then send the addres that you want to read from, the call the read_spi function 
//	which will read the contents from the DO pin every clock's falling edge. Then store that read value in a memory 
//	location that is defined at the start of "read_spi" function. After that you set the pointer to that location
//	again, and send the value stored in that location to uart so it can be displayed (this is my way, you can use what
//	ever you want)
//
//"count"	 register controls how many BITS it will read (in the second half it controls how many BYTES it WRITE to UART)
//"spi_data" register is a buffer for the data that you send via "write_instruction" function 
read_instruction:
	rcall enable_spi				//pull CS low to start the spi 
	rcall timer0_interrupt_init		//start clock 
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
	ldi count, 64					//num_of_bytes_2_send * num_of_bits_in_data = count		
	rcall read_spi					// 8bytes * 8bits = 64bits to send
	rcall stop_isr					//stop clock
	rcall disable_spi				//pull CS high to end the spi communication


	ldi ZL, low(0x0100)				//this mem location (0x0100) has to be the same as the one you set in 
	ldi ZH, high(0x0100)			//	"read_spi" instruction
	ldi count, 8					//this needs to be the num of bytes you read 
write_uart:							
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp write_uart
	sts UDR0, Z+
	dec count					
	brne write_uart				
	ret




//READ_SPI
//This function does a software read from pin "do" that is predefined. It first checks if the pin is HIGH or LOW
//	then sets the CARRY flag if it's HIGH or clears the flag if it's LOW, and does a "ROL" instruction (Rotate Left),
//	it shifts a register whitch shifts the LSB to the left and puts the value of the carry flag in that spot.
//	After that is done it check if the clock is high or low so that it doesent go twice low or twice high
//	And when the "byte_count" is 0, that means that the register is ready with 8bits full and goes to "reset" function
//	which stores the data, that it read, in the memory and clears the "data" register for the next byte 
read_spi:
	ldi ZL, low(0x0100)			//set pointer Z to a location in memory
	ldi ZH, high(0x0100)		// "0x0100" <-- this is the location 

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
	st Z+, data					//store the value of "data" register in the memory that Z is pointing to 
	ldi byte_count, 8			//this should never be higher than 8
	clr data
	rjmp do_done2
	ret






//WRITE INSTRUCTION
//This function write to spi via "di" pin that is predefined, this function only writes 1 BYTE at a time 
//Just set the "spi_data" register with the value that you want to send and your done
//If you are useing a different microcontroller you need to change the macros that are defined at the top 
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




//WRITE DUMMY BYTES
//This function writes dummy bytes, just sends 0x00 value to "DI" pin.
//To control how many bits to send, change the "count" register.
dummy_bytes:	
	//ldi count,  32 
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













//Start the timer interrupt for the clock signal, it's set for 200cycles	
timerInterrupt_ISR:			
	sbis PORTB, clk
	rjmp set_clk_high

	cbi PORTB, clk
	reti


//Set the clock high
set_clk_high:
	sbi PORTB, clk
	reti


//Stops the timer for the clock
stop_isr:
	ldi temp, 0x00
	sts TCCR0A, temp
	cbi PORTB, clk
	ret


//Init the timer, the minimal that I have set and works is 100cycles, but 200cycles is safer
timer0_interrupt_init:
	ldi temp, 199
	out OCR0A, temp
	ldi temp, (1<<WGM01)
	out TCCR0A, temp
	ldi temp, 0x01
	out TCCR0B, temp		;start Timer CTC mode, no scaler

	ldi temp, (1<<OCIE0A)
	sts TIMSK0, temp		;enable Timer0 compare match interrupt
	ret
	

//set clock low, di pin low, and cs low (that is the default and it starts the SPI communication)
enable_spi:
	clk_low
	di_low
	cs_low
	ret

//set cs high whitch stops the SPI communication
disable_spi:
	cs_high
	ret

//set all the needed pins for spi, this function is called before all
init_spi:
	cs_high
	sbi DDRB, cs
	clk_low
	sbi DDRB, clk
	di_low
	sbi DDRB, di
	cbi DDRB, do
	ret


//init uart so the data can be read 	
uart_init:
	ldi temp, 0b00000110
	sts UCSR0C,temp
	ldi temp, 0b00011000
	sts UCSR0B, temp
	ldi temp, 8				//115200 baud rate
	sts UBRR0L, temp
	ret



































