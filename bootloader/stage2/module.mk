#makefile rules for stage 2

CURRENT := $(call anrem-current-path)

$(<@)
#define module params
$(@)STAGE2_SOURCES := $(CURRENT)/stage2_asm.S
$(@)STAGE2_OBJS := $(patsubst %.S, %.o, $(call anrem-local-get, STAGE2_SOURCES))
$(@)STAGE2_C_SOURCES := $(CURRENT)/stage2_c.c
$(@)STAGE2_C_OBJS := $(patsubst %.c, %.o, $(call anrem-local-get, STAGE2_C_SOURCES))
$(@>)

$(call anrem-target, @STAGE2_OBJS): $(@STAGE2_SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $^

$(call anrem-target, @STAGE2_C_OBJS): $(@STAGE2_C_SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $^

$(call anrem-clean):
	rm -rf $(@STAGE2_OBJS)
	rm -rf $(@STAGE2_C_OBJS)
