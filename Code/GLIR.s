
#-------------------------------------------------------------------------------
#                                  START OF GLIR
#-------------------------------------------------------------------------------
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
# Version: 2019.6.18
#-------------------------------------------------------------------------------
# This is a graphics library, supporting drawing pixels, and some basic
# primitives.
#
# High Level documentation is provided in the index.html file.
# Per-method documentation is provided in the block comment following each
# function definition.
#
# Does not support being run in a terminal tab; requires a separate window.
#
# GLIR was converted from the original GLIM which can be found here:
# https://github.com/AustinGrey/GLIM
#
# Intended for use with RARS RISC-V simulator; though I have limited use of
# pseudo instructions and made use of loading syscall service numbers from
# labels for ease of protability.
# https://github.com/TheThirdOne/rars
#-------------------------------------------------------------------------------

.data
.align 2
# GLOBALS

# Here we store the RARS syscall service numbers which are needed.
# Before a syscall we load from the label.
# They are saved and loaded in this way to promote code portability.
_PRINT_STRING:  .word 4

# These tell GLIR how big the terminal is currently.
# The setter for these values is _GLIR_SetDisplaySize.
# They are used to prevent off screen printing in the positive direction; the
# negative direction does not require this check as far as I know.
# Any negative value indicates that these variables have not been set.
_TERM_ROWS:     .word -1
_TERM_COLS:     .word -1

.align 2
ClearScreen_String: .byte 0x1b, 0x5b, 0x32, 0x4a, 0x00
.text
jal             zero, main                      # Don't enter lib unless asked
#-------------------------------------------------------------------------------
# ClearScreen
#
# Uses xfce4-terminal escape sequence to clear the screen.
#-------------------------------------------------------------------------------
GLIR_ClearScreen:
        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        la      a0, ClearScreen_String
        ecall

        jalr    zero, ra, 0

.data
.align 2
SetCursor_String:   .byte 0x1b, 0x5b, 0x30, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30,
                    0x30, 0x30, 0x48, 0x00
.text
#-------------------------------------------------------------------------------
# SetCursor
# Args:     a0 = row number to move to
#           a1 = col number to move to
#
# Moves the cursor to the specified location on the screen. Max location is 3
# digits for row number, and 3 digits for column number. (Row, Col).
#
# The control sequence we need is "\x1b[a1;a2H" where "\x1b"
# is xfce4-terminal's method of passing the hex value for the ESC key.
# This moves the cursor to the position, where we can then print.
#
# The command is preset in memory, with triple zeros as placeholders
# for the char coords. We translate the args to decimal chars and edit
# the command string, then print.
#-------------------------------------------------------------------------------
_GLIR_SetCursor:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -12                     # Adjust stack to save variables
        sw      ra, -4(s0)                      # Save ra
        sw      s1, -8(s0)
        sw      s2, -12(s0)

        addi    s1, a0, 0                       # s1 <- Row
        addi    s2, a1, 0                       # s2 <- Col

        # ROW
        # We add 1 to each coordinate because we want (0,0) to be the top
        # left corner of the screen, but most terminals define (1,1) as top left
        addi    a0, s1, 1
        jal     ra, _GLIR_IntToChar
        la      t2, SetCursor_String
        lb      t0, 0(a0)
        sb      t0, 5(t2)
        lb      t0, 1(a0)
        sb      t0, 4(t2)
        lb      t0, 2(a0)
        sb      t0, 3(t2)
        lb      t0, 3(a0)
        sb      t0, 2(t2)

        # COL
        addi    a0, s2, 1
        jal     ra, _GLIR_IntToChar
        la      t2, SetCursor_String
        lb      t0, 0(a0)
        sb      t0, 10(t2)
        lb      t0, 1(a0)
        sb      t0, 9(t2)
        lb      t0, 2(a0)
        sb      t0, 8(t2)
        lb      t0, 3(a0)
        sb      t0, 7(t2)

        # Move the cursor
        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        la      a0, SetCursor_String
        ecall

        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        lw      s2, -12(s0)
        addi    sp, sp, 12
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
# PrintString
# Args:     a0 = address of string to print
#           a1 = integer value 0-999, row to print to (y position)
#           a2 = integer value 0-999, col to print to (x position)
#
# Prints the specified null-terminated string according to the printing
# preferences of your terminal (standard terminals print left to right, top to
# bottom). Prints starting at the specified location of the string and continues
# until the end of the string. Is not screen aware; passing paramaters that
# would print a character off screen has undefined effects on your terminal
# window. For most terminals the cursor will wrap around to the next row and
# continue printing. If you have hit the bottom of the terminal window, the
# xfce4-terminal window default behavior is to scroll the window down. This can
# offset your screen without you knowing and is dangerous since it is
# undetectable. The most likely useage of this function is to print characters.
# The reason that it is a string that is printed is to support the printing of
# escape character sequences around the character so that fancy effects are
# supported. Some other terminals may treat the boundaries of the terminal
# window different. For example, some may not wrap or scroll. It is up to the
# user to test their terminal window for its default behaviour. Built for
# xfce4-terminal. Position (0, 0) is defined as the top left of the terminal.
#
# Uses TERM_ROW and TERM_COL to determine if the target tile is outside of the
# boundary of the terminal screen, in which case it does nothing.
#-------------------------------------------------------------------------------
GLIR_PrintString:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -8                      # Adjust stack to save variables
        sw      ra, -4(s0)                      # Save ra
        sw      s1, -8(s0)


        # Terminal automatically rejects negative values, not certain why, but
        # not checking for it either
        la      t0, _TERM_ROWS                  # Check if past boundary
        lw      t0, 0(t0)
        slt     t0, t0, a1                      # If TERM_ROWS < print row

        la      t1, _TERM_COLS
        lw      t1, 0(t1)
        slt     t1, t1, a2                      # or if TERM_COLS < print col

        or      t0, t0, t1
        bne     t0, zero, PrintString_End       # then do nothing

        # Else
        addi    s1, a0, 0
        addi    a0, a1, 0
        addi    a1, a2, 0
        jal     ra, _GLIR_SetCursor

        # Print the char
        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        addi    a0, s1, 0
        ecall

        PrintString_End:
        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        addi    sp, sp, 8
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
# BatchPrint
# Args:     a0 = address of batch list to print
# Reg. Use: s1 = scanner for the list
#           s2 = store row info
#           s3 = store column info
#           s4 = store print code info
#           s7 = temporary color info storage accross calls
#           s8 = temporary color info storage accross calls
#
# A batch is a list of print jobs. The print jobs are in the format below, and
# will be printed from start to finish. This function does some basic
# optimization of color printing (eg. color changing codes are not printed if
# they do not need to be), but if the list constantly changes color and is not
# sorted by color, you may notice flickering.
#
# List format (each job contains the following words in order together):
# half words unsigned:    [row] [col]
# bytes unsigned:         [printing code] [foreground color] [background color]
#                         [empty]
# word:                   [address of string to print]
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
# xfce4-terminal supports the 256 color lookup table assignment; see the index
# for a list of color codes.
#
# The payload of each job in the list is the address of a string.
# Escape sequences for prettier or bolded printing supported by your terminal
# can be included in the strings. However, including such escape sequences can
# effect not just this print, but also future prints for other GLIR methods.
#-------------------------------------------------------------------------------
GLIR_BatchPrint:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -28                     # Adjust stack to save variables
        sw      ra, -4(s0)
        sw      s1, -8(s0)
        sw      s2, -12(s0)
        sw      s3, -16(s0)
        sw      s4, -20(s0)
        sw      s7, -24(s0)
        sw      s8, -28(s0)

        # Store the last known colors, to avoid un-needed printing
        li      s7, -1                          # LastFg = -1
        li      s8, -1                          # LastBg = -1


        addi    s1, a0, 0                       # Scanner = start of batch
        # For item in list
        BatchPrint_Scan:
                # Extract row and col to vars
                lhu     s2, 0(s1)               # Row
                lhu     s3, 2(s1)               # Col
                # If Row is 0xFFFF: break
                li      t0, 0xFFFF
                beq     s2, t0, BatchPrint_ScanEnd

                # Extract printing code
                lbu     s4, 4(s1)               # Print code (PCode)
                # Skip if printing code is 0
                beq     s4, zero, BatchPrint_ScanCont

                # Print to match printing code if needed
                # If standard print, make sure to clear the current color
                # settings
                li      t0, 1                   # If PCode != 1
                bne     s4, t0, BatchPrint_ScanClearEnd
                # Check if we need to reset the color
                # If Fg and Bg are -1 then current settings are terminal default
                li      t0, -1
                bne     s7, t0, BatchPrint_ScanClearColor   # If LastFg != -1
                bne     s8, t0, BatchPrint_ScanClearColor   # OR LastBg != -1
                jal     zero, BatchPrint_ScanClearEnd
                BatchPrint_ScanClearColor:
                jal     ra, GLIR_RestoreSettings
                li      s7, -1
                li      s8, -1

                BatchPrint_ScanClearEnd:
                # Change foreground color if needed
                li      t0, 2                   # If PCode == 2 or PCode == 4
                beq     s4, t0, BatchPrint_FgColor
                li      t0, 4
                beq     s4, t0, BatchPrint_FgColor
                jal     zero, BatchPrint_FgColorEnd
                BatchPrint_FgColor:
                lbu     t0, 5(s1)
                beq     t0, s7, BatchPrint_FgColorEnd   # If Color != LastFg
                addi    s7, t0, 0               # Store to LastFg
                addi    a0, t0, 0               # Set as foreground color
                li      a1, 1
                jal     ra, GLIR_SetColor

                BatchPrint_FgColorEnd:
                # Change background color if needed
                li      t0, 3                   # If PCode == 3 or PCode == 4
                beq     s4, t0, BatchPrint_BgColor
                li      t0, 4
                beq     s4, t0, BatchPrint_BgColor
                jal     zero, BatchPrint_BgColorEnd
                BatchPrint_BgColor:
                lbu     t0, 6(s1)
                beq     t0, s8, BatchPrint_BgColorEnd   # If Color != LastBg
                addi    s8, t0, 0               # Store to LastBg
                addi    a0, t0, 0               # Set as background color
                li      a1, 0
                jal     ra, GLIR_SetColor

                BatchPrint_BgColorEnd:
                # Then print string to (Row, Col)
                lw      a0, 8(s1)
                addi    a1, s2, 0
                addi    a2, s3, 0
                jal     ra, GLIR_PrintString

                BatchPrint_ScanCont:
                addi    s1, s1, 12
                jal     zero, BatchPrint_Scan

        BatchPrint_ScanEnd:
        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        lw      s2, -12(s0)
        lw      s3, -16(s0)
        lw      s4, -20(s0)
        lw      s7, -24(s0)
        lw      s8, -28(s0)
        addi    sp, sp, 28
        lw      s0, 0(sp)
        addi    sp, sp, 4


        jalr    zero, ra, 0

.data
.align 2
# Storing 4 bytes, potentially up to 9999
IntToChar_Space:    .space 4
.text
#-------------------------------------------------------------------------------
# IntToChar
# Args:     a0 = integer to convert
# Returns:  a0 = address of the bytes, in the following order, 1's, 10's, 100's,
#                1000's
#
# Given an int x, where 0 <= x <= 9999, converts the integer into 4 bytes; which
# are the character representation of the int. If the integer requires larger
# than 4 chars to represent, only the 4 least significant digits will be
# converted.
#-------------------------------------------------------------------------------
_GLIR_IntToChar:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust stack to save variables
        sw      s0, 0(sp)

        li      t0, 0x30                        # '0' in ascii; we add to offset
                                                # into the ascii table
        # Separate the three digits of the passed in number
        # 1's = x%10
        # 10's = x%100 - x%10
        # 100's = x - x%100
        la      s0, IntToChar_Space

        # Ones
        li      t1, 10
        rem     t4, a0, t1                      # x%10
        # Byte = 0x30 + x%10
        add     t1, t0, t4
        sb      t1, 0(s0)

        # Tens
        li      t1, 100
        rem     t5, a0, t1                      # x%100
        # Byte = 0x30 + (x%100 - x%10)/10
        sub     t1, t5, t4
        li      t3, 10
        div     t1, t1, t3
        add     t1, t0, t1
        sb      t1, 1(s0)

        # Hundreds
        li      t1, 1000
        rem     t2, a0, t1                      # x%1000
        # Byte = 0x30 + (x%1000 - x%100)/100
        sub     t1, t2, t5
        li      t3, 100
        div     t1, t1, t3
        add     t1, t0, t1
        sb      t1, 2(s0)

        # Thousands
        li      t1, 10000
        rem     t6, a0, t1                      # x%10000
        # Byte = 0x30 + (x%10000 - x%1000)/1000
        sub     t1, t6, t2
        li      t3, 1000
        div     t1, t1, t3
        add     t1, t0, t1
        sb      t1, 3(s0)

        addi    a0, s0, 0

        # Stack Restore
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

.data
.align 2
SetColor_String:    .byte 0x1b, 0x5b, 0x30, 0x38, 0x3b, 0x35, 0x3b, 0x30, 0x30,
                    0x30, 0x30, 0x6d, 0x00
.text
#-------------------------------------------------------------------------------
# SetColor
# Args:        a0 = color code (see index)
#             a1 = 0 if setting background, 1 if setting foreground
#
# Prints the escape sequence that sets the color of the text to the color
# specified.
#
# xfce4-terminal supports 256 color lookup table assignment; see the index for a
# list of color codes.
#-------------------------------------------------------------------------------
GLIR_SetColor:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -12                     # Adjust stack to save variables
        sw      ra, -4(s0)
        sw      s1, -8(s0)
        sw      s2, -12(s0)

        addi    s1, a0, 0
        addi    s2, a1, 0
        # Get the digits of the color code to print
        jal     ra, _GLIR_IntToChar

        addi    t2, a0, 0
        addi    a0, s1, 0
        addi    a1, s2, 0

        la      t0, SetColor_String
        # Alter the string to print; max 3 digits; ignore 1000's
        lb      t1, 0(t2)
        sb      t1, 10(t0)
        lb      t1, 1(t2)
        sb      t1, 9(t0)
        lb      t1, 2(t2)
        sb      t1, 8(t0)

        # Set the code to print foreground or background
        beq     a1, zero, SetColor_SetBg
        # Setting foreground
        li      t1, 0x33
        jal     zero, SetColor_Set
        SetColor_SetBg:
        # Setting background
        li      t1, 0x34

        SetColor_Set:
        sb      t1, 2(t0)

        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        addi    a0, t0, 0
        ecall

        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        lw      s2, -12(s0)
        addi    sp, sp, 12
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

.data
.align 2
RestoreSettings_String: .byte 0x1b, 0x5b, 0x30, 0x6d, 0x00
.text
#-------------------------------------------------------------------------------
# RestoreSettings
#
# Prints the escape sequence that restores all default color settings to the
# terminal.
#-------------------------------------------------------------------------------
GLIR_RestoreSettings:
        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        la      a0, RestoreSettings_String
        ecall

        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
# Start
# Args:     a0 = number of rows to set the screen to
#           a1 = number of cols to set the screen to
#
# Sets up the display in order to provide a stable environment. Call GLIR_End
# when program is finished to return to as many defaults and stable settings as
# possible. Unfortunately screen size changes are not code-reversible, so
# GLIR_End will only return the screen to the hardcoded value of 24x80.
#-------------------------------------------------------------------------------
GLIR_Start:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -4                      # Adjust stack to save ra
        sw      ra, -4(s0)

        jal     ra, _GLIR_SetDisplaySize
        jal     ra, GLIR_RestoreSettings
        jal     ra, GLIR_ClearScreen
        jal     ra, _GLIR_HideCursor

        # Stack Restore
        lw      ra, -4(s0)
        addi    sp, sp, 4
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
# End
#
# Reverts to default as many settings as it can, meant to end a program that was
# started with Start. The default terminal window in xfce4-terminal is
# 24x80, so this is the assumed default we want to return to.
#-------------------------------------------------------------------------------
GLIR_End:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -4                      # Adjust stack to save variables
        sw      ra, -4(s0)

        li      a0, 24
        li      a1, 80
        jal     ra, _GLIR_SetDisplaySize
        jal     ra, GLIR_RestoreSettings

        jal     ra, GLIR_ClearScreen

        jal     ra, _GLIR_ShowCursor
        li      a0, 0
        li      a1, 0
        jal     ra, _GLIR_SetCursor

        # Stack Restore
        lw      ra, -4(s0)
        addi    sp, sp, 4
        lw      s0, 0(sp)
        addi    sp, sp, 4

        ret

.data
.align 2
HideCursor_String:  .byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c, 0x00
.text
#-------------------------------------------------------------------------------
# HideCursor
#
# Prints the escape sequence that hides the cursor.
#-------------------------------------------------------------------------------
_GLIR_HideCursor:
        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        la      a0, HideCursor_String
        ecall

        jalr    zero, ra, 0

.data
.align 2
ShowCursor_String:  .byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x68, 0x00
.text
#-------------------------------------------------------------------------------
# ShowCursor
#
# Prints the escape sequence that restores the cursor visibility.
#-------------------------------------------------------------------------------
_GLIR_ShowCursor:
        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        la      a0, ShowCursor_String
        ecall

        jalr    zero, ra, 0

.data
.align 2
SetDisplaySize_String:  .byte 0x1b, 0x5b, 0x38, 0x3b, 0x30, 0x30, 0x30, 0x30, 0x3b,
                        0x30, 0x30, 0x30, 0x30, 0x74, 0x00
.text
#-------------------------------------------------------------------------------
# SetDisplaySize
# Args:     a0 = number of rows
#           a1 = number of columns
#
# Prints the escape sequence that changes the size of the display to match the
# parameters passed. The number of rows and cols are ints x and y such that:
# 0 <= x,y <= 999.
#-------------------------------------------------------------------------------
_GLIR_SetDisplaySize:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -12                     # Adjust stack to save variables
        sw      ra, -4(s0)
        sw      s1, -8(s0)
        sw      s2, -12(s0)

        # If either argument is negative, do nothing
        slt     t0, a0, zero
        slt     t1, a1, zero
        or      t0, t0, t1
        bne     t0, zero, SetDisplaySize_End

        # Else
        addi    s1, a0, 0
        addi    s2, a1, 0

        # Set the TERM globals
        la      t0, _TERM_ROWS
        sw      a0, 0(t0)
        la      t0, _TERM_COLS
        sw      a1, 0(t0)

        # Rows
        # Get the digits of the params to print
        jal     ra, _GLIR_IntToChar

        # Alter the string to print
        la      t0, SetDisplaySize_String
        lb      t1, 0(a0)
        sb      t1, 7(t0)
        lb      t1, 1(a0)
        sb      t1, 6(t0)
        lb      t1, 2(a0)
        sb      t1, 5(t0)
        lb      t1, 3(a0)
        sb      t1, 4(t0)

        # Cols
        addi    a0, s2, 0
        # Get the digits of the params to print
        jal     ra, _GLIR_IntToChar

        # Alter the string to print
        la      t0, SetDisplaySize_String
        lb      t1, 0(a0)
        sb      t1, 12(t0)
        lb      t1, 1(a0)
        sb      t1, 11(t0)
        lb      t1, 2(a0)
        sb      t1, 10(t0)
        lb      t1, 3(a0)
        sb      t1, 9(t0)

        la      a7, _PRINT_STRING
        lw      a7, 0(a7)
        addi    a0, t0, 0
        ecall

        SetDisplaySize_End:
        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        lw      s2, -12(s0)
        addi    sp, sp, 12
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

.data
.align 2
ColorDemo_Char: .asciz "█"
.text
#-------------------------------------------------------------------------------
# ColorDemo
# Reg. Use: s1 = Holds the initial offset - we start at color 16 because the
#           first 16 (0-15) don't align very well in this demo. Change it to 0
#           (and adjust minimum terminal size) if you want the FULL color gamut.
#           s2 = Holds the current column being printed to.
#           s3 = Holds the current row being printed to.
#
# Attempts to print the 16-256 color gamut of your terminal.
# Requires that the terminal size be at least 41 rows and 6 cols big.
# Currently skips the first 15 colors because it's prettier :P
#-------------------------------------------------------------------------------
GLIR_ColorDemo:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -16                     # Adjust stack to save variables
        sw      ra, -4(s0)
        sw      s1, -8(s0)
        sw      s2, -12(s0)
        sw      s3, -16(s0)

        jal     ra, GLIR_ClearScreen
        # Print the colored boxes, skip the first 15 because its prettier
        # Start at color 16 so that we dont get offset weirdly by the first 15
        # colors
        li      s1, 16                          # Color
        li      s2, 1                           # Col
        li      s3, 1                           # Row
        ColorDemo_Loop:                         # While True
                addi    a0, s1, 0
                li      a1, 1
                jal     ra, GLIR_SetColor
                la      a0, ColorDemo_Char
                addi    a1, s3, 0
                addi    a2, s2, 0
                jal     ra, GLIR_PrintString
                addi    s2, s2, 1
                li      t0, 7
                bne     s2, t0, ColorDemo_LoopCont
                li      s2, 1
                addi    s3, s3, 1
                ColorDemo_LoopCont:
                addi    s1, s1, 1
                li      t0, 256
                beq     s1, t0, ColorDemo_LoopEnd
                jal     zero, ColorDemo_Loop

        ColorDemo_LoopEnd:
        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        lw      s2, -12(s0)
        lw      s3, -16(s0)
        addi    sp, sp, 16
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

.data
.align 2
PrintCircle_List:   .space 98                   # 8*3*4 bytes + 2, only prints 8
                                                # pixels at a time
PrintCircle_Char:   .asciz " "                  # Character to print with
.text
#-------------------------------------------------------------------------------
# PrintCircle
# Args:     a0 = row to print at
#           a1 = col to print at
#           a2 = radius of the circle to print
#           a3 = byte code [printing code][fg color][bg color][empty]
#           determining how to print the circle pixels, compatible with
#           printList
#
# Prints a circle onto the screen using the midpoint circle algorithm and the
# character PrintCircle_Char.
#
# Valid Printing codes:
# 0 = skip printing
# 1 = standard print, default terminal settings
# 2 = print using foreground color
# 3 = print using background color
# 4 = print using all colors
#
# xfce4-terminal supports the 256 color lookup table assignment; see the index
# for a list of color codes.
#
# The tuple describing a position on the grid is (R, C) and not (C, R).
# Terminals were designed to print text top to bottom, left to right. Their
# underlying control structures are built on this assumption. Thus the row
# number comes before the column number. The origin (0, 0) is at the top left of
# the xfce4-terminal window.
#-------------------------------------------------------------------------------
GLIR_PrintCircle:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -36                     # Adjust stack to save variables
        sw      ra, -4(s0)
        sw      s1, -8(s0)
        sw      s2, -12(s0)
        sw      s3, -16(s0)
        sw      s4, -20(s0)
        sw      s5, -24(s0)
        sw      s6, -28(s0)
        sw      s7, -32(s0)
        sw      s8, -36(s0)

        addi    s1, a2, 0                       # Row = Radius
        li      s2, 0                           # Col = 0
        li      s3, 0                           # Err = 0
        la      s4, PrintCircle_Char
        addi    s5, a0, 0                       # s5 <- RowCenter
        addi    s6, a1, 0                       # s6 <- ColCenter
        addi    s7, a3, 0                       # s7 <- PrintSettings

        PrintCircle_Loop:                       # While (Col <= Row)
                addi    t1, s2, -1
                slt     t0, t1, s1
                beq     t0, zero, PrintCircle_LoopEnd
                # Draw a pixel to each octant of the screen
                la      t0, PrintCircle_List

                # Draw first pixel in 4th quadrant
                add     t1, s5, s1              # y <- RowCenter + Row
                add     t2, s6, s2              # x <- ColCenter + Col
                # Store pixel location
                sh      t1, 0(t0)               # Print row
                sh      t2, 2(t0)               # Print col
                sw      s7, 4(t0)               # Store PrintSettings
                sw      s4, 8(t0)               # Store pixel to print
                addi    t0, t0, 12

                # Draw second pixel in 4th quadrant reflection on x = -y
                add     t1, s5, s2              # y <- RowCenter + Col
                add     t2, s6, s1              # x <- ColCenter + Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw first pixel in 1st quadrant
                sub     t1, s5, s2              # y <- RowCenter - Col
                add     t2, s6, s1              # x <- ColCenter + Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw second pixel in 1st quadrant reflection on x = y
                sub     t1, s5, s1              # y <- RowCenter - Row
                add     t2, s6, s2              # x <- ColCenter + Col
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw first pixel in 2nd quadrant
                sub     t1, s5, s1              # y <- RowCenter - Row
                sub     t2, s6, s2              # x <- ColCenter - Col
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw second pixel in 2nd quadrant reflection on x = -y
                sub     t1, s5, s2              # y <- RowCenter - Col
                sub     t2, s6, s1              # x <- ColCenter - Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw first pixel in 3rd quadrant
                add     t1, s5, s2              # y <- RowCenter + Col
                sub     t2, s6, s1              # x <- ColCenter - Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw second pixel in 3rd quadrant reflection on x = y
                add     t1, s5, s1              # y <- RowCenter + Row
                sub     t2, s6, s2              # x <- ColCenter - Col
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Terminate batch
                li      t1, 0xFFFF
                sh      t1, 0(t0)

                # Sterilize the input to GLIR_BatchPrint of the guard value
                # 0xFFFF in print row to avoid not printing the remainder of a
                # batch if the guard is encountered
                addi    t0, zero, 0             # i = 0
                addi    t1,    zero, 8          # Loop 8 times
                la      t2, PrintCircle_List
                PrintCircle_GuardLoop:
                lhu     t3, 0(t2)               # Print row
                li      t4, 0xFFFF              # Guard
                bne     t3, t4, PrintCircle_Sterile
                sb      zero, 4(t2)             # Set print code 0
                sh      zero, 0(t2)             # Reset print row
                PrintCircle_Sterile:
                addi    t2, t2, 12              # Increment by 3 words (1 job)
                addi    t0,    t0, 1            # i++
                bne     t0, t1, PrintCircle_GuardLoop

                PrintCircle_GuardEnd:
                la      a0, PrintCircle_List
                jal     ra, GLIR_BatchPrint

                addi    s2, s2, 1               # Y += 1
                blt     zero, s3, PrintCircle_MoveRow   # If (Err <= 0)
                add     s3, s3, s2              # Err += 2Y+1
                add     s3, s3, s2
                addi    s3, s3, 1
                jal     zero, PrintCircle_LoopCont
                PrintCircle_MoveRow:            # Else
                addi    s1, s1, -1              # X -= 1
                sub     t0, s2, s1              # Err += 2(Y-X) + 1
                add     s3, s3, t0
                add     s3, s3, t0
                addi    s3, s3, 1
                PrintCircle_LoopCont:
                jal     zero, PrintCircle_Loop

        PrintCircle_LoopEnd:
        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        lw      s2, -12(s0)
        lw      s3, -16(s0)
        lw      s4, -20(s0)
        lw      s5, -24(s0)
        lw      s6, -28(s0)
        lw      s7, -32(s0)
        lw      s8, -36(s0)
        addi    sp, sp, 36
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
#                                   END OF GLIR
#-------------------------------------------------------------------------------
