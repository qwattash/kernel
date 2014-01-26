#makefile import for 'boot' goal

#module specific toolchain and toolchain options
VBOX := VBoxManage
VBOXFLAGS := convertfromraw  --uuid 84e10c7b-5fa0-4c91-9ed1-722b372570ed -format VDI
DD := dd

#define module params
BOOT_TARGET := boot/boot.vdi
BOOT_MERGED := boot/boot.hd
#external params
STAGE1_IN := stage1/mbr.sect
STAGE2_IN := stage2/stage2.out

#define target for 'boot' goal
CLEAN += $(BOOT_TARGET) $(BOOT_MERGED)

$(BOOT_TARGET): $(BOOT_MERGED)
    # Create a vdi from raw boot.hd
	rm -f $@
	$(VBOX) $(VBOXFLAGS) $^ $@

$(BOOT_MERGED): $(STAGE1_IN) $(STAGE2_IN)
    # need to add enouth data to cross the 1MB boundary, otherwise the VBoxManage tool
	# @todo automatic count generation for $(DD)
	$(DD) if=/dev/zero bs=512 count=2878 | cat $^ - > $@
