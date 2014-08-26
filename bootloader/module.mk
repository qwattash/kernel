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

$(call anrem-build, $(HDD_VDI)) : $(HDD_IMG)
	rm -f $@
	$(VBOXMANAGE) $(VBOXMANAGEFLAGS) $^ $@

$(call anrem-target, $(HDD_IMG)): $(STAGE1_IN) $(HDD_VDI).orig
	rm -f $@
	@#$(VBOXMANAGE) clonehd $(HDD_VDI) $@ --format RAW
	qemu-img convert -f vdi $(HDD_VDI) -O raw $@
	$(DISKMGMT) mbr $@ $(STAGE1_IN)

$(call anrem-target, $(HDD_VDI).orig) :
	$(DISKMGMT) create $(HDD_IMG) $(HDDSIZE)
	sudo $(DISKMGMT) format $(HDD_IMG) $(FIRSTP_FS) $(FIRSTP_START) $(FIRSTP_END)
	$(DISKMGMT) active $(HDD_IMG) $(FIRSTP_INDEX)
	$(VBOXMANAGE) $(VBOXMANAGEFLAGS) $(HDD_IMG) $(HDD_VDI)
	ln $(HDD_VDI) $@ 

$(call anrem-target, runvm): $(HDD_VDI)
	$(VBOX) $(VBOXFLAGS)

$(call anrem-target, disk-clean):
	rm -f $(HDD_IMG) $(HDD_VDI) $(HDD_VDI).orig
