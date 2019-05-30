/*
when a = mmap(from 0x40400000 to 0x4040000f)
then, generate a[0]~a[15] as vector.
And in case of DMA REGISTER, for example,
DMA REGISTER is a byte addressable.
so if you wanna access to MM2S_CONTROL_REGISTER,
you should access from a[0] to a[3].
This is the reason using the shift in the index of vector.

*/

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/mman.h>

#define BRAM_BASE   0x40000000
#define BRAM_OFFSET 0x1FFF

#define MYIP_BASE   0xA0001000
#define MYIP_OFFSET 0xFFF

#define DMA_BASE    0xA0000000
#define DMA_OFFSET  0xFFF

#define DRAM_SOURCE_BASE        0x0E000000
#define DRAM_SOURCE_OFFSET      0xFFFF
#define DRAM_DESTINATION_BASE   0x1F000000
#define DRAM_DESTINATION_OFFSET 0xFFFF

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
#define BUFF_SIZE 576

static volatile unsigned int* myip = NULL;

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

	printf("start myip using axi_lite\n");
	
	int fd = open("/dev/mem",(O_RDWR|O_SYNC));
	if(fd == -1){
		printf("ERROR: can't open \"/dev/mem\"...\n");
		return 1;
	}

	myip = mmap(NULL, MYIP_OFFSET, PROT, FLAGS, fd, MYIP_BASE);
	if(myip == MAP_FAILED){
		printf("ERROR: myip mmap() failed...\n" );
		return 1;
	}

	printf("start writing data to myIP...\n");
	unsigned int ctrl_data = 0x3;
	int f_1 = 4;
	int f_2 = 2;
	int f_3 = 6;
	int f_4 = 6;
	int f_5 = 2;
	int f_6 = -1;
	int f_7 = 2;
	int f_8 = -2;
	int f_9 = -2;

	int kernel_data_1 = ((f_1<<16) & (0x00ff0000))+ ((f_4<<8) & (0x0000ff00))+((f_7) & (0x000000ff));
	int kernel_data_2 = ((f_2<<16) & (0x00ff0000))+ ((f_5<<8) & (0x0000ff00))+((f_8) & (0x000000ff));
	int kernel_data_3 = ((f_3<<16) & (0x00ff0000))+ ((f_6<<8) & (0x0000ff00))+((f_9) & (0x000000ff));
	
	printf("0 : %08x\n", ctrl_data);
	myip[0] = ctrl_data;
	printf("1 : %08x\n", kernel_data_1);
	myip[1] = kernel_data_1;
	printf("2 : %08x\n", kernel_data_2);
	myip[2] = kernel_data_2;
	printf("3 : %08x\n", kernel_data_3);
	myip[3] = kernel_data_3;

	unsigned int data[2304] = {0,};

	int k = 0;
	int a;

	FILE *fp = fopen("./i_low_img.txt","r");

	while(!feof(fp)){
		fscanf(fp, "%d\n", &a);
		data[k] = a;
		k++;
	}

	for(k=0; k<2304; k++){
		if(k%4==0) data[k] = data[k]<<24;
		else if(k%4==1) data[k] = data[k]<<16;
		else if(k%4==2) data[k] = data[k]<<8;
		else data[k] = data[k-3]+data[k-2]+data[k-1]+data[k];
	}

	fclose(fp);

	printf("start using dma");
	unsigned int* virtual_dram_source = NULL;
	unsigned int* virtual_dram_dest = NULL;
	unsigned int* virtual_dma_base = NULL;

	virtual_dram_source = mmap(NULL, DRAM_SOURCE_OFFSET, PROT, FLAGS, fd, DRAM_SOURCE_BASE);
	if(virtual_dram_source == MAP_FAILED){
		printf("ERROR: dram source mmap() failed...\n" );
		return 1;
	}	
	
	virtual_dram_dest = mmap(NULL, DRAM_DESTINATION_OFFSET, PROT, FLAGS, fd, DRAM_DESTINATION_BASE);
	if(virtual_dram_dest == MAP_FAILED){
		printf("ERROR: dram destination mmap() failed...\n" );
		return 1;
	}
	
	virtual_dma_base = mmap(NULL, DMA_OFFSET, PROT, FLAGS, fd, DMA_BASE);
	if(virtual_dma_base == MAP_FAILED){
		printf("ERROR: dram mmap() failed...\n" );
		return 1;
	}

	unsigned int i;

	printf("initializing dram source ...\n");
	for ( i = 0; i < BUFF_SIZE; i++) {
		virtual_dram_source[i] = data[3+4*(i)];
	}

	printf("after init, read dram source \n");
	for ( i = 0; i < BUFF_SIZE+5; i++) printf("data_source[%d] : %08x\n", i, virtual_dram_source[i]);

	printf("initializing dram target ...\n");
	for ( i = 0; i < BUFF_SIZE; i++) virtual_dram_dest[i] = 0xDEADBEEF;

	printf("after init, read dram target \n");
	for ( i = 0; i < BUFF_SIZE+5; i++) printf("data_dest[%d] : %08x\n", i, virtual_dram_dest[i]);
	
	printf("---------------- Using dma, copy the data in dram source to dram target addr --------------------\n");
	
	unsigned int mm2s_status = virtual_dma_base[MM2S_STATUS_REGISTER >> 2];
	unsigned int s2mm_status = virtual_dma_base[S2MM_STATUS_REGISTER >> 2];

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

	printf("writing source address...\n");
	virtual_dma_base[MM2S_SOURCE_ADDRESS >> 2] = DRAM_SOURCE_BASE;
	dma_mm2s_status(virtual_dma_base);

	printf("Starting MM2S channel with all interrupts masked...\n");
	virtual_dma_base[MM2S_CONTROL_REGISTER >> 2] = 0xF001;
	dma_mm2s_status(virtual_dma_base);

	printf("writing mm2s length...\n");
	virtual_dma_base[MM2S_LENGTH >> 2] = 2304;
	dma_mm2s_status(virtual_dma_base);

	mm2s_status = virtual_dma_base[MM2S_STATUS_REGISTER >> 2];

	printf("mm2s sync...\n");
	while (!(mm2s_status & 0x1000) || !(mm2s_status & 0x2))
	{
		dma_mm2s_status(virtual_dma_base);
		mm2s_status = virtual_dma_base[MM2S_STATUS_REGISTER >> 2];
	}

	printf("writing destination address...\n");
	virtual_dma_base[S2MM_DESTINATION_ADDRESS >> 2] = DRAM_DESTINATION_BASE;
	dma_s2mm_status(virtual_dma_base);

	printf("Starting S2MM channel with all interrupts masked...\n");
	virtual_dma_base[S2MM_CONTROL_REGISTER >> 2] = 0xF001;
	dma_s2mm_status(virtual_dma_base);

	printf("writing s2mm length...\n");
	virtual_dma_base[S2MM_LENGTH >> 2] = 2308;
	dma_s2mm_status(virtual_dma_base);

	s2mm_status = virtual_dma_base[S2MM_STATUS_REGISTER >> 2];

	printf("s2mm sync...\n");
	while (!(s2mm_status & 0x1000) || !(s2mm_status & 0x2))
	{
		dma_s2mm_status(virtual_dma_base);
		s2mm_status = virtual_dma_base[S2MM_STATUS_REGISTER >> 2];
	}


	printf("re-read the data of dram from dram target address \n");
	for ( i = 0; i < BUFF_SIZE+10; i++) printf("dram_dest[%d] : %08x\n", i, virtual_dram_dest[i]);

	printf("Using dma is done! \n\n");
/*
	printf("start using bram\n");
	
	unsigned int* virtual_bram = NULL;

	virtual_bram = mmap(NULL, BRAM_OFFSET, PROT, FLAGS, fd, BRAM_BASE);
	if(virtual_bram == MAP_FAILED){
		printf("ERROR: bram mmap() failed...\n" );
		return 1;
	}

	unsigned int bram_init = 0xDEADBEEF;
	
	printf("read bram\n");
	for ( i = 0; i < BUFF_SIZE*2; i++) printf("bram[%d] : %08x\n", i, virtual_bram[i]);
	
	printf("initializing bram...\n");
	for ( i = 0; i < BUFF_SIZE*1; i++){
		virtual_bram[i] = bram_init;
	}
	
	printf("re-read bram\n");
	for ( i = 0; i < BUFF_SIZE*2; i++) printf("bram[%d] : %08x\n", i, virtual_bram[i]);
*/
	return 0;
}
