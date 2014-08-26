#architecture
ARCH := i386

#toolchain
CC := gcc
LD := ld

#toolchain options
CFLAGS := -Wall -Wno-implicit-function-declaration -g -m32 -nostdlib -nodefaultlibs -nostartfiles -fno-builtin
ASMFLAGS := 
LDFLAGS := -m elf_i386
LDASMFLAGS := 

#
# configuration variables for VirtualBox and VBoxManage
#
VBOXMINSIZE := 1048576
VBOX := VirtualBox
VBOXFLAGS := --debug --startvm Kernel
VBOXMANAGE := VBoxManage
VBOXMANAGEFLAGS := convertfromraw --uuid 84e10c7b-5fa0-4c91-9ed1-722b372570ee -format VDI

#
# configuration variables for disk-mgmt-tool
#
DISKMGMT := python bootloader/utils/disk-mgmt-tool/diskmgmt.py
HDDSIZE := 128 # in MiB
##
## 1st partition
## 64 MiB (sectors 2048 - 133120)
## fat32
##
FIRSTP_START := 2048
FIRSTP_END := 133120
FIRSTP_FS := fat32
FIRSTP_INDEX := 1

