@;	MoTdevice_DAC1.S
@;	uses renamed macros from MoTstructures.h

	#define __ASSEMBLY__	@;for MoTstructures.h -- selects assembly macro definitions instead of C structs
	#include "MoTstructures.h"
	.equ NULL, 0			@;for returning NULL pointr various places

	@;register equates 
	rLISTP 		.req r4	@;points to the device_list[] defined in main()
	rDEVP		.req r5	@;points to the device data of the current active task.

	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed 
	.thumb							@; we are using thumb instructions only

	.text							@; macros below place variable data in initialized .data, the rest in .text

	.equ 	TIM2_BASE,	(0x40000000)	@; origin of TIM2 control register array
	.equ 	TIM4_BASE,	(0x40000800)	@; origin of TIM2 control register array
	.equ	CR1,		0x00
	.equ	ARR,		0x2C
@; ----- DAC1 command dispatch
	.global DAC1_cmdHandler		@;this is a void/void* function referenced in main()
	.thumb_func
DAC1_cmdHandler:	@; void DAC1_cmdHandler(void *); //first byte at void* is the secondary dispatch index.
	@; The command dispatcher branches here from the devicelist entry after receiving a valid command string 
	@; The first byte of a MoT command was the index into the devicelist which dispatched this cmdHandler (see main())  
	@; The second byte in the MoT command selects and wxecutes a command in DAC1_cmds[] jump table below
	@; subsequent bytes in the command may be arguments of any type depending on the device specification. 
	@; See DAC1_cmds (below) for the actions of various command DAC1 command codes.
	push {r7,lr}		@; 'push' balanced with a matching 'pop' at exit of the routines in the dispatch table below
	ldrb r1,[r0],#1		@; read command from the command buffer and advance r0 to point to the argument list (if any) 
	and r1,0x07			@; limit range of command codes to 0-7 for safety 	
	tbb [pc,r1]
DAC1_cmds:
	.byte (DAC1_INITcmd - DAC1_cmds)/2			@; DAC1 command #0 initialize DAC1_CH2 hardware.
	.byte (DAC1_CONSTANTcmd - DAC1_cmds)/2		@; DAC1 command #1 outputs a constant voltage to DAC1_CH2
												@; which is connected to the userLED.
	.byte (DAC1_PULSEcmd - DAC1_cmds)/2			@; DAC1 command #2 outputs a pulse of Vlo for T1 msec and Vhi for T2 msec
	.byte (DAC1_SINcmd - DAC1_cmds)/2			@; DAC1 command #3 outputs a sine wave of desired frequency (100 Hz to 3 kHz)
	.byte (DAC1_SKIPinstall - DAC1_cmds)/2		@; DAC1 command #4 installs DAC1 task skipper.
	.align 1 @;!!important to do this where odd-byte alignment is possible

@; ----- DAC1 data structure allocations
@; '_m' macros  below (MoT_core_m, MoT_msgLink_m, MoT_cmdLink_m) create data structures for this device in .data

	@; IMPORTANT! The 'MoT_core_m' macro must create the first variable defined in the device's data structure
	@; macro arguments: name for the device, name of the device's command handler, name of the default task
	MoT_core_m DAC1, DAC1_cmdHandler, DAC1_skiptask @; create device with initialized command & task ptrs

@;create any local variables needed use by device commands and tasks using the MoT_varAlloc_m macro
	MoT_varAlloc_m DAC1_delay1, DAC1_T1
	MoT_varAlloc_m DAC1_delay2, DAC1_T2
	MoT_varAlloc_m DAC1_Vlo, DAC1_LOW
	MoT_varAlloc_m DAC1_Vhi, DAC1_HIGH
	MoT_varAlloc_m DAC1_sin_enabled, DAC1_SIN_EN, 0x00
	MoT_varAlloc_m DAC1_sin_position, DAC1_SIN_POS, 0x00
	MoT_varAlloc_m DAC1_sin_amplitude, DAC1_SIN_AMPL, 0x0FFF

@;create any constant messages needed for reporting device information using the MoT_msgLink_m macro
	MoT_msgLink_m INITIALIZED_msg, INITIALIZED_msgtxt, INITIALIZED_msglen,
	INITIALIZED_msgtxt:
	.ascii "DAC1 is initialized\n\r\0"
	.equ INITIALIZED_msglen, ( . - INITIALIZED_msgtxt)

	MoT_msgLink_m CONSTANT_msg, CONSTANT_msgtxt, CONSTANT_msglen,
	CONSTANT_msgtxt:
	.ascii "DAC1 is outputting a constant voltage\n\r\0"
	.equ CONSTANT_msglen, ( . - CONSTANT_msgtxt)

	MoT_msgLink_m PULSE_msg, PULSE_msgtxt, PULSE_msglen,
	PULSE_msgtxt:
	.ascii "DAC1 is outputting a pulse\n\r\0"
	.equ PULSE_msglen, ( . - PULSE_msgtxt)

	MoT_msgLink_m SIN_msg, SIN_msgtxt, SIN_msglen,
	SIN_msgtxt:
	.ascii "DAC1 is outputting a sine wave\n\r\0"
	.equ SIN_msglen, ( . - SIN_msgtxt)

	MoT_msgLink_m SIN_STOP_msg, SIN_STOP_msgtxt, SIN_STOP_msglen,
	SIN_STOP_msgtxt:
	.ascii "DAC1 has stopped active sine wave\n\r\0"
	.equ SIN_STOP_msglen, ( . - SIN_STOP_msgtxt)

	MoT_msgLink_m SKIP_msg, SKIP_msgtxt, SKIP_msglen,
	SKIP_msgtxt:
	.ascii "DAC1 is skipping\n\r\0"
	.equ SKIP_msglen, ( . - SKIP_msgtxt)

@;create a default message for messages created with MoT_msgLink_m which lack explicit initial message references
	DEFAULT_MSGTXT:	@;note: labels 'DEFAULT_MSGTXT' and 'DEFAULT_MSGLEN' are required by default message macro
	.ascii "this is the default message\n\r\0"
	.equ DEFAULT_MSGLEN, ( . - DEFAULT_MSGTXT)

	.align 1

@; ----- DAC1 commands
@; DAC1_cmdHandler() (above) dispatches the commands below.
@; Upon execution, commands perform some operation and then post a message on the message queue 'consoleMsgs'   
@; IMPORTANT: DAC1_cmdHandler() saves its entering context with 'push {r7,lr}', so commands below must exit with 'pop {r7,pc}'

	.thumb_func
DAC1_INITcmd:
//	push {r7,lr}								@; done above at command entry, so dont do here!
	bl DAC1_CH2_init							@; in \LL_device_support\stm32G491RE_MoT_DAC1.S

	@; post the 'initialized' message
	add r0,rDEVP,#INITIALIZED_msg				@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}									@; command is completed

	.thumb_func
DAC1_CONSTANTcmd:
//	push {r7,lr}								@; done above at command entry, so dont do here!

	ldrh r1,[r0]
	bl DAC1_CH2_output_constant					@; in \LL_device_support\stm32G491RE_MoT_DAC1.S

	@; post the 'constant' message

	add r0,rDEVP,#CONSTANT_msg					@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}									@; command is completed

	.thumb_func
DAC1_PULSEcmd:
//	push {r7,lr}		@; done above at command entry, so dont do here!
	bl TIM2_init

	ldrh r1,[r0]		@; load T1
	mov r2, #1000		@; convert msec to usec
	mul r1, r1, r2		@; ..
	str r1, [rDEVP, #DAC1_T1]	@; store T1

	ldr r1,[r0]			@; load T2
	lsr r1, r1, 0x10	@; delete lower byte
	mov r2, #1000		@; convert msec to usec
	mul r1, r1, r2		@; ..
	str r1, [rDEVP, #DAC1_T2]	@; store T2

	ldrh r1, [r0, 0x4]	@; load voltage 1

	ldr r2, [r0, 0x4]	@; load voltage 2
	lsr r2, r2, 0x10	@; delete lower byte

	push {r1, r2}		@; sort r1 and r2 into lowest and biggest voltage respectively
	cmp r1, r2			@; ..
	itte hi				@; if r1 is higher than r2 then swap so Vlo is in r1
	pophi {r2}			@; split into two instruction to avoid warning
	pophi {r1}			@; ..
	popls {r1, r2}		@; pop back to original to restore stack

	str r1, [rDEVP, #DAC1_LOW]		@; store low voltage
	str r2, [rDEVP, #DAC1_HIGH]		@; store high voltage

	mov r0, 0x0
	ldr r1, [rDEVP, #DAC1_T1]
	bl TIM2_pulse_usec				@; in \LL_device_support\stm32G491RE_MoT_TIM2.S

	ldr r1, [rDEVP, #DAC1_LOW]
	bl DAC1_CH2_output_constant		@; in \LL_device_support\stm32G491RE_MoT_DAC1.S

	MOV_imm32 r0,DAC1_pulsetaskT1
	mov r1,#NULL
	bl MoT_taskUpdate

	@; post the 'pulse' message
	add r0,rDEVP,#PULSE_msg						@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}

.global DAC1_SINcmd
	.thumb_func
DAC1_SINcmd:
	ldrb r1, [rDEVP, #DAC1_SIN_EN]
	cmp r1, 0x1
	beq 1f

	mov r1, 0x1						@; set enable bit high
	str r1, [rDEVP, #DAC1_SIN_EN]	@; ..

	ldrh r1, [r0]			@; load frequency
	mov r2, #128			@; 128 points in sine wave
	mul r1, r2				@; calculate step (interrupt) frequency (# of points * wave frequency)
	MOV_imm32 r2, #36000000	@; timer_freq = 36 MHz
	udiv r1, r2, r1			@; timer_freq/step_freq
	sub r1, r1, #1			@; subtract 1; ARR calculated

	bl TIM4_init			@; in \LL_device_support\stm32G491RE_MoT_TIM4.S

	ldr r3, =TIM4_BASE
	@;set TIM4 counter reload value
	str r1,[r3,#ARR]	@; calculated ARR

	ldr r1, [r0]		@; load amplitude
	lsr r1, r1, 0x10	@; delete lower byte
	str r1, [rDEVP, #DAC1_SIN_AMPL]

	add r0,rDEVP,#SIN_msg						@; r0= address of the 'SIN' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)

	b 2f

1:	ldr r3, =TIM4_BASE
	mov r1, 0x00			@; block TIM4
	str r1,[r3,#ARR]		@; ..

	str r1, [rDEVP, #DAC1_SIN_EN]	@; set enable bit low

	add r0,rDEVP,#SIN_STOP_msg					@; r0= address of the 'SIN' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)

2:	pop {r7, pc}

	.global DAC1_SKIPinstall					@; made global for debug
	.thumb_func
DAC1_SKIPinstall:
	MOV_imm32 r0,DAC1_skiptask
	mov r1,#NULL
	bl MoT_taskUpdate

	add r0,rDEVP,#SKIP_msg						@; r0= address of the 'skip' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks
	@;return to cmdHandlers caller
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

	.thumb_func
DAC1_NOP:  @; DAC1 command #6 and  #7 are placeholders for unimplemented commands
	@;return to cmdHandlers caller
//	push {r7,lr}								@; done above at command entry, so dont do here
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

@; ----- DAC1  tasks
@; One of the tasks below always executes on each cycle of the while(1) in main().
@; DAC1_skiptask is installed by default at device definition time (see MoT_core_m at top)
@; DAC1_ONtask is installed by the DAC1_BLINKinstall command above
@; DAC1_OFFtask is installed by DAC1_ONtask
@; The currently selected task of each/every device runs once per system task-cycle (one cycle of main's while(1))

@; When a device has nothing to do, a 'skiptask' must execute to continue the task sequence of the task-cycle
	.global DAC1_skiptask 					@;default DAC1 initial task. made global for debug
	.thumb_func
DAC1_skiptask:								@; the DAC1 default task
	@; proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

	.global DAC1_pulsetaskT1
	.thumb_func
DAC1_pulsetaskT1:
	ldr r3, =TIM2_BASE		@; Base address of TIM2
	ldr r2, [r3, #CR1]		@; check if pulse is already happening
	tst r2, 0x1				@; if CEN = 1
	bne 1f					@; branch to exit

	@; done waiting here
	mov r0, 0x0
	ldr r1, [rDEVP, #DAC1_T2]
	bl TIM2_pulse_usec				@; in \LL_device_support\stm32G491RE_MoT_TIM2.S

	ldr r1, [rDEVP, #DAC1_HIGH]
	bl DAC1_CH2_output_constant		@; in \LL_device_support\stm32G491RE_MoT_DAC1.S

	MOV_imm32 r0, DAC1_pulsetaskT2
	mov r1, #NULL
	bl MoT_taskUpdate

1:	@; proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

	.global DAC1_pulsetaskT2
	.thumb_func
DAC1_pulsetaskT2:
	ldr r3, =TIM2_BASE		@; Base address of TIM2
	ldr r2, [r3, #CR1]		@; check if pulse is already happening
	tst r2, 0x1				@; if CEN = 1
	bne 1f					@; branch to exit

	@; done waiting here
	mov r1, 0x00				@; set output voltage to zero
	bl DAC1_CH2_output_constant	@; in \LL_device_support\stm32G491RE_MoT_DAC1.S

	MOV_imm32 r0, DAC1_skiptask	@; reinstall skip task
	mov r1, #NULL
	bl MoT_taskUpdate

1:	@; proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device
