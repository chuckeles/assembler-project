name datetime

; procedures in this file deal with date and time
; getting it and printing it


; includes
include macros.asm


.model small


.data

    ; exports
    public print_date
    public print_time


.code

    ; imports
    extrn print_number : proc

    ; prints the current date
    print_date proc

        ; call service to get system date
        mov ah, 2ah
        int 21h

        ; store registers
        push cx
        push dx

        ; write the day
        mov al, dl
        mov ah, 0
        push ax
        call print_number

        ; delimeter
        write_char '.'
        write_char ' '

        ; restore dx
        pop dx

        ; write the month
        mov al, dh
        mov ah, 0
        push ax
        call print_number

        ; delimeter
        write_char '.'
        write_char ' '

        ; restore cx
        pop cx

        ; write the year
        push cx
        call print_number

        ; done
        ret

    endp

    ; prints the current time
    print_time proc

        ; call service to get system time
        mov ah, 2ch
        int 21h

        ; store registers
        push dx
        push cx

        ; write the hour
        mov al, ch
        mov ah, 0
        push ax
        call print_number

        ; delimeter
        write_char ':'

        ; restore cx
        pop cx

        ; write the minute
        mov al, cl
        mov ah, 0
        push ax
        call print_number

        ; delimeter
        write_char ':'

        ; restore dx
        pop dx

        ; write the second
        mov al, dh
        mov ah, 0
        push ax
        call print_number

        ; done
        ret

    endp

end

