.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb
@if you are reading this then I will be copying and pasting from the last lab to save time since I have already done this
.global main
.type main, %function
.data
.align 4
button_pressed:
    .word 0
.text
main:

	@i had a problem with sleeping with WFI and debugger disconnecting apparently
	@accoridng to google this is a setting I need to enable for this called DBGMCU_CR that allows the debugger to handle this
	LDR r0, =0xE0042004      @ DBGMCU_CR
	LDR	r1, [r0]
    ORR r1, r1, #(1 << 0)
    STR r1, [r0]
	@enable PWR Clock APB1
	LDR r0, =0x40023800
	LDR	r1, [r0, #0x40]
    ORR r1, r1, #(1 << 28)
    STR r1, [r0, #0x40]
    @enable Backup Domain Access
    LDR r0, =0x40007000
    LDR r1, [r0, #0x00]
    ORR r1, r1, #(1 << 8)
    STR r1, [r0, #0x00]
	@enable LSE in RCC_BDCR
    LDR r0, =0x40023800
    LDR r1, [r0, #0x70]
    @set LSE drive strength to the highest setting
    BIC r1, r1, #(3 << 3)
    ORR r1, r1, #(3 << 3)
    @enable LSE
    ORR r1, r1, #1
    STR r1, [r0, #0x70]
    @wait for LSE
	lse_waiter:
    	LDR r1, [r0, #0x70]
    	TST r1, #(1 << 1)
    	BEQ lse_waiter
	@now set as real time clock, CLEAAR rtcsel, lse, rtc enable
	LDR r0, =0x40023800
	LDR r1, [r0, #0x70]
	BIC r1, r1, #(3 << 8)
	ORR r1, r1, #(1 << 8)
	ORR r1, r1, #(1 << 15)
	STR r1, [r0, #0x70]
	@now read from clock
	LDR r0, =0x40002800
	LDR r2, [r0, #0x28]		@this gets precise
	LDR r1, [r0, #0x00]			@read TR which gives hours minutem seconds
	LDR r3, [r0, #0x04]		@read the DR section which gives months, year, day
	MOVW r6, #0x0000			@this will load 2^31 the modulus of my LCG
	MOVT r6, #0x8000
	SUBS r6, r6, #1	@subtract by 1
	MOV r9, #0
	ADD r9, r9, r1	@ I addd together all the times
	ADD r9, r9, r2
	ADD r9, r9, r3
	AND r9, r9, r6
	MOVW r7, #0x4E6D 		@this will set this register to 1103515245 the multiplier
	MOVT r7, #0x41C6
	MOVW r8, #12345			@this is the adder of 12345
	MOVT r8, #0
	@in the previous LAB 2 I forgopt to disable the RTC after im done using it so I will do that here
	@disable lse first
	LDR r0, =0x40023800
    LDR r1, [r0, #0x70]
	BIC r1, r1, #(1 << 0) @lse off
    @disable rtcc
	BIC r1, r1, #(1 << 15)
	STR r1, [r0, #0x70]
	@this is very important since this allows us to save energy its like leaving the bathroom light on when not using it
	@this is setting GPIO input and output feel free to skip to loop
	LDR r0, =0x40023830 		@ rcc AHB1ENR base address
	LDR r1, [r0]				@load from ahb1enr address
	ORR r1, r1, #0x05			@ this sets ports A And C for us to use for clokcing
	STR r1, [r0]				@ we set it
	@I will setup the user button here at PORT C pin 13 as user input
	LDR r0, =0x40020800 		@at Port C base address
	LDR r1, [r0]				@read GPIOC
	BIC r1, r1, #(0x3 << 26)	@set PC_13 (13*2=26) as input 00
	STR r1, [r0]
	@I will setup pin 5 Port A as ouput in 3
	LDR r0, =0x40020000 		@at A base address
	LDR r1, [r0]				@read GPIOA
	BIC r1, r1, #(0x3 << 10)		@clear PA _5 (5*2=10) to 00
	ORR r1, r1, #(0x1 << 10)		@set PA_5 (5*2=10) as ouput 01
	STR r1, [r0]
	@now lets setup our interupts, I will make a systick interupt for our sleep and a interupt for our input pin using a tim5 timer
	@this is a long prcoess but i looked up each step needed
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
	@-> APB2ENR enable SYSCFGEN -> Map PC_13 to EXTI 13 -> configure as falling or rising edge -> enable NVIC -> set priority below systick
	LDR r0, =0x40023844 @APB2ENR
	LDR r1, [r0]
	ORR r1, r1, #(0x1 << 14) @syscfgen bit
	STR r1, [r0]
	LDR r0, =0x40013814 @SYSCFG_EXTICR4
	LDR r1, [r0]
	BIC r1, r1, #(0xF << 4)		@clear all the bits since F is max for 4 bit number
	ORR r1, r1, #(2 << 4)		@port c
	STR r1, [r0]
	LDR r0, =0x40013C0C	@EXTI_RTSR on press send interupt
	LDR r1, [r0]
	ORR r1, r1, #(1 << 13)		@exti13
	STR r1, [r0]
	LDR r0, =0x40013C08 @disable release/falling edge
	LDR r1, [r0]
	BIC r1, r1, #(1 << 13)
	STR r1, [r0]
	LDR r0, =0x40013C00 @exti imr
	LDR r1, [r0]
	ORR r1, r1, #(1 << 13)
	STR r1, [r0]
	@ clearing a flag
	LDR r0, =0x40013C14
	MOV r1, #(1 << 13)
	STR r1, [r0]
	LDR r0, =0xE000E100 @nvic_isr the exti from 10-15 shares EXTI15_10_IRQn whic represents 15*2+10 = isr 40 which is ISER1 register
	LDR r1, [r0, #4] @ 0xE000E100 + 4 isr[1] interupts 32–63
	ORR r1, r1, #(1 << 8) @ 40 - 32
	STR r1, [r0, #4]
	LDR r0, =0xE000E400 @NVIC_IPR priority
	MOV r1, #0x20 @priority 2
	STRB r1, [r0, #40] @ipr 40th bit
	LDR r0, =0x40023808 @testing
	LDR r1, [r0]
	LDR r0, =0x40023800
	LDR r1, [r0]@test ending
	LDR r1, =0x40020000 @gpio A led
	LDR r3, =0x40000C24 @timer5_counter adresss
	LDR r0, [r1, #0x14]
	BIC r0, r0, #(1 << 5)
	STR r0, [r1, #0x14]
	CPSID i
   	B    run_loop    @branch to lowercase routine

end:
   WFI
   B     end            @stop here
@----------------------------------------------------------------------
@ I wrote it like this so we can do this more than once but for now thats once is enough
run_loop:
			@run the LCG Linear Congruential Generator https://www.geeksforgeeks.org/dsa/linear-congruence-method-for-generating-pseudo-random-numbers/
			MUL r9, r7, r9		@we start by multiplying and dont worry about overflows
			ADD  r9, r9, r8		@adding by the addder
			AND  r9, r9, r6		@instead of doing a modulo this allows me to use a AND instead for a power of 2
			MOV r5, #10			@we do mod 10 so we get a number from 0 - 9 + 1
			UDIV r4, r9, r5
			MLS r4, r5, r4, r9
			ADDS r4, r4, #1
			@now that we got a random time lets tell our systick timer to wait that long
			@I will use a flagging system so that button interupt doesnt interfere with the sleep function
			LDR r0, =1000 	@setting up timer convert sec to ms
			MUL r4, r0, r4	@ random time in seconf times 1000 gets us ms wait time
			LDR r0, [r3]	@this gets previous time for loop
			waiter: @this is a waiting loop that uses tim current-previous time and comparing it to the random time*1000 to see if we have waited enough
				LDR r5, [r3]
				SUB r5, r5, r0
				CMP r5, r4
				BLO waiter
			LDR r0, =0x40013C14 @this clears pending interupts
			MOV r2, #(1 << 13)
			STR r2, [r0]
			LDR r0, [r1, #0x14]	@turns on led
			ORR r0, r0, #(1 << 5)
			STR r0, [r1, #0x14]
			LDR r0, [r3]	@set the previous time here
			CPSIE i
			waitForInterupt: @this just a general polling loop that is able to handle multiple interupts
				WFI
    			LDR r4, =button_pressed
    			LDR r4, [r4]
    			CMP r4, #0
    			BEQ waitForInterupt
			CPSID i
			LDR r2, =button_pressed @get the time in ms from shared memory
			LDR r4, [r2]
			SUB r4, r4, r0 @difference from current- previous
			MOV r0, #0	@reeset time to 0
			STR r0, [r2]
			LDR r0, [r1, #0x14]	@turn off light after pressing
			BIC r0, r0, #(1 << 5)
			STR r0, [r1, #0x14]
			LDR r0, =0x40000C00
			LDR r5, [r0]
			BIC r5, r5, #(1 << 0) @stop timer
			STR r5, [r0]
			B end


.global EXTI15_10_IRQHandler
.type EXTI15_10_IRQHandler, %function
EXTI15_10_IRQHandler:
		@interupt handler we usually handle multiple interupts here but not
		PUSH {r4, r5}
		LDR r5, =0x40000C24	@get counter from tim5
		LDR r4, [r5]
    	LDR r5, =button_pressed
    	STR r4, [r5]              @set the time on button click
		LDR r5, =0x40013C14 @clear pending
    	MOV r4, #(1 << 13)
    	STR r4, [r5]
    	POP {r4, r5}
		BX lr






