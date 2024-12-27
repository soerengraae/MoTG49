//mpaland_printf_services.c wmh 2023-11-12 : custom functions to create message strings for devices
//  MoT devices wishing to use mpaland's printf()/sprintf()/snprintf/vsnprintf() functions will create a custom functions here.
//
//MoTdevice_printfDemo.c wmh 2023-11-07 : helper function for MoTdevice_printfDemo.S 

#include "stdint-gcc.h"	//for uint8_t, uint16_t, uint32_t  etc. 

#include <stddef.h> 
#include <string.h>
#include "mpaland_printf.h"

uint32_t device9_printMSG1(char * buf)
{
	extern int16_t ADC1_avg; //defined in main, updated in DMA1_Channel1_IRQHandler, to be reported by device9

	sprintf(buf,"average of ADC1 readings= %d\n", ADC1_avg);
	return strlen(buf);
}

uint32_t device3_printMSGTX(char *buf, char data)
{
	sprintf(buf,"SPI2 transmitted 0x%02X!\r\n", data);
	return strlen(buf);
}

uint32_t device3_printMSGRX(char *buf, char data)
{
	sprintf(buf,"SPI2 received 0x%02X!\r\n", data);
	return strlen(buf);
}
