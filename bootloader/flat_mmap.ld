/*
 Linker script to generate a flat binary executable for the stage2 bootloader

 @see http://wiki.osdev.org/Linker_Scripts
 @see https://sourceware.org/binutils/docs-2.21/ld/Scripts.html#Scripts
*/
SECTIONS {
	/* 0x7e00; change this with _KERNEL_BASE_ var 
	   put the text section of stage2_stub.o and put it at the beginning
	*/
	.text.mbr (0x7c00) : {
		  bootloader/stage1/stage1.o(.text)
	}	     
	.text.vbr (0x7e00) : {
		  bootloader/stage2/stage2.o(.text)
	}
	
	/*
	following all other sections are created, variables track the
	location of the sections and are available via C
	using extern "C" void <varname>
	and take &(<varname>) to take the value
	*/
	.text : {
	      _TEXT_START_ = .;
	      *(.text)
	      _TEXT_END_ = .;
	}
        
	.data : {
	      _DATA_START_ = .;
	      *(.data)
	      _DATA_END_ = .;
	}
	
	.rodata : {
		_RODATA_START_ = .;
		*(.rodata)
		_RODATA_END_ = .;
	}
	
	.bss  : {
	      _BSS_START_ = .;
	      *(.bss)
	      _BSS_END_ = .;
	}
}
