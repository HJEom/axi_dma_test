#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>

#define M_AXI_GP0_0_BASE 0x43C00000
#define M_AXI_GP0_0_HIGH 0x43C0FFFF
#define M_AXI_GP0_0_MASK (M_AXI_GP0_0_HIGH - M_AXI_GP0_0_BASE)

#define DMA_BASE 0x41E00000
#define DMA_HIGH 0x41E0FFFF
#define DMA_MASK (DMA_HIGH - DMA_BASE)

#define S_AXI_HP0_BASE 0x00000000
#define S_AXI_HP0_HIGH 0x1FFFFFFF
#define S_AXI_HP0_MASK (S_AXI_HP0_HIGH - S_AXI_HP0_BASE)

#define PROT (PROT_READ|PROT_WRITE)
#define FLAGS (MAP_SHARED)
#define BUFF_SIZE 5

static volatile unsigned short *ddr_base = NULL;
static volatile unsigned short *m_axi_base = NULL;
static volatile unsigned short *dma_base = NULL;

int main(){
	int fd = open("/dev/mem",(O_RDWR|O_SYNC));
	if(fd == -1){
		printf("ERROR: can't open \"/dev/mem\"...");
		return 1;
	}
	
	unsigned int *virtual_s_axi_hp0_0_base;
	virtual_s_axi_hp0_0_base = mmap(NULL, S_AXI_HP0_MASK, PROT, FLAGS, fd, S_AXI_HP0_BASE);
	if(virtual_s_axi_hp0_0_base == MAP_FAILED){
		printf("ERROR: axi_ddr mmap() failed..." );
		return 1;
	}
	
	unsigned int *virtual_m_axi_gp0_0_base;
	virtual_m_axi_gp0_0_base= mmap(NULL, M_AXI_GP0_0_MASK, PROT, FLAGS, fd, M_AXI_GP0_0_BASE);
	if(virtual_m_axi_gp0_0_base== MAP_FAILED){
		printf("ERROR: m_axi_gp mmap() failed..." );
		return 1;
	}
	unsigned int *virtual_dma_base;
	virtual_dma_base= mmap(NULL, DMA_MASK, PROT, FLAGS, fd, DMA_BASE);
	if(virtual_dma_base== MAP_FAILED){
		printf("ERROR: dma mmap() failed..." );
		return 1;
	}
	ddr_base = (volatile unsigned short *)virtual_s_axi_hp0_0_base + (unsigned long) 0x0;
	m_axi_base = (volatile unsigned short *)virtual_m_axi_gp0_0_base + (unsigned long) 0x0;
	dma_base = (volatile unsigned short *)virtual_dma_base + (unsigned long) 0x0;

	for ( int i = 0; i < 10; i++){
		printf("addr : %08x , data : %08x",virtual_s_axi_hp0_0_base[i] ,*virtual_s_axi_hp0_0_base[i]);
	}
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
	volatile unsigned short *m_axi_wdata = NULL;
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
