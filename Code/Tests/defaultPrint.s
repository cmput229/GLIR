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
# A test for the GLIR_BatchPrint print code 1 functionality (standard print, 
# default terminal settings). Meant to print three characters diagonally. The 
# first character is printed with print code 4 and non-default terminal 
# background and foreground colors. The next two characters are printed with 
# print code 1 and should be printed with termianl default background and 
# foreground regardless of the colors specified in their respective jobs.
# Use the runDefaultPrint shell script to run this test.
#-------------------------------------------------------------------------------

.include "../GLIR.s"

.data
# Here we store the RARS syscall service numbers which are needed.
# Before a syscall we load from the label.
# They are saved and loaded in this way to promote code portability.
_EXIT:			.word 10
_SLEEP:			.word 32

# Three 'char' variables because each unqiue character we want to print needs to
# pass an address containing the string to print for the GLIR_BatchPrint job. 
Char1:			.asciz " "	
Char2:			.asciz " "	
Char3:			.asciz " "
.align 2
# Three jobs and a null terminator 3 x 12 + 2
PrintList:		.space 38
.text
main:
		addi	sp, sp, -4						# Adjust the stack to save fp
		sw		s0, 0(sp)						# Save fp
		add		s0, zero, sp					# fp <- sp
		addi	sp, sp, -4						# Adjust stack to save variables
		sw		ra, -4(s0)						# Save ra

		# Pass the size of terminal
		li      a0, 5							# Number of rows
		li      a1, 5							# Number of cols
		jal     ra, GLIR_Start

		la		a0, PrintList					# Address of list for 
												# GLIR_BatchPrint

		# Create a print job by adding to the list
		# First job
		li		s1, 1							# Row
		li		s2, 1							# Col
		li		s3, 26							# Fgcolor, valid colors are 
												# between 0 and 255
		li		s4, 164							# Bgcolor, valid colors are 
												# between 0 and 255
		# Char, printable chars are between 0x20 and 0x7e
		li		s5, 0x41						# 'A'
		sh		s1, 0(a0)						# Halfword row
		sh		s2, 2(a0)						# Halfword col
		li		t0, 4
		sb		t0, 4(a0)						# Print code 4 (both foreground
												# and background colors)
		sb		s3, 5(a0)						# Foreground color
		sb		s4, 6(a0)						# Background color
		# 7th byte is empty
		la		t0, Char1
		sb		s5, 0(t0)						# Update the Char string 
		sw		t0, 8(a0)						# Then provide it to the job

		addi 	a0, a0, 12						# Increment to add next job
		# Second job
		li		s1, 2							# Row
		li		s2, 2							# Col
		# When print code 1 is used for a job the Fg/Bgcolor should be ignored
		li		s3, 211							# Fgcolor
		li		s4, 217							# Bgcolor
		li		s5, 0x42						# 'B'
		sh		s1, 0(a0)
		sh		s2, 2(a0)
		li		t0, 1
		sb		t0, 4(a0)						# Print code 1; default settings
		sb		s3, 5(a0)		
		sb		s4, 6(a0)		
		# 7th byte is empty
		la		t0, Char2
		sb		s5, 0(t0)
		sw		t0, 8(a0)

		addi 	a0, a0, 12						# Increment to add next job
		# Third job
		li		s1, 3							# Row
		li		s2, 3							# Col
		li		s3, 157							# Fgcolor
		li		s4, 166							# Bgcolor
		li		s5, 0x43						# 'C'
		sh		s1, 0(a0)	
		sh		s2, 2(a0)
		li		t0, 1
		sb		t0, 4(a0)						# Print code 1
		sb		s3, 5(a0)
		sb		s4, 6(a0)
		# 7th byte is empty
		la		t0, Char3
		sb		s5, 0(t0)
		sw		t0, 8(a0)
		
		# Terminate the job list
		li		t0, 0xFFFF
		sh		t0, 12(a0)

		# a0 has been incremented a bunch; re-get the base of the PrintList
		la  	a0, PrintList
		jal		ra, GLIR_BatchPrint

		# Wait 2.5 seconds
		la		a7, _SLEEP
		lw		a7, 0(a7)
		li      a0, 2500
		ecall

		jal     ra, GLIR_End

		# Stack restore
		lw		ra, -4(s0)
		addi	sp, sp, 4
		lw		s0, 0(sp)
		addi	sp, sp, 4

		# Exit program
		la		a7, _EXIT
		lw		a7, 0(a7)
		ecall
