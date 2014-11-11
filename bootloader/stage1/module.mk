#makefile rules for stage 1

CURRENT := $(call anrem-current-path)

$(<@)
#define module params
$(@)STAGE1_SOURCES := $(CURRENT)/stage1.S
$(@)STAGE1_OBJS := $(patsubst %.S, %.o, $(call anrem-local-get, STAGE1_SOURCES))
$(@)STAGE1_TARGET := $(CURRENT)/mbr.sect
$(@>)

$(call anrem-target, @STAGE1_OBJS): $(@STAGE1_SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $^

$(call anrem-clean):
	rm -rf $(@STAGE1_OBJS) $(@STAGE1_TARGET)
