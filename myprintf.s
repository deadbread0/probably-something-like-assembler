;:====================================================
;: myprintf.s                   (c)Justin Bieber, 2026
;:====================================================

; nasm -f elf64 -l myprintf.lst myprintf.s  ;  ld -s -o myprintf myprintf.o

section .bss
SAVED_REG: resb 4
Buffer: resb 32                ; Резервирует 32 байта под именем Buffer
NewBuf: resb 32

section .text

global _start                  ; predefined entry point name for ld

_start:     
            ;mov rax, 0x00      ; читать данные
            ;mov rdi, 0         ; stdin
            ;mov rsi, Buffer
            ;mov rdx, BufSize   ; strlen (Msg)
            ;syscall

            ;cmp rax, BufSize    ;если буфер не переполнен, то надо удалить \n
            ;jge Next
            ;mov byte [Buffer + rax - 1], ''
            ;Next:

            mov rax, 456
            mov rbx, "%b"
            call myprintf  

            mov rax, 0x3C      ; exit64 (rdi)
            xor rdi, rdi
            syscall

;-----------------------------------------------------
; myprintf
; enter:    rbx - format
;           rax - number (str or symb in Buffer)
; exit:
;-----------------------------------------------------
myprintf:
            cmp rbx, "%s"      ;тут потом по умному будет
            je SpecNoX
            cmp rbx, "%c"
            je SpecC
            cmp rbx, "%x"
            jne SpecNoX

            call remake_nums16
            
            SpecNoX:
            cmp rbx, "%b"
            jne SpecNoB
            call remake_nums2

            SpecNoB:

            mov rax, 0x01      ; писать данные
            mov rdi, 1         ; stdout
            mov rsi, Buffer
            mov rdx, BufSize   ; strlen (Msg)
            syscall
            jmp EndOfFunc

            SpecC:
            mov rax, 0x01      ; писать данные
            mov rdi, 1         ; stdout
            mov rsi, Buffer
            mov rdx, BufSize
            syscall

            EndOfFunc:

            ret

;-----------------------------------------------------
; remake_byte16
; enter: rcx - amount of symbols (this func will make numbers from letters)
;        al - num
; exit:  dx - amount of symb in NewBuf
;-----------------------------------------------------
remake_byte16:       
            cmp al, 9

            ja Letter
            add al, 30h        ;ascii for num
            jmp NotLetter

            Letter:
            sub al, 10d        ;ascii for letter
            add al, 61h

            NotLetter:
            cmp al,'0'         ;не записываем ведущие нули в буфер
            jne Not0InAl
            cmp dx, 0
            je EndOfRemake16

            Not0InAl:
            mov [Buffer + rdx], al
            inc dx
            EndOfRemake16:

            ret

;----------------------------------------------------------------------
; remake_nums16
; enter: al - num
; exit:  dx - amount of symb in Buffer
;----------------------------------------------------------------------
remake_nums16: 

            xor dx, dx
            mov [SAVED_REG], rax 

            shr rax, 16
            shr ah, 4               ;first on the left
            mov al, ah
            call remake_byte16

            mov rax, [SAVED_REG]

            shr rax, 16
            shl ah, 4               ;second on the left
            shr ah, 4
            mov al, ah
            call remake_byte16

            mov rax, [SAVED_REG]

            shr rax, 16
            shr al, 4               ;second on the right
            call remake_byte16

            mov rax, [SAVED_REG]

            shr rax, 16
            shl al, 4               ;first on the right (..!.)
            shr al, 4
            call remake_byte16

            mov rax, [SAVED_REG]

            shr ah, 4               ;first on the left
            mov al, ah
            call remake_byte16

            mov rax, [SAVED_REG]

            shl ah, 4               ;second on the left
            shr ah, 4
            mov al, ah
            call remake_byte16

            mov rax, [SAVED_REG]

            shr al, 4               ;second on the right
            call remake_byte16

            mov rax, [SAVED_REG]

            shl al, 4               ;first on the right
            shr al, 4
            call remake_byte16

            mov rax, [SAVED_REG]
            ;dec dx
            ;mov [BufSize], dx

            ret


;----------------------------------------------------------------------
; remake_nums2 - make binary nums
; enter: rax - num
; exit:  dx - amount of symb in Buffer
;----------------------------------------------------------------------
remake_nums2: 

            xor dx, dx
            mov [SAVED_REG], rax 

            mov cx, 32              ;amount of bytes in num
            MakeBinary:             
            shr rax, cl             ;сдвиг на (32 - номер итерации)
            jc Mov1                 ;типа если мы сдвинули 1, то cf = 1 и будет прыжок
            cmp dx, 0               ;не записываем ведущие нули в буфер
            je EndOfRemake2        
            mov byte [Buffer + rdx], '0'
            inc dx                  ;увеличивается счетчик символов в буфере
            jmp EndOfRemake2

            Mov1:
            mov byte [Buffer + rdx], '1'
            inc dx

            EndOfRemake2:
            mov rax, [SAVED_REG]
            loop MakeBinary

            ret


            
section     .data
BufSize: db 32
Shift: dd 0