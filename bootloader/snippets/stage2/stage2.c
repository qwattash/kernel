/**
 * This is the code of the second stage of the boot loader
 *
 * @todo
 * 
 *
 */

#include "stage2.h"

//this function is actually a test for running protected mode C 
//immediately after the GDT initialization
void protected_print(char* buffer) 
{
  unsigned int* lp_video_memory = (unsigned int*) VIDEO_MEMORY_ADDR;
  while (*buffer != '\0')
    {
      *(lp_video_memory++) = *(buffer++);
    }

}

/**
 * printf function 
 * @see http://wiki.osdev.org/Detecting_Colour_and_Monochrome_Monitors
 * @see http://wiki.osdev.org/Printing_To_Screen
 *
 */
/*
void printf(char* format, ...) 
{

}
*/
