.model tiny
.code
org 100h
VIDEOSEG equ 0b800h

start:

      mov ax, 3509h      
      int 21h       
      mov word ptr offset old09Ofs, bx
      mov word ptr offset old09Ofs1, bx
      mov bx, es
      mov word ptr offset old09Seg, bx
      mov word ptr offset old09Seg1, bx

      push 0
      pop es

      cli
      mov bx, 09h * 4               ;туда надо прерывание засунуть, используется только тут, я считаю, недостойно константы, очень удобно прям тут менять если что
      mov es: [bx], offset New09 
      mov ax, cs
      mov es: [bx + 2], ax          ;кидаем сюда сегмент, в котором находимся
      mov bx, 08h * 4               ;оч круто
      mov es: [bx], offset New08 
      mov ax, cs
      mov es: [bx + 2], ax
      sti

      mov ax, 3100h                 ;сохранение кода
      mov dx, offset EndOfProgram
      shr dx, 4
      inc dx
      

      int 21h


New09   proc                        ;обработчик прерываний (клавиатура)
        push ax 
        push bx 
        push es
        push 0b800h
        pop es
        mov bx, (5 * 80d + 40d) * 2
        in al, 60h 

        mov cl, 03h                 ;проверка на то, что считан скан-код клавиши с цифрой 2
        cmp al, cl
        jne Not2
        call MainFunc               ;если 2 нажали, вызываем рамку
        mov int08flag, 1            ;выставлен флаг для прерывания таймера

        Not2:

        in al, 61h                  ;мигаем старшим битом в 61 порту
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al
        mov al, 20h                 ;сообщаем контроллеру прерываний, что обработка сигнала с клавиатуры закончена
        out 20h, al

        pop es 
        pop bx 
        pop ax


        db 0eah                     
        old09Ofs dw 0
        old09Seg dw 0
        ret
        endp

New08   proc                        ;обработчик прерываний (таймер)
        push ax 
        push bx 
        push es
        push 0b800h
        pop es
        cmp int08flag, 1
        jne NoFlag                  ;если флаг из 9 прерывания выставлен, то обновляем рамку
        call MainFunc
        NoFlag:

        pop es 
        pop bx 
        pop ax

        db 0eah
        old09Ofs1 dw 0
        old09Seg1 dw 0
        ret
        endp


;----------------------------------------------------------------------
;                         MainFunc
;to think
;Enter:
;Exit:  
;Destr: 
;----------------------------------------------------------------------
  MainFunc   proc 

	    push ax ;чтобы сохранить начальные значения регистров
	    push bx
	    push dx
	
	    mov ax, VIDEOSEG
	    mov es, ax
	
	    ; да, копипаст, невкусно, но мб оправдано:
	    ; 1. мне не приходится пушить cx в стек, тк нет цикла, да это ж круто!!
	    ; 2. я не знаю, как сделать подстановку регистров, типа чтобы в ax каждый раз в цикле разные регистры были
	    ; 3. это стильно, модно и молодежно
	
	    mov bx, STRING5
	    mov dx, "ax"
	    call PrintReg   
	
	    mov bx, STRING5 + LEN_OF_STR
	    pop dx
	    pop ax
	    push ax
	    push dx
	    mov dx, "bx"
	    call PrintReg
	
	    mov bx, STRING5 + LEN_OF_STR * 2
	    mov ax, cx
	    mov dx, "cx"
	    call PrintReg
	
	    mov bx, STRING5 + LEN_OF_STR * 3
	    pop ax
	    mov dx, "dx"
	    call PrintReg
	    push ax
	
	    mov bx, STRING5 + LEN_OF_STR * 4
	    mov ax, si
	    inc si
	    mov dx, "si"
	    call PrintReg 
	
	    mov bx, STRING5 + LEN_OF_STR * 5
	    mov ax, di
	    mov dx, "di"
	    call PrintReg
	
	    mov bx, STRING5 + LEN_OF_STR * 6
	    mov ax, bp
	    mov dx, "bp"
	    call PrintReg
	
	    mov bx, STRING5 + LEN_OF_STR * 7
	    mov ax, sp
	    mov dx, "sp"
	    call PrintReg
	
	    mov bx, STRING5 + LEN_OF_STR * 8
	    mov ax, ds
	    mov dx, "ds"
	    call PrintReg
	
	    mov bx, STRING5 + LEN_OF_STR * 9
	    mov ax, es
	    mov dx, "es"
	    call PrintReg
	
	    call PrintFrame
	
	    pop dx
	    pop bx
	    pop ax
	      
	    ret
	    endp

;----------------------------------------------------------------------
;                         PrintReg
;print reg
;Enter: ax - this reg
;       dh, dl - name of reg (first letter in ah)
;       bx - start pos
;Exit:  
;Destr: 
;----------------------------------------------------------------------
  PrintReg   proc 

	    mov es: byte ptr [bx], dh
	    mov es: byte ptr [bx + 1], 0dh
	    add bx, 2
	    mov es: byte ptr [bx], dl
	    mov es: byte ptr [bx + 1], 0dh
	    add bx, 10
	
	    mov SAVED_REG, ax
	
	    shl al, 4               ;first on the right
	    shr al, 4
	    call PrintHalfOfReg
	
	    sub bx, 2
	    mov ax, SAVED_REG
	            
	    shr al, 4               ;second on the right
	    call PrintHalfOfReg
	
	    sub bx, 2
	    mov ax, SAVED_REG
	
	    shl ah, 4               ;second on the left
	    shr ah, 4
	    mov al, ah
	    call PrintHalfOfReg
	
	    sub bx, 2
	    mov ax, SAVED_REG
	
	    shr ah, 4               ;first on the left
	    mov al, ah
	    call PrintHalfOfReg
	
	    mov ax, SAVED_REG
	      
	    ret
	    endp


;----------------------------------------------------------------------
;                         PrintHalfOfReg
;print half/2 of reg (funny func)
;Enter: al (after shift)
;Exit:  
;Destr: 
;----------------------------------------------------------------------
  PrintHalfOfReg   proc 

	    cmp al, 9           ;comparison with 9
	    ja LETTER1          ;if it's not num jump
		add al, 30h         ;ascii for num
	    jmp PRINTBYTE1
	    LETTER1:
	    sub al, 10d         ;ascii for letter
	    add al, 41h
	    PRINTBYTE1:         ;even a baby will understand it
	    mov es: byte ptr [bx], al
	    mov es: byte ptr [bx + 1], 0dh
	      
	    ret
	    endp


    

;----------------------------------------------------------------------
;                              PrintLineX
;	print hor line cx times, in bx start pos on the screen
;Entry: bx - (first) symb pos
;Exit: ???
;Destr: cx becomes 0, bx becomes bx + 2 * cx(start)
;----------------------------------------------------------------------
  PrintLineX	proc

	    mov cx, XLEN
	  	Printline:
		mov es: byte ptr [bx], XLINE
		mov es: byte ptr [bx + 1], COLOR
		add bx, 2
		loop PrintLine
		ret
		endp


;----------------------------------------------------------------------
;                                PrintLineY
;	print vert line cx times, in bx start pos on the screen
;Entry: bx - (first) symb pos
;Exit: ???
;Destr: cx becomes 0, bx becomes bx + 2 * cx(start)
;----------------------------------------------------------------------
  PrintLineY	proc

	    mov cx, YLEN
	  	Printlinee:
		mov es: byte ptr [bx], YLINE
		mov es: byte ptr [bx + 1], COLOR
		add bx, 80*2
		loop PrintLinee
		ret
		endp


;----------------------------------------------------------------------
;                              PrintFrame
;print frame
;Entry: bx - (first) symb pos
;Exit: ???
;Destr: cx becomes 0, bx becomes bx + 2 * cx(start)
;----------------------------------------------------------------------
  PrintFrame	proc
      
	    mov bx, LUP
	    call PrintLineX
	    mov bx, LDOWN
	    call PrintLineX
	    mov bx, LUP
	    call PrintLineY
	    mov bx, LUP + XLEN * 2
	    call PrintLineY

		ret
		endp

.data
		SAVED_REG dw 0
		LUP = (3 * 80d + 42d) * 2
		LDOWN = (21 * 80d + 42d) * 2
		YLEN = 18
		XLEN = 16
		RUP = LUP + XLEN * 2 
		RDOWN = LDOWN + XLEN * 2 
		COLOR = 0dh
		XLINE = 0c4h
		YLINE = 0b3h
		LUPAngle = 0dah
		RUPAngle = 0bfh
		LDOWNAngle = 0c0h
		RDOWNAngle = 0d9h
		int08flag db 0
		STRING5 = (5 * 80d + 50d) * 2
		LEN_OF_STR = 160
		;regs db di, bp, sp, ds, es такое досбокс не одобряет, это печально, придется оставлять копипастт
		;name_of_reg dw "di", "bp", "sp", "ds", "es"

EndOfProgram:
end    start


