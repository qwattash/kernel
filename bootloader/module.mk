#
# Top level makefile for the bootloader module
#

CURRENT := $(call anrem-current-path)

boot_BUILD_DIR := $(CURRENT)/boot

#module specific toolchain and toolchain options

#define module params
BOOT_HDD := $(boot_BUILD_DIR)/boot.vdi
BOOT_MERGED := $(boot_BUILD_DIR)/boot.hd
#external params
STAGE1_IN := $(CURRENT)/stage1/mbr.sect
STAGE2_IN := $(CURRENT)/stage2/stage2.out

$(call anrem-target, $(BOOT_HDD)): $(BOOT_MERGED)
# Create a vdi from raw boot.hd
	rm -f $@
	$(VBOXMANAGE) $(VBOXMANAGEFLAGS) $^ $@

$(call anrem-target, $(BOOT_MERGED)): $(STAGE1_IN) $(STAGE2_IN)
# Create a raw disk containing the MBR (stage1) and stage2
	$(DD) if=/dev/zero bs=$(DDBLOCKSIZE) count=$(call dd-count, $^) | cat $^ - > $@

$(call anrem-target, runvm): $(BOOT_MERGED)
	$(VBOX) $(VBOXFLAGS) $(BOOT_MERGED)

$(call anrem-target, boot_clean):
	rm -f $(BOOT_HDD) $(BOOT_MERGED)

$(call anrem-build, $(BOOT_HDD))
$(call anrem-clean, boot_clean)
