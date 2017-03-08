name main

; this is the main project file
; it handles the menu and the basic logic, like reading
; the user input
; stack is defined here as well


; includes
include macros.asm


.model small
.stack


.data

    ; the status items, printed before the menu
    status_title db 'STATUS', 0
    status_subtitle db 'Martin Jakubik (xjakubikm), Assignment 9', 0
    status_filename db 'Entered file name: ', 0
    status_date db 'Current date: ', 0
    status_time db 'Current time: ', 0

    ; the main menu items
    menu_title db 'MAIN MENU', 0
    menu_filename db '[f] Change the file name', 0
    menu_print db '[p] Print the file contents', 0
    menu_numbers db '[n] Print those lines that contain a number', 0
    menu_exit db '[x] Exit the program', 0
    menu_prompt db 'Choose an option: ', 0
    menu_unknown db 'Invalid option! Choose better next time...', 0

    ; filename
    filename_prompt db 'Enter the new file name: ', 0
    filename_confirm db 'Filename changed.', 0
    filename_max db 127
    filename_size db 0
    filename_buffer db 128 dup(0)


.code

    ; imports
    extrn print_string : proc
    extrn read_char : proc
    extrn read_string : proc

    ; prints the status and the main menu
    print_menu proc

        ; setup ds
        mov ax, seg menu_title
        mov ds, ax

        ; clear the screen
        clear

        ; print the status
        write_line status_title
        write_line status_subtitle

        ; write the current file name
        write status_filename
        write_line filename_buffer

        write_line status_date
        write_line status_time

        ; space
        end_line

        ; print the menu
        write_line menu_title
        write_line menu_filename
        write_line menu_print
        write_line menu_numbers
        write_line menu_exit

        ; space
        end_line

        ; print the prompt
        write menu_prompt

        ; done, return
        ret

    endp

    ; reads the user input and executes the appropriate action
    ; after returning, when ax is 0, the program should end, otherwise it should loop
    read_execute proc

        ; read the character
        call read_char

        ; 'x' means end the program
        cmp al, 'x'
        jne read_execute_x

        ; return 0
        mov ax, 0
        ret

        read_execute_x:

        ; 'f' prompts for the file name
        cmp al, 'f'
        jne read_execute_f

        ; print the prompt
        end_line
        end_line
        write filename_prompt

        ; read the file name
        read filename_max

        ; confirm
        end_line
        write_line filename_confirm

        ; wait for a character
        call read_char

        ; done, loop
        mov ax, 1
        ret

        read_execute_f:

        ; unknown option
        end_line
        write_line menu_unknown

        ; wait for a character
        call read_char

        ; return 1 to loop
        mov ax, 1
        ret

    endp

    ; program entry point
    start:

    ; print the menu
    call print_menu

    ; read user input and execute action
    call read_execute

    ; loop if non-0 is returned
    cmp ax, 0
    jne start

    ; terminate the program with exit code 0
    mov ah, 4ch
    mov al, 0
    int 21h

    end start

end

