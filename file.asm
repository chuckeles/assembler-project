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

    ; error strings
    error db 'Error: ', 0
    error_file_not_found          db 'File not found!', 0
    error_path_not_found          db 'Path not found!', 0
    error_no_handle               db 'Too many open files! How did that happen???', 0
    error_access_denied           db 'Access denied!', 0
    error_access_mode             db 'Invalid access mode!', 0
    error_unknown                 db 'Unknown error with error code ', 0

    ; opened file handle
    file_handle dw 0

    ; file size
    file_size dd 0


.code

    ; imports
    extrn print_string : proc
    extrn print_number : proc

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

end

