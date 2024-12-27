@; stm32fL476xx_TIM2_interrupt--broken.S wmh 2024-10-17 : initialize TIM2 for interrupt operation
@;  Polls TIM2's CC1IE (TIM2 CH1 interrupt flag) to test if TIM2_CH1 compare is working for later use in PWM
@;  Adds debug timer freeze

@; --- characterize target syntax, processor
	.syntax unified				@; ARM Unified Assembler Language (UAL). 
	.thumb						@; but here we'll use thumb instructions only
 	
 	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

@; --- definitions pertinent to DAC1, extracted from 'stm32L476xx.h'
.equ	RCC_BASE,           0x40021000
.equ 	APB1RSTR1,			0x38		@; RCC APB1 peripheral reset register; TIM2 is bit0
.equ	APB1ENR1,			0x58		@; RCC APB1 peripheral clock enable register; TIM2 is bit0
.equ 	AHB2RSTR,			0x2C		@; RCC AHB2 peripheral reset register; DAC1 is bit16
.equ 	AHB2ENR,			0x4C		@; RCC AHB2 peripheral clock enable register; DAC1 is bit16
.equ 	GPIOAEN,			0x00

.equ 	DAC1_BASE,			(0x50000800)	@; origin of DAC1 control register array
@; offsets to registers in DAC1 control array
.equ CR,		0x00	/*!< DAC control register,                                    Address offset: 0x00 */
.equ SWTRIGR,	0x04	/*!< DAC software trigger register,                           Address offset: 0x04 */
.equ DHR12R1,	0x08	/*!< DAC channel1 12-bit right-aligned data holding register, Address offset: 0x08 */
.equ DHR12L1,	0x0C	/*!< DAC channel1 12-bit left aligned data holding register,  Address offset: 0x0C */
.equ DHR8R1,	0x10	/*!< DAC channel1 8-bit right aligned data holding register,  Address offset: 0x10 */
.equ DHR12R2,	0x14	/*!< DAC channel2 12-bit right aligned data holding register, Address offset: 0x14 */
.equ DHR12L2,	0x18	/*!< DAC channel2 12-bit left aligned data holding register,  Address offset: 0x18 */
.equ DHR8R2,	0x1C	/*!< DAC channel2 8-bit right-aligned data holding register,  Address offset: 0x1C */
.equ DHR12RD,	0x20	/*!< Dual DAC 12-bit right-aligned data holding register,     Address offset: 0x20 */
.equ DHR12LD,	0x24	/*!< DUAL DAC 12-bit left aligned data holding register,      Address offset: 0x24 */
.equ DHR8RD,	0x28	/*!< DUAL DAC 8-bit right aligned data holding register,      Address offset: 0x28 */
.equ DOR1,		0x2C	/*!< DAC channel1 data output register,                       Address offset: 0x2C */
.equ DOR2,		0x30	/*!< DAC channel2 data output register,                       Address offset: 0x30 */
.equ SR,		0x34	/*!< DAC status register,                                     Address offset: 0x34 */
.equ CCR,		0x38	/*!< DAC calibration control register,                        Address offset: 0x38 */
.equ MCR,		0x3C	/*!< DAC mode control register,                               Address offset: 0x3C */
.equ SHSR1,		0x40	/*!< DAC Sample and Hold sample time register 1,              Address offset: 0x40 */
.equ SHSR2,		0x44	/*!< DAC Sample and Hold sample time register 2,              Address offset: 0x44 */
.equ SHHR,		0x48	/*!< DAC Sample and Hold hold time register,                  Address offset: 0x48 */
.equ SHRR,		0x4C	/*!< DAC Sample and Hold refresh time register,               Address offset: 0x4C */
.equ STR1,		0x58	/*!< DAC Sawtooth register,                                   Address offset: 0x58 */
.equ STR2,		0x5C	/*!< DAC Sawtooth register,                                   Address offset: 0x5C */
.equ STMODR,	0x60	/*!< DAC Sawtooth Mode register,                              Address offset: 0x60 */

.equ	GPIOA_BASE,0x48000000	@;origin of GPIOA register struct (pg 78 of the manual)
.equ	MODER,	0x00			@;GPIOA configuration register offsets (pg 312 of the manual)
.equ	OTYPER,	0x04	    	@; ..
.equ	OSPEEDR,0x08	    	@; ..
.equ	OPUPDR,	0x0C	    	@; ..
.equ	IDR,	0x10	    	@; ..
.equ	ODR,	0x14	    	@; ..
.equ	BSRR,	0x18	    	@; ..
.equ	LCKR,	0x1C	    	@; ..
.equ	AFRL,	0x20	    	@; ..
.equ	AFRH,	0x24	    	@; ..
.equ	BRR,	0x28	    	@; ..
.equ	ASCR,	0x2C	    	@; ..

.equ	PA5,	5				@; bit offset to PA5 (LD2 LED control)			@; bit offset to PA5 (LD2 LED control)

@; --- DAC1 code
	.text
	.align 2

	.global GPIOA_init
	.thumb_func
GPIOA_init:
	push {r7, lr}

	@;(re-)enable GPIOA
	ldr r3,=RCC_BASE			@;enable GPIOA
	ldr r2,[r3,#AHB2ENR]		@; ..
	orr r2,#(1 << GPIOAEN)		@;enable port
	str r2,[r3,#AHB2ENR]		@; ..

	@; configure PA5 as an output (pg 304 of the manual)
	ldr r3,=GPIOA_BASE			@;load GPIOA struct address
	ldr r2,[r3,#MODER]			@;get current mode values of port
	bic r2,#(3<<(2*PA5))		@;clear current mode value of port bit
	orr	r2,#(3<<(2*PA5))		@;set new mode value of port bit to analog output
	str r2,[r3,#MODER]			@; ..

	@; configure output as push/pull (pg 304 of the manual)
	ldr r2,[r3,#OTYPER]			@;get current push/pull settings of port
	bic r2,#(1<<(1*PA5))		@;clear current control value of port bit (make output push/pull)
	str r2,[r3,#OTYPER]			@; ..

	@; configure output as high speed (pg 304 of the manual)
	ldr r2,[r3,#OSPEEDR]		@;get current speed values of port
	bic r2,#(3<<(2*PA5))		@;clear current speed value of port bit
	orr	r2,#(2<<(2*PA5))		@;set new speed of port bit as high speed
	str r2,[r3,#OSPEEDR]		@; ..

	@; configure output as no pullup, pulldown (pg 305 of the manual)
	ldr r2,[r3,#OPUPDR]			@;get current pu/pd settings of port
	bic r2,#(3<<(2*PA5))		@;clear current pupd value of port bit (=no pu/pd)
	str r2,[r3,#OPUPDR]			@; ..

	pop {r7, pc}

	.global DAC1_CH2_init
	.thumb_func
DAC1_CH2_init:
	push {r7, lr}

	bl GPIOA_init

@;(re-)enable DAC1 and then reset it
	ldr r3,=RCC_BASE			@;enable clock for DAC1
	ldr r2,[r3,#AHB2ENR]		@; ..
	orr	r2,r2,#(0x1 << 16)		@; ..
	str r2,[r3,#AHB2ENR]		@; ..
	ldr r2,[r3,#AHB2RSTR]		@;reset DAC1
	orr r2,r2,#(0x1 << 16) 		@; ..
	str r2,[r3,#AHB2RSTR]		@; ..
	bic	r2,r2,#(0x1 << 16)		@; ..  manual: APB1RSTR bits are "set _and_ cleared by software"
	str r2,[r3,#AHB2RSTR]		@; ..

	ldr r3,=DAC1_BASE

	ldr r2,[r3,#CR]			@; enable channel2 output
	orr r2,r2,#(0x1 << 16)	@; ..
	str r2,[r3,#CR]			@; ..

	pop {r7, pc}

	.global DAC1_CH2_output_constant
	.thumb_func
DAC1_CH2_output_constant:
	push {r7, lr}

	ldr r3,=DAC1_BASE
1:
	ldr r2,[r3,#SR]			@; poll for DAC2RDY
	tst r2, #(0x1 << 27)	@; if DAC2RDY = 1 for DAC1
	beq 1b

	str r1,[r3,#DHR12R2]	@; ..

	pop {r7, pc}
