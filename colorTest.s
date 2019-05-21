######################
# Author: Taylor Zowtuk
# Date: May 2019
#
# A demo meant to show off GLIR's colorDemo subroutine
######################
.data
.align 0
cDchar2:
    .byte 0xe2, 0x96, 0x88      #unicode full block char █; loaded as bytes for RARS
    .byte 0
.text
main:
    addi	sp, sp, -4		# Adjust the stack to save fp
    sw	s0, 0(sp)		# Save fp
    add	s0, zero, sp		# fp <= sp
    addi	sp, sp, -4		# Adjust stack to save variables
    sw	ra, -4(s0)		# Save ra

    #pass the size of terminal
    li      a0, 41
    li      a1, 6
    jal     startGLIR

    jal clearScreen

    jal     colorDemo

    #wait 10 seconds
    li      a0, 5000
    jal     sleep

    jal     endGLIR

    #restore stack
    lw	ra, -4(s0)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4

    #end
	li a7, 10
	ecall

sleep:
	#############################################
	# Waits the specified number of milliseconds (roughly) by doing nothing
	# a0 = the number of seconds to sleep
	#############################################
	wSoutLoop:
	beq	a0, zero, wSoLend
		addi	a0, a0, -1
		li	t0, 740
		wSloop:
		beq	t0, zero, wSlend
			nop
			addi	t0, t0, -1
			jal		zero, wSloop
		wSlend:
		jal		zero, wSoutLoop
	wSoLend:
	jalr	zero, ra, 0	
