name io

; this file contains functions
; for console input and output


.model small


.data

    ; exports
    public print_string
    public print_number
    public read_char
    public read_string


.code

    ; prints a string, push the address of the string,
    ; the string must be 0-terminated
    print_string proc

        ; store bp
        push bp
        mov bp, sp

        ; load the parameter into si - the offset of the string to print
        mov si, [bp + 4]

        ; the service 2h will be used
        mov ah, 2h

        print_string_loop:

        ; move the next char
        mov dl, [si]

        ; end if this is the 0 terminator
        cmp dl, 0
        je print_string_end

        ; print the char
        int 21h

        ; move to the next char and repeat
        inc si
        jmp print_string_loop

        print_string_end:

        ; restore bp
        pop bp
        ; return and pop the parameter
        ret 2

    endp

    ; prints a number
    print_number proc

        ; store bp
        push bp
        mov bp, sp

        ; init registers
        mov bx, 10
        mov cx, 0

        ; store the number in ax
        mov ax, [bp + 4]

        print_number_push:

        ; clear the remainder
        mov dx, 0

        ; divide by 10
        div bx

        ; push the remainder
        push dx
        inc cx

        ; loop if not 0
        cmp ax, 0
        jne print_number_push

        print_number_pop:

        ; pop the next digit
        pop dx

        ; convert to char
        add dx, '0'

        ; print the char
        mov ah, 2h
        int 21h

        ; loop if cx is greater than 0
        loop print_number_pop

        ; done, restore bp
        pop bp
        ; return and pop the parameter
        ret 2

    endp

    ; read a character, the result will be in the al register
    read_char proc

        ; call the service 1h
        mov ah, 1h
        int 21h

        ; return
        ret

    endp

    ; read a string, push the address of the buffer
    ; the buffer must start with 2 bytes - max chars to read, actual # of chars read
    ; the buffer is automatically 0-terminated
    read_string proc

        ; store bp
        push bp
        mov bp, sp

        ; store the parameter in dx - the offset of the buffer
        mov dx, [bp + 4]

        ; call the service 0ah
        mov ah, 0ah
        int 21h

        ; store the start of the string
        mov bx, [bp + 4]

        ; get the number of chars read
        inc bx
        mov dl, [bx]
        mov dh, 0

        ; move to the end of the string
        inc bx
        add bx, dx

        ; 0-terminate
        mov [bx], 0

        ; restore bp
        pop bp
        ; return and pop the parameter
        ret 2

    endp

end

