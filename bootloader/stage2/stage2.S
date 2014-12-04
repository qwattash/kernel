#####
#
# stage 2 test
#
#####

# relevant location constants
#define SCRATCH             0x0710    
#define INT15_E820_SIG      0x534d4150
    
.code16

##
# the stage 2 image is placed from 0x7e00 in memory after the mbr code
# and is stored in the vbr and immediately following sectors in the fat32
# boot partition 
#             

.text
stage2_start:     
    call get_ram_size
endloop:
    jmp endloop


  /*     
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

/*next:
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
    #// if al == 0 an error occured
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
    #// if CF is set an error occurred
    jnc 1f
    movw $0x1, %ax
1:
    movw $0x0, %ax
    leave
    ret
    #################################################################

    #################################################################
    # u_int32 get_ram_size(void)
    # Returns the available ram size (in bytes) starting from 0x100000
    # In case of error the carry flag is set
get_ram_size: 
    pushw %bp
    movw  %sp, %bp
    # max memory size set to 0
    subw  $4, %sp
    movl  $0, -4(%bp)
    
    # save registers
    pushl %ebx
    pushl %edx
    pushl %ecx
   
    pushw %di
    # BIOS int INT 0x15 (EAX=0xE820) (Detects upper memory).
    xor %eax, %eax
    xor %ebx, %ebx
    # destination buffer is set to the scratch memory zone
    movw $SCRATCH, %di

1:  
    # signature as reported in routine documentation (ACPI 5.1 Specs)
    movl $INT15_E820_SIG, %edx
    movw $0xE820, %ax
    movw $24, %cx
    clc
    
    int $0x15
    #// if EAX != signature OR CF != 0 the call is not supported
    cmpl $INT15_E820_SIG, %eax
    jne 2f
    jc 2f
    
    # success
    # save BaseAddrLow + LengthLow to EAX (4GiB ought to be enough for anybody)
    movl 4(%di), %eax
    addl 8(%di), %eax
    # check if max_memory_size > EAX
    cmpl -4(%bp), %eax
    jb 4f
    movl %eax, -4(%bp)
4:
    # increment DI by 24 for the next call
    addw $24, %di

    # check if we are done
    cmpl $0, %ebx
    jnz 1b

    # clear CF for return
    clc
    movl -4(%bp), %eax
    jmp 3f
2:
    # failure
    stc
3:
    popw %di
    popl %ecx
    popl %edx
    popl %ebx
    leave
    ret
    #################################################################

    
    #################################################################
    # creates a GDT (or LDT) entry at given index and with given type
    # bool make_gdt_entry(addr_16 gdt_base, u_int_16 index, SegmentType type)
    #                          ^^                 ^^
    # enum SegmentType
    # {
    #   DATA=1, CODE=2, TSS=4, NULL=0
    # }

write_gdt_entry:
    # (REM) gdt_base, index, type
    pushw %bp
    movw  %sp,%bp
    pushl %ebx
    pushl %ecx
    pushl %edx
    pushl %esi 
    pushl %edi

    # gdt_base -> %eax
    movl 4(%bp), %eax
    # index -> %ebx
    movl 8(%bp), %ebx
    # esi is set to the destination gdt entry address
    lea (%eax, %ebx, 8), %esi

    # type-> %al
    movb 12(%bp), %al
    # type == 0x00 ?
    testb %al, %al
    jz 4f
    # type == 0x01 ?
    shr $1, %al
    test %al, %al
    jz 1f
    # type == 0x02 ?
    shr $1, %al
    test %al, %al
    jz 2f
    # type == 0x04 ?
    shr $1, %al
    test %al, %al
    jz 3f
    # /else nop
    jmp 5f
    
    # /if type == DATA:
1:
    # flags same as for CODE segment
    # TYPE = 0b0110 (bit 11:8) [RW data, expand-down]
    movl $0x00C09600, %ecx
    jmp 6f

    # /if type == CODE:
2:
    # G = 1 (bit 23) granularity
    # S = 1 (bit 12) data or code seg.
    # D/B = 1 (bit 22) always set to 1 for 32bit segments
    # P = 1 (bit 15) segment present
    # TYPE = 0b1010 (bit 11:8) [RX code, conforming]
    movl $0x00C09A00, %ecx
6:  
    # base is set to 0x0 and limit to the max memory available
    # bytes 0:3 [base 15:0, limit 15:0] in %ebx
    movl $0, %ebx
    call get_ram_size
    jc 7f
    # divide by 4*2^10 = 4KiB to obtain segment limit (given granularity G=1)
    shr $12, %eax
    # move segment_limit [15:0] to %bl
    movb %al, %bl
    movl %ebx, (%esi)

    # bytes 4:7 [flags and partial base and limit]in %ebx
    movl $0, %ebx
    # SEG LIM [19:16] (bit 19:16)
    movb %ah, %bl
    shr $16, %ebx
    orl %ecx, %ebx
    movl %ebx, 4(%esi)
    # all the rest is 0x00, both flags and base segment address parts
    jmp 5f
    
    # /if type == TSS:
3:
    
    jmp 5f

    # /if type == NULL:
4:  
    movl $0, (%esi)
    movl $0, 4(%esi)
    jmp 5f

    # /error
7:  
    movl $0x00, %eax
    jmp 8f
5:
    movl $0x1, %eax
8:  
    popl %edi
    popl %esi
    popl %edx
    popl %ecx
    popl %ebx
    leave
    ret

#################################################################

    #
    # Macro definitions
    #
    
# GDT data
#gdt_pointer:
#	.word 0x? #gdt limit
#	.long 0x? #gdt base

