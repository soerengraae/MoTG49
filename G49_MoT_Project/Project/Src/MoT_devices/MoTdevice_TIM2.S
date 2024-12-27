@;  MoTdevice_TIM2.S
@;	uses renamed macros from MoTstructures.h

	#define __ASSEMBLY__			@; For MoTstructures.h -- selects assembly macro definitions instead of C structs
	#include "MoTstructures.h"
	.equ NULL,0						@; For returning NULL pointr various places

	@; Register equates
	rLISTP 		.req r4				@; Points to the device_list[] defined in main()
	rDEVP		.req r5				@; Points to the device data of the current active task.

	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed 
	.thumb							@; We are using thumb instructions only

	.text							@; Macros below place variable data in initialized .data, the rest in .text

@; ----- TIM2 command dispatch
@; Definitions of the green LED command functions and tasks follow 
	.global TIM2_cmdHandler		@; This is a void/void* function referenced in main()
	.thumb_func
TIM2_cmdHandler:	@; void TIM2_cmdHandler(void *); //first byte at void* is the secondary dispatch index.
	@; The command dispatcher branches here from the devicelist entry after receiving a valid command string 
	@; The first byte of a MoT command was the index into the devicelist which dispatched this cmdHandler (see main())  
	@; The second byte in the MoT command selects and wxecutes a command in TIM2_cmds[] jump table below
	@; subsequent bytes in the command may be arguments of any type depending on the device specification. 
	@; See TIM2_cmds (below) for the actions of various command TIM2 command codes.
	push {r7,lr}		@; 'push' balanced with a matching 'pop' at exit of the routines in the dispatch table below
	ldrb r1,[r0],#1		@; Read command from the command buffer and advance r0 to point to the argument list (if any)
	and r1,0x07			@; Limit range of command codes to 0-7 for safety
	tbb [pc,r1]
TIM2_cmds:
	.byte (TIM2_INITcmd - TIM2_cmds)/2			@; TIM2 command #0 initializes timer hardware
	.byte (TIM2_PULSE_ONEcmd - TIM2_cmds)/2		@; TIM2 command #1 sends a single output pulse
	.byte (TIM2_PULSE_STREAMcmd - TIM2_cmds)/2	@; TIM2 command #2 installs the pulse stream task
	.byte (TIM2_SKIPinstall - TIM2_cmds)/2		@; TIM2 command #3 installs TIM2 task skipper
	.align 1 @;!!important to do this where odd-byte alignment is possible

@; ----- TIM2 data structure allocations
@; '_m' macros  below (MoT_core_m, MoT_msgLink_m, MoT_cmdLink_m) create data structures for this device in .data

	@; IMPORTANT! The 'MoT_core_m' macro must create the first variable defined in the device's data structure
	@; macro arguments: name for the device, name of the device's command handler, name of the default task
	MoT_core_m TIM2, TIM2_cmdHandler, TIM2_skiptask @; create device with initialized command & task ptrs

@;create any local variables needed use by device commands and tasks using the MoT_varAlloc_m macro
	MoT_varAlloc_m TIM2_delay, TIM2_DELAY
	MoT_varAlloc_m TIM2_duration, TIM2_DURATION

	.equ 	TIM2_BASE,			(0x40000000)	@; origin of TIM2 control register array
	.equ	CR1,				0x00

@;create any constant messages needed for reporting device information using the MoT_msgLink_m macro
	MoT_msgLink_m INITIALIZED_msg, INITIALIZED_msgtxt, INITIALIZED_msglen,
	INITIALIZED_msgtxt: 
	.ascii "TIM2 is initialized\n\r\0"
	.equ INITIALIZED_msglen, ( . - INITIALIZED_msgtxt)

	MoT_msgLink_m PULSE_ONE_msg, PULSE_ONE_msgtxt, PULSE_ONE_msglen,
	PULSE_ONE_msgtxt:
	.ascii "TIM2 is sending 1 (one) pulse\n\r\0"
	.equ PULSE_ONE_msglen, ( . - PULSE_ONE_msgtxt)

	MoT_msgLink_m PULSE_STREAM_msg, PULSE_STREAM_msgtxt, PULSE_STREAM_msglen,
	PULSE_STREAM_msgtxt:
	.ascii "TIM2 is generating pulses\n\r\0"
	.equ PULSE_STREAM_msglen, ( . - PULSE_STREAM_msgtxt)

	MoT_msgLink_m skip_msg, skip_msgtxt, skip_msglen,
	skip_msgtxt:
	.ascii "TIM2 is skipping\n\r\0"
	.equ skip_msglen, ( . - skip_msgtxt)

@;create a default message for messages created with MoT_msgLink_m which lack explicit initial message references
	DEFAULT_MSGTXT:	@;note: labels 'DEFAULT_MSGTXT' and 'DEFAULT_MSGLEN' are required by default message macro
	.ascii "this is the default message\n\r\0"
	.equ DEFAULT_MSGLEN, ( . - DEFAULT_MSGTXT)

	.align 1

@; ----- TIM2 commands
@; TIM2_cmdHandler() (above) dispatches the commands below.
@; Upon execution, commands perform some operation and then post a message on the message queue 'consoleMsgs'   
@; IMPORTANT: TIM2_cmdHandler() saves its entering context with 'push {r7,lr}', so commands below must exit with 'pop {r7,pc}'

	.thumb_func
TIM2_INITcmd:
//	push {r7,lr}								@; done above at command entry, so dont do here!
	bl TIM2_init								@; in \LL_device_support\stm32G491RE_MoT_TIM2.S
	bl TIM2_connect_CH1_to_PA5					@; in \LL_device_support\stm32G491RE_MoT_TIM2.S

	@; post the 'initialized' message
	add r0,rDEVP,#INITIALIZED_msg				@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}									@; command is completed

	.global TIM2_PULSE_ONEcmd				@;made global for debug
	.thumb_func
TIM2_PULSE_ONEcmd:	@; function outputs one pulse with given delay and duration.
					@; Delay and duration shall be given in msec
//	push {r7,lr}	@; done above at command entry, so dont do here
	ldrh r1, [r0], 0x2
	mov r2, #1000		@; convert msec to usec
	mul r1, r1, r2		@; ..

	ldrh r0, [r0]
	mul r0, r0, r2		@; convert msec to usec

	push {r0}		@; Reorder
	mov r0, r1		@; ..
	pop {r1}		@; ..

	bl TIM2_pulse_usec

	add r0,rDEVP,#PULSE_ONE_msg					@; r0= address of the 'pulse' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?)
	pop {r7,pc}									@; command is completed

	.global TIM2_PULSE_STREAMcmd				@;made global for debug
	.thumb_func
TIM2_PULSE_STREAMcmd:	@;function outputs one pulse with given delay and duration.
					@; Delay and duration shall be given in msec
//	push {r7,lr}							@; done above at command entry, so dont do here

	ldrh r1, [r0]					@; Load delay input
	str r1, [rDEVP, #TIM2_DELAY]	@; Store delay

	ldrh r1, [r0, 0x2]				@; Load duration input
	str r1, [rDEVP, #TIM2_DURATION]	@; Store duration

	ldr r0, [rDEVP, #TIM2_DELAY]
	ldr r1, [rDEVP, #TIM2_DURATION]

	@; Start pulse
	bl TIM2_pulse_usec

	@; Install PULSE_STREAMtask
	MOV_imm32 r0,TIM2_PULSE_STREAMtask
	mov r1,#NULL
	bl MoT_taskUpdate

	@; Post message PULSE_STREAMmsg
	add r0,rDEVP,#PULSE_STREAM_msg				@; r0= address of the 'PULSE' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?)
	pop {r7,pc}									@; command is completed

	.global TIM2_SKIPinstall					@; made global for debug
	.thumb_func
TIM2_SKIPinstall:
	MOV_imm32 r0,TIM2_skiptask
	mov r1,#NULL
	bl MoT_taskUpdate

	add r0,rDEVP,#skip_msg					@; r0= address of the 'pulse' message
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks
	@;return to cmdHandlers caller
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

	.thumb_func
TIM2_NOP:  @; TIM2 command #6 and  #7 are placeholders for unimplemented commands
	@;return to cmdHandlers caller
//	push {r7,lr}								@; done above at command entry, so dont do here
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

@; ----- TIM2  tasks
@; One of the tasks below always executes on each cycle of the while(1) in main().
@; TIM2_skiptask is installed by default at device definition time (see MoT_core_m at top)
@; TIM2_ONtask is installed by the TIM2_BLINKinstall command above
@; TIM2_OFFtask is installed by TIM2_ONtask
@; The currently selected task of each/every device runs once per system task-cycle (one cycle of main's while(1))

@; When a device has nothing to do, a 'skiptask' must execute to continue the task sequence of the task-cycle
	.global TIM2_skiptask 					@;default TIM2 initial task. made global for debug
	.thumb_func
TIM2_skiptask:								@; the TIM2 default task
	@; proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

	.global TIM2_PULSE_STREAMtask
	.thumb_func
TIM2_PULSE_STREAMtask:		@;  arrive here with rDEVP pointing to this device's data
	ldr r3, =TIM2_BASE		@; Base address of TIM2
	ldr r2, [r3, #CR1]		@; Check if pulse is already happening/TIM2 is running
	tst r2, 0x1				@; ..
	bne 6f					@; if CEN != 0 (CEN == 1); branch to exit

	@; here when no pulse is running
	@; send new pulse
	ldr r0, [rDEVP,#TIM2_DELAY]		@; load delay value
	mov r2, #1000		@; ..
	mul r0, r0, r2		@; convert msec to usec
	ldr r1, [rDEVP,#TIM2_DURATION]	@; load duration value
	mov r2, #1000		@; ..
	mul r1, r1, r2		@; convert msec to usec
	bl TIM2_pulse_usec				@; output pulse

6:	@; task for this device is done for now -- proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device
