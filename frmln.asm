.model	tiny
  .code
  ORG 	100h
  LUPAngle = 0dah
  RUPAngle = 0bfh
  LDOWNAngle = 0c0h
  RDOWNAngle = 0d9h
  xlen equ 20
  ylen equ 5
  y1 equ 80 * 2 * 11d
  y2 equ 80 * 2 * 15d
  color = 3dh
  xline = 0c4h
  yline = 0b3h
  ascii_a = 31h
  
  VIDEOSEG equ 0b800h
  
start:	

  mov cl, ds: byte ptr [80h]
  dec cl

  call FindCenterOfString
  call PrintString

  mov ax, VIDEOSEG
  mov es, ax

  mov bx, y1
  call PrintLineX

  mov bx, y2
  call PrintLineX

  mov bx, y1
  add bx, 80d
  sub bx, si
  sub bx, si
  sub bx, xlen/2
  call PrintLineY

  mov bx, y1
  add bx, 80d
  add bx, xlen
  add bx, si
  add bx, si
  ;add bx, xlen
  call PrintLineY

  lea di, SymbForFrame            ;address in dx
  mov al, num_of_style
  mov dl, 6
  mul dl
  add di, ax                      ;in di addr(arr) + 6 * num_of_style
  add di, 2                       ;num of lupangle
  xor dx, dx

  mov bx, y1                      ;up
  call Print2Angles

  inc di
  mov bx, y2                      ;down
  call Print2Angles

  mov ax, 4c00h
  int 21h

;----------------------------------------------------------------------
;                         PrintString
;get and print string (unexpected)
;Entry: bx - start pos, cl - lenght of string
;Exit: 
;Destr: ax
;----------------------------------------------------------------------

  PrintString proc
	mov di, 82h      		        ;first symbol of str

  call SetStyleOfFrame

	mov ax, VIDEOSEG
	mov es, ax
		
	GetAndPrintLine:
		
	mov al, ds: byte ptr [di]	  ;input str
  mov ah, 5dh			            ;color
	add bx, 2			              ;step
  mov es: word ptr [bx], ax 	;place on display
	inc di				              ;increase counter of symbols
		
	loop GetAndPrintLine
  ret
  endp


;----------------------------------------------------------------------
;                         SetStyleOfFrame
;set style of frame (wow)
;Enter: ds - entered string
;       di - address of 1st symb in str
;       cl - counter of symb in str
;Exit:  muhaha
;Destr: all is ok
;----------------------------------------------------------------------
  SetStyleOfFrame   proc 

      mov al, ds: byte ptr [di]
      sub al, ascii_a
      cmp al, 04h                 ;amount of styles
      jbe norm_style              ;user entered existing style
      mov al, 0
      jmp standart_frame          ;user didn't entered existing style

      norm_style:
      inc di                      ;second symbol of str
      dec cl

      standart_frame:
      mov num_of_style, al
      
      ret
      endp


;----------------------------------------------------------------------
;                         FindCenterOfString
;find the center of a string (unbelievable)
;Entry: cl - length of string
;Exit: total in al
;Destr: ???
;----------------------------------------------------------------------
  FindCenterOfString proc

    mov al, cl			    ;there i divide the length by 2
    mov dl, 4
    div dl				      ;total in al
    xor dh, dh
    mov si, dx
    shl al, 1d			    ;mul2

    mov bx, 80*2*13d 		;practically the center (y)
      
    add bx, 80			    ;there i find the center (x)
    ;xor ah, ah			    ;delete residue from division
    mov ah, 0
    sub bx, ax			    ;clear ax
    mov ax, 0
    ret
    endp

;----------------------------------------------------------------------
;                              PrintLineX
;	print hor line cx times, in bx start pos on the screen
;Entry:
;	bx - line of symb pos
;Exit: ???
;Destr: cx becomes 0, bx becomes bx + 2 * cx(start)
;----------------------------------------------------------------------
  PrintLineX	proc

    add bx, 80d ;find pos for print
    sub bx, si
    sub bx, si
    sub bx, xlen/2

    mov cx, xlen
    add cx, si
    ;add cx, si
    xor ax, ax

    lea di, SymbForFrame            ;address in dx
    mov al, num_of_style
    mov dl, 6
    mul dl
    add di, ax                      ;in di addr(arr) + 6 * num_of_style
    xor dx, dx

    mov al, byte ptr [di]

  		Printline:
		mov es: byte ptr [bx], al
		mov es: byte ptr [bx + 1], color
		add bx, 2
		loop PrintLine
		ret
		endp


;----------------------------------------------------------------------
;                                PrintLineY
;	print vert line cx times, in bx start pos on the screen
;Entry: cx - amount of symb
;	bx - (first) symb pos
;Exit: ???
;Destr: cx becomes 0, bx becomes bx + 2 * cx(start)
;----------------------------------------------------------------------
  PrintLineY	proc
  
    mov cx, ylen

    lea di, SymbForFrame            ;address in dx
    mov al, num_of_style
    mov dl, 6
    mul dl
    add di, ax                      ;in di addr(arr) + 6 * num_of_style
    inc di                          ;num in array
    xor dx, dx

    mov al, byte ptr [di]

  		Printlinee:
		mov es: byte ptr [bx], al
		mov es: byte ptr [bx + 1], color
		add bx, 80*2
		loop PrintLinee
		ret
		endp

;----------------------------------------------------------------------
;                              PrintAngle
;	print angle
;Entry: bx - position
;       al - symbol from array
;Exit: ???
;Destr: 
;----------------------------------------------------------------------
  PrintAngle	proc
		            mov es: byte ptr [bx], al
		            mov es: byte ptr [bx + 1], color
		            ret
		            endp


;----------------------------------------------------------------------
;                                Print2Angles
;	try to kill copypaste
;Entry: bx - starting line
;Exit: ???
;Destr:
;----------------------------------------------------------------------
  Print2Angles	proc
  
    add bx, 80d
    sub bx, si
    sub bx, si
    sub bx, xlen/2

    mov al, byte ptr [di]
    call PrintAngle
    

    add bx, si                      ;rup
    add bx, 2
    add bx, 2 * xlen

    inc di
    mov al, byte ptr [di]
    call PrintAngle
		ret
		endp

  mov ax, 4c00h
  int 21h

.data
SymbForFrame db xline, yline, LUPAngle, RUPAngle, LDOWNAngle, RDOWNAngle, 0cdh, 0bah, 0c9h, 0bbh, 0c8h, 0bch, 0dch, 0deh, 0dch, 0dch, 0dch, 0dch, 0dfh, 0ddh, 0dfh, 0dfh, 0dfh, 0dfh 
num_of_style db 0
END	start