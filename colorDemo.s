######################
# Author: Taylor Zowtuk
# Date: May 2019
#
# A demo meant to utilize GLIR's colorDemo function
######################
.text
main:
    addi	sp, sp, -4		# Adjust the stack to save fp
    sw	s0, 0(sp)		# Save fp
    add	s0, zero, sp		# fp <= sp
    addi	sp, sp, -4		# Adjust stack to save variables
    sw	ra, -4(s0)		# Save ra

    # colorDemo requires that the terminal size be at least 30 rows and 6 cols big 
    li      a0, 31
    li      a1, 7
    jal     startGLIR

    
    jal     clearScreen

    jal     colorDemo

    # loop to pause the demo for viewing before quiting; increase the immediate in t1 for a longer pause
    add     t0, zero, zero
    li      t1,  1000000
    colorLoop:
        beq     t0, t1, doneColor
        addi    t0, t0, 1 
        nop
        jal     zero, colorLoop

doneColor:
    jal     endGLIR

    lw	ra, -4(s0)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4

	li a7 10
	ecall	
