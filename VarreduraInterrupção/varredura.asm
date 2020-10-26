;Fazer a leitura de 2 dois botão e acionar o led correspondente caso algum deles estejam ativo e escreve no lcd ambos por um determinado tempo 
	scl	equ	P1.6
	sda	equ	P1.7
	AC1	EQU 	P2.0	
	AC2	EQU 	P2.1	
	LED1	EQU 	P2.2		;
	LED2	EQU 	P2.3		; LEDs em current sink
	ORG	000H
	JMP 	CONFIG
;---------Rotina Principal------------------
CONFIG:	SETB	AC1
	SETB	AC2
	SETB	LED1
	SETB	LED2
	
	acall	lcd_init
	mov	b,#00000001b
	acall	position
	mov	a,#00h
	acall	writetable	;escreve 'LED 1: ' na primeira linha
	mov	a,#1Ah
	acall	writetable	;escreve DESLIGADO na primeira linha
	
	mov	b,#10000001b
	acall	position
	mov	a,#08h
	acall	writetable	;escreve 'LED 2: 'na segunda linha
	mov	a,#1Ah		;escreve DESLIGADO na segunda linha
	acall	writetable

loop:	JB	AC1,AUXLOOP
	CLR	LED1
	;ESCREVE DISPLAY LED1 ATIVADO
	mov	b,#00001000b	;muda o cursor para a coluna 7 da linha 1
	acall	position
	mov	a,#10h	
	acall	writetable	;escreve LIGADO na primeira linha
	
	ACALL	DELAY4S
	SETB 	LED1
	
	acall	position
	mov	a,#1Ah		
	acall	writetable	;escreve DESLIGADO na primeira linha
	
	
AUXLOOP:JB	AC2,ENDLOOP
	CLR	LED2
	;ESCREVE DISPLAY LED2 ATIVADO
	mov	b,#10001000b	;muda o cursor para a coluna 7 da linha 1
	acall	position
	mov	a,#10h		
	acall	writetable	;escreve LIGADO na segunda linha
	
	ACALL	DELAY8S
	SETB	LED2

	acall	position
	mov	a,#1Ah		
	acall	writetable	;escreve DESLIGADO na segunda linha
ENDLOOP:
	jmp loop
;-------------------------------
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
	clr	acc.3	;NC
	clr	acc.2	;e
	clr	acc.1	;rw
	clr	acc.0	;rs
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
ClearDisplay:
	mov	a,#00000001b	;instrução para limpar display e voltar o cursor para 1x1
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
DisplayON:
	mov	a,#00001111b	
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
delay8s:
	call	delay4s
	call	delay4s
	ret
;-------------------------------
delay4s:
	call	delay1s
	call	delay1s
	call	delay1s
	call	delay1s
	ret	
;-------------------------------
delay1s:                                            	; 2       | ciclos de máquina do mnemônico call
                mov             R7,#0fah                ; 1       | move o valor 250 decimal para o registrador R1
                mov             R5,#78h                  ; 2
                nop                                     ; 1
                nop                                     ; 1
                nop                                     ; 1        
aux:
                djnz            R5,aux                   ; 2*120
aux1:
                mov             R6,#0f9h                ; 1 x 250 | move o valor 249 decimal para o registrador R2
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
                nop                                     ; 1 x 250
aux2:           nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                nop                                     ; 1 x 250 x 249 = 62250
                djnz            R6,aux2                 ; 2 x 250 x 249 = 124500     | decrementa o R2 até chegar a zero
                djnz            R7,aux1                 ; 2 x 250                    | decrementa o R1 até chegar a zero
                ret                                     ; 2                          | retorna para a função main
                                                        ;------------------------------------
                                                        ; Total = 500005 us ~~ 500 ms = 0,5 seg
;-------------------------------
;Dados memória de programa
WORDS:
One:	db	'LED 1: '	;00h
	db	'\0'
Two:	db	'LED 2: '	;08h
	db	'\0'
Three:	db	'LIGADO   '	;10h
	db	'\0'
Four:	db	'DESLIGADO'	;19h
	db	'\0'
	
END