#
# Top level makefile for the bootloader module
#

CURRENT := $(call anrem-current-path)

boot_BUILD_DIR := $(CURRENT)/boot

#module specific toolchain and toolchain options
VBOX := VBoxManage
VBOXFLAGS := convertfromraw  --uuid 84e10c7b-5fa0-4c91-9ed1-722b372570ed -format VDI
DD := dd

#define module params
BOOT_HDD := $(boot_BUILD_DIR)/boot.vdi
BOOT_MERGED := $(boot_BUILD_DIR)/boot.hd
#external params
STAGE1_IN := $(CURRENT)/stage1/mbr.sect
STAGE2_IN := $(CURRENT)/stage2/stage2.out

$(call anrem-target, $(BOOT_HDD)): $(BOOT_MERGED)
# Create a vdi from raw boot.hd
	rm -f $@
	$(VBOX) $(VBOXFLAGS) $^ $@

$(call anrem-target, $(BOOT_MERGED)): $(STAGE1_IN) $(STAGE2_IN)
	$(DD) if=/dev/zero bs=$(DDBLOCKSIZE) count=$(call dd-count, $^) | cat $^ - > $@

$(call anrem-target, boot_clean):
	rm -rf $(BOOT_HDD) $(BOOT_MERGED)

$(call anrem-build, $(BOOT_HDD))
$(call anrem-clean, boot_clean)
