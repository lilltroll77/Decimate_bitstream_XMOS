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
#define SP_H_PTR sp[1]
#define C r0
#define PORT r1
#define BITP_PTR r3
#define CT 6
#define H_PTR r4
#define BIT_PTR r5
#define INT_SIZE r6
#define READ r7
#define WRITE r8
#define ACC r9
#define ZERO r10
#define FIFO ZERO
#define PORTVAL r11

#define CALC {add BIT_PTR, BIT_PTR, 1 ; ld8u r11, BIT_PTR[ZERO]}; ldw r11, H_PTR[r11]; {add ACC , ACC , r11; sub H_PTR , H_PTR , INT_SIZE}
#define CALC2 CALC;CALC
#define CALC4 CALC2;CALC2
#define CALC8 CALC4;CALC4
#define CALC16 CALC8;CALC8
#define CALC24 CALC16;CALC8
#define CALC32 CALC16;CALC16


//resource control bits
#define CTRL_COND_NONE 0x0001
#define CTRL_IE_MODE_INTERRUPT 0x000a

decimate64asm:
	.issue_mode dual
	dualentsp 0

 	 {
 	  ldc ZERO, 0
	  ldc WRITE,0}
	 {
	 //Store r2 in dp
	  set dp , r2
      sub r11 , ZERO , 8
     }
	//Set resource control bits
	 {
	  setc res[PORT], CTRL_COND_NONE
	  //Use cp to keep track of the port timer
	  set cp , r11 // start at -8 -> 56 , ...
	 }
	 ldc INT_SIZE, (4*SIZE)

  	setupInterupt:
	ldap 	r11,   readPort
	setv 	res[PORT], r11
	setc    res[PORT], XS1_SETC_IE_MODE_INTERRUPT //enable interupts on port

	outct res[C], CT
	 //Discard first bit
	inpw r11, res[PORT], 1



LOOP: // 6 clkcycles

	clre
	setsr  	XS1_SR_IEBLE_MASK //enable interupts in thread

/** DO NOT USE r0 OR r2 **/
	{
	 add r11 , WRITE , 2 //Read = WRITE+2
	 ldc ACC , 0
	}
	{
	 ldaw H_PTR , dp[0] 	//restore original r2
	 shl r11 , r11 , 2		//READ <<=2
	}
	//register char * alias bit_ptr =&(bitpattern ,char[])[read]; //r10
	{
	 add BIT_PTR, BITP_PTR, r11
	 eeu  	res[PORT] //enable event uncond. on PORT
	}
CALC_60:
	CALC32
	CALC8
	CALC8
	CALC8
	CALC4

PORT_IN_24:
//8*50ns==400ns
    //bf r0,PORT_IN_24 // Ensure interupts was triggered during CALC

	clrsr  	XS1_SR_IEBLE_MASK //disable interupts in thread and wait for port

/** r0,r2,r11 IS NOW FREE TO USE **/
 	inpw PORTVAL, res[PORT], 24
	{
	 shr PORTVAL, PORTVAL, 8
     ldc r2, FIFO_INT
	}
	stw  PORTVAL, BITP_PTR[WRITE]
	add r2 , r2 , WRITE
	stw PORTVAL, BITP_PTR[r2]
	{
	 getts r2, res[PORT]
	 ldaw r11 , cp[16] // r11 = cp+64
	}
	eq r2 , r11, r2 //64 port clocks should have passed between each inpw_24, if not -> too late
	{
	 ecallf r2 //Safest to disable the gatedriver if thread was starved out of time
	 set cp , r11
	}

CALC_3:
	CALC2
	CALC

PORT_IN_8:
	inpw PORTVAL, res[PORT], 8
	shr  r2, PORTVAL, 24

CALC_1:
	ldw  r2, H_PTR[r2]
	add  ACC , ACC , r2

CHANNEL_OUT:
 	out res[C], ACC

UPDATE_BUFFER:
	ldw r2 , BITP_PTR[WRITE]
	{or r11 , PORTVAL , r2
	ldc r2 , FIFO_INT
	}
	stw r11, BITP_PTR[WRITE]
	{add r2 , r2 , WRITE
	 add WRITE,WRITE,1}
	stw r11, BITP_PTR[r2]
	zext WRITE, 4
	bu LOOP


readPort:
//Do not use r11 during interupt!
		edu  	res[PORT] //Disable event uncond.
		{
		in r2, res[PORT]
		ldc FIFO, FIFO_INT
		}
		stw r2, BITP_PTR[WRITE]
		{
		 add FIFO , FIFO , WRITE
		 add WRITE , WRITE ,1
		}
		//zext WRITE, 4
		stw r2, BITP_PTR[FIFO]
		ldc ZERO , 0// restore ZERO reg
		kret

	.cc_bottom decimate64asm.function
	.set	decimate64asm.nstackwords,0
	.globl	decimate64asm.nstackwords
	.set	decimate64asm.maxcores,1
	.globl	decimate64asm.maxcores
	.set	decimate64asm.maxtimers,0
	.globl	decimate64asm.maxtimers
	.set	decimate64asm.maxchanends,1
	.globl	decimate64asm.maxchanends

