#
# Top level makefile for the bootloader module
#

#include submodules
BASE_$(DIR) := $(DIR)
DIR += /boot
include $(DIR)/module.mk

DIR += /stage1
include $(DIR)/module.mk

DIR += /stage2
include $(DIR)/module.mk

