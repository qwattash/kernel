/**
 * Header file for Stage 2 constants
 * @author Alfredo Mazzinghi, Nicola Piga
 */


// scratch area address
#define SCRATCH 0x0710
// signature required for INT15_E820 bios call
#define INT15_E820_SIG 0x534d4150
// temporary GDT base
#define GDT_BASE 0x1000
// temporary GTT limit
#define GDT_LIMIT 0x0040
// initial protected-mode TSS base
#define TSS_BASE 0x1040
// initial protected-mode TSS limit
#define TSS_LIMIT 0x0067
