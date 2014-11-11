#makefile rules for stage 2

CURRENT := $(call anrem-current-path)

$(<@)
#define module params
$(@)STAGE2_SOURCES := $(CURRENT)/stage2.S
$(@)STAGE2_OBJS := $(patsubst %.S, %.o, $(call anrem-local-get, STAGE2_SOURCES))
$(@)STAGE2_TARGET := $(CURRENT)/stage2.out
$(@>)

$(call anrem-target, @STAGE2_OBJS): $(@STAGE2_SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $^

$(call anrem-clean):
	rm -rf $(@STAGE2_OBJS) $(@STAGE2_TARGET)
