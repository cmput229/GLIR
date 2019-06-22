# Copyright 2019 Taylor Zowtuk
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
# IN THE SOFTWARE.
#-------------------------------------------------------------------------------
# Author: Taylor Zowtuk
# Date: June 2019
#-------------------------------------------------------------------------------
# A demo meant to show off GLIR's colorDemo subroutine.
# Use the runColorDemo shell script to run this demonstration.
#-------------------------------------------------------------------------------

.text
main:
		# Stack Adjustments
		addi	sp, sp, -4						# Adjust the stack to save fp
		sw		s0, 0(sp)						# Save fp
		add		s0, zero, sp					# fp <= sp
		addi	sp, sp, -4						# Adjust stack to save variables
		sw		ra, -4(s0)						# Save ra

		# Pass the size of terminal
		li      a0, 42							# Number of rows
		li      a1, 6							# Number of cols
		jal     startGLIR

		jal 	clearScreen

		jal     colorDemo

		# Wait 5 seconds to admire
		li      a0, 5000
		jal     sleep

		jal     endGLIR

		# Stack Restore
		lw		ra, -4(s0)
		addi	sp, sp, 4
		lw		s0, 0(sp)
		addi	sp, sp, 4

		# Exit program
		li 		a7, 10
		ecall

#-------------------------------------------------------------------------------
# sleep
# Args:		a0 = the number of milliseconds to sleep
# 
# Waits the specified number of milliseconds (roughly) by doing nothing
#-------------------------------------------------------------------------------
sleep:
		wSoutLoop:
				beq		a0, zero, wSoLend
				addi	a0, a0, -1
				li		t0, 740
				wSloop:
				beq		t0, zero, wSlend
				nop
				addi	t0, t0, -1
				j		wSloop
				wSlend:
				j		wSoutLoop

		wSoLend:
		ret
