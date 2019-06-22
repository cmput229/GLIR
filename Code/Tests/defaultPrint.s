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
# A test for the batchPrint print code 1 functionality (standard print, default
# terminal settings). Meant to print three characters diagonally. The first
# character is printed with print code 4 and non-default terminal background and
# foreground colors. The next two characters are printed with print code 1 and 
# should be printed with termianl default background and foreground regardless
# of the colors specified in their respective jobs.
# Use the runDefaultPrint shell script to run this test.
#-------------------------------------------------------------------------------

.data
# Three 'char' variables because each unqiue character we want to print needs to
# pass an address containing the string to print for the batchPrint job. 
char1:			.asciz " "	
char2:			.asciz " "	
char3:			.asciz " "
.align 2
# Three jobs and a null terminator 3 x 12 + 2
printList:		.space 38
.text
main:
		addi	sp, sp, -4						# Adjust the stack to save fp
		sw		s0, 0(sp)						# Save fp
		add		s0, zero, sp					# fp <= sp
		addi	sp, sp, -4						# Adjust stack to save variables
		sw		ra, -4(s0)						# Save ra

		# Pass the size of terminal
		li      a0, 5							# Number of rows
		li      a1, 5							# Number of cols
		jal     startGLIR

		jal 	clearScreen

		la		a0, printList					# Address of list for batchPrint
		# Create a print job by adding to the list

		# First job
		li		s1, 1							# row
		li		s2, 1							# col
		li		s3, 26							# fgcolor, valid colors are 
												# between 0 and 255
		li		s4, 164							# bgcolor, valid colors are 
												# between 0 and 255
		# char, printable chars are between 0x20 and 0x7e
		li		s5, 0x32						# '2'
		sh		s1, 0(a0)						# Halfword row
		sh		s2, 2(a0)						# Halfword col
		li		t0, 4
		sb		t0, 4(a0)						# Print code 4 (both foreground
												# and background colors)
		sb		s3, 5(a0)						# Foreground color
		sb		s4, 6(a0)						# Background color
		# 7th byte is empty
		la		t0, char1
		sb		s5, 0(t0)						# Update the char string 
		sw		t0, 8(a0)						# Then provide it to the job

		addi 	a0, a0, 12						# Increment to add next job
		# Second job
		li		s1, 2							# row
		li		s2, 2							# col
		# When print code 1 is used for a job the fg/bgcolor should be ignored
		li		s3, 211							# fgcolor
		li		s4, 217							# bgcolor
		li		s5, 0x4e						# 'N'
		sh		s1, 0(a0)
		sh		s2, 2(a0)
		li		t0, 1
		sb		t0, 4(a0)						# Print code 1; default settings
		sb		s3, 5(a0)		
		sb		s4, 6(a0)		
		# 7th byte is empty
		la		t0, char2
		sb		s5, 0(t0)
		sw		t0, 8(a0)

		addi 	a0, a0, 12						# Increment to add next job
		# Third job
		li		s1, 3							# row
		li		s2, 3							# col
		li		s3, 157							# fgcolor
		li		s4, 166							# bgcolor
		li		s5, 0x57						# 'W'
		sh		s1, 0(a0)	
		sh		s2, 2(a0)
		li		t0, 1
		sb		t0, 4(a0)						# Print code 1
		sb		s3, 5(a0)
		sb		s4, 6(a0)
		# 7th byte is empty
		la		t0, char3
		sb		s5, 0(t0)
		sw		t0, 8(a0)
		
		# Terminate the job list
		li		t0, 0xFFFF
		sh		t0, 12(a0)

		# a0 has been incremented a bunch; re-get the base of the printList
		la  	a0, printList
		jal		batchPrint

		# Wait 2.5 seconds
		li      a0, 2500
		jal     sleep

		jal     endGLIR

		# Stack restore
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
