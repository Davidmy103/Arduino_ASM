/*
 * Software_UART_C.c
 *
 * Created: 08/08/2022 13:41:11
 * Author : David
 */ 

#include <avr/io.h>
#include <stdio.h>
#include <avr/delay.h>
#include <avr/interrupt.h>
#include <avr/iom328pb.h>

#define Rx_pin 0
#define Tx_pin 1

uint8_t bit_count = 0;
uint8_t Tx_byte = 0;
uint8_t timer_count = 0;


int main()
{
	PORTD = Tx_pin;
	DDRD  = 0b00000010;
	sei();
	
	pin_init();
	
	
	
	while (1)
	{
	}
	

}

 
 void pin_init()
 {
  
  PCICR  |= (1 << PCIE2);
  PCMSK2 |= (1 << PCINT16); //| (1 << PCINT17);
 }

ISR (PCINT2_vect)
{
	
	PCICR = 0x00;
	PCMSK2 = 0x00;
	
	
	
	start_timer0();
	wait_1bit();
	Rx_receive();
	wait_1bit();		//stop bit
	
	
	start_bit();	
	Tx_send();
	stop_timer0();
}

ISR (TIMER1_COMPA_vect)
{
	timer_count = timer_count + 1;
	
	
}

void start_timer0()
{
	TCNT1  = 0x00;
	OCR1A  = 8355;
	TCCR1A = (1<<COM1A1);
	TCCR1B = (1<<WGM12) | (1<<CS10);
	TIMSK1 = (1<<OCIE1A);
	sei();
	
}

void stop_timer0()
{
	OCR1A = 0;
	TCCR1A = 0x00;
	TCCR1B = 0x00;
}

void wait_1bit()
{
	while (timer_count < 1)
	{	 
	}
	timer_count = 0;
}


void Rx_receive()
{
	bit_count = 0;
	for (int i = 0; i < 8; i++)
	{
		if (PINC & Rx_pin)
		{
			bit_count = 1;
		}
		if (bit_count == 1)
		{
			Tx_byte |= 0b0000001;	
		}
		Tx_byte = Tx_byte << 1;
		
		while (timer_count < 1)
		{
		}
		timer_count = 0;
		bit_count = 0;
	}
}



void start_bit()
{
	PORTC &= ~(1UL <<Tx_pin);
	while (timer_count < 1)
	{
	}
	timer_count = 0;
}

void Tx_send()
{
	bit_count = 0;
	for (int i = 0; i < 8; i++)
	{
		if (Tx_byte & 0x80)
		{
			bit_count = 1;
		}
		if (bit_count == 1)
		{
			PORTC |= 1UL << Tx_pin;
		}
		else
		{
			PORTC &= ~(1UL <<Tx_pin);
		}
		bit_count = 0;
		Tx_byte = Tx_byte << 1;
		while (timer_count < 1)
		{
		}
		timer_count = 0;
	}	
	PORTC |= 1UL << Tx_pin;
	while (timer_count < 1)
	{
	}
	timer_count = 0;
	
}