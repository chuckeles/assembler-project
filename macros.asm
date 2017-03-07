; this file contains handy macros
; used throughout the project


; prints the string to the console, the string
; must be 0 terminated
write macro string

    ; push the string and call the printing function
    push offset string
    call print_string

endm

; write a single character to the console
write_char macro char

    ; execute the service
    mov ah, 2h
    mov dl, char
    int 21h

endm

; ends the line
end_line macro

    ; print line feed and carriage return
    write_char 13
    write_char 10

endm

; prints the string and ends the line
write_line macro string

    ; print the string
    write string
    ; end the line
    end_line

endm

; clear the screen
clear macro

    mov ax, 7h
    int 10h

endm

; reads a string to the buffer and 0-terminates it
read macro buffer

    ; push the buffer and call the function
    push offset buffer
    call read_string

endm

