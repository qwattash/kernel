####
#
# stage 2 test
#
#####

#video memory
.equ VIDEO_MEM, 0xA000

.text
.code32
entry_point:
    #protected mode entry point
    #write a char to top-left screen
    #movl $VIDEO_MEM, %eax
    #movb 'W', (%eax)
1:
    jmp 1b
