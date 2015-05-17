.section .data
.include "nios_macros.s"
.equ ADDR_JP1, 0x10000060   /*Address GPIO JP1*/
.equ TIMER, 0x10002000 /*Address of timer*/
.global main
.section .text
 
main:
  movia  r8, ADDR_JP1 
  movia r7, TIMER 
  movia  r9, 0x07f557ff
  stwio  r9, 4(r8)
  movia r10, 0xFFFFFBFF /* Sensor 0 LEFT */
  movia r11, 0xFFFFEFFF /* Sensor 1 RIGHT */
  
balance:
	call starttime
	call polltime
	bne r4, r0, balance
    movia r4, 50000
    call pwm
    call pollpwm

	stwio r11, (r8)
	movi r5, 13
	call pollsensor /*poll sensor 1 -right side*/
	mov r13, r14
	
	stwio r10, (r8)
	movi r5, 11
	call pollsensor /* poll sensor 0 - left side */

    /* can try pwm call here and disable / enabling */

	addi r13, r13, 1 /* "calibration" */
	ble r14, r13, right
	ble r13, r14, left
	br balance
  
left:
	movia r6, 0xfffffffe
	subi sp, sp, 4
	stw ra, (sp)
	stwio r6, 0(r8) /*motor on*/

    movia r4, 50000 /*delay*/
    call pwm
    call pollpwm

    stwio r0, 0(r8) /*motor off*/
    movia r4, 50000 /*delay*/
    call pwm
    call pollpwm

    ldw ra, (sp)
    addi sp, sp, 4
	ret

right:
	movia r6, 0xfffffffc
	subi sp, sp, 4
	stw ra, (sp)
	stwio r6, 0(r8) /*motor on*/

    movia r4, 50000 /* delay */
    call pwm
    call pollpwm

    stwio r0, 0(r8) /*motor off*/
    movia r4, 50000 /*delay*/
    call pwm
    call pollpwm
	
    ldw ra, (sp)
    addi sp, sp, 4
	ret
  
pollsensor:
	ldwio r14, (r8)
	srl r14, r14, r5 
	andi r14, r14, 1
	bne r14, r0, pollsensor 
	ldwio r14, (r8)
	srli r14, r14, 27 
	andi r14, r14, 0x000F 
	ret
	
polltime:
	stwio r0, 16(r7)
	ldwio r18, 16(r7)
	ldwio r19, 20(r7)
	slli r19, r19, 16
	or r19, r19, r18 
	ret

starttime:
	movia r2, 50000
    stwio r2, 8(r7)
	stwio r0, 12(r7)
	movui r2, 0
	stwio r2, 4(r7)
	ret

pwm:
    stwio r4, 8(r7)       #two low byte of the timer
    stwio zero, 12(r7)     #two high bytes of the timer
    stwio zero, (r7)       #reset timer
    movi  r24, 0b0100
    stwio r24, (r7)
		
pollpwm:
    ldwio r24, (r7)
    andi r24, r24, 1
    beq r24, zero, pollpwm */

pwm: /*timer runs, times out after x cycles */
    stwio r4, 8(r7) ;timer period set for 50,000 cycles
    stwio r0, 12(r7)
    movui r2, 4
    stwio r2, 4(r7) /*start the timer*/
    ret

pollpwm:
    stwio r0, 16(r7) /*take a snapshot of the timer*/
    ldwio r3, 16(r7) /* read snapshot low bits */
    ldwio r4, 20(r7) /* read snapshot high bits */
    slli r4, r4, 16
    or r4, r4, r3 /*snapshot in r4*/
    bne r4, r0, pollpwm
    ret
