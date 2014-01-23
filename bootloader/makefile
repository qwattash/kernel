all: clean boot.vdi

boot.vdi: boot.hd
    # Create a vdi from raw boot.sect.
	rm -f boot/boot.vdi
	mkdir boot
	cp boot.hd boot/
    # Fixed uuid allows easy testing with VirtualBox
	VBoxManage convertfromraw  --uuid 84e10c7b-5fa0-4c91-9ed1-722b372570ed -format VDI boot/boot.hd boot/boot.vdi

boot.hd: boot.sect stage2.out
        # boot.sect is 2*512 byte.
        # A correct concatention requires count to be 2880-2=2878.
	dd if=/dev/zero bs=512 count=2878 | cat boot.sect stage2.out - > boot.hd
#cat boot.sect stage2.out > boot.hd

boot.sect: boot.o
	ld -m elf_i386 --Ttext=0x7c00 -oformat=binary -o boot.out boot.o
	objcopy -O binary boot.out boot.sect

boot.o: boot.s
	as --32  boot.s -o boot.o

stage2.o: stage2.c stage2.s
	gcc -m32 -nostdlib -nodefaultlibs -nostartfiles -c -o stage2.o stage2.c
	gcc -m32 -c stage2.s -o a_stage2.o

stage2.out: stage2.o a_stage2.o
	ld -m elf_i386 -Ttext=0x7e00 -oformat=binary -o stage2.tmp stage2.o a_stage2.o
	objcopy -O binary stage2.tmp stage2.out
	rm stage2.tmp

clean:
	rm -rf boot.fd boot.sect boot.o boot boot.iso boot.out stage2.out stage2.o
