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

        cmp flgbckgrnd, 1           ;создаю фон рамки
        je SkipBackgrnd
        call FrmBackground
        mov flgbckgrnd, 1
        SkipBackgrnd:

        cmp int08flag, 1
        je KillFrame
        mov int08flag, 1            ;выставлен флаг для прерывания таймера
        jmp DontKillFrame

        KillFrame:
        mov int08flag, 0

        DontKillFrame:

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
        lea di, COLOR               
        xor ch, ch
        mov cx, 0dh
        mov byte ptr [di], cl

        inc bp                      ;по приколу, чтобы не все регистры были неподвижными в рамке
        push ss es ds sp bp di si dx cx bx ax
        call MainFunc
        pop ax bx cx dx si di bp sp ds es ss

        jmp AfterNoFlag

        NoFlag:                     ;теперь рамка может исчезать (ну просто она становится прозрачной)
        lea di, COLOR
        xor ch, ch
        mov cx, 0h
        mov byte ptr [di], cl

        push ss es ds sp bp di si dx cx bx ax
        call MainFunc
        pop ax bx cx dx si di bp sp ds es ss

        AfterNoFlag:

        mov al, 20h                 ;сообщаем контроллеру прерываний, что обработка сигнала закончена
        out 20h, al

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

    push bp
    mov bp, sp                        ;будем через последний элемент стека адресоваться к другим элементам в нем

    mov ax, VIDEOSEG
    mov es, ax

    mov cx, NUM_OF_REG                ;столько раз будем печатать регистры
    lea si, NAMES_OF_REG  
    add bp, 2 * 2                     ;пропускаем в стеке адрес возврата и bp 
    ;mov bx, STRING5

    PrintAllRegs:

    mov SAVED_REG2, cx

    mov ax, LEN_OF_STR                ;bx = 5 строка + порядковый номер регистра (с нуля) * длина строки
    mov bx, NUM_OF_REG
    sub bx, cx
    mul bx
    mov bx, ax
    add bx, STRING5

    ;mov bx, STRING5
    ;mov ax, LEN_OF_STR
    ;mul cx

    mov ax, word ptr [bp]
    add bp, 2                         ;двигаемся по стеку

    mov dh, byte ptr cs:[si]          ;помещаем сюда имя регистра (в dh первую букву)
    mov dl, byte ptr cs:[si + 1]
    add si, 2                         ;смещение по массиву названий регистров
    call PrintReg
    ;add bx, LEN_OF_STR
    mov cx, SAVED_REG2
    loop PrintAllRegs

    call PrintFrame

    pop bp                            ;почистим после своих прикольчиков стек
      
    ret
    endp

;----------------------------------------------------------------------
;                         PrintReg
;print reg
;Enter: ax - this reg
;       dh, dl - name of reg (first letter in dh)
;       bx - start pos
;Exit:  
;Destr: cx, di
;----------------------------------------------------------------------
  PrintReg   proc 

    xor di, di
    xor cx, cx
    lea di, COLOR
    mov cl, byte ptr [di]

    mov es: byte ptr [bx], dh
    mov es: byte ptr [bx + 1], cl
    add bx, 2
    mov es: byte ptr [bx], dl
    mov es: byte ptr [bx + 1], cl
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
;Destr: dx, di
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

    xor di, di
    xor dx, dx
    lea di, COLOR
    mov dl, byte ptr [di]

    mov es: byte ptr [bx], al
    mov es: byte ptr [bx + 1], dl
      
    ret
    endp


    

;----------------------------------------------------------------------
;                              PrintLineX
;	print hor line cx times, in bx start pos on the screen
;Entry: bx - (first) symb pos
;Exit: ???
;Destr: cx becomes 0, bx becomes bx + 2 * cx(start), dx
;----------------------------------------------------------------------
  PrintLineX	proc

    xor di, di
    xor dx, dx
    lea di, COLOR
    mov dl, byte ptr [di]

    mov cx, XLEN
  	Printline:
		mov es: byte ptr [bx], XLINE
		mov es: byte ptr [bx + 1], dl
		add bx, 2
		loop PrintLine
		ret
		endp


;----------------------------------------------------------------------
;                                PrintLineY
;	print vert line cx times, in bx start pos on the screen
;Entry: bx - (first) symb pos
;Exit: ???
;Destr: cx becomes 0, bx becomes bx + 2 * cx(start), dx
;----------------------------------------------------------------------
  PrintLineY	proc

    xor di, di
    xor dx, dx
    lea di, COLOR
    mov dl, byte ptr [di]

    mov cx, YLEN
  	Printlinee:
		mov es: byte ptr [bx], YLINE
		mov es: byte ptr [bx + 1], dl
		add bx, 80 * 2
		loop PrintLinee
		ret
		endp


;----------------------------------------------------------------------
;                              PrintFrame
;print frame
;Entry: bx - (first) symb pos
;Exit: ???
;Destr: 
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

    call PrintAngles

		ret
		endp

;----------------------------------------------------------------------
;                              FrmBackground
;print background of a frame
;Entry: bx
;Exit: 
;Destr: 
;----------------------------------------------------------------------
  FrmBackground	proc

    mov cx, YLEN            
    mov bx, LUP  
    add bx, LEN_OF_STR          
    mov SAVED_REG1, cx     

    FirstLoop:
    mov cx, XLEN  
    ;add cx, LEN_OF_STR          

    SecondLoop:
    mov es:byte ptr [bx], 20h   
    mov es:byte ptr [bx + 1], 0h 
    add bx, 2                   
    loop SecondLoop             

    sub bx, XLEN * 2
    add bx, LEN_OF_STR       

    mov cx, SAVED_REG1        
    dec cx                    
    mov SAVED_REG1, cx       
    loop FirstLoop           
   
    ret
endp


;----------------------------------------------------------------------
;                              PrintAngles
;	print angles
;Entry: bx - position
;       al - symbol from array
;Exit: ???
;Destr: dl, di
;----------------------------------------------------------------------
  PrintAngles	proc

    mov cx, NUM_OF_ANGLS          ;amount of angles
    lea di, SMB_OF_ANGLS
    lea si, COLOR
    mov dl, byte ptr [si]
    lea si, POS_OF_ANGLS

    PrintOneOfThem:
    xor bx, bx
    xor ax, ax
    mov bx, word ptr cs:[si]
    add si, 2
    mov al, byte ptr cs:[di]
    inc di

		mov es: byte ptr [bx], al
		mov es: byte ptr [bx + 1], dl

    loop PrintOneOfThem
		ret
		endp

.data
SAVED_REG dw 0
SAVED_REG1 dw 0
SAVED_REG2 dw 0
LUP = (3 * 80d + 42d) * 2
LDOWN = (21 * 80d + 42d) * 2
YLEN = 18
XLEN = 16
RUP = LUP + XLEN * 2 
RDOWN = LDOWN + XLEN * 2 
COLOR db 0dh
XLINE = 0c4h
YLINE = 0b3h
LUPAngle = 0dah
RUPAngle = 0bfh
LDOWNAngle = 0c0h
RDOWNAngle = 0d9h
NUM_OF_ANGLS = 4
SMB_OF_ANGLS db LUPAngle, LDOWNAngle, RUPAngle, RDOWNAngle
POS_OF_ANGLS dw LUP, LDOWN, RUP, RDOWN
int08flag db 0
flgbckgrnd db 0
STRING5 = (5 * 80d + 50d) * 2
LEN_OF_STR = 160
NAMES_OF_REG db "ax", "bx", "cx", "dx", "si", "di", "bp", "sp", "ds", "es", "ss", "ip", "cs"
NUM_OF_REG = 13

EndOfProgram:
end    start

