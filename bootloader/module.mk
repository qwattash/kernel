# build the bootloader image containing all the stages

CURRENT := $(call anrem-current-path)

$(<@)
#define module params
$(@)OBJS := $(bootloader|stage1)/stage1.o $(bootloader|stage2)/stage2.o
$(@)TARGET := $(CURRENT)/bootloader.out
$(@)LD_MAP := $(CURRENT)/flat_mmap.ld
$(@>)

$(call anrem-target, @TARGET): $(@OBJS)
	$(LD) $(LDFLAGS) -T $(@LD_MAP) -oformat=binary -o $(addsuffix .out, $@) $^
	objcopy -O binary $(addsuffix .out, $@) $@
	rm -f $(addsuffix .out, $@)
