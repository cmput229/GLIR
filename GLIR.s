##############################################################################
#					START OF GLIR
##############################################################################
#Copyright 2017 Austin Crapo
#
#Permission is hereby granted, free of charge, to any person obtaining a copy 
#of this software and associated documentation files (the "Software"), to deal 
#in the Software without restriction, including without limitation the rights 
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
#copies of the Software, and to permit persons to whom the Software is 
#furnished to do so, subject to the following conditions:
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
######################
# Author: Austin Crapo
# Date: June 2017
# Version: 2017.8.24
# Conversion to RISC-V: Taylor Zowtuk
# Date: May 2019
#
#
# Does not support being run in a tab; Requires a separate window.
#
# This is a graphics library, supporting drawing pixels, 
# and some basic primitives
#
# @TODO suggestion was made to make a more general version of the updateCursor 
# function from Game of Life into the library
#
# @TODO more primatives?
#
# High Level documentation is provided in the index.html file.
# Per-method documentation is provided in the block comment 
# following each function definition
######################
.data
.align 2
#GLOBALS

# These tell GLIR how big the terminal is currently.
# The setter for these values is setDisplaySize.
# They are used to prevent off screen printing in the positive direction, the negative direction does not require this check as far as I know.
# Any negative value indicates that these variables have not been set.
TERM_ROWS:
	.word -1
TERM_COLS:
	.word -1


.data
.align 2
clearScreenCmd:
	.byte 0x1b, 0x5b, 0x32, 0x4a, 0x00
.text
clearScreen:
	########################################################################
	# Uses xfce4-terminal escape sequence to clear the screen
	#
	# Register Usage
	# Overwrites a7 and a0 during operation
	########################################################################
	li	a7, 4
	la	a0, clearScreenCmd
	ecall
	
	jalr		zero, ra, 0

.data
setCstring:
	.byte 0x1b, 0x5b, 0x30, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x48, 0x00
.text
setCursor:
	########################################################################
	#Moves the cursor to the specified location on the screen. Max location
	# is 3 digits for row number, and 3 digits for column number. (row, col)
	#
	# a0 = row number to move to
	# a1 = col number to move to
	#
	# Register Usage
	# Overwrites a0 during operation
	########################################################################
	# Stack Adjustments
	addi	sp, sp, -4		# Adjust the stack to save fp
	sw	s0, 0(sp)		# Save fp
	add	s0, zero, sp		# fp <= sp
	addi	sp, sp, -12		# Adjust stack to save variables
	sw	ra, -4(s0)		# Save ra
	#skip s1, this could be cleaned up
	sw	s2, -8(s0)		
	sw	s3, -12(s0)		
	
	#The control sequence we need is "\x1b[a1;a2H" where "\x1b"
	#is xfce4-terminal's method of passing the hex value for the ESC key.
	#This moves the cursor to the position, where we can then print.
	
	#The command is preset in memory, with triple zeros as placeholders
	#for the char coords. We translate the args to decimal chars and edit
	# the command string, then print
	
	mv		s2, a0	# s2 <- row
	mv		s3, a1	# s3 <- col
	
	# NOTE: we add 1 to each coordinate because we want (0,0) to be the top
	# left corner of the screen, but most terminals define (1,1) as top left
	#ROW
	addi	a0, s2, 1
	jal	intToChar
	la	t2, setCstring
	lb	t0, 0(a0)
	sb	t0, 5(t2)
	lb	t0, 1(a0)
	sb	t0, 4(t2)
	lb	t0, 2(a0)
	sb	t0, 3(t2)
	lb	t0, 3(a0)
	sb	t0, 2(t2)
	
	#COL
	addi	a0, s3, 1
	jal	intToChar
	la	t2, setCstring
	lb	t0, 0(a0)
	sb	t0, 10(t2)
	lb	t0, 1(a0)
	sb	t0, 9(t2)
	lb	t0, 2(a0)
	sb	t0, 8(t2)
	lb	t0, 3(a0)
	sb	t0, 7(t2)

	#move the cursor
	li	a7, 4
	la	a0, setCstring
	ecall
	
	#Stack Restore
	lw	ra, -4(s0)
	lw	s2, -8(s0)
	lw	s3, -12(s0)
	addi	sp, sp, 12
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	jalr		zero, ra, 0

.text
printString:
	########################################################################
	# Prints the specified null-terminated string started at the
	# specified location to the string and then continuing until
	# the end of the string, according to the printing preferences of your
	# terminal (standard terminals print left to right, top to bottom).
	# Is not screen aware, passing paramaters that would print a character
	# off screen have undefined effects on your terminal window. For most
	# terminals the cursor will wrap around to the next row and continue
	# printing. If you have hit the bottom of the terminal window,
	# the xfce4-terminal window default behavior is to scroll the window 
	# down. This can offset your screen without you knowing and is 
	# dangerous since it is undetectable. The most likely useage of this
	# function is to print characters. The reason that it is a string it
	# prints is to support the printing of escape character sequences
	# around the character so that fancy effects are supported. Some other
	# terminals may treat the boundaries of the terminal window different,
	# for example some may not wrap or scroll. It is up to the user to
	# test their terminal window for its default behaviour.
	# Is built for xfce4-terminal.
	# Position (0, 0) is defined as the top left of the terminal.
	#
	# Uses TERM_ROW and TERM_COL to determine if the target tile
	# is outside of the boundary of the terminal screen, in which
	# case it does nothing.
	#
	# a0 = address of string to print
	# a1 = integer value 0-999, row to print to (y position)
	# a2 = integer value 0-999, col to print to (x position)
	#
	# Register Usage
	# t0 - t3, t4-t2 = temp storage of bytes and values
	########################################################################
	# Stack Adjustments
	addi	sp, sp, -4		# Adjust the stack to save fp
	sw	s0, 0(sp)		# Save fp
	add	s0, zero, sp		# fp <= sp
	addi	sp, sp, -8		# Adjust stack to save variables
	sw	ra, -4(s0)		# Save ra
	sw	s1, -8(s0)		# Save s1
	
	
	#terminal automatically rejects negative values, not certain why, but not checking for it either
	la	t0, TERM_ROWS	#check if past boundary
	lw	t0, 0(t0)
	slt	t0, t0, a1	#if TERM_ROWS < print row
	
	la	t1, TERM_COLS
	lw	t1, 0(t1)
	slt	t1, t1, a2	#or if TERM_COLS < print col
	
	or	t0, t0, t1
	bne	t0, zero, pSend	#do nothing
	
	#else
	mv		s1, a0
	
	mv		a0, a1
	mv		a1, a2
	jal	setCursor
	
	#print the char
	li	a7, 4
	mv		a0, s1
	ecall
	
	pSend:
	
	#Stack Restore
	lw	ra, -4(s0)
	lw	s1, -8(s0)
	addi	sp, sp, 8
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	jalr		zero, ra, 0

batchPrint:
	########################################################################
	# A batch is a list of print jobs. The print jobs are in the format
	# below, and will be printed from start to finish. This function does
	# some basic optimization of color printing (eg. color changing codes
	# are not printed if they do not need to be), but if the list constantly
	# changes color and is not sorted by color, you may notice flickering.
	#
	# List format:
	# Each element contains the following words in order together
	# half words unsigned:[row] [col]
	# bytes unsigned:     [printing code] [foreground color] [background color] 
	#			    [empty] 
	# word: [address of string to print here]
	# total = 3 words
	#
	# The batch must be ended with the halfword sentinel: 0xFFFF
	#
	# Valid Printing codes:
	# 0 = skip printing
	# 1 = standard print, default terminal settings
	# 2 = print using foreground color
	# 3 = print using background color
	# 4 = print using all colors
	# 
	# xfce4-terminal supports the 256 color lookup table assignment, 
	# see the index for a list of color codes.
	#
	# The payload of each job in the list is the address of a string. 
	# Escape sequences for prettier or bolded printing supported by your
	# terminal can be included in the strings. However, including such 
	# escape sequences can effect not just this print, but also future 
	# prints for other GLIR methods.
	#
	# a0 = address of batch list to print
	#
	# Register Usage
	# s1 = scanner for the list
	# s2 = store row info
	# s3 = store column info
	# s4 = store print code info
	# s7 = temporary color info storage accross calls
	# s8 = temporary color info storage accross calls
	########################################################################
	# Stack Adjustments
	addi	sp, sp, -4		
	sw	s0, 0(sp)		
	add	s0, zero, sp		
	addi	sp, sp, -28		
	sw	ra, -4(s0)		
	sw	s1, -8(s0)		
	sw	s2, -12(s0)
	sw	s3, -16(s0)
	sw	s4, -20(s0)
	sw	s7, -24(s0)
	sw	s8, -28(s0)
	
	#store the last known colors, to avoid un-needed printing
	li	s7, -1		#lastFG = -1
	li	s8, -1		#lastBG = -1
	
	
	mv		s1, a0		#scanner = list
	#for item in list
	bPscan:
		#extract row and col to vars
		lhu	s2, 0(s1)		#row
		lhu	s3, 2(s1)		#col
		
		#if row is 0xFFFF: break
		li	t0, 0xFFFF
		beq	s2, t0, bPsend
		
		#extract printing code
		lbu	s4, 4(s1)		#print code
		
		#skip if printing code is 0
		beq	s4, zero, bPscont
		
		#print to match printing code if needed
		#if standard print, make sure to have clear color
		li	t0, 1		#if pcode == 1
		beq	s4, t0, bPscCend
		bPsclearColor:
			li	t0, -1	
			bne	s7, t0, bPscCreset	#if lastFG != -1 
			bne	s8, t0, bPscCreset	#OR lastBG != -1
			jal	zero, bPscCend
			bPscCreset:
				jal	restoreSettings
				li	s7, -1
				li	s8, -1

		bPscCend:		
		#change foreground color if needed
		li	t0, 2		#if pcode == 2 or pcode == 4
		beq	s4, t0, bPFGColor
		li	t0, 4
		beq	s4, t0, bPFGColor
		jal		zero, bPFCend
		bPFGColor:
			lbu	t0, 5(s1)
			beq	t0, s7, bPFCend	#if color != lastFG
				mv		s7, t0	#store to lastFG
				mv		a0, t0	#set as FG color
				li	a1, 1
				jal	setColor

		bPFCend:		
		#change background color if needed
		li	t0, 3		#if pcode == 3 or pcode == 4
		beq	s4, t0, bPBGColor
		li	t0, 4
		beq	s4, t0, bPBGColor
		jal		zero, bPBCend
		bPBGColor:
			lbu	t0, 6(s1)
			beq	t0, s8, bPBCend	#if color != lastBG
				mv		s8, t0	#store to lastBG
				mv		a0, t0	#set as BG color
				li	a1, 0
				jal	setColor

		bPBCend:		
		#then print string to (row, col)
		lw	a0, 8(s1)
		mv		a1, s2
		mv		a2, s3
		jal	printString
		
		bPscont:
		addi	s1, s1, 12
		jal		zero, bPscan

	bPsend:	
	#Stack Restore
	lw	ra, -4(s0)
	lw	s1, -8(s0)
	lw	s2, -12(s0)
	lw	s3, -16(s0)
	lw	s4, -20(s0)
	lw	s7, -24(s0)
	lw	s8, -28(s0)
	addi	sp, sp, 28
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	
	jalr		zero, ra, 0
	
.data
.align 2
intToCharSpace:
	.space	4	#storing 4 bytes, potentially up to 9999
.text
intToChar:
	########################################################################
	# Given an int x where 0 <= x <= 9999, converts the integer into 4 bytes,
	# which are the character representation of the int. If the integer
	# requires larger than 4 chars to represent, only the 4 least 
	# significant digits will be converted.
	#
	# a0 = integer to convert
	#
	# Return Values:
	# a0 = address of the bytes, in the following order, 1's, 10's, 100's, 1000's
	#
	# Register Usage
	# t0-t2 = temporary value storage
	########################################################################
	addi		sp, sp, -4
	sw			s0, 0(sp)
	
	li	t0, 0x30	#'0' in ascii, we add according to the number
	#separate the three digits of the passed in number
	#1's = x%10
	#10's = x%100 - x%10
	#100's = x - x$100
	la	s0, intToCharSpace
	
	#ones
	li	t1, 10
	rem		t4, a0, t1		#x%10			
	add	t1, t0, t4	#byte = 0x30 + x%10
	sb	t1, 0(s0)
	
	#tens
	li	t1, 100	
	rem 	t5, a0, t1		#x%100	
	sub	t1, t5, t4	#byte = 0x30 + (x%100 - x%10)/10
	li	t3, 10
	div 	t1, t1, t3
	add	t1, t0, t1	
	sb	t1, 1(s0)
	
	#100s
	li	t1, 1000
	rem		t2, a0, t1		#x%1000			
	sub	t1, t2, t5	#byte = 0x30 + (x%1000 - x%100)/100
	li	t3, 100
	div		t1, t1, t3
	add	t1, t0, t1	
	sb	t1, 2(s0)
	
	#1000s
	li	t1, 10000
	rem		t6, a0, t1		#x%10000		
	sub	t1, t6, t2	#byte = 0x30 + (x%10000 - x%1000)/1000
	li	t3, 1000
	div		t1, t1, t3
	add	t1, t0, t1	
	sb	t1, 3(s0)

	mv			a0, s0

	lw			s0, 0(sp)
	addi		sp, sp, 4
	
	jalr		zero, ra, 0
	
.data
.align 2
setFGorBG:
	.byte 0x1b, 0x5b, 0x34, 0x38, 0x3b, 0x35, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x6d, 0x00
.text
setColor:
	########################################################################
	# Prints the escape sequence that sets the color of the text to the
	# color specified.
	# 
	# xfce4-terminal supports the 256 color lookup table assignment, 
	# see the index for a list of color codes.
	#
	#
	# a0 = color code (see index)
	# a1 = 0 if setting background, 1 if setting foreground
	#
	# Register Usage
	# s1 = temporary arguement storage accross calls
	# s2 = temporary arguement storage accross calls
	########################################################################
	# Stack Adjustments
	addi	sp, sp, -4		
	sw	s0, 0(sp)		
	add	s0, zero, sp		
	addi	sp, sp, -12		
	sw	ra, -4(s0)		
	sw	s1, -8(s0)		
	sw	s2, -12(s0)		
	
	mv		s1, a0
	mv		s2, a1
	
	jal	intToChar		#get the digits of the color code to print
	mv		t2, a0

	mv		a0, s1
	mv		a1, s2
	
	la	t0, setFGorBG
	lb	t1, 0(t2)		#alter the string to print, max 3 digits ignore 1000's
	sb	t1, 10(t0)
	lb	t1, 1(t2)
	sb	t1, 9(t0)
	lb	t1, 2(t2)
	sb	t1, 8(t0)
	
	beq	a1, zero, sCsetBG	#set the code to print FG or BG
		#setting FG
		li	t1, 0x33
		jal		zero, sCset
	sCsetBG:
		li	t1, 0x34
	sCset:
		sb	t1, 2(t0)
	
	li	a7, 4
	mv		a0, t0
	ecall
		
	#Stack Restore
	lw	ra, -4(s0)
	lw	s1, -8(s0)
	lw	s2, -12(s0)
	addi	sp, sp, 12
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	jalr		zero, ra, 0

.data
.align 2
rSstring:
	.byte 0x1b, 0x5b, 0x30, 0x6d, 0x00
.text
restoreSettings:
	########################################################################
	# Prints the escape sequence that restores all default color settings to
	# the terminal
	#
	# Register Usage
	# NA
	########################################################################
	la	a0, rSstring
	li	a7, 4
	ecall
	
	jalr		zero, ra, 0

.text
startGLIR:
	########################################################################
	# Sets up the display in order to provide
	# a stable environment. Call endGLIR when program is finished to return
	# to as many defaults and stable settings as possible.
	# Unfortunately screen size changes are not code-reversible, so endGLIR
	# will only return the screen to the hardcoded value of 24x80.
	#
	#
	# a0 = number of rows to set the screen to
	# a1 = number of cols to set the screen to
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	sp, sp, -4		
	sw	s0, 0(sp)		
	add	s0, zero, sp		
	addi	sp, sp, -4		
	sw	ra, -4(s0)
	
	jal	setDisplaySize
	jal	restoreSettings
	jal	clearScreen
	jal	hideCursor
	
	#Stack Restore
	lw	ra, -4(s0)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	jalr		zero, ra, 0
	

.text
endGLIR:
	########################################################################
	# Reverts to default as many settings as it can, meant to end a program
	# that was started with startGLIR. The default terminal window in
	# xfce4-terminal is 24x80, so this is the assumed default we want to
	# return to.
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	sp, sp, -4		
	sw	s0, 0(sp)		
	add	s0, zero, sp		
	addi	sp, sp, -4		
	sw	ra, -4(s0)
	
	li	a0, 24
	li	a1, 80
	jal	setDisplaySize
	jal	restoreSettings
	
	jal	clearScreen
	
	jal	showCursor
	li	a0, 0
	li	a1, 0
	jal	setCursor
	
	#Stack Restore
	lw	ra, -4(s0)
	addi	sp, sp, 4
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	jalr		zero, ra, 0
	
.data
.align 2
hCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c, 0x00
.text
hideCursor:
	########################################################################
	# Prints the escape sequence that hides the cursor
	#
	# Register Usage
	# NA
	########################################################################
	la	a0, hCstring
	li	a7, 4
	ecall
	
	jalr		zero, ra, 0

.data
.align 2
sCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x68, 0x00
.text
showCursor:
	########################################################################
	#Prints the escape sequence that restores the cursor visibility
	#
	# Register Usage
	# NA
	########################################################################
	la	a0, sCstring
	li	a7, 4
	ecall
	
	jalr		zero, ra, 0

.data
.align 2
sDSstring:
	.byte 0x1b, 0x5b, 0x38, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x74 0x00
.text
setDisplaySize:
	########################################################################
	# Prints the escape sequence that changes the size of the display to 
	# match the parameters passed. The number of rows and cols are 
	# ints x and y s.t.:
	# 0<=x,y<=999
	#
	# a0 = number of rows
	# a1 = number of columns
	#
	# Register Usage
	# s1 = temporary a0 storage
	# s2 = temporary a1 storage
	########################################################################
	# Stack Adjustments
	addi	sp, sp, -4		
	sw	s0, 0(sp)		
	add	s0, zero, sp		
	addi	sp, sp, -12		
	sw	ra, -4(s0)		
	sw	s1, -8(s0)		
	sw	s2, -12(s0)
	
	slt	t0, a0, zero		#if either argument is negative, do nothing
	slt	t1, a1, zero
	or	t0, t0, t1
	bne	t0, zero, sDSend
	
	#else	
	mv		s1, a0
	mv		s2, a1
	
	la	t0, TERM_ROWS		#set the TERM globals
	sw	a0, 0(t0)
	la	t0, TERM_COLS
	sw	a1, 0(t0)
	
	#rows
	jal	intToChar		#get the digits of the params to print
	
	la	t0, sDSstring
	lb	t1, 0(a0)		#alter the string to print
	sb	t1, 7(t0)
	lb	t1, 1(a0)
	sb	t1, 6(t0)
	lb	t1, 2(a0)
	sb	t1, 5(t0)
	lb	t1, 3(a0)
	sb	t1, 4(t0)
	
	#cols
	mv	a0, s2
	jal	intToChar		#get the digits of the params to print
	
	la	t0, sDSstring
	lb	t1, 0(a0)		#alter the string to print
	sb	t1, 12(t0)
	lb	t1, 1(a0)
	sb	t1, 11(t0)
	lb	t1, 2(a0)
	sb	t1, 10(t0)
	lb	t1, 3(a0)
	sb	t1, 9(t0)
	
	li	a7, 4
	mv	a0, t0
	ecall
	
	sDSend:	
	#Stack Restore
	lw	ra, -4(s0)
	lw	s1, -8(s0)
	lw	s2, -12(s0)
	addi	sp, sp, 12
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	jalr		zero, ra, 0

.data
cDchar:
	.asciz "#"
.text
colorDemo:
	########################################################################
	# Attempts to print the 16-256 color gamut of your terminal.
	# Requires that the terminal size be at least 30 rows and 6 cols big.
	# Currently skips the first 15 colors because it's prettier :P
	#
	# RISC-V conversion notes: Had to temporarily replace the unicode full block char as used in MIPS version because RARS doesn't appear to support unicode chars or extended ascii chars
	#
	# Register Usage
	# s1 = Holds the initial offset - we start at color 16 because the first 16 (0-15) don't align very well in this demo. Change it to 0 if you want to FULL color gamut
	# s2 = Holds the current column being printed to.
	# s3 = Holds the current row being printed to.
	########################################################################
	addi	sp, sp, -4		
	sw	s0, 0(sp)		
	add	s0, zero, sp		
	addi	sp, sp, -16		
	sw    ra, -4(s0)		
	sw	s1, -8(s0)		
	sw	s2, -12(s0)
	sw	s3, -16(s0)
	
	jal	clearScreen
	#print the color space, skip the first 15 because prettier
	li	s1, 16	#start at 16 so that we dont get offset weirdly by the first 15 colors
	li	s2, 1
	li	s3, 1
	mLoop:		#while True
		mv	a0, s1
		li	a1, 1
		jal	setColor
		la	a0, cDchar
		mv	a1, s3
		mv	a2, s2
		jal	printString
		addi	s2, s2, 1
		li	t0, 7
		bne	s2, t0, mLcont
			li	s2, 1
			addi	s3, s3, 1
		mLcont:
		addi	s1, s1, 1
		li	t0, 256
		beq	s1, t0, mLend
		j	mLoop
	mLend:

	lw	ra, -4(s0)
	lw	s1, -8(s0)
	lw	s2, -12(s0)
	lw	s3, -16(s0)
	addi	sp, sp, 16
	lw	s0, 0(sp)
	addi	sp, sp, 4

	jalr		zero, ra, 0
	
.data
pClist:
	.align 2
	.space 100	#9*3*4 words, only prints 8 pixels at a time
pCchar:
	.asciz " " #character to print with
.text
printCircle:
	############################
	# Prints a circle onto the screen using the midpoint circle algorithm
	# and the character pCchar.
	#
	# a0 = row to print at 
	# a1 = col to print at
	# a2 = radius of the circle to print
	# a3 = byte code [printing code][fg color][bg color][empty] determining
	#		how to print the circle pixels, compatible with printList
	############################
	# Stack Adjustments
	addi	sp, sp, -4		
	sw	s0, 0(sp)		
	add	s0, zero, sp		
	addi	sp, sp, -36		
	sw    ra, -4(s0)		
	sw	s1, -8(s0)		
	sw	s2, -12(s0)
	sw	s3, -16(s0)
	sw	s4, -20(s0)
	sw	s5, -24(s0)
	sw	s6, -28(s0)
	sw	s7, -32(s0)
	sw	s8, -36(s0)
	
	mv	s1, a2	#row = radius
	li	s2, 0	#col = 0
	li	s3, 0	#err = 0
	la	s4, pCchar
	mv	s5, a0	#store the args
	mv	s6, a1
	mv	s7, a3
	
	pCloop:	#while (col <= row)
	addi	t1, s2, -1
	slt	t0, t1, s1
	beq	t0, zero, pClend
		#draw a pixel to each octant of the screen
		la	t0, pClist
		add	t1, s5, s1
		add	t2, s6, s2
		sh	t1, 0(t0)		#pixel location
		sh	t2, 2(t0)
		sw	s7, 4(t0)		#pixel printing code
		sw	s4, 8(t0)
		addi	t0, t0, 12
		add	t1, s5, s2
		add	t2, s6, s1
		sh	t1, 0(t0)
		sh	t2, 2(t0)
		sw	s7, 4(t0)
		sw	s4, 8(t0)
		addi	t0, t0, 12
		sub	t1, s5, s2
		add	t2, s6, s1
		sh	t1, 0(t0)
		sh	t2, 2(t0)
		sw	s7, 4(t0)
		sw	s4, 8(t0)
		addi	t0, t0, 12
		sub	t1, s5, s1
		add	t2, s6, s2
		sh	t1, 0(t0)
		sh	t2, 2(t0)
		sw	s7, 4(t0)
		sw	s4, 8(t0)
		addi	t0, t0, 12
		sub	t1, s5, s1
		sub	t2, s6, s2
		sh	t1, 0(t0)
		sh	t2, 2(t0)
		sw	s7, 4(t0)
		sw	s4, 8(t0)
		addi	t0, t0, 12
		sub	t1, s5, s2
		sub	t2, s6, s1
		sh	t1, 0(t0)
		sh	t2, 2(t0)
		sw	s7, 4(t0)
		sw	s4, 8(t0)
		addi	t0, t0, 12
		add	t1, s5, s2
		sub	t2, s6, s1
		sh	t1, 0(t0)
		sh	t2, 2(t0)
		sw	s7, 4(t0)
		sw	s4, 8(t0)
		addi	t0, t0, 12
		add	t1, s5, s1
		sub	t2, s6, s2
		sh	t1, 0(t0)
		sh	t2, 2(t0)
		sw	s7, 4(t0)
		sw	s4, 8(t0)
		addi	t0, t0, 12
		li	t1, 0xFFFF
		sh	t1, 0(t0)
		la	a0, pClist
		jal	batchPrint
		
		#li	a0, 1000
		#jal	sleep
		
		addi	s2, s2, 1		#y += 1
		bgtz	s3, pClmoveRow	#if(err <= 0)
			add	s3, s3, s2	#err += 2y+1
			add	s3, s3, s2
			addi	s3, s3, 1
			jal	zero, pClcont
		pClmoveRow:			#else
			addi	s1, s1, -1	#x -= 1
			sub	t0, s2, s1	#err += 2(y-x) + 1
			add	s3, s3, t0
			add	s3, s3, t0
			addi	s3, s3, 1
		pClcont:
		jal		zero, pCloop
	pClend:

	#Stack Restore
	lw	ra, -4(s0)
	lw	s1, -8(s0)
	lw	s2, -12(s0)
	lw	s3, -16(s0)
	lw	s4, -20(s0)
	lw	s5, -24(s0)
	lw	s6, -28(s0)
	lw	s7, -32(s0)
	lw	s8, -36(s0)
	addi	sp, sp, 36
	lw	s0, 0(sp)
	addi	sp, sp, 4
	
	jalr		zero, ra, 0
##############################################################################
#					END OF GLIR
##############################################################################