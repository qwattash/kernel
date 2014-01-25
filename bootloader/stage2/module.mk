#makefile import for the stage1 boot loader

#define module params
STAGE2_CSOURCES := $(wildcard stage2/*.c)
STAGE2_ASOURCES := $(wildcard stage2/*.s)
STAGE2_COBJS := $(patsubst %.c, %.o, $(STAGE2_CSOURCES))
STAGE2_AOBJS := $(patsubst %.s, %_a.o, $(STAGE2_ASOURCES))
STAGE2_TARGET := stage2/stage2.out

#define target for the stage2 image

CLEAN += $(STAGE2_COBJS) $(STAGE2_AOBJS) $(STAGE2_TARGET)

$(STAGE2_COBJS): $(STAGE2_CSOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<

$(STAGE2_AOBJS): $(STAGE2_ASOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<

$(STAGE2_TARGET): $(STAGE2_COBJS) $(STAGE2_AOBJS)
	$(LD) $(LDFLAGS) -Ttext=0x7e00 -oformat=binary -o stage2/stage2.tmp $^
	objcopy -O binary stage2/stage2.tmp $@
	rm stage2/stage2.tmp
