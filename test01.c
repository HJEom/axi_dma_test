#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/mman.h>

//#define M_AXI_GP0_0_BASE 0x43C00000
//#define M_AXI_GP0_0_HIGH 0x43C0FFFF
//#define M_AXI_GP0_0_MASK (M_AXI_GP0_0_HIGH - M_AXI_GP0_0_BASE)

#define DMA_BASE 0x40400000
#define DMA_HIGH 0x4040FFFF
#define DMA_MASK (DMA_HIGH - DMA_BASE)

#define DRAM_BASE 0x00000000
#define DRAM_HIGH 0x1FFFFFFF
#define DRAM_MASK (DRAM_HIGH - DRAM_BASE)

#define PROT (PROT_READ|PROT_WRITE)
#define FLAGS (MAP_SHARED)
#define BUFF_SIZE 0xF

// MM2S CONTROL
#define MM2S_CONTROL_REGISTER        0x00    // MM2S_DMACR
#define MM2S_STATUS_REGISTER         0x04    // MM2S_DMASR
#define MM2S_SOURCE_ADDRESS          0x18    // MM2S_SA
#define MM2S_LENGTH                  0x28    // MM2S_LENGTH

// S2MM CONTROL
#define S2MM_CONTROL_REGISTER        0x30    // S2MM_DMACR
#define S2MM_STATUS_REGISTER         0x34    // S2MM_DMASR
#define S2MM_DESTINATION_ADDRESS     0x48    // S2MM_DA
#define S2MM_LENGTH                  0x58    // S2MM_LENGTH

//static volatile unsigned int *dram_source = NULL;
//static volatile unsigned int *dram_target = NULL;
//static volatile unsigned int *m_axi_base = NULL;
//static volatile unsigned int *dma_base = NULL;


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

int main(){
	
//	unsigned int* phy_dram_source = NULL;
//	unsigned int* phy_dram_target = NULL;
	unsigned int* phy_dram_base = NULL;
	unsigned int* phy_dram_base_t = NULL;
	unsigned int* phy_dma_base = NULL;

	int fd = open("/dev/mem",(O_RDWR|O_SYNC));
	if(fd == -1){
		printf("ERROR: can't open \"/dev/mem\"...\n");
		return 1;
	}

//	unsigned int *virtual_m_axi_gp0_0_base;
//	virtual_m_axi_gp0_0_base= mmap(NULL, M_AXI_GP0_0_MASK, PROT, FLAGS, fd, M_AXI_GP0_0_BASE);
//	if(virtual_m_axi_gp0_0_base== MAP_FAILED){
//		printf("ERROR: m_axi_gp mmap() failed..." );
//		return 1;
//	}

	phy_dram_base = mmap(NULL, 0xffff, PROT, FLAGS, fd, 0x1e000000);
	if(phy_dram_base == MAP_FAILED){
		printf("ERROR: dram mmap() failed...\n" );
		return 1;
	}	
	
	phy_dram_base_t = mmap(NULL, 0xffff, PROT, FLAGS, fd, 0x0f000000);
	if(phy_dram_base_t == MAP_FAILED){
		printf("ERROR: dram_t mmap() failed...\n" );
		return 1;
	}
	
	phy_dma_base = mmap(NULL, DMA_MASK, PROT, FLAGS, fd, DMA_BASE);
	if(phy_dma_base == MAP_FAILED){
		printf("ERROR: dram mmap() failed...\n" );
		return 1;
	}

	unsigned int i;
	printf("*************** before init, read dram source **************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_base[i<<2]);

	printf("initializing dram source ...\n");
	for ( i = 0; i < (BUFF_SIZE/4); i++) phy_dram_base[i<<2] = 0x22222222;

	printf("*************** after init, read dram source ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_base[i<<2]);

	printf("*************** before init, read dram target ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_base_t[i<<2]);

	printf("initializing dram target ...\n");
	for ( i = 0; i < (BUFF_SIZE/4); i++) phy_dram_base_t[i<<2] = 0xDEADBEEF;

	printf("*************** after init, read dram target ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_base_t[i<<2]);
	
	printf("---------------- using dma copy the data of dram source addr to dram target addr --------------------\n");

	printf("Resetting DMA\n");
	phy_dma_base[MM2S_CONTROL_REGISTER >> 2] = 4;
	phy_dma_base[S2MM_CONTROL_REGISTER >> 2] = 4;
	dma_s2mm_status(phy_dma_base);
	dma_mm2s_status(phy_dma_base);

	printf("Halting DMA\n");
	phy_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0;
	phy_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0;
	dma_s2mm_status(phy_dma_base);
	dma_mm2s_status(phy_dma_base);

	printf("writing destination address...\n");
	phy_dma_base[S2MM_DESTINATION_ADDRESS >> 2] = 0x0f000000;
	dma_s2mm_status(phy_dma_base);

	printf("writing source address...\n");
	phy_dma_base[MM2S_SOURCE_ADDRESS >> 2] = 0x1e000000;
	dma_mm2s_status(phy_dma_base);

	printf("Starting S2MM channel with all interrupts masked...\n");
	phy_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0xF001;
	dma_s2mm_status(phy_dma_base);

	printf("Starting MM2S channel with all interrupts masked...\n");
	phy_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0xF001;
	dma_mm2s_status(phy_dma_base);

	printf("writing s2mm length...\n");
	phy_dma_base[S2MM_LENGTH >> 2] = 32;
	dma_s2mm_status(phy_dma_base);

	printf("writing mm2s length...\n");
	phy_dma_base[MM2S_LENGTH >> 2] = 32;
	dma_mm2s_status(phy_dma_base);

	unsigned int mm2s_status = phy_dma_base[MM2S_STATUS_REGISTER >> 2];
	unsigned int s2mm_status = phy_dma_base[S2MM_STATUS_REGISTER >> 2];

	printf("mm2s sync...\n");
	while (!(mm2s_status & 1<<12) || !(mm2s_status & 1<<1))
	{
		//dma_mm2s_status(phy_dma_base);
		mm2s_status = phy_dma_base[MM2S_STATUS_REGISTER >> 2];
	}
	printf("s2mm sync...\n");
	while (!(s2mm_status & 0x1000) || !(s2mm_status & 0x2))
	{
		//dma_s2mm_status(phy_dma_base);
		s2mm_status = phy_dma_base[S2MM_STATUS_REGISTER >> 2];
	}

	printf("mm2s_status : %08x\n", mm2s_status);
	printf("s2mm_status : %08x\n", s2mm_status);
	printf("re-read dram from target base to target base + BUFF_SIZE ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_base_t[i<<2]);

	
/*
	unsigned int *virtual_dram_base_s;
	virtual_dram_base_s = mmap(NULL, DRAM_MASK, PROT, FLAGS, fd, DRAM_BASE);
	if(virtual_dram_base_s == MAP_FAILED){
		printf("ERROR: dram_s mmap() failed...\n" );
		return 1;
	}
	
	unsigned int *virtual_dram_base_t;
	virtual_dram_base_t = mmap(NULL, DRAM_MASK, PROT, FLAGS, fd, DRAM_BASE+0x10000);
	if(virtual_dram_base_t == MAP_FAILED){
		printf("ERROR: dram_t mmap() failed...\n" );
		return 1;
	}
	
	unsigned int *virtual_dma_base;
	virtual_dma_base= mmap(NULL, DMA_MASK, PROT, FLAGS, fd, DMA_BASE);
	if(virtual_dma_base== MAP_FAILED){
		printf("ERROR: dma mmap() failed...\n" );
		return 1;
	}
*/
//	m_axi_base = (volatile unsigned int *)virtual_m_axi_gp0_0_base + (unsigned long) 0x0;
//	phy_dram_source = (volatile unsigned int *) virtual_dram_base + (unsigned int) 0x0;
//	phy_dram_target = (volatile unsigned int *)virtual_dram_base + (unsigned int) 0x10000;
//	phy_dma_base = (volatile unsigned int *)virtual_dma_base;

//	phy_dram_source = (unsigned int *) virtual_dram_base_s;
//	phy_dram_target = (unsigned int *)virtual_dram_base_t;
//	phy_dma_base = (unsigned int *)virtual_dma_base;
/*
	unsigned int i;
	printf("*************** before init, read dram source **************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_source[i<<2]);

	printf("initializing dram source ...\n");
	for ( i = 0; i < (BUFF_SIZE/4); i++) phy_dram_source[i<<2] = 0x22222222;

	printf("*************** after init, read dram source ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_source[i<<2]);

	printf("\n");

	printf("*************** before init, read dram target ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_target[i<<2]);

	printf("initializing dram target ...\n");
	for ( i = 0; i < (BUFF_SIZE/4); i++) phy_dram_target[i<<2] = 0xDEADBEEF;

	printf("*************** after init, read dram target ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_target[i<<2]);
	
	printf("---------------- using dma copy the data of dram source addr to dram target addr --------------------\n");

	printf("Resetting DMA\n");
	phy_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0x4;
	phy_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0x4;
	dma_s2mm_status(phy_dma_base);
	dma_mm2s_status(phy_dma_base);

	printf("Halting DMA\n");
	phy_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0x0;
	phy_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0x0;
	dma_s2mm_status(phy_dma_base);
	dma_mm2s_status(phy_dma_base);

	printf("writing destination address...\n");
	phy_dma_base[S2MM_DESTINATION_ADDRESS >> 2] = 0x10000;
	dma_s2mm_status(phy_dma_base);

	printf("writing source address...\n");
	phy_dma_base[MM2S_SOURCE_ADDRESS >> 2] = 0x00;
	dma_mm2s_status(phy_dma_base);

	printf("Starting S2MM channel with all interrupts masked...\n");
	phy_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0xF001;
	dma_s2mm_status(phy_dma_base);

	printf("Starting MM2S channel with all interrupts masked...\n");
	phy_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0xF001;
	dma_mm2s_status(phy_dma_base);

	printf("writing s2mm length...\n");
	phy_dma_base[S2MM_LENGTH >> 2] = 32;
	dma_s2mm_status(phy_dma_base);

	printf("writing mm2s length...\n");
	phy_dma_base[MM2S_LENGTH >> 2] = 32;
	dma_mm2s_status(phy_dma_base);

	unsigned int mm2s_status = phy_dma_base[MM2S_STATUS_REGISTER >> 2];
	unsigned int s2mm_status = phy_dma_base[S2MM_STATUS_REGISTER >> 2];

	printf("mm2s sync...\n");
	while (!(mm2s_status & 1<<12) || !(mm2s_status & 1<<1))
	{
		//dma_mm2s_status(phy_dma_base);
		mm2s_status = phy_dma_base[MM2S_STATUS_REGISTER >> 2];
	}
	printf("s2mm sync...\n");
	while (!(s2mm_status & 0x1000) || !(s2mm_status & 0x2))
	{
		//dma_s2mm_status(phy_dma_base);
		s2mm_status = phy_dma_base[S2MM_STATUS_REGISTER >> 2];
	}

	printf("mm2s_status : %08x\n", mm2s_status);
	printf("s2mm_status : %08x\n", s2mm_status);
	printf("re-read dram from target base to target base + BUFF_SIZE ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, phy_dram_target[i<<2]);
*/	
	return 0;
}
