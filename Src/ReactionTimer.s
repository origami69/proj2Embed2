.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb
@if you are reading this then I will be copying and pasting from the last lab to save time since I have already done this
.global main
.type main, %function
.data
.align 4
time1:
	.word 0
time2:
	.word 0
time3:
	.word 0
.text
main:

	@this will be my last time writing in asm32, I will switch to C but i have learned how
	@to implement many things since I was forced to implement them myself
	@i had a problem with sleeping with WFI and debugger disconnecting apparently
	@accoridng to google this is a setting I need to enable for this called DBGMCU_CR that allows the debugger to handle this
	LDR r0, =0xE0042004      @ DBGMCU_CR
	LDR	r1, [r0]
    ORR r1, r1, #(1 << 0)
    STR r1, [r0]
	@this is setting GPIO input and output feel free to skip to loop
	LDR r0, =0x40023830 		@ rcc AHB1ENR base address
	LDR r1, [r0]				@load from ahb1enr address
	ORR r1, r1, #0x03			@ this sets ports A And B for us to use for clokcing
	STR r1, [r0]				@ we set it
	@I will setup the user button here at PORT A pins 5,6,7 as user input
	LDR r0, =0x40020000 		@at Port A base address
	LDR r1, [r0]				@read GPIOA
	BIC r1, r1, #(0x3 << 10)	@set PA_5 (5*2=5) as input 00
	BIC r1, r1, #(0x3 << 12)	@set PA_6 (6*2=12) as input 00
	BIC r1, r1, #(0x3 << 14)	@set PA_7 (7*2=14) as input 00
	STR r1, [r0]
	@I will setup pins 6,8,9 Port B as ouput
	LDR r0, =0x40020400 			@at B base address
	LDR r1, [r0]					@read GPIOB
	BIC r1, r1, #(0x3 << 12)		@clear PB _6 (5*2=12) to 00
	ORR r1, r1, #(0x1 << 12)		@set PB_6 	 (5*2=12) as ouput 01
	BIC r1, r1, #(0x3 << 16)		@clear PB _8 (5*2=16) to 00
	ORR r1, r1, #(0x1 << 16)		@set PB_8 	 (5*2=16) as ouput 01
	BIC r1, r1, #(0x3 << 18)		@clear PB _9 (5*2=18) to 00
	ORR r1, r1, #(0x1 << 18)		@set PB_9 	 (5*2=18) as ouput 01
	STR r1, [r0]
	@i will setup a tim 5 timer here
	LDR r0, =0x40023840 @this is the tim5 timer clock setup RCC->APB1ENR 5
	LDR r1, [r0]
	ORR r1, r1, #(1 << 3) @clock 5
	STR r1, [r0]
	LDR r0, =0x40000C28    @clock prescaler we have 16mhz as default
	LDR r1, =15999
	STR r1, [r0]
	LDR r0, =0x40000C2C @clock ARR max it out
	LDR r1, =0xFFFFFFFF
	STR r1, [r0]
	LDR r0, =0x40000C14
	MOV r1, #1
	STR r1, [r0]          @send event so prescale is right
	LDR r0, =0x40000C10   @tim_sr
	MOV r1, #0
	STR r1, [r0]
	LDR r0, =0x40000C24 @setting clock counter to 0
	MOV r1, #0
	STR r1, [r0]
	LDR r0, =0x40000C00 @timer5_cnt  start
	LDR r1, [r0]
	ORR r1, r1, #(1 << 0) @start timer
	STR r1, [r0]
	@first enable clock and gpio pin and set to input and no pull since board has resistor which we have done already
	@-> APB2ENR enable SYSCFGEN -> Map PA5,6,7 to EXTI 5-9 -> configure as falling or rising edge -> enable NVIC -> set priority below systick
	LDR r0, =0x40023844 @APB2ENR
	LDR r1, [r0]
	ORR r1, r1, #(0x1 << 14) @syscfgen bit
	STR r1, [r0]
	LDR r0, =0x4001380C   	    @SYSCFG_EXTICR2
	LDR r1, [r0]
	BIC r1, r1, #(0xF << 4)		@clear all the bits since F is max for 4 bit number and 0000 is port A
	BIC r1, r1, #(0xF << 8)
	BIC r1, r1, #(0xF << 12)
	STR r1, [r0]
	LDR r0, =0x40013C0C	@EXTI_FTSR on press send interupt
	LDR r1, [r0]
	ORR r1, r1, #(1 << 5)		@exti13
	ORR r1, r1, #(1 << 6)		@exti13
	ORR r1, r1, #(1 << 7)		@exti13
	STR r1, [r0]
	LDR r0, =0x40013C08 @disable release
	LDR r1, [r0]
	BIC r1, r1, #(1 << 5)
	BIC r1, r1, #(1 << 6)
	BIC r1, r1, #(1 << 7)
	STR r1, [r0]
	LDR r0, =0x40013C00 @exti imr
	LDR r1, [r0]
	ORR r1, r1, #(1 << 5)
	ORR r1, r1, #(1 << 6)
	ORR r1, r1, #(1 << 7)
	STR r1, [r0]
	@ clearing a flag
	LDR r0, =0x40013C14
	MOV r1, #(1 << 5)
	ORR r1, r1, #(1 << 6)
	ORR r1, r1, #(1 << 7)
	STR r1, [r0]
	LDR r0, =0xE000E100 @nvic_isr the exti from 5-9 shares EXTI9_5_IRQn
	LDR r1, [r0]
	ORR r1, r1, #(1 << 23)
	STR r1, [r0]
	LDR r0, =0xE000E400 	@NVIC_IPR priority
	MOV r1, #0x20 			@priority 2
	STRB r1, [r0, #23]  	@ipr 23th bit
	LDR r0, =0x40020400 	@at Port B base address
	LDR r1, =0x40020000 		@at Port A base address
	LDR r2, =832   			@the light state
	MOV r3, 0				@Biggest
	MOV r4, 0				@light 1
	MOV r5, 0				@light 2
	MOV r6, 0				@light 3
	LDR r7, =time1   			@the light state
	LDR r8, =time2   			@the light state
	LDR r9, =time3   			@the light state
	STR r2, [r0, #0x14]
   	B    run_loop    		@branch to lowercase routine

end:
   WFI
   B     end            @stop here
@----------------------------------------------------------------------
@ I wrote it like this so we can do this more than once but for now thats once is enough
run_loop:
	CPSID i
	LDR r10, [r7]
	CMP r10, #0
	BNE led_1
	LDR r10, [r8]
	CMP r10, #0
	BNE led_2
	LDR r10, [r9]
	CMP r10, #0
	BNE led_3
	DSB
	WFI
	CPSIE i
	B run_loop


led_1:
		CPSIE i
		LDR r10, [r1, #0x10]
		TST r10, #(1 << 5)
		BNE process_time1
		reset_time1:
			LDR r10, =0x40000C24 	@timer5_counter adresss
			LDR r10, [r10]
			STR r10, [r7]
			B run_loop
		process_time1:
			LDR r10, =0x40000C24 	@timer5_counter adresss
			LDR r10, [r10]
			LDR r11, [r7]
			SUBS r10, r10, r11
			CMP r10, #20
			BHS thelighter1
			B run_loop
		thelighter1:
			BL final_check1
			MOV r10, #0
			STR r10, [r7]
			ADDS r4, r4, #1
			CMP r4, r3
			BGT handle_bigger1
			BEQ handle_equal1
			B enablexti1
			handle_bigger1:
				MOV r2, #(1 << 6)
				MOV r3, r4
				STR r2, [r0, #0x14]
				B enablexti1
			handle_equal1:
				ORR r2, r2, #(1 << 6)
				STR r2, [r0, #0x14]
				B enablexti1
			final_check1:
				LDR r10, [r1, #0x10]
				TST r10, #(1 << 5)
				BEQ reset_time1
				BX lr
			enablexti1:
				LDR r10, =0x40013C14
				MOV r11, #(1 << 5)
				STR r11, [r10]
				LDR r10, =0x40013C00    @ EXTI_IMR
				LDR r11, [r10]
				ORR r11, r11, #(1 << 5)
				STR r11, [r10]
				B run_loop
led_2:
		CPSIE i
		LDR r10, [r1, #0x10]
		TST r10, #(1 << 6)
		BNE process_time2
		reset_time2:
			LDR r10, =0x40000C24 	@timer5_counter adresss
			LDR r10, [r10]
			STR r10, [r8]
			B run_loop
		process_time2:
			LDR r10, =0x40000C24 	@timer5_counter adresss
			LDR r10, [r10]
			LDR r11, [r8]
			SUBS r10, r10, r11
			CMP r10, #20
			BHS thelighter2
			B run_loop
		thelighter2:
			BL final_check2
			MOV r10, #0
			STR r10, [r8]
			ADDS r5, r5, #1
			CMP r5, r3
			BGT handle_bigger2
			BEQ handle_equal2
			B enablexti2
			handle_bigger2:
				MOV r2, #(1 << 8)
				MOV r3, r5
				STR r2, [r0, #0x14]
				B enablexti2
			handle_equal2:
				ORR r2, r2, #(1 << 8)
				STR r2, [r0, #0x14]
				B enablexti2
			final_check2:
				LDR r10, [r1, #0x10]
				TST r10, #(1 << 6)
				BEQ reset_time2
				BX lr
			enablexti2:
				LDR r10, =0x40013C14
				MOV r11, #(1 << 6)
				STR r11, [r10]
				LDR r10, =0x40013C00    @ EXTI_IMR
				LDR r11, [r10]
				ORR r11, r11, #(1 << 6)
				STR r11, [r10]
				B run_loop

led_3:
		CPSIE i
		LDR r10, [r1, #0x10]
		TST r10, #(1 << 7)
		BNE process_time3
		reset_time3:
			LDR r10, =0x40000C24 	@timer5_counter adresss
			LDR r10, [r10]
			STR r10, [r9]
			B run_loop
		process_time3:
			LDR r10, =0x40000C24 	@timer5_counter adresss
			LDR r10, [r10]
			LDR r11, [r9]
			SUBS r10, r10, r11
			CMP r10, #20
			BHS thelighter3
			B run_loop
		thelighter3:
			BL final_check3
			MOV r10, #0
			STR r10, [r9]
			ADDS r6, r6, #1
			CMP r6, r3
			BGT handle_bigger3
			BEQ handle_equal3
			B enablexti3
			handle_bigger3:
				MOV r2, #(1 << 9)
				MOV r3, r6
				STR r2, [r0, #0x14]
				B enablexti3
			handle_equal3:
				ORR r2, r2, #(1 << 9)
				STR r2, [r0, #0x14]
				B enablexti3
			final_check3:
				LDR r10, [r1, #0x10]
				TST r10, #(1 << 7)
				BEQ reset_time3
				BX lr
			enablexti3:
				LDR r10, =0x40013C14
				MOV r11, #(1 << 7)
				STR r11, [r10]
				LDR r10, =0x40013C00    @ EXTI_IMR
				LDR r11, [r10]
				ORR r11, r11, #(1 << 7)
				STR r11, [r10]
				B run_loop

.global EXTI9_5_IRQHandler
.type EXTI9_5_IRQHandler, %function
EXTI9_5_IRQHandler:
		@interupt handler we usually handle multiple interupts here but not
		PUSH {r3,r4, r5,r6}
		LDR r5, =0x40013C14		@exti_pr
		LDR r4, [r5]			@get the pin that gave interupt
		LDR r6, =0x40000C24 	@timer5_counter adresss
		TST r4, #(1 << 5)		@now we do if if 5 or 6 else 7
		BNE pin_5
		TST r4, #(1 << 6)
		BNE pin_6
		pin_7:
    		@we turn off exti for this pin
    		@then we clear any pending interupts and now the main loop will handle the rest
   			@then we will set our timer variables and these also act as flags for us
   			LDR r3, =0x40013C00
			LDR r4, [r3]
    		BIC r4, r4, #(1 << 7)
    		STR r4, [r3]
			MOV r5, #(1 << 7)
			LDR r4, =time3
			LDR r3, [r6]
			STR r3, [r4]
			B debounce
		pin_5:
   			LDR r3, =0x40013C00
			LDR r4, [r3]
    		BIC r4, r4, #(1 << 5)
    		STR r4, [r3]
			MOV r5, #(1 << 5)
			LDR r4, =time1
			LDR r3, [r6]
			STR r3, [r4]
			B debounce
		pin_6:
   			LDR r3, =0x40013C00
			LDR r4, [r3]
    		BIC r4, r4, #(1 << 6)
    		STR r4, [r3]
			MOV r5, #(1 << 6)
			LDR r4, =time2
			LDR r3, [r6]
			STR r3, [r4]
		debounce:
			LDR r6, =0x40013C14		@exti_pr
			STR r5, [r6]
			POP {r3, r4, r5, r6}
			BX lr



