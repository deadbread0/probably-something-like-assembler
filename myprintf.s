;:====================================================
;: myprintf.s                   (c)Justin Bieber, 2026
;:====================================================
global fakeprintf                       ; predefined entry point name for ld
; nasm -f elf64 -l myprintf.lst myprintf.s  ;  ld -s -o myprintf.exe myprintf.o

section .bss
SAVED_REG: resb 4
Buffer: resb 32                     ; Резервирует 32 байта под именем Buffer

section     .data
DEFAULT_BUFSIZE: dq 32
AMOUNT_OF_CASES: dq 23              ;количество вариантов в CHOOSELABEL
BufSize: dq 32                      ;dq, а не db, тк иначе старшие биты засоряются и ошибки вылезают
Shift: dd 0
ELSIZE: dq 8                        ;это размер данных в стеке
MAXSPECS: dq 10                     ;кол-во итераций в myprintf и getparams, может не отражать максимальное число 
                                    ;спецификаторов, тк еще ограничения по памяти для двух массивов есть

    ; Аргументы идут в rdi, rsi, rdx, rcx, r8, r9

section .text

fakeprintf:     
            push r9                 ;параметры (если их больше, то они перед этими в стек запушены)
            push r8 
            push rcx 
            push rdx 
            push rsi 

            call myprintf  

            pop rsi 
            pop rdx 
            pop rcx 
            pop r8 
            pop r9

            ret                      ;кстати без этого мусор печатается после того, что надо


;-----------------------------------------------------
; myprintf
; enter:    SPECS - aaray of formats
;           WHATPRINTF - array of data, which we need to print
;           cx - amount of elements
; exit:
;-----------------------------------------------------
myprintf:                           ;в этой функции в цикле выделяется спецификатор и данные для печати из массивов      
                                    ;в каждой итерации вызывается печать одного спецификатора
            push rbp
            mov rbp, rsp             ;будем через последний элемент стека адресоваться к другим элементам в нем 
            add rbp, 2 * 8           ;пропускаем адрес возврата и rbp в стеке
                                     ;через rbp теперь обращаемся в данным для печати

            xor rdx, rdx  
            xor rax, rax
            xor rsi, rsi
            xor rbx, rbx
            mov rcx, [MAXSPECS]

            PrintEl:
            mov bl, byte [rdi]      ;принимаем символ из строки спецификаторов

            cmp bl, ' '
            je PrintSpace

            inc rdi

            mov bh, byte [rdi] 

            mov rax, [rbp]          ;данные для печати
            mov rsi, [ELSIZE]
            add rbp, rsi            ;переход к следующему элементу в стеке

            call changes_for_prcnt  ;да, обработка "%%" отдельная, это кажется удобным, но мб это только кажется
            call myprintf1

            jmp TheEnd

            PrintSpace:
            mov rax, ' '
            mov rbx, "%c"
            call myprintf1

            TheEnd:
            inc rdi
            loop PrintEl

            pop rbp

            ret


;-----------------------------------------------------
; myprintf1
; enter:    rbx - format
;           rax - number (str or symb in Buffer)
; exit:
;-----------------------------------------------------
myprintf1:                          ;печатает 1 спецификатор
            push rcx
            push rdi
            push rbx
            push rbp
            mov rbp, rsp            ;будем через последний элемент стека адресоваться к другим элементам в нем
            mov rbx, [rbp + 8]

            shr bx, 8               ;бесполезный символ процента надо вытолкнуть из регистра (константы не будет, я не знаю, как это можно назвать)
            sub bx, 'b'             ;а тут для таблицы переходов делаем из спецификатора индекс для таблички

            cmp rbx, [AMOUNT_OF_CASES]
            ja DEFT
            jmp [CHOOSELABEL + 8 * rbx]

            X:
            call remake_nums16
            jmp PRINTBUF

            B:
            call remake_nums2
            jmp PRINTBUF

            O:
            call remake_nums8
            jmp PRINTBUF

            D:
            call remake_nums10
            jmp PRINTBUF

            C:
            call changes_for_1char
            jmp PRINTBUF

            S:                      ;просто строку не надо готовить никак
            call changes_for_s
            jmp PRINTBUF

            PRINTBUF:

            mov rax, 0x01           ; писать данные
            mov rdi, 1              ; stdout
            mov rsi, Buffer
            mov rdx, [BufSize]
            syscall

            DEFT:
            mov rcx, [DEFAULT_BUFSIZE]
            mov [BufSize], rcx

            pop rbp
            pop rbx
            pop rdi
            pop rcx

            ret


;-----------------------------------------------------
; changes_for_1char
; enter:    rax - number (symb)
; exit:
;-----------------------------------------------------
changes_for_1char:                          
            mov dword [BufSize], 1
            mov [Buffer], rax

            ret

;-----------------------------------------------------
; changes_for_prcnt
; enter:    rax - number (symb)
; exit:
;-----------------------------------------------------
changes_for_prcnt:   

            cmp bh, '%'
            jne Next
                                  
            mov rbx, "%c"
            mov rax, '%'

            Next:
            ret

;-----------------------------------------------------
; changes_for_s
; enter:    rax - str
; exit:
;-----------------------------------------------------
changes_for_s:   

            push rdi
            push rbx
            xor rdi, rdi

            copy_loop:              ;посимвольно переписывает, мда, осуждаю
            mov bl, [rax]
            mov [Buffer + rdi], bl
            inc rax
            inc rdi
            cmp bl, 0
            jne copy_loop

            pop rbx
            pop rdi

            ret

;-----------------------------------------------------
; remake_byte16
; enter: rcx - amount of symbols (this func will make letters from numbers)
;        al - num
; exit:  dx - amount of symb in NewBuf
;-----------------------------------------------------
remake_byte16:       
            cmp al, 9

            ja Letter
            add al, 30h             ;ascii for num
            jmp NotLetter

            Letter:
            sub al, 10d             ;ascii for letter
            add al, 61h

            NotLetter:
            cmp al,'0'              ;не записываем ведущие нули в буфер
            jne Not0InAl
            cmp rdx, 0
            je EndOfRemake16

            Not0InAl:               ;запись в буфер, если это не ведущий 0
            mov [Buffer + rdx], al
            inc rdx
            EndOfRemake16:

            ret

;----------------------------------------------------------------------
; remake_nums16
; enter: al - num
; exit:  dx - amount of symb in Buffer
;----------------------------------------------------------------------
remake_nums16:                      

            push cx
            xor rdx, rdx
            mov cl, 16                  ;это сдвиг, принимаемый на вход функции
            call remake_half_num16
            mov cl, 0                   ;это тоже сдвиг кстати
            call remake_half_num16
            mov [BufSize], rdx          ;оп оп обновление размера
            pop cx

            ret


;----------------------------------------------------------------------
; remake_half_num16
; enter: al - num
;        cl - shift
; exit:  dx - amount of symb in Buffer
;----------------------------------------------------------------------
remake_half_num16:                      

            push cx
            mov [SAVED_REG], rax 

            shr rax, cl
            shr ah, 4                   ;first on the left
            mov al, ah
            call remake_byte16

            mov rax, [SAVED_REG]

            shr rax, cl
            shl ah, 4                   ;second on the left
            shr ah, 4
            mov al, ah
            call remake_byte16

            mov rax, [SAVED_REG]

            shr rax, cl
            shr al, 4                   ;second on the right
            call remake_byte16

            mov rax, [SAVED_REG]

            shr rax, cl
            shl al, 4                   ;first on the right 
            shr al, 4
            call remake_byte16

            mov rax, [SAVED_REG]
            pop cx

            ret

;----------------------------------------------------------------------
; remake_nums2 - make binary nums
; enter: rax - num
; exit:  dx - amount of symb in Buffer
;----------------------------------------------------------------------
remake_nums2: 
            push cx
            xor rdx, rdx
            mov [SAVED_REG], rax 

            mov cx, [DEFAULT_BUFSIZE]              
            MakeBinary:             
            shr rax, cl                  ;сдвиг на (32 - номер итерации)
            jc Mov1                      ;типа если мы сдвинули 1, то cf = 1 и будет прыжок
            cmp rdx, 0                   ;не записываем ведущие нули в буфер
            je EndOfRemake2        
            mov byte [Buffer + rdx], '0'
            inc rdx                      ;увеличивается счетчик символов в буфере
            jmp EndOfRemake2

            Mov1:
            mov byte [Buffer + rdx], '1'
            inc rdx

            EndOfRemake2:
            mov rax, [SAVED_REG]
            loop MakeBinary

            mov [BufSize], rdx 
            pop cx

            ret

;----------------------------------------------------------------------
; remake_nums8 - make octal nums
; enter: rax - num
; exit:  dx - amount of symb in Buffer
;----------------------------------------------------------------------
remake_nums8: 
            push cx
            xor rdx, rdx
            mov [SAVED_REG], rax 

            mov cx, [DEFAULT_BUFSIZE]       ;32
            inc cx                          ;33
            mov rsi, rcx
            Make8:                          ;в каждой итерации цикла обрабатываются 3 бита (в cl)
            xor rdi, rdi
            shr rax, cl            
            jnc End22

            cmp rcx, rsi                    ;отдельная обработка знака (сравнение с 33)
            je End22
            add rdi, 4
            End22:
            mov rax, [SAVED_REG]
            dec cl

            shr rax, cl            
            jnc End21
            add rdi, 2
            End21:
            mov rax, [SAVED_REG]
            dec cl

            shr rax, cl           
            jnc End20
            add rdi, 1
            End20:

            cmp di, 0
            jne MovInBuf
            cmp rdx, 0                   ;не записываем ведущие нули в буфер
            je EndOfRemake8 
            MovInBuf:       
            add rdi, 30h                 ;цифра -> буква
            mov [Buffer + rdx], rdi
            inc rdx                      ;увеличивается счетчик символов в буфере

            EndOfRemake8:
            mov rax, [SAVED_REG]
            loop Make8
            mov [BufSize], rdx           ;новый размер

            pop cx

            ret


;----------------------------------------------------------------------
; remake_nums10 - make decimal nums
; enter: rax - num
; exit:  dx - amount of symb in Buffer
;----------------------------------------------------------------------
remake_nums10: 

            push rbx
            xor rdx, rdx
            xor rdi, rdi
            mov [SAVED_REG], rax 
            cqo                         ;там при делении надо чтоб размеры делителя и частного определенные были,
                                        ;так вот это для расширения rax

            mov rcx, [DEFAULT_BUFSIZE]  ;чтобы весь неиспользуемый буфер заполнился нулями
            MakeDigit:
            mov rbx, 10                 ;на это делить надо
            div rbx                     ;остаток от деления в rdx

            add rdx, 30h                ;цифра -> буква
            push rdx                    ;кладется на стек
            ;mov [Buffer + rdi], rdx     ;по неизвестным причинам если я пытаюсь вывести в норм порядке, выводится 0, восхитительно
            
            inc rdi
            cqo

            cmp rax, 0
            je NumIsOver                ;если число закончилось, заканчиваем вынос цифр в стек

            loop MakeDigit

            NumIsOver:
            mov rcx, rdi                ;в rdi кол-во цифр из прошлого цикла
            mov [BufSize], rdi
            xor rdi, rdi
            FillBuf:
            pop rdx
            mov byte [Buffer + rdi], dl
            inc rdi
            loop FillBuf

            pop rbx

            ret



section .rodata align=8

CHOOSELABEL:                            ;понимаю, выглядит непрезентабельно как-то, но либо так, либо выбор формата печати будет не одним прыжком
    dq B           ; Вариант %b         ;а еще ассемблерный листинг switch показал +- то же самое, такие дела
    dq C           ; Вариант %c
    dq D           ; Вариант %d
    times ('O' - 'D' - 1) dq DEFT
    dq O           ; Вариант %o
    times ('S' - 'O' - 1) dq DEFT
    dq S           ; Вариант %s
    times ('X' - 'S' - 1) dq DEFT
    dq X           ; Вариант %x