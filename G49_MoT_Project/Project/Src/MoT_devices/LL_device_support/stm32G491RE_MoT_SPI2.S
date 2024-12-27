@; --- characterize target syntax, processor
	.syntax unified				@; ARM Unified Assembler Language (UAL). 
	.thumb						@; but here we'll use thumb instructions only

 	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.equ	RCC_BASE,           (0x40021000)
	.equ 	APB1RSTR1,			0x38		@; RCC APB1 peripheral reset register; SPI2 is bit 14
	.equ	APB1ENR1,			0x58		@; RCC APB1 peripheral clock enable register; SPI2 is bit 14
	
	.equ	AHB1RSTR,			0x28		@; RCC AHB1 peripheral reset register; CRC is bit 12
	.equ	AHB1ENR,			0x48		@; RCC AHB1 peripheral clock enable register; CRC is bit 12
	
	.equ	AHB2RSTR,			0x2C		@; RCC AHB2 peripheral reset register; GPIOB is bit 1
	.equ	AHB2ENR,			0x4C		@; RCC AHB2 peripheral clock enable register; GPIOB is bit 1

	.equ	SPI2_BASE,			(0x40003800)
	@; offsets to registers in SPI control array
	.equ	CR1,				0x00
	.equ	CR2,				0x04
	.equ	SR,					0x08
	.equ	DR,					0x0C
	.equ	CRCPR,				0x10
	.equ	RXCRCR,				0x14
	.equ	TXCRCR,				0x18
	.equ	I2SCFGR,			0x1C
	.equ	I2SPR,				0x20

	.equ	GPIOB_BASE,			(0x48000400)
	@; offsets to registers in GPIO control array
	.equ	MODER,	0x00	@;  GPIO port mode register,	Address offset:	0x00
	.equ	OTYPER,	0x04	@;  GPIO port output type register,	Address offset:	0x04
	.equ	OSPEEDR,0x08	@;  GPIO port output speed register,	Address offset:	0x08
	.equ	PUPDR,	0x0C	@;  GPIO port pull-up/pull-down register,	Address offset:	0x0C
	.equ	IDR,	0x10	@;  GPIO port input data register,	Address offset:	0x10
	.equ	ODR,	0x14	@;  GPIO port output data register,	Address offset:	0x14
	.equ	BSRR,	0x18	@;  GPIO port bit set/reset register,	Address offset:	0x18
	.equ	LCKR,	0x1C	@;  GPIO port configuration lock register,	Address offset:	0x1C
	.equ	AFRL,	0x20	@;  GPIO alternate function register low,	Address offset:	0x20
	.equ	AFRH,	0x24	@;  GPIO alternate function register high,	Address offset:	0x24

	.text
	.align 2

	.thumb_func
GPIOB_init:
	push {r7, lr}

	@; configure GPIO pins (see datasheet @ 4.10 for alternate functions)
	@; PB12; NSS, PB13; SCK, PB14; MISO, PB15; MOSI
	@; AF5 for all four pins

	@; (re-)enable GPIOB
	ldr r3, =RCC_BASE			@; Enable GPIOB
	ldr r2, [r3,#AHB2ENR]		@; ..
	orr r2, #(0x1 << 1)			@; Enable port
	str r2, [r3,#AHB2ENR]		@; ..
	ldr r2,[r3,#AHB2RSTR]		@; ..
	orr r2,r2,#(0x1 << 1)		@; ..
	str r2,[r3,#AHB2RSTR]		@; ..
	bic	r2,r2,#(0x1 << 1)		@; ..  manual: APB1RSTR bits are "set _and_ cleared by software"
	str r2,[r3,#AHB2RSTR]		@; ..

    ldr r3, =GPIOB_BASE       	@; Select GPIOB for register operations

	@; configure speed for PB12,13,14, and 15 to very high
	ldr r2, [r3, #OSPEEDR]
	bic r2, r2, #(0xFF << 24)	@; Clear speed bits for PB12,13,14, and 15
	orr r2, r2, #(0xFF << 24)	@; Set speed to very high for PB12,13,14, and 15
	str r2, [r3, #OSPEEDR]

	@; put PB12,13,14, and 15 in alternate function mode
	ldr r2, [r3,#MODER]
    bic r2, r2, #(0xFF << 24)		@; Clear mode bits for PB12,13,14, and 15
	orr r2, r2, #(0x1 << 24) 		@; Make PB12 general output
	@;orr r2, r2, #(0x2 << 24) 		@; Make PB12 alternate function
	orr r2, r2, #(0x2 << 26) 		@; Make PB13 alternate function
	orr r2, r2, #(0x2 << 28) 		@; Make PB14 alternate function
	orr r2, r2, #(0x2 << 30) 		@; Make PB15 alternate function
	str r2, [r3,#MODER]

	@; connect PB13,14, and 15 alternate function 5 (AFRH) -- SPI2
	ldr r2, [r3,#AFRH]
	MOV_imm32 r1, 0xFFFF0000	@; Clear alternate function bits for PB12,13,14, and 15
    bic r2, r2, r1				@; ..
    @;orr r2, r2, #(0x5 << 16)	@; Make PB12 AF5
    orr r2, r2, #(0x5 << 20)	@; Make PB13 AF5
    orr r2, r2, #(0x5 << 24)	@; Make PB14 AF5
    orr r2, r2, #(0x5 << 28)	@; Make PB15 AF5
	str r2, [r3,#AFRH]

	bl SPI2_CS_high

	pop {r7, pc}

	.global SPI2_init
	.thumb_func
SPI2_init:
	push {r7, lr}

	bl GPIOB_init

	@; (re-)enable SPI2 and then reset it
	ldr r3,=RCC_BASE			@;enable SPI2
	ldr r2,[r3,#APB1ENR1]		@; ..
	orr	r2,r2,#(0x1 << 14)		@; ..
	str r2,[r3,#APB1ENR1]		@; ..
	ldr r2,[r3,#APB1RSTR1]		@;reset SPI2
	orr r2,r2,#(0x1 << 14)		@; ..
	str r2,[r3,#APB1RSTR1]		@; ..
	bic	r2,r2,#(0x1 << 14)		@; ..  manual: APB1RSTR bits are "set _and_ cleared by software"
	str r2,[r3,#APB1RSTR1]		@; ..

	@; here with SPI2 clock enabled
	ldr r3, =SPI2_BASE			@; load base address

	@; configure SPI2
	ldr r1, [r3, #CR2]
	orr r1, r1, #(0x1 << 2)		@; Set bit 2; SSOE: Slave select output enable
	orr r1, r1, #(0x7 << 8)		@; Set bit 8,9,10; DS: Data size bits
	bic r1, r1, #(0x1 << 11)	@; Clear bit 11; DS: Data size bits
	orr r1, r1, #(0x1 << 12)	@; Set bit 12; FRXTH: FIFO reception threshold
	str r1, [r3, #CR2]

	@; configure SPI2
	ldr r1, [r3, #CR1]			@; ..
	orr r1, r1, #(0x1 << 2)		@; Set bit 2; MSTR: Master select bit
	orr r1, r1, #(0x3 << 3)		@; Set bit 3,4; BR: Baud rate bits
	bic r1, r1, #(0x1 << 5)		@; Clear bit 5: BR: Baud rate bits
	bic r1, r1, #(0x1 << 7)		@; Clear bit 7; LSBFIRST: Frame format
	orr r1, r1, #(0x1 << 9)		@; Set bit 9; SSM: Software slave management
	str r1, [r3, #CR1]			@; ..

	@; enable SPI2
	ldr r1, [r3, #CR1]			@; ..
	orr r1, r1, #(0x1 << 6)		@; Set bit 6; SPE: SPI enable bit
	str r1, [r3, #CR1]			@; ..

	pop {r7, pc}

	.global SPI2_transmit
	.thumb_func
SPI2_transmit:
	push {r7, lr}

	ldr r3, =SPI2_BASE		@; Base address of SPI2
	ldr r2, [r3, #SR]		@; Check if TX buffer is empty
	tst r2, 0x2
	beq	1f					@; If TXE = 0; not empty -> indicate fail
							@; If TXE = 1; empty -> populate with data

	strb r0, [r3, #DR]	@; Transmit byte
	mov r0, 0x00		@; Indicate success
	b 2f				@; Branch to exit

1:	mov r0, 0x1			@; Indicate fail

2:	pop {r7, pc}

	.global SPI2_read
	.thumb_func
SPI2_read:
	push {r7, lr}

	ldr r3, =SPI2_BASE		@; Base address of SPI2
	ldr r2, [r3, #SR]		@; Check if RX buffer is empty
	tst r2, 0x1
	beq	1f					@; If RXNE = 0; empty -> indicate fail
							@; If RXNE = 1; not empty -> read data

	ldrb r1, [r3, #DR]		@; Read data
	mov r0, 0x00			@; Indicate success
	b 2f					@; Branch to exit

1:	mov r0, 0x1				@; Indicate fail
2:	pop {r7, pc}

	.global SPI2_CS_high
	.thumb_func
SPI2_CS_high:
	push {r7, lr}

	ldr r3, =GPIOB_BASE			@; Base address of GPIOB
	ldr r2, [r3,#BSRR]
	orr r2, r2, #(0x1 << 12)	@; Set CS high
	str r2, [r3,#BSRR]

	pop {r7, pc}

	.global	SPI2_CS_low
	.thumb_func
SPI2_CS_low:
	push {r7, lr}

	ldr r3, =GPIOB_BASE			@; Base address of GPIOB
	ldr r2, [r3,#BSRR]
	orr r2, r2, #(0x1 << 28)	@; Set CS low
	str r2, [r3,#BSRR]

	pop {r7, pc}
