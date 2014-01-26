#makefile import for the stage1 boot loader

#define module params
STAGE2_CSOURCES := $(wildcard stage2/*.c)
STAGE2_COBJS := $(patsubst %.c, %.o, $(STAGE2_CSOURCES))
STAGE2_TARGET := stage2/stage2.out

#the stub is placed by the linker script at the top of the image
STAGE2_STUB := stage2/stage2_stub.s
STAGE2_STUB_OBJ := $(patsubst %.s, %.o, $(STAGE2_STUB))

#define target for the stage2 image

CLEAN += $(STAGE2_COBJS) $(STAGE2_TARGET) $(STAGE2_STUB_OBJ)

#linker script
LD_SCRIPT := stage2/flat_mmap.ld

$(STAGE2_COBJS): $(STAGE2_CSOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<

$(STAGE2_STUB_OBJ): $(STAGE2_STUB)
	$(CC) $(CFLAGS) -c -o $@ $^

$(STAGE2_TARGET): $(STAGE2_STUB_OBJ) $(STAGE2_COBJS)
	$(LD) $(LDFLAGS) -oformat=binary -T $(LD_SCRIPT) -o stage2/stage2.tmp $^
	objcopy -O binary stage2/stage2.tmp $@
	rm stage2/stage2.tmp
