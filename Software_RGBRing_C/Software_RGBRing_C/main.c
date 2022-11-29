/*
 * Software_RGBRing_C.c
 *
 * Created: 03/08/2022 15:23:59
 * Author : David
 */ 

#include <avr/io.h>
#include <avr/iom328pb.h>
#include <avr/interrupt.h>
#include <avr/delay.h>


extern unsigned char rgb_niz[] = {10,10,10,  0x80,0x80,0,  0,0x55,0x55};

extern void rgb_funkcija(int *s, uint8_t broj );

extern int broj = 0;

uint8_t data = 0;
uint8_t uart_data = 0;

uint8_t i_broj = 0;


int main(void)
{
	
	

	
	while(1)
	{
	
		
	rgb_funkcija(rgb_niz,3);
	_delay_ms(1000);

	
	} 
	


	return 0;


}



void uart_init()
{
	UCSR0C |= 0b00000110;
	UCSR0B |= 0b00011000;
	UBRR0L |= 103;
}


void uart_start()
{
	
	while (!(UCSR0A & (1<<RXC0)))
	{
	}
	
	while (!(UCSR0A & (1<<UDRE0)))
	{
	}
	
	uart_data = UDR0;
	UDR0 = uart_data;
	data = UDR0;
	
	
}

