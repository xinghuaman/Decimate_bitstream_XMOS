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
#define CALC2 CALC;CALC
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
calc0_4:
		CALC4
calc4_8:
		CALC4
calc8_12:
		CALC4
calc12_16:
		CALC4

	#if (BLOCKS>32)
calc16_20:
		CALC4
	#endif


	#if (BLOCKS>36)
calc20_24:
		CALC4
	#endif

	#if (BLOCKS>40)
calc24_28:
		CALC4
	#endif

	#if (BLOCKS>44)
calc28_32:
		CALC4
	#endif

	#if (BLOCKS>48)
calc32_36:
		CALC4
	#endif

	#if (BLOCKS>52)
calc36_40:
		CALC4
	#endif

	#if (BLOCKS>56)
calc40_44:
		CALC4
	#endif

	#if (BLOCKS>60)
calc44_48:
		CALC4
	#endif

	#if (BLOCKS>64)
calc48_52:
		CALC4
	#endif

	#if (BLOCKS>68)
calc52_56:
		CALC4
	#endif

	#if (BLOCKS>72)
calc56_60:
		CALC4
	#endif

	#if (BLOCKS>76)
calc60_64:
		CALC4
	#endif

	#if (BLOCKS>80)

calc64_68:
		CALC4
	#endif

	#if (BLOCKS>84)
calc68_72:
		CALC4
	#endif

	#if (BLOCKS>88)
calc72_76:
		CALC4
	#endif

#if (BLOCKS>92)
calc76_80:
		CALC4
#endif

#if (BLOCKS>96)
calc80_84:
		CALC4
#endif
#if (BLOCKS>100)

calc84_88:
		CALC4
#endif

#if (BLOCKS>104)
calc88_92:
		CALC4
#endif
	CALC3

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
CALC_LUT_PART2:
	//PLACE AS MANY CALC AS POSSIBLE HERE: 12 for 100MHz CPU @ 500/26 MHz port clock
	//PLACE AS MANY CALC AS POSSIBLE HERE: 11 for 100MHz CPU @ 500/24 MHz port clock
	CALC4
	CALC4
	CALC4

PORT_IN_8:
	inpw PORTVAL, res[PORT], 8
	shr  r7, PORTVAL, 24

CALC_LAST_BYTE:
	ldw  r7, LUT_PTR[r7]
	add  ACC , ACC , r7

CHANNEL_OUT:
	//shr ACC , ACC , FIR_scale
 	out res[C], ACC

UPDATE_BUFFER:
	ldw r7 , dp[1]
	{or r11 , PORTVAL , r7 		; ldc r4 , FIFO_INT}
	{stw r11, dp[1] 			; add WRITE , WRITE , 2}
	{stw r11, dp[(1+FIFO_INT)] 	; lsu r7 , WRITE , r4 }
	mul WRITE , r7 , WRITE
	bu LOOP



readPort:
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

