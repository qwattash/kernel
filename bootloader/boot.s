##
## author: Alfredo Mazzinghi
##
## Floppy disk boot sector
## Fists stage

## real mode
.code16
	
## segments
.equ SEG_BOOT,  0x0000
.equ SEG_STACK, 0x9000
.equ INIT_SP,   0xFBFF

### memory map documentation
### 0x0000:0000	 +------------------------------+
###              |     IVT                      |
### 0x0000:04FF	 +------------------------------+
###              |     BIOS                     |
### 0x0000:04FF	 +------------------------------+
###              |     BootLoader free Mem      |
### 0x0000:7C00	 +------------------------------+
###              |     BootLoader .text         |
### 0x0000:7E00	 +------------------------------+
###              |     BootLoader free Mem      |
### 0x9000:0000	 +------------------------------+
###              |     Available Stack space    |
### 0x9000:7C00	 +------------------------------+
###              |     BootLoader stack         |
### 0x9000:FC00	 +------------------------------+
###              |     Extended BIOS data       |
### 0xA000:0000	 +------------------------------+
###              |     Video Memory             |
### 0xC000:0000	 +------------------------------+
###              |     Video BIOS               |
### 0xC000:8000  +------------------------------+
###              |     MemMapped I/O            |
### 0xF000:0000  +------------------------------+
###              |     BIOS                     |
### 0xF000:FFFF  +------------------------------+

.text
boot_begin:
    ## disable interrupts, we are messing with segments now
    cli
    ## normalize %cs:%eip
    ljmp $SEG_BOOT,  $boot_start

boot_start:
    ## init segment selectors
    movw $SEG_BOOT,  %ax        # 
    movw %ax,        %ds        # data segment = SEG_BOOT
    movw %ax,        %es        # set other registers to a known value
    movw %ax,        %fs
    movw %ax,        %gs
    movw $SEG_STACK, %ax
    movw %ax,        %ss        # stack segment = SEG_STACK
    movw $INIT_SP,   %ax
    movw %ax,        %sp        # init stack pointer

    sti                         # enable interrupts again
	
    ## print welcome message
    movw $welcome,   %ax
    call bios_strprint

end:	
    jmp  end                    # loop forever
    hlt                         # you should not be here!

#bootloader private functions
bios_strprint:	                # void bios_strprint(char* AX)
    pushw %ax
    pushw %bx
    pushw %si
    ## BIOS void INT 0x10(AH=0x0e display_char, AL=char_to_display, BH=page_number, BL=foreground_color graphic mode only)
    movw  %ax,       %si
    movb  $0x0e,     %ah
    movb  $0,        %bh
    ## prepare to loop
bios_strprint_writeloop:
    lodsb                       # load char in %al
    orb   %al,       %al        # check if %al is 0x00 (null char)
    jz    bios_strprint_writeloop_end
    int   $0x10                 # if char is ok, display it
    jmp   bios_strprint_writeloop
bios_strprint_writeloop_end:
    popw  %si
    popw  %bx
    popw  %ax
    ret
	
#data
welcome: .asciz "\b\bWelcome to Custom Boot v0\r\n"

boot_end:
    ##pad to 512 bytes
    .fill   510 - (boot_end - boot_begin)
signature:
    ## boot sector signature
    .byte   0x55
    .byte   0xaa
