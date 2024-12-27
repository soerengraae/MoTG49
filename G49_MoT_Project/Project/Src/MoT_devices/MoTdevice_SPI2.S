@;  MoTdevice_SPI2.S
@;	uses renamed macros from MoTstructures.h

	#define __ASSEMBLY__			@;for MoTstructures.h -- selects assembly macro definitions instead of C structs
	#include "MoTstructures.h"

	.equ NULL,0					@;for returning NULL pointr various places

	@;register equates
	rLISTP 		.req r4				@;points to the device_list[] defined in main()
	rDEVP		.req r5				@;points to the device data of the current active task.

	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.macro ADD_TX value, offset
		mov r1, \value
		ldr r2, =SPI2_transmitbuffer
		str r1, [r2, \offset]
	.endm

	.macro SET_BBCMD cmd
		MOV_imm32 r1, \cmd				@; Set cmd as branch-back command
		str r1, [rDEVP, #SPI2_CMD]		@; ..
	.endm

	.macro POST_BBCMD
		ldr r0, [rDEVP, #SPI2_CMD]
		MOV_imm32 r1,internalCmds
		bl MoT_cmdPost
	.endm

	@; BSTEP supports up to 4 branches.
	@; If more is needed, simply set SPI2_CMDSTEP to the needed value and use another BSTEP
	.macro BSTEP
		ldr r1, [rDEVP, #SPI2_CMDSTEP]
		sub r1, r1, 0x1		@; Adjusts CMPSTEP so it matches the label.
							@; Example: OLD: CMDSTEP = 1, goes to 2f; ADJUSTED: CMDSTEP = 1, goes to 1f.
		tbb [pc, r1]
		0:
		.byte (1f - 0b)/2
		.byte (2f - 0b)/2
		.byte (3f - 0b)/2
		.byte (4f - 0b)/2
		.align 1
	.endm

	.macro SET_CMDSTEP value
		mov r1, #\value
		str r1, [rDEVP, #SPI2_CMDSTEP]
	.endm

	.macro RESET_CMDSTEP
		mov r1, 0x01
		str r1, [rDEVP, #SPI2_CMDSTEP]
	.endm

	.macro SET_INSTRUCTIONLENGTH value
		mov r1, \value
		sub r1, r1, 0x1			@; Adjust to fit instruction task.
		str r1, [rDEVP, #SPI2_INSTRUCTIONLENGTH]
	.endm

	.macro SEND_INSTRUCTION
		MOV_imm32 r0,SPI2_INSTRUCTIONtask
		mov r1,#NULL
		bl MoT_taskUpdate
	.endm

	.macro PRINTMSG	message
		add r0,rDEVP,#\message\()_msg	@; \message contains the message to post (excluding 'msg')
		MOV_imm32 r1,consoleMsgs		@; consoleMsgs is defined in MoTdevice_device0
		bl MoT_msgPost
	.endm

	.macro PRINTMSG_YES						@; Use in command/task to enable printing received byte
		mov r1, 0x1
		str r1, [rDEVP, #SPI2_PRINTRXBYTE]
	.endm

	.macro PRINTMSG_NO						@; Use in command/task to disable printing received byte
		mov r1, 0x0
		str r1, [rDEVP, #SPI2_PRINTRXBYTE]
	.endm

	.syntax unified				@; ARM Unified Assembler Language (UAL) is allowed
	.thumb						@; We are using thumb instructions only

	@; Maximum allowed fails for either transmitting or receiving a byte
	.equ	MAX_FAILS,			10

	.text							@; Macros below place variable data in initialized .data, the rest in .text
@; ----- SPI2 command dispatch
	.global SPI2_cmdHandler		@;this is a void/void* function referenced in main()
	.thumb_func
SPI2_cmdHandler:	@; void SPI2_cmdHandler(void *); //first byte at void* is the secondary dispatch index.
	@; The command dispatcher branches here from the devicelist entry after receiving a valid command string 
	@; The first byte of a MoT command was the index into the devicelist which dispatched this cmdHandler (see main())  
	@; The second byte in the MoT command selects and wxecutes a command in SPI2_cmds[] jump table below
	@; subsequent bytes in the command may be arguments of any type depending on the device specification. 
	@; See SPI2_cmds (below) for the actions of various command SPI2 command codes.
	push {r7,lr}		@; 'push' balanced with a matching 'pop' at exit of the routines in the dispatch table below
	ldrb r1,[r0],#1		@; Read command from the command buffer and advance r0 to point to the argument list (if any)
	and r1,0x07			@; Limit range of command codes to 0-7 for safety
	tbh [pc,r1]
SPI2_cmds:
	.hword (SPI2_INITcmd - SPI2_cmds)/2			@; SPI2 command #0 initialize SPI2 hardware.
	.hword (SPI2_WHOAMIcmd - SPI2_cmds)/2		@; SPI2 command #1 performs WHOAMI.
	.hword (SPI2_ERASEBLOCK64cmd - SPI2_cmds)/2	@; SPI2 command #2 erases (sets to 1) 64KB at address.
	.hword (SPI2_READBYTEcmd - SPI2_cmds)/2		@; SPI2 command #3 reads a byte at address.
	.hword (SPI2_WRITEBYTEcmd - SPI2_cmds)/2	@; SPI2 command #4 writes a byte at address.
	.hword (SPI2_SLAVEBSYcmd - SPI2_cmds)/2		@; SPI2 command #5 checks slaves busy flag.
	.align 1 @;!!important to do this where odd-byte alignment is possible

@; ----- SPI2 data structure allocations
@; '_m' macros  below (MoT_core_m, MoT_msgLink_m, MoT_cmdLink_m) create data structures for this device in .data

	@; IMPORTANT! The 'MoT_core_m' macro must create the first variable defined in the device's data structure
	@; macro arguments: name for the device, name of the device's command handler, name of the default task
	MoT_core_m SPI2, SPI2_cmdHandler, SPI2_skiptask @; create device with initialized command & task ptrs

	MoT_cmdLink_m SPI2_WHOAMI_cmd, SPI2_WHOAMI_cmdbin, SPI2_WHOAMI_cmdlen,
	SPI2_WHOAMI_cmdbin:
	.byte 3,1	@; Device 3 is this device, function 1 is SPI2_WHOAMIcmd
	.equ SPI2_WHOAMI_cmdlen, ( . - SPI2_WHOAMI_cmdbin)
	.align 1 @;!!important to do this where odd-byte alignment is possible

	MoT_cmdLink_m SPI2_ERASEBLOCK64_cmd, SPI2_ERASEBLOCK64_cmdbin, SPI2_ERASEBLOCK64_cmdlen,
	SPI2_ERASEBLOCK64_cmdbin:
	.byte 3,2	@; Device 3 is this device, function 2 is SPI2_ERASEBLOCK64cmd
	.equ SPI2_ERASEBLOCK64_cmdlen, ( . - SPI2_ERASEBLOCK64_cmdbin)
	.align 1 @;!!important to do this where odd-byte alignment is possible

	MoT_cmdLink_m SPI2_READBYTE_cmd, SPI2_READBYTE_cmdbin, SPI2_READBYTE_cmdlen,
	SPI2_READBYTE_cmdbin:
	.byte 3,3	@; Device 3 is this device, function 3 is SPI2_READBYTEcmd
	.equ SPI2_READBYTE_cmdlen, ( . - SPI2_READBYTE_cmdbin)
	.align 1 @;!!important to do this where odd-byte alignment is possible

	MoT_cmdLink_m SPI2_WRITEBYTE_cmd, SPI2_WRITEBYTE_cmdbin, SPI2_WRITEBYTE_cmdlen,
	SPI2_WRITEBYTE_cmdbin:
	.byte 3,4	@; Device 3 is this device, function 4 is SPI2_WRITEBYTEcmd
	.equ SPI2_WRITEBYTE_cmdlen, ( . - SPI2_WRITEBYTE_cmdbin)
	.align 1 @;!!important to do this where odd-byte alignment is possible

	MoT_cmdLink_m SPI2_SLAVEBSY_cmd, SPI2_SLAVEBSY_cmdbin, SPI2_SLAVEBSY_cmdlen,
	SPI2_SLAVEBSY_cmdbin:
	.byte 3,5	@; Device 3 is this device, function 5 is SPI2_SLAVEBSYcmd
	.equ SPI2_SLAVEBSY_cmdlen, ( . - SPI2_SLAVEBSY_cmdbin)
	.align 1 @;!!important to do this where odd-byte alignment is possible

	.equ RECEIVED_msglen, 0x15
	MoT_printbuffer_m RECEIVED_msgbuf, RECEIVED_msglen

	@; Create any local variables needed use by device commands and tasks using the MoT_varAlloc_m macro.
	MoT_varAlloc_m SPI2_cmdargumentsaddress, SPI2_CMDARGSADDR, 0x00
	@; This acts as a flag to tell the instruction task whether to post the RXMSG or not
	MoT_varAlloc_m SPI2_printreceivedbyte, SPI2_PRINTRXBYTE, 0x00
	MoT_varAlloc_m SPI2_receivebyte, SPI2_RXBYTE, 0x00
	MoT_varAlloc_m SPI2_fail, SPI2_FAILS, 0x00

	@; is used for the intruction task to know whether it's at transmitting or receiving
	MoT_varAlloc_m SPI2_instructionstep, SPI2_INSTRUCTIONSTEP, 0x00
	@; is used for the intruction task to know how many bytes to transmit
	MoT_varAlloc_m SPI2_instructionlength, SPI2_INSTRUCTIONLENGTH, 0x00
	@; is used to tell the instruction task which cmd called it, so it can branch back
	MoT_varAlloc_m SPI2_command, SPI2_CMD, 0x00
	@; is used for the commands to know whether to skip steps or not
	MoT_varAlloc_m SPI2_commandstep, SPI2_CMDSTEP, 0x01

	@; The longets instruction we allow is a Page Program with 256 data bytes (one page)
	@; 256 data bytes + 3 address bytes + 1 command byte = 260 bytes (0x104)
	MoT_bufAlloc_m SPI2_transmitbuffer, SPI2_TXBUFFER, 0x2, 260

@;create any constant messages needed for reporting device information using the MoT_msgLink_m macro
	MoT_msgLink_m RECEIVED_msg, RECEIVED_msgbuf, RECEIVED_msglen,

	MoT_msgLink_m INITIALIZED_msg, INITIALIZED_msgtxt, INITIALIZED_msglen,
	INITIALIZED_msgtxt:
	.ascii "SPI2 initialized!\n\r\0"
	.equ INITIALIZED_msglen, ( . - INITIALIZED_msgtxt)

	MoT_msgLink_m WHOAMI_msg, WHOAMI_msgtxt, WHOAMI_msglen,
	WHOAMI_msgtxt:
	.ascii "SPI2 is asking slave WHOAMI?\n\r\0"
	.equ WHOAMI_msglen, ( . - WHOAMI_msgtxt)

	MoT_msgLink_m ERASE64_msg, ERASE64_msgtxt, ERASE64_msglen,
	ERASE64_msgtxt:
	.ascii "SPI2 is erasing 64 KB block. Wait.\n\r\0"
	.equ ERASE64_msglen, ( . - ERASE64_msgtxt)

	MoT_msgLink_m READ_msg, READ_msgtxt, READ_msglen,
	READ_msgtxt:
	.ascii "SPI2 is reading byte.\n\r\0"
	.equ READ_msglen, ( . - READ_msgtxt)

	MoT_msgLink_m WRITING_msg, WRITING_msgtxt, WRITING_msglen,
	WRITING_msgtxt:
	.ascii "SPI2 is writing byte.\n\r\0"
	.equ WRITING_msglen, ( . - WRITING_msgtxt)

	MoT_msgLink_m DONE_msg, DONE_msgtxt, DONE_msglen,
	DONE_msgtxt:
	.ascii "Done.\n\r\0"
	.equ DONE_msglen, ( . - DONE_msgtxt)

	MoT_msgLink_m ERROR_msg, ERROR_msgtxt, ERROR_msglen,
	ERROR_msgtxt:
	.ascii "SPI2 instruction failed!!\n\r\0"
	.equ ERROR_msglen, ( . - ERROR_msgtxt)

	MoT_msgLink_m SKIP_msg, SKIP_msgtxt, SKIP_msglen,
	SKIP_msgtxt:
	.ascii "SPI2 is skipping\n\r\0"
	.equ SKIP_msglen, ( . - SKIP_msgtxt)

@;create a default message for messages created with MoT_msgLink_m which lack explicit initial message references
	DEFAULT_MSGTXT:	@;note: labels 'DEFAULT_MSGTXT' and 'DEFAULT_MSGLEN' are required by default message macro
	.ascii "this is the default message\n\r\0"
	.equ DEFAULT_MSGLEN, ( . - DEFAULT_MSGTXT)

	.align 1

@; ----- SPI2 commands
@; SPI2_cmdHandler() (above) dispatches the commands below.
@; Upon execution, commands perform some operation and then post a message on the message queue 'consoleMsgs'   
@; IMPORTANT: SPI2_cmdHandler() saves its entering context with 'push {r7,lr}', so commands below must exit with 'pop {r7,pc}'

	.thumb_func
SPI2_INITcmd:
//	push {r7,lr}							@; done above at command entry, so dont do here!
	str r0, [rDEVP, #SPI2_CMDARGSADDR]		@; Store the adddress for SPI2 arguments
	bl SPI2_init

	PRINTMSG INITIALIZED
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}									@; command is completed

	.thumb_func
SPI2_WHOAMIcmd:
	@; Commands that send the slave instruction must follow a specific configuration.
	@; Requries: SET_BBCMD, ADD_TX (at least one), PRINTMSG_YES/NO,
	@;			 SET_INSTRUCTIONLENGTH, SEND_INSTRUCTION, SET_CMDSTEP x
	@; Additionally it must have labels: 1, 2, 3, 4.
	@; RESET_CMDSTEP and pop {r7, pc} must be in different labels. This ensures that BSTEP doesn't branch
	@; to 1 when it returns from the instruction (which will cause an infinite loop).
	BSTEP

1:	@; Add bytes to transmit buffer.
	@; First byte to be transmitted is at position 259 - instruction length
	@; Instruction length = # of bytes to transmit - 1
	@; Example: JEDECID instruction has 4 bytes, so first byte is at 256 (259 - (4 - 1) = 259 - 3 = 256)
	@; We only use 2 bytes as we just want to read Manufacture ID
	ADD_TX 0x9F, 258	@; (instruction)
	ADD_TX 0x9F, 259	@; (dummy)
	SET_INSTRUCTIONLENGTH #2	@; Set length of instruction. This is the # of bytes to transmit

	PRINTMSG_YES
	PRINTMSG WHOAMI
	SEND_INSTRUCTION

	SET_CMDSTEP 2

	@; The command used with SET_BBCMD must be defined as a cmdLink further up.
	@; Notice we're not using WHOAMIcmd but WHOAMI_cmd; WHOAMI_cmd is a link to WHOAMIcmd.
	SET_BBCMD SPI2_WHOAMI_cmd

	b 3f	@; exit command

2:	@; reset CMDSTEP and exit command
	RESET_CMDSTEP

3:
4:	pop {r7,pc}		@; command is completed

	.thumb_func
SPI2_WRITEENABLE:
@; This function sends the Write Enable instruction to the external flash module.
@; The function is internal; used by commands.
	push {r7, lr}

	ADD_TX 0x06, 259	@; (instruction)
	PRINTMSG_NO
	SET_INSTRUCTIONLENGTH #1	@; Set length of instruction. This is the # of bytes to transmit
	SEND_INSTRUCTION

	pop {r7,pc}

	.thumb_func
SPI2_ERASEBLOCK64cmd:
	@; Commands that send the slave instruction must follow a specific configuration.
	@; Requries: SET_BBCMD, ADD_TX (at least one), PRINTMSG_YES/NO,
	@;			 SET_INSTRUCTIONLENGTH, SEND_INSTRUCTION, SET_CMDSTEP x
	@; Additionally it must have labels: 1, 2, 3, 4.
	@; RESET_CMDSTEP and pop {r7, pc} must be in different labels. This ensures that BSTEP doesn't branch
	@; to 1 when it returns from the instruction (which will cause an infinite loop).

	BSTEP

1:	SET_BBCMD SPI2_ERASEBLOCK64_cmd

	bl SPI2_WRITEENABLE

	SET_CMDSTEP 2
	b 3f

2:	ldr r0, [rDEVP, #SPI2_CMDARGSADDR]
	ADD_TX 0xD8, 256			@; (instruction)
	ldrb r1, [r0], #1
	ADD_TX r1, 257				@; (A23	- A16)
	ldrb r1, [r0], #1
	ADD_TX r1, 258				@; (A15 - A8)
	ldrb r1, [r0], #1
	ADD_TX r1, 259 				@; (A7	- A0)
	SET_INSTRUCTIONLENGTH #4	@; Set length of instruction. This is the # of bytes to transmit

	PRINTMSG_NO			@; Redundant but added for good measure
	PRINTMSG ERASE64
	SET_BBCMD SPI2_SLAVEBSY_cmd
	SEND_INSTRUCTION

	RESET_CMDSTEP
3:
4:	pop {r7,pc}		@; command is completed

	.thumb_func
SPI2_READBYTEcmd:
	BSTEP

1:	ldr r0, [rDEVP, #SPI2_CMDARGSADDR]
	ADD_TX 0x03, 255			@; (instruction)
	ldrb r1, [r0], #1
	ADD_TX r1, 256				@; (A23	- A16)
	ldrb r1, [r0], #1
	ADD_TX r1, 257				@; (A15 - A8)
	ldrb r1, [r0], #1
	ADD_TX r1, 258 				@; (A7	- A0)
	ADD_TX 0x00, 259 			@; (dummy)
	SET_INSTRUCTIONLENGTH #5	@; Set length of instruction. This is the # of bytes to transmit

	PRINTMSG_YES
	PRINTMSG READ
	SET_BBCMD SPI2_READBYTE_cmd
	SEND_INSTRUCTION

	SET_CMDSTEP 2

	b 3f

2:	RESET_CMDSTEP

3:
4:	pop {r7, pc}

	.thumb_func
SPI2_WRITEBYTEcmd:
	@; Commands that send the slave instruction must follow a specific configuration.
	@; Requries: SET_BBCMD, ADD_TX (at least one), PRINTMSG_YES/NO,
	@;			 SET_INSTRUCTIONLENGTH, SEND_INSTRUCTION, SET_CMDSTEP x
	@; Additionally it must have labels: 1, 2, 3, 4.
	@; RESET_CMDSTEP and pop {r7, pc} must be in different labels. This ensures that BSTEP doesn't branch
	@; to 1 when it returns from the instruction (which will cause an infinite loop).

	BSTEP

1:	SET_BBCMD SPI2_WRITEBYTE_cmd

	bl SPI2_WRITEENABLE

	SET_CMDSTEP 2
	b 3f

2:	ldr r0, [rDEVP, #SPI2_CMDARGSADDR]
@; As a Page Program instruction doesn't have a fixed size, the first input is the number of data bytes to write.
@; This is used to calculate the total size of the instruction.

	ldrb r1, [r0], #1			@; Load # of bytes to write
	add r1, r1, 0x3				@; Increment length by 3 address bytes
	add r1, r1, 0x1				@; Increment length by 1 instruction byte
	SET_INSTRUCTIONLENGTH r1	@; Set length of instruction. This is the # of bytes to transmit as calculated above
	add r1, r1, 0x1				@; SET_INSTRUCTIONLENGTH modifies r1 by -1 so we add it back

	mov r3, #260				@; Calculate starting position of instruction
	sub r3, r3, r1				@; Subtract # of bytes to write
								@; Example: 1 byte to write, 3 address bytes, 1 instruction
								@; Posiiton = 260 - 1 - (3 + 1) = 255
	ADD_TX 0x02, r3				@; (instruction)
	add r3, r3, 0x1				@; Increment position by 1

WRITELoop:
	ldrb r2, [r0], #1			@; Load address/write-byte
	ADD_TX r2, r3 				@; (byte; either address or data to write)
	add r3, r3, 0x1				@; Increment position by 1
	cmp r3, #260				@; Did we reach end of buffer?
	bne	WRITELoop				@; Loop if not, if yes move on

	PRINTMSG_NO					@; Redundant but added for good measure
	PRINTMSG WRITING
	SET_BBCMD SPI2_SLAVEBSY_cmd
	SEND_INSTRUCTION

	RESET_CMDSTEP
3:
4:	pop {r7,pc}		@; command is completed

	.thumb_func
SPI2_SLAVEBSYcmd:
@; While the user does have access to this command, it's only intended for inter-Device usage.
@; User usage is not illegal, just primarily useless.

	@; Commands that send the slave instruction must follow a specific configuration.
	@; Requries: SET_BBCMD, ADD_TX (at least one), PRINTMSG_YES/NO,
	@;			 SET_INSTRUCTIONLENGTH, SEND_INSTRUCTION, SET_CMDSTEP x
	@; Additionally it must have labels: 1, 2, 3, 4.
	@; RESET_CMDSTEP and pop {r7, pc} must be in different labels. This ensures that BSTEP doesn't branch
	@; to 1 when it returns from the instruction (which will cause an infinite loop).
	BSTEP

1:	ADD_TX 0x05, 258	@; (instruction)
	ADD_TX 0x05, 259	@; (dummy)
	SET_INSTRUCTIONLENGTH 2

	PRINTMSG_NO
	SET_BBCMD SPI2_SLAVEBSY_cmd
	SEND_INSTRUCTION

	SET_CMDSTEP 2
	b 3f

2:	ldr r1, [rDEVP, #SPI2_RXBYTE]
	tst r1, 0x1
	bne 1b			@; If busy flag is high, go to step one to read again
					@; Else, don't read again - just exit

	PRINTMSG DONE
	RESET_CMDSTEP

3:
4:	pop {r7, pc}

	.thumb_func
SPI2_SKIPinstall:
	MOV_imm32 r0,SPI2_skiptask
	mov r1,#NULL
	bl MoT_taskUpdate

	PRINTMSG SKIP
	@;return to cmdHandlers caller
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

	.thumb_func
SPI2_NOP:  @; SPI2 command #6 and  #7 are placeholders for unimplemented commands
	@;return to cmdHandlers caller
//	push {r7,lr}								@; done above at command entry, so dont do here
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

@; ----- SPI2  tasks
@; One of the tasks below always executes on each cycle of the while(1) in main().
@; SPI2_skiptask is installed by default at device definition time (see MoT_core_m at top)
@; The currently selected task of each/every device runs once per system task-cycle (one cycle of main's while(1))

@; When a device has nothing to do, a 'skiptask' must execute to continue the task sequence of the task-cycle
	.thumb_func
SPI2_skiptask:									@; the SPI2 default task
	@; proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

	.thumb_func
SPI2_INSTRUCTIONtask:
	ldr r1, [rDEVP, #SPI2_INSTRUCTIONSTEP]
	cbz r1, 0f

	cmp r1, 0x1
	beq 1f	@; Step 1 is to transmit data

	cmp r1, 0x2
	beq 2f	@; Step 2 is to read data

0:	@; Step 0: Set CS low to activate slave
	@; FOR WHATEVER REASON WE CAN ONLY TRANSMIT A NEW COMMNAND TO SLAVE IF WE REINIT SPI AGHGHGHH
	bl SPI2_init
	@; :) <--- happy face

	bl SPI2_CS_low

	mov r1, 0x1								@; Update to step 1
	str r1, [rDEVP, #SPI2_INSTRUCTIONSTEP]	@; ..

1:	@; Step 1: Poll for TXE and transmit if empty - both handled in SPI2_transmit
	MOV_imm32 r0, #259
	ldr r1, [rDEVP, #SPI2_INSTRUCTIONLENGTH]
	rsb r1, r1, r0		@; Get's position in TXBUFFER with byte to use
	ldr r0, =SPI2_transmitbuffer
	ldrb r0, [r0, r1]	@; Loads byte at derived position

	@; here with data to transmit in r0
	bl SPI2_transmit

	@; if transmission was successful then r0 = 0
	cmp r0, 0x0
	ittt eq
	moveq r0, 0x2								@; Update to step 2 if success
	streq r0, [rDEVP, #SPI2_INSTRUCTIONSTEP]	@; ..
	beq 4f										@; move on

	@; if transmission failed then r0 = 1
	ldr r0, [rDEVP, #SPI2_FAILS]	@; update # of failed attempts
	add r0, r0, 0x1					@; ..
	cmp	r0, #MAX_FAILS	@; if we've reached MAX_FAILS failed attempts
	beq 5f				@; branch to exit with error, reset fails, and install skip

	@; here if we've not reached MAX_FAILS attempts
	str r0, [rDEVP, #SPI2_FAILS]	@; store new # of fails
	b 4f	@; move on

2:	@; Step 2: Poll for RXNE and read if not empty - both handled in SPI2_read
	bl SPI2_read
	@; here with received data in r1 if success

	@; if receive was successful then r0 = 0
	cmp r0, 0x0
	ittt eq
	moveq r0, 0x1								@; Update to step 1 if success
	streq r0, [rDEVP, #SPI2_INSTRUCTIONSTEP]	@; ..
	beq 7f										@; Update instruction length

	@; if transmission failed then r0 = 1
	ldr r1, [rDEVP, #SPI2_FAILS]	@; update # of failed attempts
	add r1, r1, 0x1					@; ..
	cmp	r1, #MAX_FAILS	@; if we've reached MAX_FAILS failed attempts
	beq 5f				@; branch to exit with error, reset fails, and install skip

	@; here if we've not reached MAX_FAILS attempts
	str r1, [rDEVP, #SPI2_FAILS]	@; store new # of fails
	b 4f	@; move on

3:	@; check if this was last byte
	ldr r0, [rDEVP, #SPI2_INSTRUCTIONLENGTH]
	cbz r0, 6f

	@; here if there's more bytes (length > 0)
	sub r0, r0, 0x1
	str r0, [rDEVP, #SPI2_INSTRUCTIONLENGTH]

4:	@; proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

5:	@; exit with error message and install skip
	mov r1, 0x00					@; reset failed attempts
	str r1, [rDEVP, #SPI2_FAILS]	@; ..

	PRINTMSG ERROR

6:	@; pull CS high, reset step, and branch back to cmd
	bl SPI2_CS_high

	mov r0, 0x00
	str r0, [rDEVP, #SPI2_INSTRUCTIONSTEP]

	POST_BBCMD

	@; install skip task
	MOV_imm32 r0,SPI2_skiptask
	mov r1,#NULL
	bl MoT_taskUpdate

	PRINTMSG_NO		@; Reset PRINTRXBYTE for further cmds

	b 4b

7:	@; update RXBYTE, and update + post RXMSG if neccessary
	@; here with data in r1
	str r1, [rDEVP, #SPI2_RXBYTE]		@; Store received byte in case we wanna use it later
										@; NOTICE: Only the last received byte of the instruction is saved,
										@; as the others will be overwritten.

	ldr r0, [rDEVP, #SPI2_PRINTRXBYTE]
	cmp r0, 0x00
	beq 3b		@; Branch to 3b if we don't want to print result

	ldr r0, =RECEIVED_msgbuf		@; Load MoT message buffer
	bl device3_printMSGRX			@; Populate buffer with received byte

	PRINTMSG RECEIVED

	b 3b	@; check if that was the last byte

