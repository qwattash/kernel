#makefile rules for stage 1

CURRENT := $(call anrem-current-path)

#define module params
STAGE1_SOURCES := $(CURRENT)/stage1.s
STAGE1_OBJS := $(patsubst %.s, %.o, $(STAGE1_SOURCES))
STAGE1_TARGET := $(CURRENT)/mbr.sect

$(call anrem-target, $(STAGE1_TARGET)): $(STAGE1_OBJS)
	$(LD) $(LDFLAGS) --Ttext=0x7c00 -oformat=binary -o $(addsuffix .out, $@) $^
	objcopy -O binary $(addsuffix .out, $@) $@
	rm -f $(addsuffix .out, $@)

$(call anrem-target, $(STAGE1_OBJS)): $(STAGE1_SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $^

$(call anrem-target, stage1_clean):
	rm -rf $(STAGE1_OBJS) $(STAGE1_TARGET)

$(call anrem-build, $(STAGE1_TARGET))
$(call anrem-clean, stage1_clean)
