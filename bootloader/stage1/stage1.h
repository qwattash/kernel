/**
 * Header file for Bootloader constants
 * @author Alfredo Mazzinghi, Nicola Piga
 */

// boot segment selector (real mode)
#define SEG_BOOT 0x0000
// stack segment selector (real mode)
#define SEG_STACK 0x9000
// initial stack pointer (real mode)
#define INIT_SP 0xFBFF
// address where the stage 2 bootloader is loaded in memory (real mode)
#define STAGE2_BEGIN 0x7E00
// signature that signals the end of the stage2 bootloader (4 bytes)
#define STAGE2_END_SIGNATURE 0x0000
// address where the BIOS loads the stage1 bootloader code (real mode)
#define BOOT_BEGIN 0x7C00
