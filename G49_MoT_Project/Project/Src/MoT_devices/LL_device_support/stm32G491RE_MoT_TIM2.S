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

@; --- definitions pertinent to TIM2, extracted from 'stm32L476xx.h'
@;.equ 	PERIPH_BASE,		0x40000000 @; Base address of : AHB/ABP Peripherals 
@;.equ	AHB1PERIPH_BASE,	(PERIPH_BASE + 0x00020000)
.equ	RCC_BASE,           0x40021000
.equ 	APB1RSTR1,			0x38		@; RCC APB1 peripheral reset register; TIM2 is bit0
.equ	APB1ENR1,			0x58		@; RCC APB1 peripheral clock enable register; TIM2 is bit0
.equ 	AHB2ENR,			0x4C		@; RCC AHB2 peripheral clock enable register; GPIOA is bit0
.equ	GPIOAEN,0				@;GPIOA peripheral clock enable bit offset (pg 251 of the manual)


.equ 	TIM2_BASE,			(0x40000000)	@; origin of TIM2 control register array
.equ 	TIM3_BASE,			(0x40000400)	@; origin of TIM3 control register array
@; offsets to registers in TIM2 control array
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

@; --- definitions for alternate function assignment of TIM2 to PA5
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

@; --- TIM2 code
	.text						
	.align 2

	.global TIM2_connect_CH1_to_PA5
    .thumb_func
TIM2_connect_CH1_to_PA5:
	push {r7,lr}

	@;(re-)enable GPIOA
	ldr r3,=RCC_BASE			@;enable GPIOA
	ldr r2,[r3,#AHB2ENR]		@; ..
	orr r2,#(1 << GPIOAEN)		@;enable port
	str r2,[r3,#AHB2ENR]		@; ..

    @;configure PA5 for alternate function TIM2 CH1
    ldr r3,=GPIOA_BASE       	@;select GPIOA for register operations

	@;put PA5 in alternate function mode
	ldr r2,[r3,#(MODER)]
    bic r2,#(0x3 << 10)			@;clear mode bits
	orr r2,#(0x2 << 10) 		@;make alternate function
	str r2,[r3,#(MODER)]

	@;connect PA5 alternate function 1 (AFR1) -- TIM2 CH1
	ldr r2,[r3,#(AFRL)]
    bic r2,#(0xF << 20)    		@;clear alternate function bits
	orr r2,#(0x1 << 20) 		@;make alernate function 1
	str r2,[r3,#(AFRL)]

	@;here with TIM2 CH1 output on PA5
	pop {r7,pc}

	.global TIM2_init
	.thumb_func
TIM2_init:
    push {r7,lr}

    @;(re-)enable TIM3 and then reset it
	ldr r3,=RCC_BASE			@;enable TIM3
	ldr r2,[r3,#APB1ENR1]		@; ..
	orr	r2,r2,0x2				@; ..
	str r2,[r3,#APB1ENR1]		@; ..
	ldr r2,[r3,#APB1RSTR1]		@;reset TIM3
	orr r2,r2,0x2 				@; ..
	str r2,[r3,#APB1RSTR1]		@; ..
	bic	r2,r2,0x2				@; ..  manual: APB1RSTR bits are "set _and_ cleared by software"
	str r2,[r3,#APB1RSTR1]		@; ..

	ldr   r3, =TIM3_BASE
	mov   r2, #71            	@; prescale 72MHz clock to 1MHz
	strh  r2, [r3, #PSC]

	mov r2, #1000
	str r2, [r3, #ARR]			@; "random" auto reload value

	ldr   r2, [r3, #CR2]
	orr   r2, r2, #(0x2 << 4)	@; Set MMS = 010 for TRGO on update event
	str   r2, [r3, #CR2]

	@;(re-)enable TIM2 and then reset it
	ldr r3,=RCC_BASE			@;enable TIM2
	ldr r2,[r3,#APB1ENR1]		@; ..
	orr	r2,r2,0x1				@; ..
	str r2,[r3,#APB1ENR1]		@; ..
	ldr r2,[r3,#APB1RSTR1]		@;reset TIM2
	orr r2,r2,0x1 				@; ..
	str r2,[r3,#APB1RSTR1]		@; ..
	bic	r2,r2,0x1				@; ..  manual: APB1RSTR bits are "set _and_ cleared by software"
	str r2,[r3,#APB1RSTR1]		@; ..

@; here with TIM2 enabled and reset
	ldr   r3, =TIM2_BASE      @; Base address of TIM2

	ldr   r2, [r3, #CR1]
	orr   r2, r2, #(0x1 << 3)	@; Set OPM (bit 3)
	orr   r2, r2, #(0x1 << 7)	@; Set ARPE (bit 7)
	str   r2, [r3, #CR1]

	ldr r2, [r3, #SMCR]
	bic r2, #(0x7 << 4)			@; Clear trigger
	orr	r2, #(0x2 << 4)			@; set ITR2 as trigger (TIM3 TRGO)
	bic r2, r2, #(0x7 << 0)		@; Clear slave mode
	orr r2, r2, #(0x1 << 16)	@; Set SMS = 1000 for combined reset + trigger mode
	str r2, [r3, #SMCR]

	MOV_imm32 r2,#71			@; prescale 72MHz clock to 1MHz
	strh r2,[r3,#PSC]			@; ..

	ldr r2,[r3,#CCMR1]			@; ..
	orr r2,#(0x1<<16)			@; TIM2_CCMR1 : OC1M[3:0] = 1001 (retriggarable 2)
	orr r2,#(0x1<<4)			@; ..
	orr r2,#(0x1<<3)			@; TIM2_CCMR1 : OC1PE=1
	str r2,[r3,#CCMR1]			@; ..

	mov r2, #0
	str r2, [r3, #CCR1] 		@; CCR1 must be set to zero (see page 1280)

	ldr   r2, [r3, #CCER]     	@; TIM2_CCER register
	bic   r2, r2, #(0x1 << 1)	@; Clear CC1P bit (bit 1) for active high
	orr   r2, r2, 0x1			@; Set CC1E bit (bit 0)
	str   r2, [r3, #CCER]

	@; here with timer stopped but initialized

	pop {r7, pc}

	.global TIM2_pulse_usec
	.thumb_func
TIM2_pulse_usec:
	push {r7, lr}
	ldr   r3, =TIM2_BASE	@; Base address of TIM2
	ldr r2, [r3, #CR1]		@; check if pulse is already happening
	tst r2, 0x1				@; if CEN = 1
	bne 1f					@; branch to exit

	@; here with no pulse
	str r0, [r3, #CCR1]	@;set TIM2 compare value (delay)

	add r1, r1, r0	@; calculate total duration (ARR = delay + "on time")
	str r1, [r3, #ARR]	@;set TIM2 counter reload value (duration)

	ldr   r3, =TIM3_BASE			@; generate update event on TIMM3
	ldr   r2, [r3, #EGR]			@; ..
	orr   r2, r2, 0x1     			@; Set UG to trigger update event
	str   r2, [r3, #EGR]			@; store to trigger event

1:
	pop {r7, pc}
