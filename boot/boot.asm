; boot.asm - minimal BIOS boot sector (NASM)
; - reads 4 sectors starting at sector 2 on the boot device (floppy emulation)
; - loads them to 0x0000:0x1000 and jumps there
; Assemble with: nasm -f bin boot.asm -o boot.bin

org 0x7c00

start:
    ; help for this bootloader https://wiki.osdev.org/MBR_(x86)
    ;init the stack BIOS doesn't guarantie valid setup
    cli                 ; disable interrupts (https://stackoverflow.com/questions/76281394/a-working-example-of-the-cli-and-sti-instructions-in-x86-16-bit-assembly)
    xor ax, ax          ; xor a, a = 0
    mov ss, ax          ; set the stack segment to 0
    mov sp, 0x7c00      ; set the stack pointer
    sti                 ; enable interrupts

    mov si, msg         ; sets si(index register lower 16 bits full is ESI) to the addr of the message string below(https://akash-nasm-tutorial.netlify.app/basic/register)
.print:
    ; print message (msg) to screen
    lodsb               ; loads the byte at [si] into AL and increments si. can also load a word into AX or doubleword into EAX (https://faydoc.tripod.com/cpu/lodsb.htm)
    cmp al, 0           ; check null terminator
    je .print_done      ; terminates loop
    mov ah, 0x0e        ; teletype BIOS function. using this because there is no OS yet and it's provided by the BIOS
    mov bh, 0           ; set display page 0. bh/bl(8 bit) is the lower/upper half of BX(16 bit) Data reg. https://www.tutorialspoint.com/assembly_programming/assembly_registers.htm  https://www.cs.uaf.edu/2017/fall/cs301/reference/x86_64.html
    mov bl, 7           ; color (gray on black) BX = 0x0000000000000111
    int 0x10            ; int = interrupt 0x10 bios video intr. same as reason as teletype https://en.wikipedia.org/wiki/BIOS_interrupt_call
    jmp .print          ; loop
.print_done:
    ; load the kernel rn only 4 sectors just for testing
    xor ax, ax          ; ax = 0
    mov es, ax
    mov bx, 0x1000      ; ES/BX = segment/offset = 0x0000:0x1000 so ofc real addr is 0x1000

    ; BIOS INT13 CHS read:
    ; AH = 0x02 (read sectors)
    ; AL = sectors to read (1..127)
    ; CH = cylinder (low 8 bits)
    ; CL = sector number (1..63)
    ; DH = head
    ; DL = drive (BIOS sets DL for boot device)
    mov ah, 0x02        ; func 2 is for reading sectors. ah(high byte of ax) AX is the primary accumulator; it is used in input/output and most arithmetic instructions
    mov al, 4           ; read 4 sectors(each sector is 512 bytes long)
    xor ch, ch          ; set 0 high bit of cx(Counter) same src as earlier
    mov cl, 2           ; sector 2 (sector numbering starts at 1). boot sector is sector 1.
    xor dh, dh          ; head 0
    int 0x13            ; BIOS disk read intr.
    jc disk_error       ; if carry flag handle the disk err.

    ; jump to loaded kernel at 0x0000:0x1000
    jmp 0x0000:0x1000


; same idea as earlier
disk_error:
    mov si, err_msg
err_print:
    lodsb
    cmp al, 0
    je .hang        ; after finish hang
    mov ah, 0x0e
    int 0x10
    jmp err_print

.hang:
    cli             ; no interrupts
.hang_loop:
    hlt             ; puts the cpu in low power state
    jmp .hang_loop

msg db 'Booting into Munix kernel...',0x0D, 0x0A, 0
err_msg db 'Disk read error', 0

; pad the boot sector to 512 bytes full size of MBR
times 510-($-$$) db 0
; “No bootable medium” if the last 2 bytes aren't 0xAA 0x55
dw 0xAA55
;; after compiling its 512 bytes W W W W