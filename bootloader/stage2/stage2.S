####
#
# stage 2 test
#
#####
    
.code16
    
.text
vbr_start: 
    #protected mode entry point
    #write a char to top-left screen
    movw $welcome_to_st2, %ax
    call bios_strprint
endloop:
    jmp endloop
welcome_to_st2:  .asciz "Welcome to the magic land of stage 2!"
