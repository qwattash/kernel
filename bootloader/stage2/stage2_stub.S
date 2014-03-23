####
#
# stage 2 test
#
#####

#video memory
.equ VIDEO_MEM, 0xB8000

.text
.code32
.global start, _start, entry_point
entry_point:
start:
_start: 
    #protected mode entry point
    #write a char to top-left screen
    movl $VIDEO_MEM, %eax
    movb $'K', (%eax)
endloop:
    jmp endloop
