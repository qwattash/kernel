/**
 * Header file for Bootloader constants
 * @author Alfredo Mazzinghi, Nicola Piga
 */

// address of jump table in the mbr ((0x7DB6)dec = 512 - JumpTable - 4*PartitionTableEntry -MBR_signature)
#define BOOT_JMP_TABLE 0x7DB6
// size of an entry in the jump table
#define BOOT_JMP_ENTRY_SIZE 4
// address of functions in the jump table
#define BIOS_STR_PRINT BOOT_JMP_TABLE
#define ERROR          BOOT_JMP_TABLE + (1 * BOOT_JMP_ENTRY_SIZE)
