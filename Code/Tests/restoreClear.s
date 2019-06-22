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
# A test for the restoreSettings and clearScreen functionalities of the 
# library. Prints three lines of unicode block characters with different 
# foreground colors seperated by 3 lines of text on black backgrounds and 
# different foreground colors. Resets terminal color settings using 
# restoreSettings and clears the screen using clearScreen. With the restored
# color settings, prints one final line of text.
# Use the runRestoreClear shell script to run this test.
#-------------------------------------------------------------------------------

.data
messySquares:	.asciz "█ █ █████████████████ █ █"
.align 2
string1:        .asciz "There is a mess on the screen..."
.align 2
string2:        .asciz "We should clean it up..."
.align 3
string3:        .asciz "Cleaning up now please wait..."
.align 2
string4:		.asciz "Reverted settings and cleared screen."
.text
main:
		# Stack Adjustments
		addi	sp, sp, -4						# Adjust the stack to save fp
		sw		s0, 0(sp)						# Save fp
		add		s0, zero, sp					# fp <= sp
		addi	sp, sp, -4  					# Adjust stack to save variables
		sw		ra, -4(s0)						# Save ra
		
		# Pass the size of terminal
		li		a0, 6							# Number of rows
		li		a1, 39							# Number of cols
		jal		startGLIR

		# Set the colors of the foreground for the messy line of text
		li		a0, 154							# color; GreenYellow
		li		a1, 1							# foreground
		jal		setColor

		# Print the messy string
		la		a0, messySquares
		li		a1, 0							# First row
		li		a2, 1							# Second col
		jal		printString
		
		# Set the colors of the background and foreground for first line of
		# printing
		li		a0, 0							# color; Black
		li		a1, 0							# background
		jal		setColor
		li		a0, 159							# color; PaleTurquoise1
		li		a1, 1							# foreground
		jal		setColor

		# Print the first string
		la		a0, string1
		li		a1, 1							# Second row
		li		a2, 1							# Second col
		jal		printString

		# Set the colors of the foreground for the messy line of text
		li		a0, 212							# color; Orchid2
		li		a1, 1							# foreground
		jal		setColor

		# Print the messy string
		la		a0, messySquares
		li		a1, 2							# Third row
		li		a2, 1							# Second col
		jal		printString
		
		# Set the colors of the background and foreground for second line of
		# printing
		li		a0, 0							# color; Black
		li		a1, 0							# background
		jal		setColor
		li		a0, 208							# color; DarkOrange
		li		a1, 1							# foreground
		jal		setColor

		# Print the second string
		la		a0, string2
		li		a1, 3							# Fourth row
		li		a2, 1							# Second col
		jal		printString

		# Set the colors of the foreground for the messy line of text
		li		a0, 33							# color; DodgerBlue1
		li		a1, 1							# foreground
		jal		setColor

		# Print the messy string
		la		a0, messySquares
		li		a1, 4							# Fifth row
		li		a2, 1							# Second col
		jal		printString

		# Set the colors of the background and foreground for third line of
		# printing
		li		a0, 0							# color; Black
		li		a1, 0							# background
		jal		setColor
		li		a0, 9							# color; Red
		li		a1, 1							# foreground
		jal		setColor

		# Print the third string
		la		a0, string3
		li		a1, 5							# Sixth row
		li		a2, 1							# Second col
		jal		printString

		# Wait 5 seconds
		li		a0, 5000
		jal		sleep

		# Restore default terminal color settings
		jal		restoreSettings
		# Clear the screen
		jal		clearScreen
		
		# Print final string
		la		a0, string4
		li		a1, 2							# Third row
		li		a2, 1							# Second col
		jal		printString

		# Wait 2 seconds
		li		a0, 2000
		jal		sleep

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