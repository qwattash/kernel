####
#
# stage 2 test
#
#####

# relevant location constants
#define SCRATCH             0x0710    
#define INT15_E820_MAGIC   0x534D4150    
    
.code16

##
# the stage 2 image is placed from 0x7e00 in memory after the mbr code
# and is stored in the vbr and immediately following sectors in the fat32
# boot partition 
#             

.text
stage2_start: 
    movw $welcome_to_st2, %ax
    call bios_strprint
endloop:
    jmp endloop
welcome_to_st2:	.asciz "Welcome to the magic land of stage 2!" 

       
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

    #
    # cdecl functions
    #
.code16
    ##################################################################
    # bool check_a20(void)
    # Returns 0 if A20 is enabled, 1 otherwise.
check_A20:
    pushw           %bp
    movw            %sp,%bp
    # BIOS int INT 0x15 (AX=0x2402) (Check for A20 Gate status. If disabled %al == 1, %al == 0 otherwise).
    movw $0x2402,   %ax
    int  $0x15
    cmpb $0x0,      %al
    # if al == 0 an error occured
    jnz 1f
    movw $0x1, %ax
1:
    movw $0x0,  %ax
    leave
    ret
    #################################################################
    
    #################################################################
    # bool enable_a20(void)
    # Returns 0 if activation succeded, 1 otherwise.
enable_A20: 
    pushw           %bp
    movw            %sp,%bp
    # BIOS int INT 0x15 (AX=0x2401) (Enable A20 Gate).
    clc
    movw $0x2401,   %ax
    int $0x15
    # if CF is set an error occurred
    jnc 1f
    movw $0x1, %ax
1:
    movw $0x0, %ax
    leave
    ret
    #################################################################

    #################################################################
    # ? get_ram_size(void)
    # Returns the available ram size starting from 0x100000
get_ram_size: 
    pushw           %bp
    movw            %sp,%bp
    # BIOS int INT 0x15 (EAX=0xE820) (Detects upper memory).
    xor %eax, %eax
    xor %ebx, %ebx
    movw $SCRATCH, %di
    movl $INT15_E820_MAGIC, %edx
    movw $0xE820, %ax
    movk $24, %cx
    int $0x15
    # if EAX != 0x534D4150 OR CF != 0 an error occured
    compl $INT15_E820_MAGIC, %eax
    jne 1f
    jc 1f
    # success
    
    jmp 2f
    
1:
    # failure
    movw $-1, %eax
2:
    leave
    ret
    #################################################################

    
    #
    # Macro definitions
    #
    
    #################################################################
    # macro that creates a GDT (or LDT) entry at given index and with given type
    # void make_gdt_entry(addr_16 gdt_base, u_int_16 index)
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
