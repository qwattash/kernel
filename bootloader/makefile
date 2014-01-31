#toolchain
CC := gcc
LD := ld

#toolchain options
CFLAGS := -Wall -Wno-implicit-function-declaration -g -m32 -nostdlib -nodefaultlibs -nostartfiles -fno-builtin
ASMFLAGS := 
LDFLAGS := -m elf_i386
LDASMFLAGS := 

#targets
MODULES := boot stage1 stage2

#C sources loaded by modules
C_SRC :=
#C header files loaded by modules
HEADERS := 
#ASM source files loaded by modules
A_SRC := 
#final targets defined by modules to be added to the all rule
TARGETS := boot/boot.vdi
#cleaning list
CLEAN := 

C_OBJS := $(C_SRC:.c=.o)
A_OBJS := $(A_SRC:.s=.o)


#global target defined by modules

.PHONY: all
all: $(TARGETS)

clean: 
	rm -rf $(CLEAN)

include $(patsubst %, %/module.mk, $(MODULES))
