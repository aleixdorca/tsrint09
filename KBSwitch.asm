;=======================================================;
; Programa que detecta la polsació de la tecla F3   	;
; i escriu la comanda dir<cr> al buffer de teclat   	;
;							;
; Aleix Dorca - Universitat d'Andorra - 2017		;
; 							;
; Per compilar fa falta masm32 i link16:		;
; c:\>ml /c KBSwitch.asm				;
; c:\>link16 KBSwitch.obj;				;
; c:\>KBSwitch.exe					;
; 							;
; NOTA: El programa funciona en Win7. No cal la		;
; instal·lació de DOSBox, FreeDOS, o similars.		;
;=======================================================;

.model small
.stack
.data
    Init_Msg			db "TSR enabled...", "$"	; Missatge a mostrar a l'inici
.code
.startup
	Old_Int9	 	dw ?, ?				; Variable que apunta al vector de int 09h anterior
	In_IRS			dw 0				; Semàfor per impedir que altres executin el codi
	KB_Buffer_Start		equ 80h				; Variables en memòria del Buffer de Teclat
	KB_Buffer_End 		equ 82h
	KB_Buffer_Tail 		equ 1Ch
	BIOS_Data		equ 40h
	
	jmp			Init				; Inicialment, instal·lem el TSR

	Send_Keystroke proc					; Funció que insereix un caràcter al Buffer de Teclat
		pushf
		push	bx
		push	di
		push	es
			
		cld
		mov 	bx, BIOS_Data
		mov	es, bx
		mov	di, es:[KB_Buffer_Tail]
		stosw
		cmp	es:[KB_Buffer_End], di
		jne	Tail_OK
		mov	di, es:[KB_Buffer_Start]
		
		Tail_OK:
		mov	es:[KB_Buffer_Tail], di
			
		pop	es
		pop	di
		pop	bx
		popf
		ret
	Send_Keystroke endp
	
	New_Int9 proc far					; Nova interrupció int 09h
		pushf						; Desem el que modificarem
		push	ax
			
		in	al, 60H					; Llegim el port del teclat

		cmp	In_IRS, 1				; Comprovem l'estat del semàfor
		je	Original_Int9				; Si la rutina ja s'està executant no fem res

		cmp	al, 0bdh				; Comprovem que la tecla que s'ha deixat anar és F3: f0+3d = bd
		jne	Original_Int9				; Si no no fem res
			
		mov	In_IRS, 1				; En cas contrari, activem el semàfor
			
		mov	ax, 2064h ;d				; Enviem les tecles "dir<cr>" al Buffer
		call	Send_Keystroke
		mov	ax, 1769h ;i
		call	Send_Keystroke
		mov	ax, 1372h ;r
		call	Send_Keystroke
		mov	ax, 1c0dh ;CR
		call	Send_Keystroke

		mov	In_IRS, 0				; Desactivem el semàfor

		Original_Int9:					; Cridem a la interrupció antiga
		pop	ax
		popf
			
		push	Old_Int9 + 2
		push	Old_Int9
		retf
	New_Int9 endp
	
	End_New_Int9 equ this byte				; Fins aquí el codi que quedarà resident en memòria

	Init:							; Instal·lació del TSR
		mov	ax, @data				; Posem el segment de dades a DS
		mov	ds, ax
		
		mov	ax, 3509h				; Llegim la posició de la int 09h original
		int	21h
		mov	Old_Int9, bx				; El valor es troba en es:dx
		mov	Old_Int9 + 2, es
		
		push	ds					; La canviem per la nova New_Int9
		mov	ax, @code
		mov	ds, ax
		mov	dx, offset New_Int9
		mov	ax, 2509h
		int	21h
		pop	ds
		
        	mov	ah, 9					; Mostrem el missatge Init_Msg
        	lea	dx, Init_Msg
        	int	21h
		
		mov	dx, offset End_New_Int9			; Calculem la mida del TSR
		mov	cl, 4
		shr	dx, cl
		inc	dx
		mov	ax, 3100h				; Terminate and stay resident
		int	21h
end
