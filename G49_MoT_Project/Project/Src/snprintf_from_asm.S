@; snprintf_from_asm.S wmh 2024-11-25 : quick test of using mpaland's snprintf() from assembly
@; We've already tested the snprintf(0 function in MoT_main03.c with the wrapper functions 
@;		int snprintf_08X(char* pbuf,uint32_t val);
@;		int snprintf_signedD(char* pbuf,int32_t val);
@; Purpose was to simplify calling the actual snprintf() function in order to make such calls accessible to assembly language.
@; The roblem calling snprintf()directly from assembly is interpreting a snprintf() variadic argument list. 
@; Because our wrapper functions have only two arguments and they are non-variadic, we can easily write similar functions in assembler.

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed
	.thumb							@; we're using thumb instructions only
	.text

	.global asm_snprintf_08X 
	.thumb_func
asm_snprintf_08X:
	@;arguments as if we're the C function 'snprintf_08X()' defined in MoT_main03.c
	push {r7,lr}
	ldr r0,=buf_08X					@; buffer defined in MoT_main03.c
	ldr r1,=0xF00DBEEF
	bl snprintf_08X					@; function defined in MoT_main03.c
	@; should return here with r0=character count of the converted string in the buffer
	pop {r7,pc}
