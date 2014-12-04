#
# Makefile for the execution envirnoment / boot section
#

#paths
CURRENT := $(call anrem-current-path)
$(<@)
$(@)HDD_VDI := $(CURRENT)/hdd.vdi
$(@)HDD_IMG := $(CURRENT)/hdd.img
#bootloader stages paths
$(@)BOOTLOADER_IMG := $(|bootloader)/bootloader.out

#disk-mgmt-tool vars
$(@)DISKMGMT := python $(|exec)/utils/disk-mgmt-tool/diskmgmt.py
$(@)HDDSIZE := 128 # in Mi
$(@)DISK_UUID := 84e10c7b-5fa0-4c91-9ed1-722b372570ee
#first partition: Size 64MiB; Sectors 2048-133120; Type FAT32; Index 1.
$(@)FIRSTP_START := 2048
$(@)FIRSTP_END := 133120
$(@)FIRSTP_FS := fat32
$(@)FIRSTP_INDEX := 1

$(@>)

$(call anrem-build, @HDD_VDI) : $(@HDD_IMG)
	rm -f $@
	VBoxManage convertfromraw --uuid $(@DISK_UUID) -format VDI $^ $@

$(call anrem-target, @HDD_IMG): $(@BOOTLOADER_IMG) $(@HDD_VDI).orig
	rm -f $@
	qemu-img convert -f vdi -O raw $(@HDD_VDI) $@
	$(@DISKMGMT) inject $@ $(@BOOTLOADER_IMG) 0   446 0
	$(@DISKMGMT) inject $@ $(@BOOTLOADER_IMG) 512 -1 512

$(call anrem-target, $(@HDD_VDI).orig) :
	$(@DISKMGMT) create $(@HDD_IMG) $(@HDDSIZE)
	sudo $(@DISKMGMT) format $(@HDD_IMG) $(@FIRSTP_FS) $(@FIRSTP_START) $(@FIRSTP_END)
	$(@DISKMGMT) active $(@HDD_IMG) $(@FIRSTP_INDEX)
	VBoxManage convertfromraw --uuid $(@DISK_UUID) -format VDI $(@HDD_IMG) $(@HDD_VDI)
	ln $(@HDD_VDI) $@ 

$(call anrem-target, disk-clean):
	rm -f $(@HDD_IMG) $(@HDD_VDI) $(@HDD_VDI).orig
