/** Stage 2 bootloader protected mode part
 * this loads the stage 3 image from the boot partition
*/

#define VIDEO_MEM 0xB8000

/** Entry point, called by stage 2 assembly section as soon as it is executed by stage 1
*/
void cmain()
{
    char* video_ptr = VIDEO_MEM;
    video_ptr += 2*80;
    *(video_ptr) = 'K';

    while (1)
    {
	continue;
    }
}
