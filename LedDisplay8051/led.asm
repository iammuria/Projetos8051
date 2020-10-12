; Código - Tarefa com portas digitais
; Fazer uma contagem de 0 a 9 em um display de 7 segmentos com um botão
; Autores: Múria e Rauney

	org 0000h

tabela:
	mov a, #0C0h ; 0 | 1100 0000b
	push acc
	mov a, #0F9h ; 1 | 1111 1001b
	push acc
	mov a, #0A4h ; 2 | 1010 0100b
	push acc
	mov a, #0B0h ; 3 | 1011 0000b
	push acc
	mov a, #099h ; 4 | 1001 1001b
	push acc
	mov a, #092h ; 5 | 1001 0010b
	push acc
	mov a, #082h ; 6 | 1000 0010b
	push acc
	mov a, #0F8h ; 7 | 1111 1000b
	push acc
	mov a, #080h ; 8 | 1000 0000b
	push acc
	mov a, #090h ; 9 | 1001 0000b
	push acc

inicio:
	mov a, #0FFh
	mov P2, a
	mov R0, #08h
	
loop:
	jb 	P2.7, loop
	acall	delay200us
	jb 	P2.7, loop

contagem:
	jnb	P2.7,$
	mov 	A, @R0
	mov 	P2, A
	CJNE 	R0, #11h, soma
	mov 	R0, #08h

	ajmp loop

soma:
	inc R0
	ajmp loop
	
delay200us:			;2 
	mov	R1,#200d	;1
	djnz	R1,$		;1*200
	ret			;2

end
