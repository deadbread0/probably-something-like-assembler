.model tiny
.code
org 100h
VIDEOSEG equ 0b800h
;дисклеймер, тут неподвижная, глупенькая рамка, выводятся 2 регистра и немного магических констант для вывода в определенную строку на экране, не пугайтесь, все поправлю
;при таком расположении вызова 8 прерывания сразу выскакивает рамочка и один выводимый регистр увеличивается прямо на глазах, но по плану пользователь сначала должен нажать заветную клавишу с цифрой 2 для вывода рамки и только потом она должна обновлять регистры
start:

      ;mov ax, 3509h      
       ;     int 21h       
        ;    mov word ptr offset old09Ofs, bx
         ;   mov bx, es
          ;  mov word ptr offset old09Seg, bx

      push 0
      pop es
      cli
      mov bx, 09h * 4
      mov es: [bx], offset New09 ;прерывание клавиатуры
      mov ax, cs
      mov es: [bx + 2], ax
      mov bx, 08h * 4
      mov es: [bx], offset New08 ;прерывание таймера, чтоб в реалтайм табличка обновлялась, хз куда его впихнуть, чтобы оно работало только после вызова таблички (прерывание в прерывании не работает как так то) 
      mov ax, cs
      mov es: [bx + 2], ax
      sti
      mov ax, 3100h
      mov dx, offset EndOfProgram
      shr dx, 4
      inc dx
      

       ;mov ax, 4c00h
       int 21h


New09   proc
        push ax 
        push bx 
        push es
        push 0b800h
        pop es
        mov bx, (5 * 80d + 40d) * 2
        mov ah, 4ch
        in al, 60h 
        mov es: [bx], ax

        mov cl, 03h ;проверка на то, что считан скан-код клавиши с цифрой 2
        cmp al, cl
        jne gg
        mov es: byte ptr [bx + 2], 03h
        mov es: byte ptr [bx + 3], 5dh
        call MainFunc2

        ;hlt удивительно, но если так сделать, все зависнет, невероятно
        gg:
        mov es: byte ptr [bx + 4], 02h
        mov es: byte ptr [bx + 5], 0dh


        in al, 61h
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al
        mov al, 20h
        out 20h, al
        pop es 
        pop bx 
        pop ax

        ;db 0eah
        ;old09Ofs dw 0
        ;old09Seg dw 0
        iret
        endp

New08   proc
        push ax 
        push bx 
        push es
        push 0b800h
        pop es
        mov bx, (5 * 80d + 40d) * 2
        mov ah, 4ch
        mov al, 03h ;;;;и это тоже по приколу, на результат не влияет
        mov es: [bx], ax

        mov es: byte ptr [bx + 2], 03h ;это тут по рофлу, для проверки
        mov es: byte ptr [bx + 3], 5dh
        call MainFunc2
        ;hlt удивительно, но если так сделать, все зависнет, невероятно
        ;gg:
        mov es: byte ptr [bx + 4], 02h
        mov es: byte ptr [bx + 5], 0dh


        in al, 71h
        or al, 80h
        out 71h, al
        and al, not 80h
        out 71h, al
        mov al, 20h
        out 20h, al
        pop es 
        pop bx 
        pop ax

        ;db 0eah
        ;old09Ofs dw 0
        ;old09Seg dw 0
        iret
        endp

;----------------------------------------------------------------------
;                         MainFunc
;to think
;Enter:
;Exit:  
;Destr: 
;----------------------------------------------------------------------
  MainFunc   proc 

    mov ax, VIDEOSEG
    mov es, ax

    mov bx, (5 * 80d + 50d) * 2
    mov dx, "ax"
    call PrintReg        ;loop
    mov bx, (6 * 80d + 50d) * 2
    mov ax, si
    inc si
    mov dx, "si"
    call PrintReg 
    call PrintFrame

      push 0 ;попытки сделать прерывание в прерывании (провалено)
      pop es
      cli
      mov bx, 09h * 4
      mov es: [bx], offset New08
      mov ax, cs
      mov es: [bx + 2], ax
      sti
      mov ax, 3100h 
      mov dx, offset EndOfProgram
      shr dx, 4
      inc dx
      ;int 21h вылетает блин ну ваще
      
    ret
    endp


;----------------------------------------------------------------------
;                         MainFunc2
;to think
;Enter:
;Exit:  
;Destr: 
;----------------------------------------------------------------------
  MainFunc2   proc 

    mov ax, VIDEOSEG
    mov es, ax

    mov bx, (5 * 80d + 50d) * 2
    mov dx, "ax"
    call PrintReg        ;loop
    mov bx, (6 * 80d + 50d) * 2
    mov ax, si
    inc si
    mov dx, "si"
    call PrintReg 
    call PrintFrame
      
    ret
    endp

;----------------------------------------------------------------------
;                         PrintReg
;print reg
;Enter: ax - this reg
;       dh, dl - name of reg (first letter in ah)
;Exit:  
;Destr: 
;----------------------------------------------------------------------
  PrintReg   proc 

    ;mov bx, (7 * 80d + 30d) * 2
    mov es: byte ptr [bx], dh
    mov es: byte ptr [bx + 1], 0dh
    add bx, 2
    mov es: byte ptr [bx], dl
    mov es: byte ptr [bx + 1], 0dh
    add bx, 10

    mov saved_reg, ax

    shl al, 4               ;first on the right
    shr al, 4
    call PrintHalfOfReg

    sub bx, 2
    mov ax, saved_reg
            
    shr al, 4               ;second on the right
    call PrintHalfOfReg

    sub bx, 2
    mov ax, saved_reg

    shl ah, 4               ;second on the left
    shr ah, 4
    mov al, ah
    call PrintHalfOfReg

    sub bx, 2
    mov ax, saved_reg

    shr ah, 4               ;first on the left
    mov al, ah
    call PrintHalfOfReg

    mov ax, saved_reg
      
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

    mov cx, xlen
  	Printline:
		mov es: byte ptr [bx], xline
		mov es: byte ptr [bx + 1], color
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
    mov cx, ylen
  	Printlinee:
		mov es: byte ptr [bx], yline
		mov es: byte ptr [bx + 1], color
		add bx, 80*2
		loop PrintLinee
		ret
		endp

;----------------------------------------------------------------------
;                              PrintAngle
;	print angle
;Entry: bx - position
;       al - symbol
;Exit: ???
;Destr: 
;----------------------------------------------------------------------
  PrintAngle	proc
		            mov es: byte ptr [bx], al
		            mov es: byte ptr [bx + 1], color
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
      
       mov bx, lup
       call PrintLineX
       mov bx, ldown
       call PrintLineX
       mov bx, lup
       call PrintLineY
       mov bx, lup + xlen * 2
       call PrintLineY

      lea di, pos_symb_angles
      mov cx, 4
      PrintAngles:
        mov bx, word ptr [di]
        add di, 2
        mov ax, word ptr [di]
        add di, 2
        call PrintAngle
      loop PrintAngles
		ret
		endp

.data
saved_reg dw 0
lup = (3 * 80d + 42d) * 2
ldown = (12 * 80d + 42d) * 2
ylen = 9
xlen = 16
rup = lup + xlen * 2 
rdown = ldown + xlen * 2 
color = 0dh
xline = 0c4h
yline = 0b3h
LUPAngle = 0dah
RUPAngle = 0bfh
LDOWNAngle = 0c0h
RDOWNAngle = 0d9h
pos_symb_angles dw lup, LUPAngle, ldown, LDOWNAngle, rup, RUPAngle, rdown, RDOWNAngle
lett1 db 03h
lett2 db 10h 
flag1 db 0
flag2 db 0
int08flag db 0

EndOfProgram:
end    start

