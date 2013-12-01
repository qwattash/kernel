all: clean boot.vdi

boot.vdi: boot.fd
    # Create a vdi from raw boot.sect.
	rm -f boot/boot.vdi
	cp boot.fd boot/
    # Fixed uuid allows easy testing with VirtualBox
	VBoxManage convertfromraw  --uuid 84e10c7b-5fa0-4c91-9ed1-722b372570ed -format VDI boot.fd boot/boot.vdi

boot.fd: boot.sect
    # boot.sect is 2*512 byte.
    # A correct concatention requires count to be 2880-2=2878.
	dd if=/dev/zero bs=512 count=2878 | cat boot.sect - > boot.fd

boot.sect: boot.o
	ld -m elf_i386 --Ttext=0x7c00 -oformat=binary -o boot.out boot.o
	objcopy -O binary boot.out boot.sect

boot.o: boot.s
	as --32  boot.s -o boot.o

clean:
	rm -rf boot.fd boot.sect boot.o boot boot.iso boot.out

