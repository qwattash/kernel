#makefile rules for the stage 2

CURRENT := $(call anrem-current-path)

#define module params
$(<@)
$(@)STAGE2_CSOURCES := $(wildcard $(CURRENT)/*.c)
$(@)STAGE2_COBJS := $(patsubst %.c, %.o, $(call anrem-local-get, STAGE2_CSOURCES))
$(@)STAGE2_TARGET := $(CURRENT)/stage2.out

#the stub is placed by the linker script at the top of the image
$(@)STAGE2_STUB := $(CURRENT)/stage2_stub.s
$(@)STAGE2_STUB_OBJ := $(patsubst %.s, %.o, $(call anrem-local-get, STAGE2_STUB))

#linker script
$(@)LD_SCRIPT := $(CURRENT)/flat_mmap.ld

$(@>)

$(call anrem-target, @STAGE2_COBJS): $(@STAGE2_CSOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<

$(call anrem-target, @STAGE2_STUB_OBJ): $(@STAGE2_STUB)
	$(CC) $(CFLAGS) -c -o $@ $^

$(call anrem-build, @STAGE2_TARGET): $(@STAGE2_STUB_OBJ) $(@STAGE2_COBJS)
	$(LD) $(LDFLAGS) -oformat=binary -T $(@LD_SCRIPT) -o $(path)/stage2.tmp $^
	objcopy -O binary $(path)/stage2.tmp $@
	rm $(path)/stage2.tmp

$(call anrem-clean):
	rm -rf $(@STAGE2_COBJS) $(@STAGE2_TARGET) $(@STAGE2_STUB_OBJ)
