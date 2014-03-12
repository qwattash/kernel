#
# This configuration file aims to provide centralised access to general
# variables in the make process, this is where to define global constants
# and override implicit make variables
#
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
DDBLOCKSIZE := 512
VBOXMINSIZE := 1048576
