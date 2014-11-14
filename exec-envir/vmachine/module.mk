#
# Makefile for the execution envirnoment / vmachine section
#

CURRENT := $(call anrem-current-path)

#vars
$(<@)
$(@)VM_NAME := Kernel

#paths
$(@)ABS_CURRENT := $(abspath $(CURRENT))
$(@)VM_VBOX := $(CURRENT)/$(call anrem-local-get, VM_NAME)/$(call anrem-local-get, VM_NAME).vbox
$(@)BOOT_VDI := $(exec|boot)/hdd.vdi
$(@)BOOT_VDI_ORIG := $(exec|boot)/hdd.vdi.orig
$(@)BOOT_IMG := $(exec|boot)/hdd.img

$(@>)

$(call anrem-target, vm-run) : $(@BOOT_VDI) $(@VM_VBOX)
	VBoxManage startvm $(@VM_NAME) --type sdl

$(call anrem-target, vm-debug) : $(@BOOT_VDI) $(@VM_VBOX)
	VirtualBox --startvm $(@VM_NAME) --debug

$(call anrem-target, @VM_VBOX) : 
	VBoxManage createvm --name $(@VM_NAME) --basefolder $(@ABS_CURRENT) --ostype "Other" --register
	VBoxManage storagectl $(@VM_NAME) --name "sata0" --add sata --portcount 1 --bootable on
	VBoxManage storageattach $(@VM_NAME) --storagectl "sata0" --type hdd --port 0 --medium $(@BOOT_VDI)
	VBoxManage modifyvm $(@VM_NAME) --description "A kernel for fun." --memory 512 --cpus 1 --boot1 disk

$(call anrem-target, vm-clean) :
	rm -f $(@BOOT_VDI_ORIG) $(@BOOT_IMG)
	VBoxManage unregistervm $(@VM_NAME) --delete	

