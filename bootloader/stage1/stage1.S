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
### 0x0000:0700  +------------------------------+ 
###	         |     DAP			|
### 0x0000:0710  +------------------------------+
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
#define RELOC_LABEL(reloc_addr, base_addr, addr) (reloc_addr - base_addr + addr)

## end macros
    
.text
start:
_start:
### boot sector starts here
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
    
    # save drive index given by BIOS
    pushw %dx

    ## print welcome message
    movw $welcome,   %ax
    call bios_strprint
    call get_active_partition
    movw %ax, %bx
    shlw $4, %bx
    # get partion start LBA, little endian
    # offsets are relative to the segment 0x0000 so add 0x7C00
    # to the offset relative to the start of the MBR
    movw 0x7DC8(%bx), %ax # 
    shll $0x10, %eax
    movw 0x7DC6(%bx), %ax
    # now check that the LBA is something meaningful
    # LBA = 0 would reload the MBR, which is nonsense
    cmpl $0, %eax
    je vbr_lba_err
    # check that partition has at least one sector...
    movl 0x7DCA(%bx), %ecx
    cmpl $0, %ecx
    ja vbr_lba_ok
vbr_lba_err:
    pushw $err_active_partition # inconsistent entry
    jmp error
vbr_lba_ok:
    # relocate current boot code
    movw $BOOT_RELOC, %di       # get relocation base address
    movw $BOOT_BEGIN, %si       # source
    movw $0x200, %cx            # destination
    cld
    rep movsb                   # copy

    # calculate jump address
    movw $RELOC_LABEL(BOOT_RELOC, BOOT_BEGIN, vbr_load), %bp
    #jump to relocated code, abs jump to (vbr_load - 0x7C00 + BOOT_RELOC)
    jmp *%bp
    
    # load VBR
vbr_load:
    popw %dx                    # get saved drive number
    pushw %dx                   # push once to put it again in the stack
    pushl $BOOT_BEGIN           # destination buffer
    pushw $0x01                 # number of sectors to read
    pushl %eax                  # push LBA
    pushw %dx                   # push second time for the drive parameter
    call read_sector
    add $0x0c, %sp
	
    # jump to VBR
    movw $BOOT_BEGIN, %bp
    jmp *%bp

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
# display error message and return to BIOS
# %sp pointer to error message
error:
    popw %ax
    call bios_strprint
    int $0x18 # boot error, see BIOS BBS specification
1:
    hlt
    jmp 1b
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

    # drive number in DL
    movb 4(%bp), %dl
	
    # DAP allocation
    # save DAP address to %si
    movw $0x0700, %si
    # offset 0 = 0x10 (size), offset 1 = 0x00 (unused)	
    movw $0x0010, (%si)
    # offset 2 = number of sectors to be read
    movw 10(%bp), %ax
    movw %ax, 2(%si)
    # offset 4 = segment:offset pointer to buffer
    movl 12(%bp), %eax
    movl %eax, 4(%si)
    # offset 8 = low 32 bit LBA
    movl 6(%bp), %eax
    movl %eax, 8(%si)
    # offset 12 = high 32 bit LBA (some bios does not support 64 bit LBA)	
    movl $0, 12(%si) 

    # INT 0x13/42
    movb $0x42, %ah
    int  $0x13 
    # carry flag on error
    # AH return code
    jnc read_success
    pushw $RELOC_LABEL(BOOT_RELOC, BOOT_BEGIN, read_error)
    jmp error
read_success:
    #restore regs
    popw %dx
    popl %eax
    leave
    
    ret
##################################################################

##################################################################
# get the index in the partition table of the active partition
# in case of inconsistent results the boot process is aborted
# with an error
# short get_active_partition (void)
get_active_partition:
    # save registers
    pushw %bx
    pushw %cx
    pushw %dx
    pushw %si
    # get partition entry index (0-3)
    xorw %bx, %bx
    xorw %ax, %ax
    movw $pt_entry3, %si # init current partition table entry
    # check active flag for all partitions
    movw $0x04, %cx # max partition number 
vbr_loop: # while (cx > 0)
    movb (%si), %dl # take 1st byte of partition table entry
    andb $0x80, %dl # bit n.7 = 1 => active and bootable
    jz vbr_continue # if (!active) jump
    incw %bx # increment active partitions counter
    movw %cx, %ax # move current iteration index to ax
    decw %ax # from [1, 4] to [0, 3] index
vbr_continue: 	
    subw $0x10, %si # prev partition entry
    loopw vbr_loop # end while
    # check for errors
    cmpw $0x01, %bx # only one active partition may exist 
    je vbr_ok # OK
    jb 1f
    pushw $err_active_partition # too many active entries
    jmp error
1:
    pushw $err_active_partition # no active partition
    jmp error
vbr_ok:
    # restore registers (except %ax)
    popw %si
    popw %dx
    popw %cx
    popw %bx
    ret
	
##################################################################
    
#data strings
welcome:        .asciz "Welcome to Custom Boot v0\r\n"
sector2welcome:	.asciz "Welcome to Sector 2\r\n"
err_active_partition:	 .asciz "Active partition error\r\n"
read_error:	.asciz "Read failed. Damn!\r\n"

boot_end:
    ##pad until partition table 
    .fill   446 - (boot_end - boot_begin)
#7DBE
pt_entry0:
    .byte 0x80			# pt status
    .fill 3			# CHS of first absolute sector
    .byte 0x0c			# pt type
    .fill 3			# CHS of last absolute sector
    .long 0x1			# LBA of first absolute sector
    .long 0x1			# # of sectors in pt
pt_entry1:
    .byte 0x00			# pt status
    .fill 3			# CHS of first absolute sector
    .byte 0x0c			# pt type
    .fill 3			# CHS of last absolute sector
    .long 0x0			# LBA of first absolute sector
    .long 0x0			# # of sectors in pt
pt_entry2:
    .byte 0x00			# pt status
    .fill 3			# CHS of first absolute sector
    .byte 0x0c			# pt type
    .fill 3			# CHS of last absolute sector
    .long 0x0			# LBA of first absolute sector
    .long 0x0			# # of sectors in pt
pt_entry3:
    .byte 0x00			# pt status
    .fill 3			# CHS of first absolute sector
    .byte 0x0c			# pt type
    .fill 3			# CHS of last absolute sector
    .long 0x0			# LBA of first absolute sector
    .long 0x0			# # of sectors in pt
signature:
    ## boot sector signature 7DFE
    .byte   0x55
    .byte   0xaa
# 7E00
### MBR ends here
# trial
    movw $RELOC_LABEL(BOOT_RELOC, BOOT_BEGIN, sector2welcome), %ax
    movw $RELOC_LABEL(BOOT_RELOC, BOOT_BEGIN, bios_strprint), %bp
    call *%bp
1:
    jmp 1b
