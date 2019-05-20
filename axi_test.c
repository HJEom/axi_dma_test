#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/mman.h>

#define MYIP_BASE    0x43C00000
#define MYIP_OFFSET  0xFFFF

#define PROT (PROT_READ|PROT_WRITE)
#define FLAGS (MAP_SHARED)

static volatile unsigned int* myip = NULL;

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
	myip[0] = 3;
//	for(int i = 1; i<10; i++){
//		printf("i = %d\n",i);
//		myip[i-1] = i;
//	}

	return 0;
}
