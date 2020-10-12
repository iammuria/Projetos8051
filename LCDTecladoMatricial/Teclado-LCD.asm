; Código - Varredura de teclado com LCD modo 8 bits
; Fazer uma leitura de uma senha pelo teclado e mostrar em um display o resultado
; Autores: Múria e Rauney

	org	0000h
config:
	LCD	equ	P1	;porta conectada ao LCD
	RS	equ	P3.7	;pinos de comando do LCD
	RW	equ	P3.6	;
	E	equ	P3.5	;
	LA	equ	P2.0	;define pinos de leitura do teclado
	LB	equ	P2.1	;
	LC	equ	P2.2	;
	LD	equ	P2.3	;
	C1	equ	P2.4	;
	C2	equ	P2.5	;
	C3	equ	P2.6	;
	
	clr	E		;inicia com o enable desabilitado
	
	password0	equ	50h	;primeiro digito da senha
	password1	equ	51h	;segundo digito da senha
	password2	equ	52h	;terceiro digito da senha
	password3	equ	53h	;quarto digito da senha	
	
	acall	Lcd_Init	;inicia o LCD
	mov	R0,#50h		;registrador aux para contagem de numeros pressionados
				;e apontador para digitos da senha
				
	mov	R5,#00h		;registrador para verificação de senha(se R5 = 4 -> senha certa)
	mov	P2,#0FFh	;configura port P2 como entrada do teclado

	mov 	password0,#'1'	;define 1ª digito da senha
	mov 	password1,#'4' ;
	mov 	password2,#'7' ;
	mov 	password3,#'*' ;

prepare:
	mov	a,#00h		;aponta para mensagem Digite senha
	acall	writetable	;escreve na primeira linha do LCD
	acall	secondline	;manda o cursor para a segunda linha
;-----------------loop de varredura-----------------------
LineA:
	mov	a,#00h		;define acc como caractere nulo (\0)
	mov	R7,#00h		;registrador aux de contagem de linha (R7 = 0 -> linha A)
	clr	LA		;zera a linha A para verificar a coluna pressionada
	acall	Column1		;chama Coluna1 para verificar se o botao 1x1 foi pressionado
	cjne	a,#00h,SendButton	;verifica se algum botao da coluna 1 foi pressionado(a=!0h)
	ajmp	LineB		;se nao, verifica a proxima linha
;---------------------------------------------------------
LineB:
	inc	R7		;incrementa R7 para indicar a linha B (R7 = 1 -> linha B)
	setb	LA		;volta a linha A para nível alto
	clr	LB		;zera a linha B para verificar a coluna pressionada
	acall	Column1
	cjne	a,#00h,SendButton
	ajmp	LineC
;---------------------------------------------------------
LineC:
	inc	R7		;incrementa R7 para indicar a linha C (R7 = 2 -> linha C)
	setb	LB
	clr	LC
	acall	Column1
	cjne	a,#00h,SendButton
	ajmp	LineD
;---------------------------------------------------------
LineD:
	inc	R7		;incrementa R7 para indicar a linha D (R7 = 3 -> linha D)
	setb	LC
	clr	LD
	acall	Column1
	cjne	a,#00h,SendButton	;verifica se algum botao da linha D foi pressionado
	setb	LD		;se nao, volta a linha D para nivel alto
	ajmp	LineA		;volta a verificar a partir da linha A
;---------------------------------------------------------
SendButton:
	mov	b,@R0		;move o digito (R0-50h) da senha para o registrador b
	inc	R0		;incrementa R0 para apontar para o proximo digito da senha
	acall	Send_data	;envia para o LCD o valor lido
Compare:
	cjne	a,b,Different	;verifica se o digito lido é igual ao digito (b) da senha
	inc	R5		;se sim, incrementa R5
Different:
	cjne	R0,#54h,Next	;verifica se ja leu quatro valores (tamanho da senha)
	mov	R0,#50h		;se sim, zera a contagem
Status:
	acall	delay05s
	cjne	R5,#04h,Wrong	;verifica se (R5) é igual a 4 (se a senha esta correta)
Right:				;se sim,
	mov	R5,#00h		;zera a contagem de digitos certos
	acall	secondline	;move o cursor para o começo da segunda linha
	mov	a,#0Fh		;aponta para mensagem Bem vindo
	acall	Writetable	;escreve a mensagem no LCD
	acall	delay05s
	acall	cleardisplay
	ajmp	prepare	
Wrong:
					;se a senha digitada for errada -> (R5) != 4
	mov	R5,#00h			;zera a contagem de digitos certos
	acall	secondline	;manda o cursor para o começo da segunda linha
	mov	a,#19h		;aponta para mensagem Senha errada
	acall	Writetable
	acall	delay05s
	acall	cleardisplay
	ajmp	prepare
Next:
	ajmp	LineA
;---------------------------------------------------------
Column1:
	jb	C1,Column2	;não foi pressionado (C1 = 1) -> pula para verificar coluna 2
	acall	Delay200us	;delay para bounce
	jb	C1,Column2	;não foi pressionado (C1 = 1) -> pula para verificar coluna 2
	jnb	C1,$		;espera ate o botão ser solto
	cjne	R7,#00,P2x1	;verifica se a linha é a primeira e pula se for diferente 
P1x1:	mov 	a,#'1' 		; se for a linha A, move pro acc o valor 1 em ascii
	ret			;retorna da chamada de sub-rotina
P2x1:	cjne	R7,#01,P3x1	;verifica se a linha é a segunda e pula se for diferente 
	mov 	a,#'4' 		;
	ret
P3x1:	cjne	R7,#02,P4x1	;verifica se a linha é a terceira e pula se for diferente 
	mov 	a,#'7'		;
	ret
P4x1:
	mov 	a,#'*' 		;
	ret
;---------------------------------------------------------
Column2:
	jb	C2,Column3	;não foi pressionado -> pula para verificar coluna 3
	acall	Delay200us	;delay para bounce
	jb	C2,Column3	;não foi pressionado -> pula para verificar coluna 3
	jnb	C2,$
	
	cjne	R7,#00,P2x2	;verifica se a linha é a primeira e pula se for diferente 
P1x2:	mov 	a,#'2' 		;move para o acc o valor 2 em ascii
	ret
P2x2:	cjne	R7,#01,P3x2	;verifica se a linha é a segunda e pula se for diferente 
	mov 	a,#'5' 		; 
	ret
P3x2:	cjne	R7,#02,P4x2	;verifica se a linha é a terceira e pula se for diferente 
	mov 	a,#'8' 		; 
	ret
P4x2:
	mov 	a,#'0' 		;
	ret
;---------------------------------------------------------
Column3:
	jb	C3,return	;não foi pressionado -> pula para verificar coluna 3
	acall	Delay200us	;delay para bounce
	jb	C3,return	;não foi pressionado -> pula para verificar coluna 3
	jnb	C3,$
	
	cjne	R7,#00,P2x3	;verifica se a linha é a primeira e pula se for diferente 
P1x3:	mov 	a,#'3' 		;move para o acc o valor 3 em ascii
	ret
P2x3:	cjne	R7,#01,P3x3	;verifica se a linha é a segunda e pula se for diferente 
	mov 	a,#'6'	 	;
	ret
P3x3:	cjne	R7,#02,P4x3	;verifica se a linha é a terceira e pula se for diferente 
	mov 	a,#'9'		 ;
	ret
P4x3:
	mov 	a,#'#' 		; 
return:	ret	;retorna da chamada de sub-rotina
;------------------------------------------------------
lcd_init:
	mov	a,#38h		;0000 1YNF**b / 0011 1000b
				;modo 8 bits(Y=1) ou 4 bits(Y=0) 
				;Número de linhas: 1 (N=0) e 2 ou mais (N=1)
				;Matriz do caracter: 5x7(F=0) ou 5x10(F=1) 
	acall	send_inst
	
	acall	delay15ms
	acall	send_inst
	
	acall	delay15ms
	mov	a,#06h		;0000 0111b
				;Estabelece o sentido de deslocamento do cursor 
				;(X=0 p/ esquerda, X=1 p/ direita) -> X = acc.1
				;Estabelece se a mensagem deve ou não ser deslocada com a entrada 					;de um novo caracter S=1 SIM, S=0 NÃO. Exemplo: X=1 e S=1 => 						;mensagem desloca p/ direita. -> S = acc.0
	acall	Send_Inst

	acall	DisplayON

	acall	Cleardisplay

	ret
;------------------------------------------------------
Send_Data:
	push	acc
	acall	busy_check
	pop	acc
	clr	RW
	setb	RS
	mov	LCD,a
	setb	E
	nop
	clr	E
	ret
;------------------------------------------------------
Send_Inst:
	push	acc
	acall	busy_check
	pop	acc
	clr	RW
	clr	RS
	mov	LCD,a
	setb	E
	nop
	clr	E
	ret
;------------------------------------------------------
Busy_Check:
	mov	LCD,#0FFh
	setb	RW
	clr	RS
	setb	E
	nop
	mov	a,LCD
	clr	E
	jb	acc.7,Busy_check
	ret
;------------------------------------------------------
ClearDisplay:
	acall	busy_check
	mov	a,#00000001b	;instrução para limpar display e voltar o cursor para 1x1
	acall	Send_Inst
	ret
;------------------------------------------------------
DisplayON:
	acall	busy_check
	mov	a,#00001111b	
				;0000 1DCBb
				;Liga (D=1) ou desliga display (D=0)
				;-Liga(C=1) ou desliga cursor (C=0)
				;-Cursor Piscante(B=1) se C=1
	acall	Send_Inst
	ret
;------------------------------------------------------
SecondLine:
	acall	busy_check
	mov	a,#0C0h		;11000000 / 01 ADDRESb
	acall	Send_Inst
	ret
;------------------------------------------------------
WriteTable:
	mov 	dptr,#words
auxt:
	push	acc
	acall	busy_check
	pop	ACC
	push	acc
	MOVC	A,@A+dptr
	Cjne	A,#00h,Send
	pop	acc
	jmp 	Final
Send:
	acall	send_data
	inc	dptr
	pop	acc
	jmp	auxt
Final:
	ret
;------------------------------------------------------
delay1ms:		;2
	mov	a,#0F8h	;1
	djnz	acc,$	;248*2
	mov	a,#0F9h ;1
	djnz	acc,$	;249*2	
	ret		;2
			;1000 us = 1 ms
;-----------------------------------------------
delay15ms:		;2
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	acall	delay1ms
	ret
;-----------------------------------------------
delay200us:			;2 
	mov	R6,#200d	;1
	djnz	R6,$		;2*200
	ret			;2
;---------------------------------------------------
delay05s:
	push 	acc
        mov 	R2, #250d
auxms:
	nop
        mov 	a, #248d
	djnz 	acc, $
	nop
        mov 	a, #249d
        djnz 	acc, $
        nop
	mov 	a, #249d
        djnz 	acc, $
        nop
	mov 	a, #249d
        djnz 	acc, $
        djnz 	R2, auxms
        pop	acc
        ret
;-----------------------------------------------
words:
one:	db	'DIGITE A SENHA'
	db	'\0'
two:	db	'BEM VINDO'
	db	'\0'
three:	db	'SENHA ERRADA'
	db	'\0'
end
