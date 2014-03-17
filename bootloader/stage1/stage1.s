##
## Authors: Alfredo Mazzinghi, Nicola Piga
##
## Stage 1

## real mode
.code16

.global start, _start
## segments
.equ SEG_BOOT,  0x0000
.equ SEG_STACK, 0x9000
.equ INIT_SP,   0xFBFF
.equ STAGE_2,   0x7E00
.equ BOOT_RELOC, 0x0500
.equ BOOT_BEGIN, 0x7C00

### memory map documentation
### 0x0000:0000	 +------------------------------+
###              |     IVT                      |
### 0x0000:0400	 +------------------------------+
###              |     BIOS                     |
### 0x0000:0500	 +------------------------------+
###              |     Relocated MBR            |
### 0x0000:0600  +------------------------------+
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

### What follows (between boot_begin: and signature: ) is the Stage 0.
### Any other code outside these first 512 bytes won't be copied onto the RAM by the BIOS.
### see BIOS Boot Specification in docs
### see BIOS Plug n Play Specification in docs

## macros

# reloc_addr relocated base address
# base_addr base address
# addr address to be moved relative to base_addr to reloc_addr
#define RELOC_LABEL(reloc_addr, base_addr, addr) reloc_addr - addr_base + addr
    
## end macros
    
.text
start:
_start:
### boot sector starts here
boot_begin:
    # save drive index given by BIOS
    pushw %dx
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

    # find the VBR of the partition with index stage2_partition_index
    # get partition entry index (0-3)
    xorw %bx, %bx
    movb stage2_partition_index, %bl
    shlw $4, %bx
    # get partion start LBA, little endian
    movw 0x1C8(%bx), %ax
    shll $0x10, %eax
    movw 0x1C6(%bx), %ax
    
    # relocate current boot code
    movw $BOOT_RELOC, %di       # get relocation base address
    movw $BOOT_BEGIN, %si           # source
    movw $0x100, %cx            # destination
    cld
    rep movsb                   # copy

    # calculate jump address
    # @TODO make this a macro
    movw $vbr_load, %bp
    subw $BOOT_BEGIN, %bp
    addw $BOOT_RELOC, %bp
    #jump to relocated code, abs jump to (vbr_load - 0x7C00 + BOOT_RELOC)
    jmp *%bp
    
    # load VBR
vbr_load:
    popw %dx                    # get saved drive number
    pushw %dx                   # push once to put it again in the stack
    pushw $BOOT_BEGIN           # destination buffer
    pushw $0x01                 # number of sectors to read
    pushl %eax                  # push LBA
    pushw %dx                   # push second time for the drive parameter
    call read_sector
    
    # jump to VBR
    jmp *$BOOT_BEGIN
    /*
    ## take second sector from hdd containing the C second stage
    pushw $STAGE_2              # Load second stage just below the first stage
    pushw $0x0001               # Want to read 1 sector only
    pushw $0x0002               # Selector number (rem: sectors start from 1)
    pushw $0x0000               # Head: 0
    pushw $0x0000               # Cylinder: 0
    pushw $0x0080               # Drive: Hard Drive 0
    call  read_sector
    add   $0x0C,      %sp

    ## enable A20 Gate
    call enable_A20
    ## print activation outcome
    call check_A20

    ## setup the gdt
    call write_temp_gdt
    ## load new gdt
    cli
    lgdt gdt_pointer
    
    ## ==> protected mode
    mov  %cr0,       %eax
    or   $0x1,       %al
    mov  %eax,       %cr0

    ljmp $0x08,  $next

next:
    .code32
    movw $0x10,  %ax
    movw %ax,        %ds
    movw %ax,        %es
    movw %ax,        %fs
    movw %ax,        %gs
    movw %ax,        %ss
    movl $0x90000,   %esp
    #jump to second stage
    movl $STAGE_2, %eax
    jmp *%eax #absolute near jump
    */
end:	
    jmp  end                    # loop forever
    hlt                         # you should not be here!

.code16

#bootloader private functions
###################################################################
bios_strprint:	                # void bios_strprint(char* AX)
    ## BIOS void INT 0x10(AH=0x0e display_char, AL=char_to_display, BH=page_number, BL=foreground_color graphic mode only)
    pushw            %ax
    pushw            %bx
    pushw            %si
    
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
##################################################################
    
##################################################################
# WARNING - the function shall not be called before the relocation of the boot code
# void read_sector (byte drive, dword lba, byte num_sect, void * buff)
read_sector:
    ## BIOS int INT 0x13 (AH=0x42 extended_read_sector, DL=drive number, DS:SI seg:offset of Disk Address Packet)
    #prepare stack frame
    pushw %bp
    movw %sp, %bp
    #save regs
    pushl %eax
    pushw %dx
    
    #prepare for bios call
    # drive number in DL
    movw 4(%bp), %dl
    # load LBA
    movl 6(%bp), %eax
    movl %eax, RELOC_LABEL($BOOT_RELOC, $BOOT_BEGIN, dap_start_low)
    # load number of sectors
    movw 10(%bp), %ax
    movw %ax, RELOC_LABEL($BOOT_RELOC, $BOOT_BEGIN, dap_num_sectors)
    # load dap destination buffer
    movl 12(%bp), %eax
    movl %eax, RELOC_LABEL($BOOT_RELOC, $BOOT_BEGIN, dap_buffer)
    movb $0x42,      %ah
    int  $0x13
    # carry flag on error
    # AH return code
    # jc error
    
    #restore regs
    popw %dx
    popl %eax
    leave
    
    ret
##################################################################

/*
##################################################################
check_A20:                      # void check_A20
     pushw           %ax
     ##BIOS int INT 0x15 (AX=0x2402) (Check for A20 Gate status. If disabled %al == 0, %al == 1 otherwise).
     movw $0x2402,   %ax
     int $0x15
     cmpb $0x0,      %al
     jnz enabled
     movw $A20_disabled, %ax
     jmp print
enabled:
     movw $A20_enabled,  %ax
print:  
     call bios_strprint
     popw            %ax
     ret
#################################################################

#################################################################
enable_A20:                     #void enable_A20
     pushw           %ax
     ##BIOS int INT 0x15 (AX=0x2401) (Enable A20 Gate).
     movw $0x2401,   %ax
     int $0x15
     popw            %ax
     ret
#################################################################

#################################################################
write_temp_gdt:                 #setup a temporary gdt
                                #starting from 0x01000
     pushw  %di
     movw   $0x1000, %di
     movw   $0x0,    (%di)
     add    $2,      %di
     movw   $0x0,    (%di)
     add    $2,      %di
     movw   $0x0,    (%di)
     add    $2,      %di
     movw   $0x0,    (%di)
     add    $2,      %di
     movw   $0xFFFF, (%di)
     add    $2,      %di
     movw   $0x0,    (%di)
     add    $2,      %di
     movw   $0x9A00, (%di)
     add    $2,      %di
     movw   $0x00CF, (%di)
     add    $2,      %di
     movw   $0xFFFF, (%di)
     add    $2,      %di
     movw   $0x0,    (%di)
     add    $2,      %di
     movw   $0x9200, (%di)
     add    $2,      %di
     movw   $0x00CF, (%di)        
     popw   %di
     ret
#################################################################
*/
    
#data
welcome:        .asciz "\b\bWelcome to Custom Boot v0\r\n"
A20_enabled:    .asciz "\b\bA20 Enabled.\r\n"
A20_disabled:   .asciz "\b\bA20 Disabled.\r\n"
/*
this is the number of the partition from which we load the VBR
the VBR of that partition will in turn do the job of loading the kernel
by loading the stage 2 of the bootloader or load another operating system's
boot code.
The VBR acts as a stage1.5 in grub.
This field will be modified by the installer
*/
stage2_partition_index:
    .byte 0
## Disk Address Packet
dap:
dap_size:
    .byte 0x10                  # size of DAP
dap_unused:
    .byte 0x00
dap_num_sectors:                # some Phoenix BIOSes limit this to 127
    .word 0x00
dap_buffer:
    .dword 0x00                 # seg:offset of destination buffer - take care of little endian
dap_start_low:
    .dword 0x00                 # LBA of first sector, low 32-bit
dap_start_high:
    .dword 0x00                 # LBA of first sector, high 32-bit
    
gdt_pointer:
	.word 0x17              #gdt limit
	.long 0x1000            #gdt base
boot_end:
    ##pad until signature
    .fill   510 - (boot_end - boot_begin)
signature:
    ## boot sector signature
    .byte   0x55
    .byte   0xaa

### MBR ends here
