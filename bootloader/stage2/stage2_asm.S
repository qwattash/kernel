#####
#
# stage 2
#
#####

#include "stage2.h"
   
.code16

##
# the stage 2 image is placed from 0x7e00 in memory after the mbr code
# and is stored in the vbr and immediately following sectors in the fat32
# boot partition 
#             

.text
stage2_start:     

# Switch to Protected Mode

# Write GDT
    # index 0 = null
    pushl $0x00
    pushl $0x00
    pushl $GDT_BASE 
    call write_gdt_entry
    addw $0x0C, %sp
    # index 1 = code segment
    pushl $0x02
    pushl $0x01
    pushl $GDT_BASE
    call write_gdt_entry
    addw $0x0C, %sp
    # index 2 = data segment
    pushl $0x01
    pushl $0x02
    pushl $GDT_BASE
    call write_gdt_entry
    addw $0x0C, %sp
    # index 3 = tss segment
    pushl $0x04
    pushl $0x03
    pushl $GDT_BASE
    call write_gdt_entry
    addw $0x0C, %sp
    # index 4-7 = null
    pushl $0x00
    pushl $0x04
    pushl $GDT_BASE
    call write_gdt_entry
    addw $0x0C, %sp
    pushl $0x00
    pushl $0x05
    pushl $GDT_BASE
    call write_gdt_entry
    addw $0x0C, %sp
    pushl $0x00
    pushl $0x06
    pushl $GDT_BASE
    call write_gdt_entry
    addw $0x0C, %sp
    pushl $0x00
    pushl $0x07
    pushl $GDT_BASE
    call write_gdt_entry
    addw $0x0C, %sp
    
# fill the TSS with ESP0/SS0
    call get_ram_size
    jc 1f
    movw $TSS_BASE, %bx
    movl %eax, 4(%bx)
    movw $0x10, 8(%bx)
    jmp 2f
1:
    pushw $get_ram_size_error
    call error
2:  
# A20 Gate
    call enable_A20
    jc 1f
    call check_A20
    jnc 2f
1:
    pushw $a20_error
    call error
2:  
# disable interrupts
    cli

# load gdtr register
    lgdt gdt_pointer 

# set PE flag in CR0
# bit 0 = Protected Mode Enable
    mov %cr0, %eax
    or $0x1, %al
    mov %eax, %cr0

# ljmp to next instruction
# all segment selectors are reset due to ljmp except CS
# syntax: ljmp new_index_for_CS, new_addres_for_EIP
# CS[15:3] contains GDT index
    ljmp $0x08, $next
next:
.code32

    
# load the task register
    movw $0x18, %ax
    ltr %ax

# reload remaining segment selectors
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    movl $TSS_BASE, %eax
    movl 4(%eax), %esp
    #movl $0x00, 0xfffff
    #pushl %eax
    #popl %eax
dbg:
    jmp dbg
    
# Call c_main
    call cmain
endstage:
    hlt
    jmp endstage

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
    clc
    jnz 1f
    stc
1:
    leave
    ret
    #################################################################
    
    #################################################################
    # bool enable_a20(void)
    # In case of error (activation failed) the carry flag is set
enable_A20: 
    pushw           %bp
    movw            %sp,%bp
    # BIOS int INT 0x15 (AX=0x2401) (Enable A20 Gate).
    clc
    movw $0x2401,   %ax
    int $0x15
    #// if CF is set an error occurred
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
    # bool make_gdt_entry(addr_32 gdt_base, u_int_32 index, SegmentType type)
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
    # TYPE = 0b0110 (bit 11:8) [RW data, expand-up]
    movl $0x00C09200, %ecx
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
    # bytes 0:3 [base 15:0, limit 15:0] in %ebx
    movl $TSS_BASE, %ebx
    shl $16, %ebx
    movl $TSS_LIMIT, %eax
    movw %ax, %bx
    movl %ebx, (%esi)

    # the only difference with a code/data segment are
    # S = 0 (bit 12) system segment
    # TYPE = 0b1011 (bit 11:8) [32bit TSS Free]
    # G = 0 (bit 23) byte granularity
    # bytes 4:7 [flags and partial base and limit]in %ebx

    # load bit 31:24 of TSS base
    movl $TSS_BASE, %ebx
    shr $16, %ebx
    movb $0, %bl
    shl $16, %ebx
    # load bit 23:16 of TSS base
    movl $TSS_BASE, %eax
    shr $16, %eax
    movb $0, %ah
    movw %ax, %bx
    # load bit 19:16 of TSS limit
    movl $TSS_LIMIT, %eax
    shr $16, %eax
    orl %eax, %ebx
    movl $0x00008900, %ecx
    orl %ecx, %ebx
    movl %ebx, 4(%esi)
    
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
    
# GDT base and limit
gdt_pointer:
	.word GDT_LIMIT
	.long GDT_BASE

#data strings
a20_error:    
    .asciz "Error while enabling A20 pin.\r\n"
get_ram_size_error:
    .asciz "Error while estimating max ram size.\r\n"
