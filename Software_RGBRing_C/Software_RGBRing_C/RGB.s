
/*
 * RGB.s
 *
 * Created: 03/08/2022 15:24:25
 *  Author: David
 */ 


 #include <avr/io.h>

					
 .global rgb_funkcija 
 .extern rgb_niz
 .type rgb_funkcija, @function
	


rgb_funkcija:					
								
	ldi ZL, lo8(rgb_niz)				
	ldi ZH, hi8(rgb_niz)	

	ldi r23, 24			;upisuje se broj dioda (24) u r23
	mov r24, r22		;upisuje se drugi arg iz func "rgb_funkcija" u r24
	sub r23, r22		;oduzima se broj 24 od zadatog broja sto oznacava koliko dioda su ugasene
	ldi r22, 3			;upisuje se 3 jer 3*broj_zeljenih_upaljenih_dioda
	mul r24, r22		;mnozi se broj_upaljen_dioda sa 3 					
	mov r24, r0			;upisuje se rezultat u r24
	ldi r22, 8			;upisuje se 8 u r22 
	mul r24, r22		;mnozi se gore dobijen broj sa 8	
	mov r24, r0			;upisuje se rezultat u r24

	
	
					
	ld r20, Z+					
								
								
	sbi 0x0A,4					
								
		

provera:						
	ldi r28, 8
provera_1:
	rol r20
	brcs logic_1
logic_0:
	sbi 0x0B, 4
	dec r24
	breq kraj
	nop
	cbi 0x0B, 4
	dec r28
	breq bb
	nop
	nop
	nop
	nop
	rol r20
	brcs logic_1_1
	rjmp logic_0
								
								
logic_1_1:
	nop
logic_1:
	sbi 0x0B, 4
	dec r24
	breq kraj
	dec r28
	breq aa
	nop
	nop
	nop
	cbi 0x0B, 4								
	nop
	nop							
	rol r20
	brcs logic_1_1
	rjmp logic_0							
								
bb:
	ld r20, Z+
	rjmp provera

									
			
aa:
	 nop
  	 ld r20, Z+
	 cbi 0x0B, 4
	 rjmp provera
	

	
kraj:
	cbi 0x0B, 4
	
	ldi r22, 3
	mul r23, r22
	ldi r22, 8 
	mov r23, r0
	mul r23, r22
	mov r24, r1			;high byte
	mov r23, r0			;low byte
	sub r23, 1
	rjmp write

write_1:
	nop
	nop
	nop
write:
	sbi 0x0B, 4
	nop
	ldi r26, 0
	nop
	cbi 0x0B, 4
	nop
	nop
	nop
	nop
	dec r23
	cpse r23, r26
	rjmp write_1
	dec r24
	breq end
	rjmp write



	end:
		ret

	 


	



