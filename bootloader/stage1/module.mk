#makefile import for the stage1 boot loader

#define module params
STAGE1_SOURCES := stage1/stage1.s
STAGE1_OBJS := $(patsubst %.s, %.o, $(STAGE1_SOURCES))
STAGE1_TARGET := stage1/mbr.sect

#define target MBR sector

CLEAN += $(STAGE1_OBJS) $(STAGE1_TARGET)

$(STAGE1_TARGET): $(STAGE1_OBJS)
	$(LD) $(LDFLAGS) --Ttext=0x7c00 -oformat=binary -o $(addsuffix .out, $@) $^
	objcopy -O binary $(addsuffix .out, $@) $@
	rm -f $(addsuffix .out, $@)

$(STAGE1_OBJS): $(STAGE1_SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
