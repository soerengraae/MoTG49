//MoT_main.c

#include "stdint-gcc.h"	//for uint8_t, uint16_t, uint32_t  etc. 
#include <stddef.h> 
#include "MoTstructures.h"			

//system functions
void SystemClock_init2();
void SysTick_init();
void LPUART1_init(); 						//initialize LPUART1 for STLINK VCOM at 115200N81 
void LPUART1_RX_interrupt_enable(); 		//what it says
void HW_userCOM_init(); 					//initializes MoT console communication 

//system data 
uint32_t SysTick_msecs = 0; 		//0-999; updated by Systick_Handler() 'SysTick_48MHz.S'
uint64_t SysTick_absmsecs = 0; 		//0 - 2**64; ""
uint32_t SysTick_secs = 0;			//0 - 2**32; ""

char buf_08X[9];

//MoT configuration values (required!)-- adjustable
#define COUNT 100
uint32_t userCOM_RXDATACOUNT= COUNT;			//'COUNT' is number of characters that can be buffered
uint32_t userCOM_RXDATASTORAGE[COUNT/4+1+9]; 	//allocation is for composite character data buffer + control values struct
uint32_t *userCOM_RXbufHANDLEp = userCOM_RXDATASTORAGE + 9; //'handle' points to address 9 words 'above' allocation region


//debug access to device control structures (you can use these in debug's 'Expressions' to cast register pointers)
extern MoT_core_t device0;	//1st device is the system device for MoT command '0' and starting tasks
extern MoT_core_t DAC1;
extern MoT_core_t TIM2;
extern MoT_core_t SPI2;
extern MoT_core_t deviceN;	//last device is the system device for ending tasks and returning to command loop
extern MoT_msgLink_t INITIALIZED_msg;
extern MoT_msgLink_t STARTING_msg;
extern MoT_listAnchor_t consoleMsgs;

//!! IMPORTANT: position of a 'device' in the device control list (below) is also the device ID  (0,1,...)
MoT_core_t *devicelist[] = {&device0, &DAC1, &TIM2, &SPI2, &deviceN};	 //device0, deviceN must be first, last

void * MoT_doTasks(MoT_core_t *list[] ); // in MoTservices_xx.S; dispatches device tasks

// note: MoT uses an exhaustive linked list of tasks for speed. 'link_devicetasks()' below initializes the device-task list
void link_tasks(MoT_core_t *list[], int num ) {
	int i;
	for(i=0;i<num-1;i++) {				//'num-1' because the final device (deviceN) does not have a successor. 
		list[i]->nexttask = list[i+1];	//style-trial
	}
}

int main(void)
{
	int devnum=sizeof(devicelist)/sizeof(&devicelist[0]);

	SystemClock_init2();							//initialize millisecond interrupt and timers
	SysTick_init();
	HW_userCOM_init();								//initialize user USART, USART interrupt, and message buffers
	link_tasks(devicelist,devnum);

	while (1) {
		MoT_doTasks(devicelist);	//in MoTservices*.S
	}

}
