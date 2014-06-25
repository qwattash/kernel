#
# Top level makefile for the bootloader module
#

CURRENT := $(call anrem-current-path)

boot_BUILD_DIR := $(CURRENT)/boot

#module specific toolchain and toolchain options

#define module params
HDD_VDI := $(boot_BUILD_DIR)/hdd.vdi
HDD_IMG := $(boot_BUILD_DIR)/hdd.img
#external params
STAGE1_IN := $(CURRENT)/stage1/mbr.sect
STAGE2_IN := $(CURRENT)/stage2/stage2.out

$(call anrem-build, $(HDD_VDI)): $(HDD_IMG)
	rm -f $@
	$(VBOXMANAGE) $(VBOXMANAGEFLAGS) $^ $@

$(call anrem-target, $(HDD_IMG)): $(STAGE1_IN)
	$(VBOXMANAGE) clonehd $(HDD_VDI) $@.new --format RAW
	mv $@.new $@
	$(DISKMGMT) mbr $@ $^

#$(HDD_VDI).fin: $(HDD_IMG).fin
#	--image->vdi
#
#$(HDD_IMG).fin: $(STAGE1_IN) $(HDD_IMG).tmp
#	--mod->img
#
#$(HDD_IMG).tmp: $(HDD_VDI).tmp
#	--first-line
#
#$(HDD_VDI).tmp: #<<softlink
#	--gen-disk

$(call anrem-target, gen-disk):
	rm -f $(HDD_IMG)
	$(DISKMGMT) create $(HDD_IMG) $(HDDSIZE)
	sudo $(DISKMGMT) format $(HDD_IMG) $(FIRSTP_FS) $(FIRSTP_START) $(FIRSTP_END)
	$(DISKMGMT) active $(HDD_IMG) $(FIRSTP_INDEX)
	$(VBOXMANAGE) $(VBOXMANAGEFLAGS) $(HDD_IMG) $(HDD_VDI)

$(call anrem-target, runvm): $(HDD_VDI)
	$(VBOX) $(VBOXFLAGS)

$(call anrem-target, disk-clean):
	rm -f $(HDD_IMG) $(HDD_VDI)


### DEPRECATED - START
#$(call anrem-target, $(HDD_IMG)): $(STAGE1_IN) $(STAGE2_IN)
# Create a raw disk containing the MBR (stage1) and stage2
#	$(DD) if=/dev/zero bs=$(DDBLOCKSIZE) count=$(call dd-count, $^) | cat $^ - > $@
### DEPRECATED - END
