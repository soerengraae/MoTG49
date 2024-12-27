@; stm32fL476xx_TIM4_interrupt--broken.S wmh 2024-10-17 : initialize TIM4 for interrupt operation
@;  Polls TIM4's CC1IE (TIM4 CH1 interrupt flag) to test if TIM4_CH1 compare is working for later use in PWM
@;  Adds debug timer freeze

@; --- characterize target syntax, processor
	.syntax unified				@; ARM Unified Assembler Language (UAL). 
	.thumb						@; but here we'll use thumb instructions only
 	
 	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	#include "sine.S"

@; --- definitions pertinent to TIM4, extracted from 'stm32L476xx.h'
@;.equ 	PERIPH_BASE,		0x40000000 @; Base address of : AHB/ABP Peripherals 
@;.equ	AHB1PERIPH_BASE,	(PERIPH_BASE + 0x00020000)
.equ	RCC_BASE,           0x40021000
.equ 	APB1RSTR1,			0x38		@; RCC APB1 peripheral reset register; TIM4 is bit0
.equ	APB1ENR1,			0x58		@; RCC APB1 peripheral clock enable register; TIM4 is bit0
.equ 	AHB2ENR,			0x4C		@; RCC AHB2 peripheral clock enable register; GPIOA is bit0
.equ	GPIOAEN,0				@;GPIOA peripheral clock enable bit offset (pg 251 of the manual)


.equ 	TIM4_BASE,			(0x40000800)	@; origin of TIM4 control register array
@; offsets to registers in TIM4 control array
.equ	CR1,	0x00	@;	  __IO uint32_t CR1;              TIM control register 1,              Address offset: 0x00 	
.equ	CR2,	0x04	@;	  __IO uint32_t CR2;              TIM control register 2,              Address offset: 0x04 	
.equ	SMCR,	0x08	@;	  __IO uint32_t SMCR;             TIM slave mode control register,     Address offset: 0x08 	
.equ	DIER,	0x0C	@;	  __IO uint32_t DIER;             TIM DMA/interrupt enable register,   Address offset: 0x0C 	
.equ	SR,		0x10	@;	  __IO uint32_t SR;               TIM status register,                 Address offset: 0x10 	
.equ	EGR,	0x14	@;	  __IO uint32_t EGR;              TIM event generation register,       Address offset: 0x14 	
.equ	CCMR1,	0x18	@;	  __IO uint32_t CCMR1;            TIM capture/compare mode register 1, Address offset: 0x18 	
.equ	CCMR2,	0x1C	@;	  __IO uint32_t CCMR2;            TIM capture/compare mode register 2, Address offset: 0x1C 	
.equ	CCER,	0x20	@;	  __IO uint32_t CCER;             TIM capture/compare enable register, Address offset: 0x20 	
.equ	CNT,	0x24	@;	  __IO uint32_t CNT;              TIM counter register,                Address offset: 0x24 	
.equ	PSC,	0x28	@;	  __IO uint32_t PSC;              TIM prescaler,                       Address offset: 0x28 	
.equ	ARR,	0x2C	@;	  __IO uint32_t ARR;              TIM auto-reload register,            Address offset: 0x2C
.equ	CCR1,	0x34	@;	  __IO uint32_t CCR1;             TIM capture/compare register 1,      Address offset: 0x34 	
.equ	CCR2,	0x38	@;	  __IO uint32_t CCR2;             TIM capture/compare register 2,      Address offset: 0x38 	
.equ	CCR3,	0x3C	@;	  __IO uint32_t CCR3;             TIM capture/compare register 3,      Address offset: 0x3C 	
.equ	CCR4,	0x40	@;	  __IO uint32_t CCR4;             TIM capture/compare register 4,      Address offset: 0x40
.equ    ECR,    0x58    @;    __IO uint32_t ECR;              TIM timer encoder control register,  Address offset: 0x58
.equ    TISEL,  0x5C 	@:	  __IO uint32_t TISEL;            TIM timer input selection register,  Address offset: 0x5C
.equ	AF1,	0x60	@;	  __IO uint32_t AF1;              TIM Alternate function option register 1, Address offset: 0x60 	
.equ	AF2,	0x64	@;	  __IO uint32_t AF2;              TIM Alternate function option register 2, Address offset: 0x64 	
.equ	DCR,	0x3DC	@;	  __IO uint32_t DCR;              TIM DMA control register,            Address offset: 0x3DC

@; --- definitions for alternate function assignment of TIM4 to PA5
.equ 	GPIOA_BASE, 0x48000000 @; origin of GPIOA control register array
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

@; --- NVIC register array base addresses
.equ	NVIC_ISER,	0xE000E100	@; Interrupt Set-Enable Registers, NVIC_ISER0-NVIC_ISER15
.equ	NVIC_ICER,	0xE000E180	@; Interrupt Clear-Enable Registers, NVIC_ICER0-NVIC_ICER15
.equ	NVIC_ISPR,	0xE000E200	@; Interrupt Set-Pending Registers, NVIC_ISPR0-NVIC_ISPR15
.equ	NVIC_ICPR,	0xE000E280	@; Interrupt CLR-Pending Registers, NVIC_ICPR0-NVIC_ICPR15
.equ 	NVIC_IABR,	0xE000E300	@; Interrupt Active Bit Registers, NVIC_IABR0-NVIC_IABR15
.equ 	NVIC_IPR,	0xE000E400	@; Interrupt Priority Registers, NVIC_IPR0-NVIC_IPR123

@; --- TIM4 demo code
	.text						
	.align 2

	.global TIM4_NVIC_init	@; general interrupt enable and priority setting
						@; 	called first, configures NVIC for all active interrupts
	.thumb_func
TIM4_NVIC_init:
	push {r7,lr}
	
	@;NVIC configuration values for TIM4 interrupt
	.equ position,30 		@;TIM4 location in table -- from manual Table 58 "STM32L47x/L48x/L49x/L4Ax vector table"
	.equ byteoffset,3		@;# of bytes from origin to the bit at 'position', for any of the NVIC bit-registers
	.equ bitposition,6		@;position of enable/clear/active bit in byte at byteoffset, e.g. position=8*byteoffset+bitposition

	@;enable TIM4 in NVIC (will also need to be enable in TIM configuration)
	ldr r3,=NVIC_ISER
	ldrb r2,[r3,#byteoffset]
	orr r2,#(1<<bitposition)
	strb r2,[r3,#byteoffset]

	@;set TIM4 interrupt priority mid-level (8)
	ldr r3,=NVIC_IPR	
	mov r2,#0x80			@;priority is in upper nybble
	strb r2,[r3,#position]

	pop {r7,pc}

	.global TIM4_init
	.thumb_func
TIM4_init:
    push {r7,lr}

	bl TIM4_NVIC_init

	@;(re-)enable TIM4 and then reset it
	ldr r3,=RCC_BASE			@;enable TIM4
	ldr r2,[r3,#APB1ENR1]		@; ..
	orr	r2,r2,#(1 << 2)			@; ..
	str r2,[r3,#APB1ENR1]		@; ..
	ldr r2,[r3,#APB1RSTR1]		@;reset TIM4
	orr r2,r2,#(1 << 2) 		@; ..
	str r2,[r3,#APB1RSTR1]		@; ..
	bic	r2,r2,#(1 << 2)		@; ..  manual: APB1RSTR bits are "set _and_ cleared by software"
	str r2,[r3,#APB1RSTR1]		@; ..

@; here with TIM4 enabled and reset
	@; here with TIM4 enabled and reset
    ldr r3,=TIM4_BASE       	@;select TIM4 for register operations

	@;set TIM4 prescaler reload value
	mov	r2, #1					@; prescale 72MHz to 36MHz
	strh r2,[r3,#PSC]			@; ..

	@;set TIM4 counter reload value
	MOV_imm32 r2, #1000
	str r2,[r3,#ARR]

	@;enable TIM4 interrupt
	mov r2,#1
	str r2,[r3,#DIER]

	@;enable TIM4 as up-counting edge-aligned overflow-triggered repeating counter (notes 6 and 7)
	movw r2,#0x85				@; ..
	strh r2,[r3,#CR1]			@; done last, as counter starts immediately (see manual page 937)
	@;!! here with all CCxIF flags in SR =1 as a side effect of the above instruction

	@; here with TIM4 stopped (ARR = 0)
	pop {r7, pc}

	.global TIM4_IRQHandler
	.thumb_func
TIM4_IRQHandler:
	push {r7,lr}

	@;clear interrupt flag
	ldr r3,=TIM4_BASE 			@; ..
	ldr r2,[r3,#SR]				@; ..
	bic r2,r2,#1				@; ..
	str r2,[r3,#SR]				@; ..

	ldr r3, =sine_LUT
	ldr r2, =DAC1_sin_position
	ldr r1, [r2]
	mov r2, 0x4
	mul r1, r1, r2		@; convert to word position
	ldr r1, [r3, r1]	@; contains sine value

	ldr r2, =DAC1_sin_amplitude
	ldr r2, [r2]		@; contains amplitude
	mul r1, r1, r2
	lsr r1, #12			@; contains adjusted sine value

	bl DAC1_CH2_output_constant

	ldr r2, =DAC1_sin_position
	ldr r1, [r2]	@; contains sine position
	add r1, r1, #1	@; increment sine pos by 1

	cmp r1, #127	@; if it exceeds 127; reset
	it hi
	movhi r1, 0x00

	str r1,[r2]		@; store new sine position

1:	@;interrupt is done
	pop {r7,pc}

