all: clean boot.iso

boot.iso: boot.fd
	mkdir boot
	cp boot.fd boot/
	mkisofs -b boot/boot.fd -V bootv0 -o boot.iso .

boot.fd: boot.sect
#pad bootsectro to be 1.44M = 1474560 bytes
#consider boot.sect to be = 512bytes
	dd if=/dev/zero bs=512 count=2879 | cat boot.sect - > boot.fd
#dd if=/dev/zero bs=512 count=2814 | cat boot.sect - > boot.fd


boot.sect: boot.o
	ld -m elf_i386 --Ttext=0x7c00 -oformat=binary -o boot.out boot.o
	objcopy -O binary boot.out boot.sect

boot.o: boot.s
	as --32  boot.s -o boot.o

clean:
	rm -rf boot.fd boot.sect boot.o boot boot.iso boot.out

