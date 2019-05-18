#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/mman.h>

#define DMA_BASE 0x40400000
#define DMA_HIGH 0x4040FFFF
#define DMA_MASK (DMA_HIGH - DMA_BASE)

#define DRAM_SOURCE_BASE       0x0e000000
#define DRAM_SOURCE__HIGH      0x0e00ffff
#define DRAM_DESTINATION_BASE  0x0f000000
#define DRAM_DESTINATION__HIGH 0x0f00ffff

// MM2S REGISTER
#define MM2S_CONTROL_REGISTER        0x00
#define MM2S_STATUS_REGISTER         0x04
#define MM2S_SOURCE_ADDRESS          0x18
#define MM2S_LENGTH                  0x28

// S2MM REGISTER
#define S2MM_CONTROL_REGISTER        0x30
#define S2MM_STATUS_REGISTER         0x34
#define S2MM_DESTINATION_ADDRESS     0x48
#define S2MM_LENGTH                  0x58

#define PROT (PROT_READ|PROT_WRITE)
#define FLAGS (MAP_SHARED)
#define BUFF_SIZE 10

void dma_mm2s_status(unsigned int* dma_virtual_address) {
    unsigned int status = dma_virtual_address[MM2S_STATUS_REGISTER>>2];
    printf("Memory-mapped to stream status (0x%08x@0x%02x):", status, MM2S_STATUS_REGISTER);
    if (status & 0x00000001) printf(" halted"); else printf(" running");
    if (status & 0x00000002) printf(" idle");
    if (status & 0x00000008) printf(" SGIncld");
    if (status & 0x00000010) printf(" DMAIntErr");
    if (status & 0x00000020) printf(" DMASlvErr");
    if (status & 0x00000040) printf(" DMADecErr");
    if (status & 0x00000100) printf(" SGIntErr");
    if (status & 0x00000200) printf(" SGSlvErr");
    if (status & 0x00000400) printf(" SGDecErr");
    if (status & 0x00001000) printf(" IOC_Irq");
    if (status & 0x00002000) printf(" Dly_Irq");
    if (status & 0x00004000) printf(" Err_Irq");
    printf("\n");
}

void dma_s2mm_status(unsigned int* dma_virtual_address) {
    unsigned int status = dma_virtual_address[S2MM_STATUS_REGISTER>>2];
    printf("Stream to memory-mapped status (0x%08x@0x%02x):", status, S2MM_STATUS_REGISTER);
    if (status & 0x00000001) printf(" halted"); else printf(" running");
    if (status & 0x00000002) printf(" idle");
    if (status & 0x00000008) printf(" SGIncld");
    if (status & 0x00000010) printf(" DMAIntErr");
    if (status & 0x00000020) printf(" DMASlvErr");
    if (status & 0x00000040) printf(" DMADecErr");
    if (status & 0x00000100) printf(" SGIntErr");
    if (status & 0x00000200) printf(" SGSlvErr");
    if (status & 0x00000400) printf(" SGDecErr");
    if (status & 0x00001000) printf(" IOC_Irq");
    if (status & 0x00002000) printf(" Dly_Irq");
    if (status & 0x00004000) printf(" Err_Irq");
    printf("\n");
}

int main(){
	
	unsigned int* virtual_dram_base = NULL;
	unsigned int* virtual_dram_base_t = NULL;
	unsigned int* virtual_dma_base = NULL;

	int fd = open("/dev/mem",(O_RDWR|O_SYNC));
	if(fd == -1){
		printf("ERROR: can't open \"/dev/mem\"...\n");
		return 1;
	}

	virtual_dram_base = mmap(NULL, 0xffff, PROT, FLAGS, fd, DRAM_S_BASE);
	if(virtual_dram_base == MAP_FAILED){
		printf("ERROR: dram mmap() failed...\n" );
		return 1;
	}	
	
	virtual_dram_base_t = mmap(NULL, 0xffff, PROT, FLAGS, fd, DRAM_D_BASE);
	if(virtual_dram_base_t == MAP_FAILED){
		printf("ERROR: dram_t mmap() failed...\n" );
		return 1;
	}
	
	virtual_dma_base = mmap(NULL, DMA_MASK, PROT, FLAGS, fd, DMA_BASE);
	if(virtual_dma_base == MAP_FAILED){
		printf("ERROR: dram mmap() failed...\n" );
		return 1;
	}

	unsigned int i;

	printf("initializing dram source ...\n");
	for ( i = 0; i < BUFF_SIZE; i++) {
		virtual_dram_base[i<<2] = i;
	}

	printf("*************** after init, read dram source ***************\n");
	for ( i = 0; i < BUFF_SIZE*2; i++) printf("data[%08d] : %08x\n", i, virtual_dram_base[i<<2]);


	printf("initializing dram target ...\n");
	for ( i = 0; i < BUFF_SIZE; i++) virtual_dram_base_t[i<<2] = 0xDEADBEEF;

	printf("*************** after init, read dram target ***************\n");
	for ( i = 0; i < BUFF_SIZE*2; i++) printf("data[%08d] : %08x\n", i, virtual_dram_base_t[i<<2]);
	
	printf("---------------- using dma copy the data of dram source addr to dram target addr --------------------\n");
	unsigned int mm2s_status = virtual_dma_base[MM2S_STATUS_REGISTER >> 2];
	unsigned int s2mm_status = virtual_dma_base[S2MM_STATUS_REGISTER >> 2];
	printf("mm2s_status : %08x\n", mm2s_status);
	printf("s2mm_status : %08x\n", s2mm_status);

	printf("Resetting DMA\n");
	virtual_dma_base[MM2S_CONTROL_REGISTER >> 2] = 4;
	virtual_dma_base[S2MM_CONTROL_REGISTER >> 2] = 4;
	dma_s2mm_status(virtual_dma_base);
	dma_mm2s_status(virtual_dma_base);

	printf("Halting DMA\n");
	virtual_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0;
	virtual_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0;
	dma_s2mm_status(virtual_dma_base);
	dma_mm2s_status(virtual_dma_base);

	printf("writing destination address...\n");
	virtual_dma_base[S2MM_DESTINATION_ADDRESS >> 2] = DRAM_D_BASE;
	dma_s2mm_status(virtual_dma_base);

	printf("writing source address...\n");
	virtual_dma_base[MM2S_SOURCE_ADDRESS >> 2] = DRAM_S_BASE;
	dma_mm2s_status(virtual_dma_base);

	printf("Starting S2MM channel with all interrupts masked...\n");
	virtual_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0xF001;
	dma_s2mm_status(virtual_dma_base);

	printf("Starting MM2S channel with all interrupts masked...\n");
	virtual_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0xF001;
	dma_mm2s_status(virtual_dma_base);

	printf("writing s2mm length...\n");
	virtual_dma_base[S2MM_LENGTH >> 2] = 32;
	dma_s2mm_status(virtual_dma_base);

	printf("writing mm2s length...\n");
	virtual_dma_base[MM2S_LENGTH >> 2] = 32;
	dma_mm2s_status(virtual_dma_base);

	printf("mm2s_status : %08x\n", mm2s_status);
	printf("s2mm_status : %08x\n", s2mm_status);

	printf("mm2s sync...\n");
	while (!(mm2s_status & 1<<12) || !(mm2s_status & 1<<1))
	{
		//dma_mm2s_status(virtual_dma_base);
		mm2s_status = virtual_dma_base[MM2S_STATUS_REGISTER >> 2];
	}
	printf("s2mm sync...\n");
	while (!(s2mm_status & 0x1000) || !(s2mm_status & 0x2))
	{
		//dma_s2mm_status(virtual_dma_base);
		s2mm_status = virtual_dma_base[S2MM_STATUS_REGISTER >> 2];
	}

	printf("mm2s_status : %08x\n", mm2s_status);
	printf("s2mm_status : %08x\n", s2mm_status);
	printf("re-read dram from target base to target base + BUFF_SIZE \n");
	for ( i = 0; i < BUFF_SIZE*2; i++) printf("data[%08d] : %08x\n", i, virtual_dram_base_t[i<<2]);
	
	return 0;
}
