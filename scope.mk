# create a namespace for the bootloader
$(call anrem-ns-register, ./bootloader, bootloader)

# create namespace for the execution environment
$(call anrem-ns-register, ./exec-envir, exec)
