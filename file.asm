name file

; this file contains procedures for reading
; file contents and metadata


; includes
include macros.asm


.model small


.data

    ; exports
    public open_file
    public close_file
    public print_file_size
    public print_current_directory
    public print_lines_with_number
    public print_file

    ; error strings
    error db 'Error: ', 0
    error_file_not_found          db 'File not found!', 0
    error_path_not_found          db 'Path not found!', 0
    error_no_handle               db 'Too many open files! How did that happen???', 0
    error_access_denied           db 'Access denied!', 0
    error_access_mode             db 'Invalid access mode!', 0
    error_unknown                 db 'Unknown error with error code ', 0

    ; string for the number of lines
    number_of_lines db 'Number of lines with a number: ', 0

    ; opened file handle
    file_handle dw 0

    ; file size
    file_size dd 0

    ; current working directory
    current_directory db 64 dup(0)

    ; buffer for file contents
    file_buffer db 255 dup(0)

    ; buffer size
    file_buffer_size db 253

    ; flag whether we encountered a number
    was_number db 0
    
    ; number of lines with a number
    lines_with_number db 0

    ; counter for pagination
    lines_on_screen db 0

    ; string about quitting
    quitting db 'Quitting...', 0


.code

    ; imports
    extrn print_string : proc
    extrn print_number : proc
    extrn read_char : proc

    ; opens a file for reading
    ; the parameter is the offset of the file name and the
    ; function presumes that DS already points to the correct
    ; data segment
    open_file proc

        ; store bp
        push bp
        mov bp, sp

        ; set open file service number
        ; also set access mode
        mov ax, 3d00h

        ; point to file name
        mov dx, [bp + 4]

        ; call service
        int 21h

        ; if carry is set, there was an error
        jc open_file_error

        ; store the file handle
        mov file_handle, ax

        ; return 1
        mov ax, 1

        ; restore bp
        pop bp
        ; return and pop the parameter
        ret 2

        open_file_error:

        ; setup DS
        mov bx, seg error
        mov ds, bx

        ; print error string
        ; store AX because it contains the error code
        ; but the procedure changes it
        push ax
        write error
        pop ax

        ; print the error based on the error code in AX
        ; http://stanislavs.org/helppc/dos_error_codes.html

        cmp ax, 2
        jne open_file_2

        write_line error_file_not_found
        jmp open_file_end

        open_file_2:

        cmp ax, 3
        jne open_file_3

        write_line error_path_not_found
        jmp open_file_end

        open_file_3:

        cmp ax, 4
        jne open_file_4

        write_line error_no_handle
        jmp open_file_end

        open_file_4:

        cmp ax, 5
        jne open_file_5

        write_line error_access_denied
        jmp open_file_end

        open_file_5:

        cmp ax, 0ch
        jne open_file_c

        write_line error_access_mode
        jmp open_file_end

        open_file_c:

        ; unknown error
        push ax
        write error_unknown
        call print_number
        end_line

        open_file_end:

        ; return 0
        mov ax, 0

        ; restore bp
        pop bp
        ; return and pop the parameter
        ret 2

    endp

    ; closes the currently opened file
    close_file proc

        ; set file handle
        mov bx, file_handle

        ; call close service
        mov ah, 3eh
        int 21h

        ; done
        ret

    endp
    
    ; prints the size of a file
    ; this function assumes that a file is opened
    print_file_size proc

        ; seek to the end of the file
        mov ah, 42h
        mov al, 2

        ; 0 bytes from the end
        xor cx, cx
        xor dx, dx

        ; set the file handle
        mov bx, file_handle

        ; call service
        int 21h

        ; check if an error occured
        jc print_file_size_error

        ; check if it is more than a kilobyte
        cmp ax, 400h
        ja print_file_size_kilobyte

        ; print the size in bytes
        push ax
        call print_number
        write_char ' '
        write_char 'B'
        end_line

        ; return
        ret

        print_file_size_kilobyte:

        ; divide DX:AX by 1024
        mov bx, 400h
        div bx

        ; check if it is more than a megabyte
        cmp ax, 400h
        ja print_file_size_megabyte

        ; print the size in kilobytes
        push ax
        call print_number
        write_char ' '
        write_char 'k'
        write_char 'B'
        end_line

        ; return
        ret

        print_file_size_megabyte:

        ; divide DX:AX by 1024
        mov bx, 400h
        div bx

        ; print the size in megabytes
        push ax
        call print_number
        write_char ' '
        write_char 'M'
        write_char 'B'
        end_line

        ; return
        ret

        print_file_size_error:

        ; print the error code
        push ax
        write error
        write error_unknown
        call print_number
        end_line

        ; done
        ret

    endp

    ; print the current working directory
    print_current_directory proc

        ; setup DS
        mov ax, seg current_directory
        mov ds, ax

        ; set service params
        mov ah, 47h
        mov dl, 0
        lea si, current_directory

        ; call service
        int 21h

        ; print the result
        write current_directory
        write_char '\'

        ; done
        ret

    endp

    ; print file contents
    ; the file must be opened
    ; the content will be paginated
    print_file proc

        ; setup DS
        mov ax, seg file_handle
        mov ds, ax

        ; reset counter
        mov lines_on_screen, 0

        print_file_buffer:

        ; setup registers for reading, set the max bytes to read
        ; and the pointer to the buffer
        mov ah, 3fh
        mov bx, file_handle
        mov cl, file_buffer_size
        mov ch, 0
        lea dx, file_buffer

        ; call service
        int 21h

        ; if there was an error, stop
        jc print_file_error

        ; check if we actually read something
        cmp ax, 0
        je print_file_end
        
        ; set up pointers
        lea si, file_buffer
        lea di, file_buffer
        add di, ax

        print_file_chars:

        ; check if this is a new line
        cmp byte ptr [si], 10
        jne print_file_no_nl

        ; increase counter
        inc lines_on_screen

        print_file_no_nl:

        ; print the character
        write_char [si]

        ; move to the next char
        inc si

        ; check if we need to paginate
        cmp lines_on_screen, 23
        jb print_file_no_pagination

        ; wait for input
        call read_char

        ; if 'q' was pressed, end
        cmp al, 'q'
        jne print_file_q

        ; let the user know we are quitting
        end_line
        write_line quitting

        ; end
        ret

        print_file_q:

        ; reset counter
        mov lines_on_screen, 0

        print_file_no_pagination:

        ; if this is the end of the buffer, load the next one
        cmp si, di
        jae print_file_buffer

        ; else just loop
        jmp print_file_chars

        print_file_end:

        ; finally done
        ret

        print_file_error:

        ; print the error code
        push ax
        end_line
        write error
        write error_unknown
        call print_number
        end_line

        ; done
        ret

    endp

    ; print all lines that contain a number
    ; presumes a file is already opened
    print_lines_with_number proc

        ; setup DS
        mov ax, seg file_handle
        mov ds, ax

        ; reset flag
        mov was_number, 0

        ; reset counter
        mov lines_with_number, 0

        print_lines_buffer:

        ; setup registers for reading, set the max bytes to read
        ; and the pointer to the buffer
        mov ah, 3fh
        mov bx, file_handle
        mov cl, file_buffer_size
        mov ch, 0
        lea dx, file_buffer

        ; read a new buffer
        int 21h

        ; if there was an error, stop
        jc print_lines_error_middle

        ; check if we actually read something
        cmp ax, 0
        je print_lines_end

        ; reset the pointers,
        ; si points to the start of the buffer,
        ; di points to the end
        lea si, file_buffer
        lea di, file_buffer
        add di, ax

        print_lines_chars:

        ; skip the newlines and returns
        cmp byte ptr [si], 10
        je print_lines_no_write
        cmp byte ptr [si], 13
        je print_lines_no_write

        ; detect a number
        cmp byte ptr [si], '0'
        jb print_lines_no_number
        cmp byte ptr [si], '9'
        ja print_lines_no_number

        ; found a number!
        mov was_number, 1

        print_lines_no_number:

        ; write the character
        write_char [si]

        print_lines_no_write:

        ; check if this is the end of the line
        cmp byte ptr [si], 10
        jne print_lines_no_nl

        ; check if there was a number
        cmp was_number, 1
        je print_lines_number

        ; jump to the start of the line
        write_char 13

        ; fix for too long jumps
        jmp print_line_jump_fix
        print_lines_buffer_fix:
        jmp print_lines_buffer
        print_line_jump_fix:

        ; clear the line
        call clear_line

        ; reset flag
        mov was_number, 0

        ; continue
        jmp print_lines_no_nl

        print_lines_number:

        ; reset flag
        mov was_number, 0

        ; end the line
        end_line

        ; increase the counters
        inc lines_with_number
        inc lines_on_screen

        ; check if we need to wait
        cmp lines_on_screen, 22
        jb print_lines_no_nl

        ; wait for input
        call read_char

        ; reset counter
        mov lines_on_screen, 0

        print_lines_no_nl:

        ; move to the next char
        inc si

        ; if this is the end of the buffer, load the next one
        cmp si, di
        jae print_lines_buffer_fix

        ; else just loop
        jmp print_lines_chars

        ; add this because otherwise the first jump is out of range
        print_lines_error_middle:
        jmp print_lines_error

        print_lines_end:

        ; check if there was a number
        cmp was_number, 1
        je print_lines_end_number

        ; return carriage
        write_char 13

        ; clear the line
        call clear_line

        ; skip the instructions for the number
        jmp print_lines_final

        print_lines_end_number:

        ; increase the counter
        inc lines_with_number

        ; end the line
        end_line

        print_lines_final:

        ; leave a space
        end_line

        ; print the number of lines with a number
        write number_of_lines

        mov ah, 0
        mov al, lines_with_number
        push ax

        call print_number
        end_line

        ; we're done here
        ret

        print_lines_error:

        ; print the error code
        push ax
        end_line
        write error
        write error_unknown
        call print_number
        end_line

        ; done
        ret

    endp

    ; clears just the current line
    ; presumes the cursor is at the start
    clear_line proc

        ; set up the counter
        mov cx, 79

        clear_line_loop:

        ; write space to clear the character
        write_char ' '

        ; loop
        loop clear_line_loop

        ; return to the start
        write_char 13

        ; done
        ret

    endp

end

