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
    menu_size db '[s] Print the file size', 0
    menu_numbers db '[n] Print those lines that contain a number', 0
    menu_exit db '[q] Quit the program', 0
    menu_prompt db 'Choose an option: ', 0
    menu_unknown db 'Invalid option! Choose better next time...', 0

    ; filename
    filename_prompt db 'Enter the new file name: ', 0
    filename_confirm db 'Filename changed.', 0
    filename_max db 127
    filename_size db 0
    filename_buffer db 128 dup(0)

    ; filesize
    filesize_name db 'File name: ', 0
    filesize_size db 'File size: ', 0


.code

    ; imports
    extrn open_file : proc
    extrn close_file : proc
    extrn print_string : proc
    extrn print_date : proc
    extrn print_time : proc
    extrn print_file_size : proc
    extrn print_current_directory : proc
    extrn print_file : proc
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

        ; write the current file name with path
        write status_filename
        call print_current_directory
        write_line filename_buffer

        ; write the current date
        write status_date
        call print_date
        end_line

        ; write the current time
        write status_time
        call print_time
        end_line

        ; space
        end_line

        ; print the menu
        write_line menu_title
        write_line menu_filename
        write_line menu_print
        write_line menu_size
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

        ; 'q' means end the program
        cmp al, 'q'
        jne read_execute_x

        ; return 0
        mov ax, 0
        ret

        read_execute_x:

        ; 'f' prompts for the file name
        cmp al, 'f'
        jne read_execute_f

        ; print the prompt
        clear
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

        ; 's' prints the file size
        cmp al, 's'
        jne read_execute_s

        ; open the file
        clear
        push offset filename_buffer
        call open_file

        ; check if there was an error
        cmp ax, 1
        je read_execute_s_no_error

        ; there was an error
        ; it is already printed, wait for input and loop
        call read_char
        mov ax, 1
        ret

        read_execute_s_no_error:

        ; print the file name
        write filesize_name
        write_line filename_buffer

        ; print the size
        write filesize_size
        call print_file_size

        ; close the file
        call close_file

        ; wait for input
        call read_char

        ; done, loop
        mov ax, 1
        ret

        read_execute_s:

        ; 'p' prints the file contents
        cmp al, 'p'
        jne read_execute_p
        
        ; open the file
        clear
        push offset filename_buffer
        call open_file

        ; check if there was an error
        cmp ax, 1
        je read_execute_p_no_error

        ; there was an error
        ; it is already printed, wait for input and loop
        call read_char
        mov ax, 1
        ret

        read_execute_p_no_error:

        ; print the file content
        call print_file

        ; close the file
        call close_file

        ; wait for input
        call read_char

        ; done, loop
        mov ax, 1
        ret

        read_execute_p:

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

