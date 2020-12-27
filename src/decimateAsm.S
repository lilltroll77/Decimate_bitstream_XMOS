	.text
	.file	"../src/decimateAsm.xc"

	.inline_definition delay_seconds
	.inline_definition delay_milliseconds
	.inline_definition delay_microseconds
	.set usage.anon.0,0
	.set usage.anon.1,0
	.set usage.anon.2,0
	.call usage.anon.2,delay_ticks_longlong
	.call usage.anon.1,delay_ticks_longlong
	.call usage.anon.0,delay_ticks_longlong
	.set decimate64asm.locnoside, 0


	.globl	decimate64asm
	.align	4
	.type	decimate64asm,@function
	.cc_top decimate64asm.function,decimate64asm
#include "xs1.h"
#include "defines.h"
#define C r0
#define PORT r1
#define LUT r2
#define BUFFER r3
#define LUT_PTR r4
#define TIME r5
#define BYTE_SIZE r6
#define INTERUPT_REG r7
#define WRITE r8
#define ACC r9
#define READ r10
#define PORTVAL r11
#define CT 6

#define UPDATE_READ add READ, READ, 1
#define UPDATE_LUT sub LUT_PTR , LUT_PTR , BYTE_SIZE
#define READ_BUFFER ld8u r11, BUFFER[READ]
#define READ_LUT ldw r11, LUT_PTR[r11]
#define ACCUMULATE add ACC , ACC , r11

#define CALC 	{READ_BUFFER;UPDATE_READ};{READ_LUT;nop };{ACCUMULATE;UPDATE_LUT}
#define CALC3 CALC;CALC;CALC
#define CALC4 CALC;CALC;CALC;CALC



//resource control bits
#define CTRL_COND_NONE 0x0001
#define CTRL_IE_MODE_INTERRUPT 0x000a

decimate64asm:
	.issue_mode dual
	dualentsp 4
	ldc WRITE,0
    sub r11 , WRITE , 8
	//Set resource control bits
	 {
	  setc res[PORT], CTRL_COND_NONE
	  //Use cp to keep track of the port timer
	  set cp , r11 // start at -8 -> 56 , ...
	 }
	 ldc BYTE_SIZE, (4*SIZE)

  	setupInterupt:
	ldap 	r11,   readPort
	setv 	res[PORT], r11
	setc    res[PORT], XS1_SETC_IE_MODE_INTERRUPT //enable interupts on port
    clre

	outct res[C], CT
	 //Discard first bit
	inpw r11, res[PORT], 1


LOOP:
	setsr  	XS1_SR_IEBLE_MASK //enable interupts in thread
    {
	 add READ , WRITE , 2 //Read index = WRITE+2
	 ldc ACC , 0
	}
 	 ldaw r11 , BUFFER[WRITE]
	{
	  shl READ , READ , 2
	  set dp , r11 //Write pointer
	}
	{
   	 mov LUT_PTR , LUT
	 eeu  	res[PORT] //enable event uncond. on PORT
	}

.align 4
CALC_LUT:
	#if (BLOCKS>4)
		CALC4;
	#endif
	#if (BLOCKS>8)
		CALC4;
	#endif
	#if (BLOCKS>12)
		CALC4;
	#endif
	#if (BLOCKS>16)
		CALC4;
	#endif
	#if (BLOCKS>20)
		CALC4;
	#endif
	#if (BLOCKS>24)
		CALC4;
	#endif
	#if (BLOCKS>28)
		CALC4;
	#endif
	#if (BLOCKS>32)
		CALC4;
	#endif
	#if (BLOCKS>36)
		CALC4;
	#endif
	#if (BLOCKS>40)
		CALC4;
	#endif
	#if (BLOCKS>44)
		CALC4;
	#endif
	#if (BLOCKS>48)
		CALC4;
	#endif
	#if (BLOCKS>52)
		CALC4;
	#endif
	#if (BLOCKS>56)
		CALC4;
	#endif
	#if (BLOCKS>60)
		CALC4;
	#endif
	#if (BLOCKS>64)
		CALC4;
	#endif
	#if (BLOCKS>68)
		CALC4;
	#endif
	#if (BLOCKS>72)
		CALC4;
	#endif
	#if (BLOCKS>76)
		CALC4;
	#endif
	#if (BLOCKS>80)
		CALC4;
	#endif
	#if (BLOCKS>84)
		CALC4;
	#endif
	#if (BLOCKS>88)
		CALC4;
	#endif
	#if (BLOCKS>92)
		CALC4;
	#endif
	#if (BLOCKS>96)
		CALC4;
	#endif

PORT_IN_24:
	clrsr  	XS1_SR_IEBLE_MASK //disable interupts in thread and wait for port
 	inpw r7, res[PORT], 24
    {
     shr r7, r7, 8
     getts TIME, res[PORT]
    }
    {
     ldaw r11 , cp[16]
	 stw  r7, dp[1]
	}
	{
	 stw r7, dp[(1+FIFO_INT)]
	 zext r11 , 16 //Port timer is 16 bit
	}
	{
	eq TIME , r11, TIME //64 port clocks should have passed between each inpw_24, if not -> too late
	set cp , r11
	}
	{
	 ecallf TIME //Safest to disable the gatedriver if thread was starved out of time
	 ldc TIME , 0 // restore ZERO
	}
CALC_3:
	CALC3

PORT_IN_8:
	inpw PORTVAL, res[PORT], 8
	shr  r7, PORTVAL, 24

CALC_1:
	ldw  r7, LUT_PTR[r7]
	add  ACC , ACC , r7

CHANNEL_OUT:
 	out res[C], ACC

UPDATE_BUFFER:
	ldw r7 , dp[1]
	{or r11 , PORTVAL , r7 		; ldc r4 , FIFO_INT}
	{stw r11, dp[1] 			; add WRITE , WRITE , 2}
	{stw r11, dp[(1+FIFO_INT)] 	; lsu r7 , WRITE , r4 }
	mul WRITE , r7 , WRITE
	bu LOOP



readPort:
//Do not use r11 during interupt!
		in INTERUPT_REG, res[PORT]
		{
		 edu  	res[PORT] //Disable event uncond.
		 stw INTERUPT_REG, dp[0]
		}
		stw INTERUPT_REG, dp[FIFO_INT]
		kret

	.cc_bottom decimate64asm.function
	.set	decimate64asm.nstackwords,4
	.globl	decimate64asm.nstackwords
	.set	decimate64asm.maxcores,1
	.globl	decimate64asm.maxcores
	.set	decimate64asm.maxtimers,0
	.globl	decimate64asm.maxtimers
	.set	decimate64asm.maxchanends,1
	.globl	decimate64asm.maxchanends

