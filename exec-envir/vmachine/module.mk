#
# Makefile for the execution envirnoment / vmachine section
#

#vars
$(<@)
$(@)VM_NAME := Kernel

#paths
$(@)CURRENT := $(call anrem-current-path)
$(@)ABS_CURRENT := $(shell readlink -f $(CURRENT))
$(@)VM_VBOX := $(CURRENT)/$(VM_NAME)/$(VM_NAME).vbox
$(@)BOOT_VDI := $(exec|boot)/hdd.vdi

$(@>)

$(call anrem-target, vm-run) : $(@VM_VBOX)
	VBoxManage startvm $(@VM_NAME) --type sdl

$(call anrem-target, @VM_VBOX) : 
	VBoxManage createvm --name $(@VM_NAME) --basefolder $(@ABS_CURRENT) --ostype "Other" --register
	VBoxManage storagectl $(@VM_NAME) --name "sata0" --add sata --portcount 1 --bootable on
	VBoxManage storageattach $(@VM_NAME) --storagectl "sata0" --type hdd --port 0 --medium $(@BOOT_VDI)
	VBoxManage modifyvm $(@VM_NAME) --description "A kernel for fun." --memory 512 --cpus 1 --boot1 disk

$(call anrem-target, vm-clean) :
	VBoxManage unregistervm $(@VM_NAME) --delete	
