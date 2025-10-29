;; going to replace just printing a mesage to the screen

org 0x1000
mov si, msg
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
hlt
jmp .done
msg db 'Hello from kernel!', 0