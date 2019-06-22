# Copyright 2017 Austin Crapo
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
# Author: Austin Crapo
# Date: June 2017
# Conversion to RISC-V: Taylor Zowtuk
# Date: June 2019
#-------------------------------------------------------------------------------
# A demo meant to show off GLIR's basic functions (batchPrint, printString and
# printCircle).
#
# RISC-V conversion notes: The original MIPS program appears to leave a long 
# vertical bar in the print circles section of code. Without any videos or 
# in-depth documentation of intended functioning I am assuming that this is 
# intended and have avoided fixing this for the purposes of this conversion.
#
# Use the runDemo shell script to run this demonstration.
#-------------------------------------------------------------------------------

.data
char:			.asciz " "

.align 2
# Only using 1 job at a time
# 3 words + 1 halfword (sentinel)  = 3 * 4 + 2 = 14
printList:		.space 14	
.text
main:
		# Stack Adjustments
		addi	sp, sp, -4						# Adjust the stack to save fp
		sw		s0, 0(sp)						# Save fp
		add		s0, zero, sp					# fp <= sp
		addi	sp, sp, -24						# Adjust stack to save variables
		sw		ra, -4(s0)						# Save ra
		sw		s1, -8(s0)		
		sw		s2, -12(s0)
		sw		s3, -16(s0)
		sw		s4, -20(s0)
		sw		s4, -24(s0)
		
		# Pass the size of terminal
		li		a0, 30							# Number of rows
		li		a1, 60							# Number of cols
		jal		startGLIR
		
		# This section shows off batch printing. It prints a single job at a 
		# time, but in theory you could add all the jobs to the list at once
		# and have all of them print at the same time. It's slowed here so you
		# have a chance to see it.
		
		li		s1, 0							# row
		li		s2, 0							# col
		li		s3, 0							# fgcolor, valid colors are 
												# between 0 and 255
		li		s4, 100							# bgcolor, valid colors are 
												# between 0 and 255
		li		s5, 0x20						# char, printable chars are 
												# between 0x20 and 0x7e
		loop:
				li		t0, 20
				beq		s1, t0, lend
				# Create a print job by adding to the list
				la		a0, printList
				sh		s1, 0(a0)				# Halfword row
				sh		s2, 2(a0)				# Halfword col
				li		t0, 4
				sb		t0, 4(a0)				# Print code 4 (both foreground
												# and background colors)
				sb		s3, 5(a0)				# Foreground color
				sb		s4, 6(a0)				# Background color
				# 7th byte is empty
				la		t0, char
				sb		s5, 0(t0)				# Update the char string 
				sw		t0, 8(a0)				# Then provide it to the job
				li		t0, 0xFFFF
				sh		t0, 12(a0)				# Terminate the job list
				jal		batchPrint
				
				li		a0, 1					# Wait '1' seconds
				jal		sleep
				
				addi	s4, s4, 1				# Goto next bgcolor
				li		t0, 255
				bne		s4, t0, lfgColor
				li		s4, 0
				lfgColor:
				addi	s3, s3, 1				# Goto next fgcolor
				li		t0, 255
				bne		s3, t0, lchar
				li		s3, 0
				lchar:
				addi	s5, s5, 1				# Goto next char
				li		t0, 0x7e
				bne		s5, t0, lcont
				li		s5, 0x20
					
					
				lcont:
				addi 	s2, s2, 1
				li		t0, 60
				bne		s2, t0, loop
				li		s2, 0
				addi	s1, s1, 1
				j		loop

		lend:		
		# Wait
		li		a0, 1000
		jal		sleep
		
		# Then carve out a message.
		# This section shows off printString; just simply printing the string we
		# want directly to a location using the current settings.
		
		# Restore default color settings since they probably are messed up from
		# the earlier demo
		jal		restoreSettings	
		
		
		# The goal is to print:

		#	@  @ @@@@   @
		#	@  @  @@    @
		#	@@@@  @@    @
		#	@  @  @@    
		#	@  @ @@@@   @

		la		a0, char
		# Print using spaces (it's black background white text)
		li		t1, 0x20	
		sw		t1, 0(a0)

		# We're going to be hacky to save space. printString doesn't overwrite a0
		# so lets not redefine it between calls.
		li		a1, 0
		li		a2, 4
		jal		printString
		li		a1, 1
		li		a2, 4
		jal		printString
		li		a1, 2
		li		a2, 4
		jal		printString
		li		a1, 3
		li		a2, 4
		jal		printString
		li		a1, 4
		li		a2, 4
		jal		printString
		li		a1, 2
		li		a2, 5
		jal		printString
		li		a1, 2
		li		a2, 6
		jal		printString
		li		a1, 0
		li		a2, 7
		jal		printString
		li		a1, 1
		li		a2, 7
		jal		printString
		li		a1, 2
		li		a2, 7
		jal		printString
		li		a1, 3
		li		a2, 7
		jal		printString
		li		a1, 4
		li		a2, 7
		jal		printString						# Done printing H
		
		li		a0, 500
		jal		sleep
		
		la		a0, char
		li		a1, 0
		li		a2, 9
		jal		printString
		li		a1, 4
		li		a2, 9
		jal		printString

		li		a1, 0
		li		a2, 10
		jal		printString
		li		a1, 1
		li		a2, 10
		jal		printString
		li		a1, 2
		li		a2, 10
		jal		printString
		li		a1, 3
		li		a2, 10
		jal		printString
		li		a1, 4
		li		a2, 10
		jal		printString
		li		a1, 0
		li		a2, 11
		jal		printString
		li		a1, 1
		li		a2, 11
		jal		printString
		li		a1, 2
		li		a2, 11
		jal		printString
		li		a1, 3
		li		a2, 11
		jal		printString
		li		a1, 4
		li		a2, 11
		jal		printString
		
		li		a1, 0
		li		a2, 12
		jal		printString
		li		a1, 4
		li		a2, 12
		jal		printString						# Done printing "I"
		
		li		a0, 500
		jal		sleep
		
		la		a0, char
		li		a1, 0
		li		a2, 15
		jal		printString
		li		a1, 1
		li		a2, 15
		jal		printString
		li		a1, 2
		li		a2, 15
		jal		printString
		li		a1, 4
		li		a2, 15
		jal		printString						# Done printing "!"
		
		li		a0, 1000
		jal		sleep
		
		
		
		# Print circles! 2 pixels wide, and only 3 on screen at a time
		li		a0, 15
		li		a1, 30
		li		a2, 0
		# REMEMBER this is little endian so now it's [empty] [bgcolor] [fgcolor] [printing code]
		li		a3, 0x00130003	
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 1
		li		a3, 0x00130003
		jal		printCircle
		
		li		a0, 1000
		jal		sleep
		
		li		a0, 15
		li		a1, 30
		li		a2, 0
		li		a3, 0x00120003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 1
		li		a3, 0x00120003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 2
		li		a3, 0x00130003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 3
		li		a3, 0x00130003
		jal		printCircle
		
		li		a0, 1000
		jal		sleep
		
		li		a0, 15
		li		a1, 30
		li		a2, 0
		li		a3, 0x00110003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 1
		li		a3, 0x00110003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 2
		li		a3, 0x00120003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 3
		li		a3, 0x00120003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 4
		li		a3, 0x00130003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 5
		li		a3, 0x00130003
		jal		printCircle
		
		li		a0, 1000
		jal		sleep
		
		li		a0, 15
		li		a1, 30
		li		a2, 0
		li		a3, 0x00100003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 1
		li		a3, 0x00100003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 2
		li		a3, 0x00110003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 3
		li		a3, 0x00110003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 4
		li		a3, 0x00120003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 5
		li		a3, 0x00120003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 6
		li		a3, 0x00130003
		jal		printCircle
		li		a0, 15
		li		a1, 30
		li		a2, 7
		li		a3, 0x00130003
		jal		printCircle
		
		li		a0, 1000
		jal		sleep
		
		li		s1, 2							# radius = 2 (0 and 1 already
												# covered)
		li		s2, 0							# counter = 0
		li		s4, 15							# max = 30
		
		mainCircleLoop:
				beq		s2, s4, mCLend
				
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				li		a3, 0x00100003
				jal		printCircle
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				addi	a2, a2, 1
				li		a3, 0x00100003
				jal		printCircle
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				addi	a2, a2, 2
				li		a3, 0x00110003
				jal		printCircle
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				addi	a2, a2, 3
				li		a3, 0x00110003
				jal		printCircle
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				addi	a2, a2, 4
				li		a3, 0x00120003
				jal		printCircle
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				addi	a2, a2, 5
				li		a3, 0x00120003
				jal		printCircle
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				addi	a2, a2, 6
				li		a3, 0x00130003
				jal		printCircle
				li		a0, 15
				li		a1, 30
				add		a2, s1, s2
				addi	a2, a2, 7
				li		a3, 0x00130003
				jal		printCircle
				
				li		a0, 1000
				jal		sleep
				
				addi	s1, s1, 1
				addi	s2, s2, 1
				j		mainCircleLoop
		
		mCLend:		
		jal		restoreSettings
		jal		clearScreen
		li		a0, 1000
		jal		sleep

		# MUST BE CALLED BEFORE ENDING PROGRAM
		jal		endGLIR
		
		# Stack Restore
		lw		ra, -4(s0)
		lw		s1, -8(s0)
		lw		s2, -12(s0)
		lw		s3, -16(s0)
		lw		s4, -20(s0)
		lw		s5, -24(s0)
		addi	sp, sp, 24
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
