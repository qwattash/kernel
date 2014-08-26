#
# Top level makefile for the bootloader module
#

#paths
CURRENT := $(call anrem-current-path)
BOOT_DIR := $(CURRENT)/boot
HDD_VDI := $(BOOT_DIR)/hdd.vdi
HDD_IMG := $(BOOT_DIR)/hdd.img

#external modules
STAGE1_IN := $(CURRENT)/stage1/mbr.sect
STAGE2_IN := $(CURRENT)/stage2/stage2.out

#VirtualBox vars
VBOX := VirtualBox
VBOXFLAGS := --debug --startvm Kernel

#VBoxManage vars
VBOXMANAGE := VBoxManage
VBOXMANAGEFLAGS := convertfromraw --uuid 84e10c7b-5fa0-4c91-9ed1-722b372570ee -format VDI

#qemu-img
QEMUIMG := qemu-img
QEMUIMGFLAGS := convert -f vdi -O raw

#disk-mgmt-tool vars
DISKMGMT := python bootloader/utils/disk-mgmt-tool/diskmgmt.py
HDDSIZE := 128 # in MiB
#first partition: Size 64MiB; Sectors 2048-133120; Type FAT32; Index 1.
FIRSTP_START := 2048
FIRSTP_END := 133120
FIRSTP_FS := fat32
FIRSTP_INDEX := 1

$(call anrem-build, $(HDD_VDI)) : $(HDD_IMG)
	rm -f $@
	$(VBOXMANAGE) $(VBOXMANAGEFLAGS) $^ $@

$(call anrem-target, $(HDD_IMG)): $(STAGE1_IN) $(HDD_VDI).orig
	rm -f $@
	$(QEMUIMG) $(QEMUIMGFLAGS) $(HDD_VDI) $@
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
