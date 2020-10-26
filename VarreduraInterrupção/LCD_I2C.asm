scl	equ	P1.6
sda	equ	P1.7
	org	0000h
	ajmp	inicio
Inicio:
	acall	LCD_Init		;Chama rotina de inicialização do display
	mov	a,#00h
	acall	writetable
	acall	secondline
	mov	a,#11h
	acall	Writetable
	acall	cursoroff
	jmp	$
;-------------------------------------
Send_Inst:
	acall	delay2ms
	push	acc
	acall	PrepareInst
	pop	acc
	swap	a
	acall	PrepareInst
	ret
;----------------------------------------
PrepareInst:
	clr	acc.3
	clr	acc.2
	clr	acc.1
	clr	acc.0
	acall	SendLCD

	ret
;-------------------------------------
Send_Data:
	acall	delay2ms			;teste (substitui o delay do sendlcd)
	push	acc
	acall	PrepareData
	pop	acc
	swap	a
	acall	PrepareData
	ret
;----------------------------------------
PrepareData:
	clr	acc.3
	clr	acc.2
	clr	acc.1		;rw
	setb	acc.0		;rs
	acall	SendLCD

	ret
;-------------------------------------
SendLCD:
	;acall	delay15ms
	mov	R3,#03h
SendLCDaux:
	acall	sendPCF
	rlc	a
	cpl	acc.2
	djnz	R3,SendLCDaux
	ret
;----------------------------------------
SendPCF:	
	push	acc		;sub-rotina de start do PCF
	mov	a,#01001110b	;(D7,D6,D5,D4, ,E,Rw,Rs)	endereço 27h do PCF e modo escrita
	setb	scl
	setb	sda
	acall	delay6us	;atraso de 6 us para t: SU;STA

	clr	sda
	acall	delay6us	;atraso de 6us para t: HD;STA
	mov	R0,#08h
SendPCFWrite:			;sub-rotina de escrever no PCF
	rlc	a		;desloca o bit mais sig. para a o carry
	clr	scl		;vou escrever
	mov	sda,C		;envia o bit
	acall	delay6us	;delay de 6us para t: LOW

	setb	scl		;lê o bit
	acall	delay6us	;delay de 6us para t: HIGH

	djnz	R0,SendPCFWrite
	pop	acc

	acall	SendPCFAck
	mov	R0,#08h
EnviaData:				;sub-rotina de escrever no PCF
	rlc	a		;desloca o bit mais sig. para a o carry
	clr	scl		;vou escrever
	mov	sda,C		;envia o bit
	acall	delay6us	;delay de 6us para t: LOW

	setb	scl		;lê o bit
	acall	delay6us	;delay de 6us para t: HIGH

	djnz	R0,enviadata

	acall	SendPCFAck
	
StopBit:
	clr	scl		;vou escrever
	clr	sda
	acall	delay6us
		
	setb	scl
	acall	delay6us

	setb	sda
	ret
	
SendPCFAck:
	clr	scl		;vou escrever
	setb	sda
	acall	delay6us	;2 us

	setb	scl		;bit de acknowledge
	acall	delay6us
	ret
;-----------------------------------------------------
LCD_Init:
	;Initializing display
	mov	a,#00110000b   
	acall	sendLCD

	mov	a,#00110000b 
	acall	delay15ms
	acall	sendLCD
	
	mov	a,#00110000b 
	acall	delay15ms
	acall	sendLCD
	
	; Set interface to be 4 bits long
	mov	a,#00100000b   ;(D7,D6,D5,D4, ,E,Rw,Rs) define o que envia
	acall	delay15ms
	acall	sendLCD

	mov	a,#28h   ;(D7,D6,D5,D4, ,E,Rw,Rs) define o que envia
	acall	send_inst

	mov	a,#06h   ;(D7,D6,D5,D4, ,E,Rw,Rs) define o que envia
	acall	send_inst

	acall	displayon
	;mov	a,#00001111b  ;(D7,D6,D5,D4, ,E,Rw,Rs) define o que envia
	;acall	send_inst

	;mov	a,#00000001b	;(D7,D6,D5,D4, ,E,Rw,Rs) define o que envia
	;acall	send_inst
	acall	Cleardisplay
	
	ret
;------------------------------------------------------
CursorHome:
	mov	a,#00000010b	;instrução para voltar o cursor para a posição 1x1
	acall	Send_Inst
	ret
;------------------------------------------------------
ClearDisplay:
	mov	a,#00000001b	;instrução para limpar display e voltar o cursor para 1x1
	acall	Send_Inst
	ret
;------------------------------------------------------
CursorRight:
	mov	a,#00010100b	;0001 CR**  (se C = 0, desloca cursor),(se R=1, direita) 
	acall	Send_Inst
	ret
;------------------------------------------------------
CursorLeft:
	mov	a,#00010000b	;0001 CR**  (se C = 0, desloca cursor),(se R=0, esquerda) 
	acall	Send_Inst
	ret
;------------------------------------------------------
MessageRight:
	mov	a,#00011100b	;0001 CR**  (se C = 1, desloca mensagem),(se R=1, direita) 
	acall	Send_Inst
	ret
;------------------------------------------------------
MessageLeft:
	mov	a,#00011000b	;0001 CR**  (se C = 1, desloca mensagem),(se R=0, esquerda) 
	acall	Send_Inst
	ret
;------------------------------------------------------
Position:
	push	acc
	mov	a,b
	jnb	a.7,Line1
Line2:
	clr	acc.7
	add	a,#3Fh		;soma o valor da coluna com o ultimo valor da linha 1
	setb	acc.7
	ajmp	column
Line1:
	subb	a,#00000001b
	setb	acc.7
Column:
	acall	Send_Inst
	pop	acc
	ret
;------------------------------------------------------
SecondLine:
	mov	a,#0C0h		;11000000
	acall	Send_Inst
	ret
;------------------------------------------------------
CursorOFF:
	mov	a,#00001100b	
				;0000 1DCBb
				;Liga (D=1) ou desliga display (D=0)
				;-Liga(C=1) ou desliga cursor (C=0)
				;-Cursor Piscante(B=1) se C=1
	acall	Send_Inst
	ret
;------------------------------------------------------
DisplayON:
	mov	a,#00001111b	
				;0000 1DCBb
				;Liga (D=1) ou desliga display (D=0)
				;-Liga(C=1) ou desliga cursor (C=0)
				;-Cursor Piscante(B=1) se C=1
	acall	Send_Inst
	ret
;------------------------------------------------------
DisplayOFF:
	mov	a,#00001011b	
				;0000 1DCBb
				;Liga (D=1) ou desliga display (D=0)
				;-Liga(C=1) ou desliga cursor (C=0)
				;-Cursor Piscante(B=1) se C=1
	acall	Send_Inst
	ret
;------------------------------------------------------
WriteTable:
	mov 	dptr,#words
auxt:
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
;----------------------------------------
Delay6us:			;2(acall) + 2(nop) + 2(ret)
	nop			;1 us
	nop			;1 us
	ret			;2 us
;------------------------------------------------------
delay1ms:		;2
	push	acc
	mov	a,#0F8h	;1
	djnz	acc,$	;248*2
	mov	a,#0F9h ;1
	djnz	acc,$	;249*2
	pop	acc
	ret		;2
			;1000 us = 1 ms
;-----------------------------------------------
delay2ms:
	acall	delay1ms
	acall	delay1ms
	ret
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
;Dados memória de programa
WORDS:
one:	db	'    LCD  I2C    '
	db	'\0'
two:	db	'  FUNCIONANDO!  '
	db	'\0'
three:	db	'MENSAGEM 3'
	db	'\0'

	
end







