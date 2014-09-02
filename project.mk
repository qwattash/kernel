#
# kernel Project makefile
#

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

