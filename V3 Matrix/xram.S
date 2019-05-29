;; begin xram.S

#include <avr/io.h>

	.section .init1,"ax",@progbits
	ser	r16
	out 0x17,r16
	clr r16        ;; for freestyle
	;;ldi r16,#0x02  ;; for xonik
	out 0x18,r16
	

;; end xram.S
