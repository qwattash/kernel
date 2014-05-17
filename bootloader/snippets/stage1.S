/*
 * GDT preparation / A20 handling and old hardcoded sector2 loader
 *

    
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

# GDT data
gdt_pointer:
	.word 0x17              #gdt limit
	.long 0x1000            #gdt base
*/

# strings
# A20_enabled:    .asciz "\b\bA20 Enabled.\r\n"
# A20_disabled:   .asciz "\b\bA20 Disabled.\r\n"

    # STRUCTURE OF DAP
## Disk Address Packet
#dap:
#dap_size:
#    .byte 0x10                  # size of DAP
#dap_unused:
#    .byte 0x00
#dap_num_sectors:                # some Phoenix BIOSes limit this to 127
#    .word 0x00
#dap_buffer:
#    .long 0x00                 # seg:offset of destination buffer - take care of little endian
#dap_start_low:
#    .long 0x00                 # LBA of first sector, low 32-bit
#dap_start_high:
#    .long 0x00                 # LBA of first sector, high 32-bit
