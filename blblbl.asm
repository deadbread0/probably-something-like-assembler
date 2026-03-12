.model tiny
.code
org 100h
VIDEOSEG equ 0b800h

start:
        mov ax, VIDEOSEG
        mov es, ax

        lea si, strr
        mov bx, (20 * 80 + 30) * 2

        mov dl, byte ptr [si]
        mov es: byte ptr [bx], dl
        mov es: byte ptr [bx + 1], 0dh

        mov dl, byte ptr [si + 1]
        mov es: byte ptr [bx + 2], dl
        mov es: byte ptr [bx + 3], 0dh
        mov ax, 4c00h
        int 21h
.data
strr db "ax$"
end     start