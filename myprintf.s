;:====================================================
;: myprintf.s                   (c)Justin Bieber, 2026
;:====================================================
global fakeprintf                       ; predefined entry point name for ld
; nasm -f elf64 -l myprintf.lst myprintf.s  ;  ld -s -o myprintf.exe myprintf.o

section .bss
SAVED_REG: resb 4
Buffer: resb 32                     ; Резервирует 32 байта под именем Buffer
NewBuf: resb 32
SPECS: resb 32                      ;тут спецификаторы хранятся
WHATPRINTF: resb 32                 ;столько памяти могут занимать данные для печати

section     .data
DEFAULT_BUFSIZE: dq 32
AMOUNT_OF_CASES: dq 23              ;количество вариантов в CHOOSELABEL
BufSize: dq 32                      ;dq, а не db, тк иначе старшие биты засоряются и ошибки вылезают
Shift: dd 0
ELSIZE: dq 8                        ;это надо, чтоб данные не склеивались
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

            call getparams

            pop r9 
            pop r9 
            pop r9 
            pop r9 
            pop r9

            xor rbx, rbx
            xor rdx, rdx
            xor rdi, rdi
            xor rsi, rsi

            call myprintf  

            ret                     ;кстати без этого мусор печатается после того, что надо

;-----------------------------------------------------
; getparams
; enter:    параметры в стеке
; exit:
;-----------------------------------------------------
getparams:
            push rbp
            mov rbp, rsp            ;будем через последний элемент стека адресоваться к другим элементам в нем

            mov rcx, [DEFAULT_BUFSIZE]
            xor rsi, rsi

            GetSymb:
            mov dl, byte [rdi + rsi]          ;прием спецификаторов на вход
            mov byte [SPECS + rsi], dl
            inc rsi
            loop GetSymb

            xor rcx, rcx
            xor rdi, rdi
            mov rcx, [MAXSPECS]     
            mov rdx, 2 * 8          ;скип адреса возврата и rbp в стеке

            Get1Arg:
            mov rsi, [rbp + rdx]
            mov [WHATPRINTF + rdi], rsi ;записываем в массив значения из стека
            add rdi, [ELSIZE]       ;расстояние до следующих данных в массиве
            add rdx, 8              ;следующий элемент в стеке
            loop Get1Arg

            pop rbp
            ret

;-----------------------------------------------------
; myprintf
; enter:    SPECS - aaray of formats
;           WHATPRINTF - array of data, which we need to print
;           cx - amount of elements
; exit:
;-----------------------------------------------------
myprintf:                           ;в этой функции в цикле выделяется спецификатор и данные для печати из массивов      
                                    ;в каждой итерации вызывается печать одного спецификатора
            xor rdx, rdx           
            xor rdi, rdi
            xor rbp, rbp
            xor rax, rax
            mov rcx, [MAXSPECS]

            PrintEl:
            mov bl, byte [SPECS + rdi] ;AAAA я не пон че тут происходит
            ;тут в bl должен записываться символ из массива спецификаторов, через отладчик я проверила, что вроде как все правильно записывается, но уже на второй итерации происходит какой-то бред:
            ;появляются непонятные нули, причем если просто записать "mov bl, byte [SPECS + 2]", то выведется тот символ, который реально нужен, но при rdi = 2 в bl записывается '0',
            ;вот короче что то стремное творится, я в отчаянии, годы поисков ошибки не привели к успеху

            cmp bl, ' '
            je PrintSpace

            inc rdi
            mov bh, byte [SPECS + rdi]

            push rbp
            mov rax, rbp
            mov rsi, [ELSIZE]
            mul rsi
            mov rbp, rax
            xor rax, rax
            mov rax, [WHATPRINTF + rbp]
            pop rbp
            inc rbp

            call changes_for_prcnt    ;да, обработка "%%" отдельная, это кажется удобным, но мб это только кажется
            call myprintf1
            jmp TheEnd

            PrintSpace:
            mov rax, ' '
            mov rbx, "%c"
            call myprintf1

            TheEnd:
            inc rdi
            call cleanbuf
            loop PrintEl

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
            pop rdi
            pop rcx

            ret

;-----------------------------------------------------
; cleanbuf
; enter:    rax - number (symb)
; exit:
;-----------------------------------------------------
cleanbuf:       
            push rcx                   
            mov rcx, [BufSize]
            DeleteSymb:
            mov byte [Buffer + rcx], ''
            loop DeleteSymb

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
            push rcx 
            mov [Buffer], rax
            pop rcx
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

            cmp rcx, rsi                     ;отдельная обработка знака (сравнение с 33)
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
            mov [Buffer + rdi], rdx     ;по неизвестным причинам если я пытаюсь вывести в норм порядке, выводится 0, восхитительно
            inc rdi
            cqo
            loop MakeDigit

            call reverse_buf

            ret

;----------------------------------------------------------------------
; reverse_buf
; enter: норм буфер
; exit:  перевернутый буфер
;----------------------------------------------------------------------
reverse_buf: 
            push cx
            mov rcx, [BufSize]
            mov rdx, 0

            ReverseBuf:
            dec rcx                     ;индексация с нуля, так надо
            mov rax, [Buffer + rcx] 
            inc rcx 
            mov [NewBuf + rdx], rax
            inc rdx
            loop ReverseBuf

            mov rcx, [BufSize]          ;чего не сделаешь для следующего цикла, все восстанавливаем
            mov rdx, 0
            mov rsi, 0
            xor rax, rax

            CopyBuf:
            mov al, byte [NewBuf + rsi]
            inc rsi                     ;индекс ньюбаф
            cmp rdx, 0
            jne MoveToBuf               ;дада снова приходится убивать ведущие нули
            cmp rax, '0'
            je Trash
            MoveToBuf:
            mov [Buffer + rdx], rax
            inc rdx                     ;индекс буфера
            Trash:
            loop CopyBuf

            mov [BufSize], rdx          ;шок, теперь в буфсайз реально занятый размер буфера
            pop cx

            ret



section .rodata align=8

CHOOSELABEL:                            ;понимаю, выглядит непрезентабельно как-то, но либо так, либо выбор формата печати будет не одним прыжком
    dq B           ; Вариант %b         ;а еще ассемблерный листинг switch показал +- то же самое, такие дела
    dq C           ; Вариант %c
    dq D           ; Вариант %d
    dq DEFT
    dq DEFT
    dq DEFT
    dq DEFT
    dq DEFT
    dq DEFT
    dq DEFT
    dq DEFT
    dq DEFT
    dq DEFT
    dq O           ; Вариант %o
    dq DEFT
    dq DEFT
    dq DEFT
    dq S           ; Вариант %s
    dq DEFT 
    dq DEFT
    dq DEFT
    dq DEFT
    dq X           ; Вариант %x
