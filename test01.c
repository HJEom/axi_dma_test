#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>

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
#define BUFF_SIZE 0xa

// MM2S CONTROL
#define MM2S_CONTROL_REGISTER        0x00    // MM2S_DMACR
#define MM2S_STATUS_REGISTER         0x04    // MM2S_DMASR
#define MM2S_SOURCE_ADDRESS          0x18    // MM2S_SA
#define MM2S_SOURCE_ADDRESS_MSB      0x1C    // MM2S_SA_MSB
#define MM2S_LENGTH                  0x28    // MM2S_LENGTH

// S2MM CONTROL
#define S2MM_CONTROL_REGISTER        0x30    // S2MM_DMACR
#define S2MM_STATUS_REGISTER         0x34    // S2MM_DMASR
#define S2MM_DESTINATION_ADDRESS     0x48    // S2MM_DA
#define S2MM_DESTINATION_ADDRESS_MSB 0x4C    // S2MM_DA_MSB
#define S2MM_LENGTH                  0x58    // S2MM_LENGTH

//static volatile unsigned int *dram_source = NULL;
//static volatile unsigned int *dram_target = NULL;
//static volatile unsigned int *m_axi_base = NULL;
//static volatile unsigned int *dma_base = NULL;

static volatile unsigned int* dram_source = NULL;
static volatile unsigned int* dram_target = NULL;
static volatile unsigned int* dma_base = NULL;

int main(){
	

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
	
	unsigned int *virtual_dram_base;
	virtual_dram_base = mmap(NULL, DRAM_MASK, PROT, FLAGS, fd, DRAM_BASE);
	if(virtual_dram_base == MAP_FAILED){
		printf("ERROR: dram mmap() failed...\n" );
		return 1;
	}
	
	unsigned int *virtual_dma_base;
	virtual_dma_base= mmap(NULL, DMA_MASK, PROT, FLAGS, fd, DMA_BASE);
	if(virtual_dma_base== MAP_FAILED){
		printf("ERROR: dma mmap() failed...\n" );
		return 1;
	}

//	m_axi_base = (volatile unsigned int *)virtual_m_axi_gp0_0_base + (unsigned long) 0x0;
	dram_source = (volatile unsigned int *) virtual_dram_base + (unsigned int) 0x0;
	dram_target = (volatile unsigned int *)virtual_dram_base + (unsigned int) 0x10000;
	dma_base = (volatile unsigned int *)virtual_dma_base + (unsigned int) 0x0;

	printf(" reset dma ... \n");
	dma_base[MM2S_CONTROL_REGISTER >> 2] = 0x4;
	dma_base[S2MM_CONTROL_REGISTER >> 2] = 0x4;
	dma_base[MM2S_CONTROL_REGISTER >> 2] = 0x0;
	dma_base[S2MM_CONTROL_REGISTER >> 2] = 0x0;
	printf(" done ... \n");

	int i;
	printf("*************** before init, read dram from source base to source base + BUFF_SIZE ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, dram_source[i<<2]);

	printf("initializing dram from source base to source base + BUFF_SIZE ...\n");
	for ( i = 0; i < (BUFF_SIZE/4); i++) dram_source[i<<2] = 0x22222222;

	printf("*************** after init, read dram from source base to source base + BUFF_SIZE ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, dram_source[i<<2]);

	printf("\n");

	printf("*************** before init, read dram from target base to target base + BUFF_SIZE ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, dram_target[i<<2]);

	printf("initializing dram from target base to target base + BUFF_SIZE ...\n");
	for ( i = 0; i < (BUFF_SIZE/4); i++) dram_target[i<<2] = 0xDEADBEEF;

	printf("*************** after init, read dram from target base to target base + BUFF_SIZE ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, dram_target[i<<2]);

	printf("---------------- using dma copy the data of dram source addr to dram target addr --------------------\n");
	
	int mm2s_status, s2mm_status;

	dma_base[MM2S_SOURCE_ADDRESS >> 2] = DRAM_BASE;
	dma_base[MM2S_LENGTH >> 2] = BUFF_SIZE;
	dma_base[S2MM_DESTINATION_ADDRESS >> 2] = DRAM_BASE + 0x10000;
	dma_base[S2MM_LENGTH >> 2] = BUFF_SIZE;
	
	mm2s_status = dma_base[MM2S_STATUS_REGISTER >> 2];
	s2mm_status = dma_base[S2MM_STATUS_REGISTER >> 2];
	printf("mm2s_status : %08x\n", mm2s_status);
	printf("s2mm_status : %08x\n", s2mm_status);

	printf("dma sets to running...\n");
	dma_base[MM2S_CONTROL_REGISTER ] = 0x1;
	dma_base[S2MM_CONTROL_REGISTER ] = 0x1;

	int controlregister_ok =0;
/*
	while (!controlregister_ok)
    {
	mm2s_status = dma_base[MM2S_STATUS_REGISTER >> 2];
	s2mm_status = dma_base[S2MM_STATUS_REGISTER >> 2];
		controlregister_ok = ((mm2s_status & 0x00001000) && (s2mm_status & 0x00001000));
		printf("Memory-mapped to stream status (0x%08x@0x%02x):\n", mm2s_status, MM2S_STATUS_REGISTER);
		printf("MM2S_STATUS_REGISTER status register values:\n");
		if (mm2s_status & 0x00000001) printf(" halted"); else printf(" running");
		if (mm2s_status & 0x00000002) printf(" idle");
		if (mm2s_status & 0x00000008) printf(" SGIncld");
		if (mm2s_status & 0x00000010) printf(" DMAIntErr");
		if (mm2s_status & 0x00000020) printf(" DMASlvErr");
		if (mm2s_status & 0x00000040) printf(" DMADecErr");
		if (mm2s_status & 0x00000100) printf(" SGIntErr");
		if (mm2s_status & 0x00000200) printf(" SGSlvErr");
		if (mm2s_status & 0x00000400) printf(" SGDecErr");
		if (mm2s_status & 0x00001000) printf(" IOC_Irq");
		if (mm2s_status & 0x00002000) printf(" Dly_Irq");
		if (mm2s_status & 0x00004000) printf(" Err_Irq");
		printf("\n");
		printf("Stream to memory-mapped status (0x%08x@0x%02x):\n", s2mm_status, S2MM_STATUS_REGISTER);
		printf("S2MM_STATUS_REGISTER status register values:\n");
		if (s2mm_status & 0x00000001) printf(" halted"); else printf(" running");
		if (s2mm_status & 0x00000002) printf(" idle");
		if (s2mm_status & 0x00000008) printf(" SGIncld");
		if (s2mm_status & 0x00000010) printf(" DMAIntErr");
		if (s2mm_status & 0x00000020) printf(" DMASlvErr");
		if (s2mm_status & 0x00000040) printf(" DMADecErr");
		if (s2mm_status & 0x00000100) printf(" SGIntErr");
		if (s2mm_status & 0x00000200) printf(" SGSlvErr");
		if (s2mm_status & 0x00000400) printf(" SGDecErr");
		if (s2mm_status & 0x00001000) printf(" IOC_Irq");
		if (s2mm_status & 0x00002000) printf(" Dly_Irq");
		if (s2mm_status & 0x00004000) printf(" Err_Irq");
		printf("\n");
    }
*/
	printf("mm2s_status : %08x\n", mm2s_status);
	printf("s2mm_status : %08x\n", s2mm_status);
	printf("re-read dram from target base to target base + BUFF_SIZE ***************\n");
	for ( i = 0; i < (BUFF_SIZE/4)+4; i++) printf("data[%08d] : %08x\n", i, dram_target[i<<2]);



/*
	printf("*************" << "read ddr..." << "*************"<<endl;
	for(int i = 0; i < BUFF_SIZE; i++)
		printf("\t*ddr_base : " << std::hex << *(ddr_base+i) << std::dec );
	printf(endl;
	
	printf("*************" << "read dma..." << "*************"<<endl;
	for(int i = 0; i < BUFF_SIZE; i++)
		printf("\t*dma_base : " << std::hex << *(dma_base+i) << std::dec );
	printf(endl;

	printf("*****************" << "writing to m_axi_wdata..." << "******************"<<endl;
	volatile unsigned int *m_axi_wdata = NULL;
	m_axi_wdata = m_axi_base;
//	for(unsigned int i = 0; i<BUFF_SIZE; i++){
	*m_axi_wdata = 0x7;
//	}

	printf("************************************" << "re-read ddr..." << "************************************"<<endl;
	for(int i = 0; i < BUFF_SIZE; i++)
		printf("\t*ddr_base : " << std::hex << *(ddr_base+i) << std::dec );
	printf(endl;

	printf("************************************" << "re-read dma..." << "************************************"<<endl;
	for(int i = 0; i < BUFF_SIZE; i++)
		printf("\t*dma_base : " << std::hex << *(dma_base+i) << std::dec );
	printf(endl;
*/
	return 0;
}
