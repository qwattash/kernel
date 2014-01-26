#toolchain
CC := gcc
LD := ld
VBOX := VBoxManage

#toolchain options
VBOXFLAGS := convertfromraw  --uuid 84e10c7b-5fa0-4c91-9ed1-722b372570ed -format VDI
CFLAGS := -Wall -Wno-implicit-function-declaration -g -m32 -nostdlib -nodefaultlibs -nostartfiles -fno-builtin
ASMFLAGS := 
LDFLAGS := -m elf_i386
LDASMFLAGS := 

#targets
MODULES := stage1 stage2

#C sources loaded by modules
C_SRC :=
#C header files loaded by modules
HEADERS := 
#ASM source files loaded by modules
A_SRC := 
#final targets defined by modules to be added to the all rule
TARGETS := boot.vdi
#cleaning list
CLEAN := boot

C_OBJS := $(C_SRC:.c=.o)
A_OBJS := $(A_SRC:.s=.o)


#global target defined by modules

.PHONY: all
all: $(TARGETS)

boot.vdi: boot.hd
    # Create a vdi from raw boot.sect.
	rm -f boot/boot.vdi
	mkdir boot
	mv boot.hd boot/
    # Fixed uuid allows easy testing with VirtualBox
	$(VBOX) $(VBOXFLAGS) boot/boot.hd boot/boot.vdi

boot.hd: stage1/mbr.sect stage2/stage2.out
        # boot.sect is 2*512 byte.
        # need to add enouth data to cross the 1MB boundary, otherwise the VBoxManage tool
        # will not create the disk
	dd if=/dev/zero bs=512 count=2878 | cat stage1/mbr.sect stage2/stage2.out - > boot.hd

clean: 
	rm -rf $(CLEAN)

include $(patsubst %, %/module.mk, $(MODULES))
