
#-------------------------------------------------------------------------------
#                                  START OF GLIR
#-------------------------------------------------------------------------------
# Copyright 2017 University of Alberta
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
# Version: 1.0
#-------------------------------------------------------------------------------
# This is a graphics library, supporting drawing pixels, and some basic
# primitives.
#
# High Level documentation is provided in the ../index.html file or at
# https://cmput229.github.io/GLIR/
# Per-method documentation is provided in the block comment preceding each
# subroutine definition, in the ../docs/reference.html, or at
# https://cmput229.github.io/GLIR/reference.html
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
#
# TODO: Add fill subroutines to fill the primitves.
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
# They are used to prevent off screen printing in the positive direction
# Any negative value indicates that these variables have not been set.
_TERM_ROWS:     .word -1
_TERM_COLS:     .word -1

# PUBLIC
.text
        jal     zero, main                      # Don't enter lib unless asked
#-------------------------------------------------------------------------------
# GLIR_Start
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

.text
#-------------------------------------------------------------------------------
# GLIR_End
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

        jalr    zero, ra, 0

.data
.align 2
RestoreSettings_String: .byte 0x1b, 0x5b, 0x30, 0x6d, 0x00
.text
#-------------------------------------------------------------------------------
# GLIR_RestoreSettings
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

.data
.align 2
ClearScreen_String: .byte 0x1b, 0x5b, 0x32, 0x4a, 0x00
.text
#-------------------------------------------------------------------------------
# GLIR_ClearScreen
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
SetColor_String:    .byte 0x1b, 0x5b, 0x30, 0x38, 0x3b, 0x35, 0x3b, 0x30, 0x30,
                    0x30, 0x30, 0x6d, 0x00
.text
#-------------------------------------------------------------------------------
# GLIR_SetColor
# Args:     a0 = color code (see index)
#           a1 = 0 if setting background, 1 if setting foreground
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

.text
#-------------------------------------------------------------------------------
# GLIR_PrintString
# Args:     a0 = address of string to print
#           a1 = integer value 0-999, row to print to
#           a2 = integer value 0-999, col to print to
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
# undetectable. The most likely useage of this subroutine is to print
# characters. The reason that it is a string that is printed is to support the
# printing of escape character sequences around the character so that fancy
# effects are supported. Some other terminals may treat the boundaries of the
# terminal window different. For example, some may not wrap or scroll. It is up
# to the user to test their terminal window for its default behaviour. Built for
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

        # Check if past boundaries
        la      t0, _TERM_ROWS
        lw      t0, 0(t0)
        bge     a1, t0, PrintString_End         # If TERM_ROWS <= print row

        la      t1, _TERM_COLS
        lw      t1, 0(t1)
        bge     a2, t1, PrintString_End         # or if TERM_COLS <= print col

        slt     t2, a1, zero                    # or if print row < 0

        slt     t3, a2, zero                    # or if print col < 0

        or      t2, t2, t3
        bne     t2, zero, PrintString_End       # then do nothing

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

.text
#-------------------------------------------------------------------------------
# GLIR_BatchPrint
# Args:     a0 = address of batch list to print
# Reg. Use: s1 = scanner for the list
#           s2 = store row info
#           s3 = store column info
#           s4 = store print code info
#           s7 = temporary color info storage accross calls
#           s8 = temporary color info storage accross calls
#
# A batch is a list of print jobs. The print jobs are in the format below, and
# will be printed from start to finish. This subroutine does some basic
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
# effect not just this print, but also future prints for other GLIR subroutines.
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

        addi    s1, a0, 0                       # Scanner = start of batch

        jal     ra, GLIR_RestoreSettings
        # Store the last known colors, to avoid un-needed printing
        li      s7, -1                          # LastFg = -1
        li      s8, -1                          # LastBg = -1

        # For item in list
        BatchPrint_Scan:
                # Extract row and col to vars
                lhu     s2, 0(s1)               # Row
                lhu     s3, 2(s1)               # Col
                # If Row is 0xFFFF: break
                li      t0, 0xFFFF
                beq     s2, t0, BatchPrint_ScanEnd

                # Extract printing code
                lbu     s4, 4(s1)               # PrintCode
                # Skip if printing code is 0
                beq     s4, zero, BatchPrint_ScanCont

                # Print to match printing code if needed
                # If standard print, make sure to clear the current color
                # settings
                li      t0, 1
                bne     s4, t0, BatchPrint_ScanClearEnd     # If PrintCode != 1
                # Check if we need to reset the color
                li      t0, -1
                # If Fg and Bg are -1 then current settings are terminal default
                bne     s7, t0, BatchPrint_ScanClearColor   # If LastFg != -1
                bne     s8, t0, BatchPrint_ScanClearColor   # OR LastBg != -1
                jal     zero, BatchPrint_ScanClearEnd
                BatchPrint_ScanClearColor:
                jal     ra, GLIR_RestoreSettings
                li      s7, -1
                li      s8, -1

                BatchPrint_ScanClearEnd:
                # Change foreground color if needed
                # If PrintCode == 2 or PrintCode == 4
                li      t0, 2
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
                # If PrintCode == 3 or PrintCode == 4
                li      t0, 3
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
ColorDemo_Char: .asciz "█"
.text
#-------------------------------------------------------------------------------
# GLIR_ColorDemo
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
PrintLine_Char: .asciz "█"                      # Char to print with if a5 = 0
.text
#-------------------------------------------------------------------------------
# GLIR_PrintLine
# Args:     a0 = Row1
#           a1 = Col1
#           a2 = Row2
#           a3 = Col2
#           a4 = Color to print with
#           a5 = Address of null-terminated string to print with; if 0 then uses
#                the unicode full block char (█) as default
#
# Prints a line onto the screen between points (Row1, Col1) and (Row2, Col2).
#
# The reason that it is a string that is printed is to support the printing of
# escape character sequences around the character so that fancy effects are
# supported. Printing more than one character when not using escape sequences
# will have undefined behaviour.
#
# Algorithm from:
# https://github.com/OneLoneCoder/videos/blob/master/olcConsoleGameEngine.h
#-------------------------------------------------------------------------------
GLIR_PrintLine:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -72                     # Adjust stack to save variables
        sw      ra, -4(s0)
        sw      s1, -8(s0)
        sw      s2, -12(s0)
        sw      s3, -16(s0)
        sw      s4, -20(s0)
        sw      s5, -24(s0)
        sw      s6, -28(s0)
        sw      s7, -32(s0)
        sw      s8, -36(s0)
        sw      s9, -40(s0)
        sw      s10, -44(s0)
        sw      s11, -48(s0)
        sw      a0, -52(s0)                     # Row1 at -52(s0)
        sw      a1, -56(s0)                     # Col1 at -56(s0)
        sw      a2, -60(s0)                     # Row2 at -60(s0)
        sw      a3, -64(s0)                     # Col2 at -64(s0)
        sw      a4, -68(s0)                     # Color at -68(s0)
        sw      a5, -72(s0)                     # StrAddress at -72(s0)

        # Set address of string to use for printing
        bne     a5, zero, PrintLine_StrIsSet    # If a5 != 0 then do nothing
        # Else set the StrAddress to use default unicode full block char
        la      a5, PrintLine_Char
        sw      a5, -72(s0)                     # StrAddress at -72(s0)

        PrintLine_StrIsSet:
        sub     s1, a2, a0                      # DRow = s1 <- row2 - row1
        sub     s2, a3, a1                      # DCol = s2 <- col2 - col1

        add     a0, s1, zero
        jal     ra, _GLIR_Abs
        add     s3, a0, zero                    # DRowAbs = s3 <- abs(DRow)
        add     a0, s2, zero
        jal     ra, _GLIR_Abs
        add     s4, a0, zero                    # DColAbs = s4 <- abs(DCol)

        addi    t0, zero, 2
        mul     t1, t0, s4                      # t1 <- 2 * DColAbs
        # Not checking upper 32 bits of the multiplication b/c DColAbs
        # should be a small enough number
        sub     s5, t1, s3                      # PRow = s5 <- 2 * DColAbs -
                                                # DRowAbs
        mul     t1, t0, s3                      # t1 <- 2 * DRowAbs
        # Not checking upper 32 bits of the multiplication b/c DRowAbs
        # should be a small enough number
        sub     s6, t1, s4                      # PCol = s6 <- 2 * DRowAbs -
                                                # DColAbs

        # Set the color of the foreground for the text
        lw      a0, -68(s0)                     # Color
        li      a1, 1                           # Foreground
        jal     ra, GLIR_SetColor

        # Begin checking how we should print
        blt     s3, s4, PrintLine_OuterElse     # If DColAbs > DRowAbs goto
                                                # PrintLine_OuterElse
        # Set the start and endpoints for the loop
        blt     s1, zero, PrintLine_RowPoint1Ends # If DRow < 0 goto
                                                # PrintLine_RowPoint1Ends
        lw      s7, -52(s0)                     # Row = s7 <- Row1
        lw      s8, -56(s0)                     # Col = s8 <- Col1
        lw      s9, -60(s0)                     # RowEnd = s9 <- Row2
        jal     zero, PrintLine_RowDrawFirst

        PrintLine_RowPoint1Ends:
        lw      s7, -60(s0)                     # Row = s7 <- Row2
        lw      s8, -64(s0)                     # Col = s8 <- Col2
        lw      s9, -52(s0)                     # RowEnd = s9 <- Row1

        PrintLine_RowDrawFirst:
        # Draw first point
        lw      a0, -72(s0)                     # StrAddress at -72(s0)
        add     a1, s7, zero
        add     a2, s8, zero
        jal     ra, GLIR_PrintString

        # Draw points between first point and RowEnd
        PrintLine_RowLoop:
                bge     s7, s9, PrintLine_End           # If Row >= RowEnd goto
                                                        # PrintLine_End
                addi    s7, s7, 1                       # Row = Row + 1
                bge     s5, zero, PrintLine_CheckCol    # If PRow >= 0 goto
                                                        # PrintLine_CheckCol
                li      t0, 2
                mul     t1, s4, t0
                add     s5, s5, t1                      # PRow = PRow + 2 *
                                                        # DColAbs
                jal     zero, PrintLine_RowDraw

                PrintLine_CheckCol:
                # If ((DRow < 0 && DCol < 0) || (DRow > 0 && DCol > 0)) y++;
                # else y--;
                bge     s1, zero, PrintLine_RowOr       # If DRow >= 0 goto...
                blt     s2, zero, PrintLine_IncCol      # If DCol < 0 goto...

                PrintLine_RowOr:
                bge     zero, s1, PrintLine_DecCol      # If DRow <= 0 goto...
                bge     zero, s2, PrintLine_DecCol      # If DCol <= 0 goto...

                PrintLine_IncCol:
                addi    s8, s8, 1                       # Col = Col + 1
                jal     zero, PrintLine_UpdatePRow
                PrintLine_DecCol:
                addi    s8, s8, -1                      # Col = Col - 1

                PrintLine_UpdatePRow:
                li      t0, 2
                sub     t1, s4, s3
                mul     t1, t1, t0
                # Not checking upper 32 bits of the multiplication b/c
                # (DColAbs - DRowAbs) should be a small enough number
                add     s5, s5, t1                      # PRow = PRow + 2 *
                                                        # (DColAbs - DRowAbs)

                PrintLine_RowDraw:
                # Draw a point
                # GLIR_PrintString checks terminal boundaries so we dont need to
                lw      a0, -72(s0)                     # StrAddress at -72(s0)
                add     a1, s7, zero
                add     a2, s8, zero
                jal     ra, GLIR_PrintString
                jal     zero, PrintLine_RowLoop


        PrintLine_OuterElse:
        # Set the start and endpoints for the loop
        blt     s2, zero, PrintLine_ColPoint1Ends # If DCol < 0 goto
                                                # PrintLine_ColPoint1Ends
        lw      s7, -52(s0)                     # Row = s7 <- Row1
        lw      s8, -56(s0)                     # Col = s8 <- Col1
        lw      s9, -64(s0)                     # ColEnd = s9 <- Col2
        jal     zero, PrintLine_ColDrawFirst

        PrintLine_ColPoint1Ends:
        lw      s7, -60(s0)                     # Row = s7 <- Row2
        lw      s8, -64(s0)                     # Col = s8 <- Col2
        lw      s9, -56(s0)                     # ColEnd = s9 <- Col1

        PrintLine_ColDrawFirst:
        # Draw first point
        lw      a0, -72(s0)                     # StrAddress at -72(s0)
        add     a1, s7, zero
        add     a2, s8, zero
        jal     ra, GLIR_PrintString

        # Draw points between first point and ColEnd
        PrintLine_ColLoop:
                bge     s8, s9, PrintLine_End           # If Col >= ColEnd goto
                                                        # PrintLine_End
                addi    s8, s8, 1                       # Col = Col + 1
                blt     zero, s6, PrintLine_CheckRow    # If PCol > 0 goto
                                                        # PrintLine_CheckRow
                li      t0, 2
                mul     t1, s3, t0
                add     s6, s6, t1                      # PCol = PCol + 2 *
                                                        # DRowAbs
                jal     zero, PrintLine_ColDraw


                PrintLine_CheckRow:
                # If ((DRow < 0 && DCol < 0) || (DRow > 0 && DCol > 0)) y++;
                # else y--;
                bge     s1, zero, PrintLine_ColOr       # If DRow >= 0 goto...
                blt     s2, zero, PrintLine_IncRow      # If DCol < 0 goto...

                PrintLine_ColOr:
                bge     zero, s1, PrintLine_DecRow      # If DRow <= 0 goto...
                bge     zero, s2, PrintLine_DecRow      # If DCol <= 0 goto...

                PrintLine_IncRow:
                addi    s7, s7, 1                       # Row = Row + 1
                jal     zero, PrintLine_UpdatePCol
                PrintLine_DecRow:
                addi    s7, s7, -1                      # Row = Row - 1

                PrintLine_UpdatePCol:
                li      t0, 2
                sub     t1, s3, s4
                mul     t1, t1, t0
                # Not checking upper 32 bits of the multiplication b/c
                # (DRowAbs - DColAbs) should be a small enough number
                add     s6, s6, t1                      # PCol = PCol + 2 *
                                                        # (DRowAbs - DColAbs)

                PrintLine_ColDraw:
                # Draw a point
                # GLIR_PrintString checks terminal boundaries so we dont need to
                lw      a0, -72(s0)                     # StrAddress at -72(s0)
                add     a1, s7, zero
                add     a2, s8, zero
                jal     ra, GLIR_PrintString
                jal     zero, PrintLine_ColLoop

        PrintLine_End:
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
        lw      s9, -40(s0)
        lw      s10, -44(s0)
        lw      s11, -48(s0)
        addi    sp, sp, 72
        lw      s0, 0(sp)
        addi    sp, sp, 4

        jalr    zero, ra, 0

.data
.align 2
PrintTriangle_Char: .asciz "█"                  # Char to print with if a7 = 0
.text
#-------------------------------------------------------------------------------
# GLIR_PrintTriangle
# Args:     a0 = Row1
#           a1 = Col1
#           a2 = Row2
#           a3 = Col2
#           a4 = Row3
#           a5 = Col3
#           a6 = Color to print with
#           a7 = Address of null-terminated string to print with; if 0 then uses
#                the unicode full block char (█) as default
#
# Prints a triangle onto the screen connected by the points (Row1, Col1),
# (Row2, Col2), (Row3, Col3).
#
# The reason that it is a string that is printed is to support the printing of
# escape character sequences around the character so that fancy effects are
# supported. Printing more than one character when not using escape sequences
# will have undefined behaviour.
#-------------------------------------------------------------------------------
GLIR_PrintTriangle:
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

        add     s1, a0, zero                    # s1 = Row1
        add     s2, a1, zero                    # s2 = Col1
        add     s3, a2, zero                    # s3 = Row2
        add     s4, a3, zero                    # s4 = Col2
        add     s5, a4, zero                    # s5 = Row3
        add     s6, a5, zero                    # s6 = Col3
        add     s7, a6, zero                    # s7 = Color

        # Set address of string to use for printing
        add     s8, a7, zero                    # s8 = StrAddress
        bne     a7, zero, PrintTriangle_StrIsSet    # If a7 != 0 then do nothing
        # Else set the StrAddress to use default unicode full block char
        la      s8, PrintTriangle_Char

        PrintTriangle_StrIsSet:
        # a0, a1 = (Row1, Col1) and a2, a3 = (Row2, Col2) currently
        add     a4, s7, zero                    # Color
        add     a5, s8, zero                    # StrAddress
        jal     ra, GLIR_PrintLine

        add     a0, s3, zero
        add     a1, s4, zero
        add     a2, s5, zero
        add     a3, s6, zero
        add     a4, s7, zero
        add     a5, s8, zero
        jal     ra, GLIR_PrintLine

        add     a0, s5, zero
        add     a1, s6, zero
        add     a2, s1, zero
        add     a3, s2, zero
        add     a4, s7, zero
        add     a5, s8, zero
        jal     ra, GLIR_PrintLine

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

.data
.align 2
PrintRect_Char: .asciz "█"                      # Char to print with if a5 = 0
.text
#-------------------------------------------------------------------------------
# GLIR_PrintRect
# Args:     a0 = Row of top left corner
#           a1 = Col of top left corner
#           a2 = Signed height of the rectangle
#           a3 = Signed width of the rectangle
#           a4 = Color to print with
#           a5 = Address of null-terminated string to print with; if 0 then uses
#                the unicode full block char (█) as default
#
#
# Prints a rectangle using the (Row, Col) point as the top left corner having
# width and height as specified. Supports negative widths and heights.
# Specifying a height and width of 0 will print a rectangle one cell high by
# one cell wide.
#
# The reason that it is a string that is printed is to support the printing of
# escape character sequences around the character so that fancy effects are
# supported. Printing more than one character when not using escape sequences
# will have undefined behaviour.
#-------------------------------------------------------------------------------
GLIR_PrintRect:
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

        add     s1, a0, zero                    # s1 = Row
        add     s2, a1, zero                    # s2 = Col
        add     s3, a2, zero                    # s3 = Height
        add     s4, a3, zero                    # s4 = Width
        add     s5, a4, zero                    # s5 = Color

        # Calculate the offset row and col needed for other points
        add     s6, s1, s3                      # s6 = Row + Height
        add     s7, s2, s4                      # s7 = Col + Width

        # Set address of string to use for printing
        add     s8, a5, zero                    # s8 = StrAddress
        bne     a5, zero, PrintRect_StrIsSet    # If a5 != 0 then do nothing
        # Else set the StrAddress to use default unicode full block char
        la      s8, PrintRect_Char

        PrintRect_StrIsSet:
        # Connect top left point to top right point
        # a0, a1, and a4 are all still set
        add     a2, s1, zero
        add     a3, s7, zero
        add     a5, s8, zero
        # a0 = Row, a1 = Col, a2 = Row, a3 = Col + Width
        jal     GLIR_PrintLine

        # Connect top left point to bottom left point
        add     a0, s1, zero
        add     a1, s2, zero
        add     a2, s6, zero
        add     a3, s2, zero
        add     a4, s5, zero
        add     a5, s8, zero
        # a0 = Row, a1 = Col, a2 = Row + Height, a3 = Col
        jal     GLIR_PrintLine

        # Connect bottom left point to bottom right point
        add     a0, s6, zero
        add     a1, s2, zero
        add     a2, s6, zero
        add     a3, s7, zero
        add     a4, s5, zero
        add     a5, s8, zero
        # a0 = Row + Height, a1 = Col, a2 = Row + Height, a3 = Col + Width
        jal     GLIR_PrintLine

        # Connect top right point to bottom right point
        add     a0, s1, zero
        add     a1, s7, zero
        add     a2, s6, zero
        add     a3, s7, zero
        add     a4, s5, zero
        add     a5, s8, zero
        # a0 = Row, a1 = Col + Width, a2 = Row + Height, a3 = Col + Width
        jal     GLIR_PrintLine

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

.data
.align 2
PrintCircle_List:   .space 98                   # 8*3*4 bytes + 2, only prints 8
                                                # pixels at a time
PrintCircle_Char:   .asciz "█"                  # Char to print with if a4 = 0
.text
#-------------------------------------------------------------------------------
# GLIR_PrintCircle
# Args:     a0 = row to print at
#           a1 = col to print at
#           a2 = radius of the circle to print
#           a3 = byte code [printing code][fg color][bg color][empty]
#           determining how to print the circle pixels, compatible with
#           printList
#           a4 = Address of null-terminated string to print with; if 0 then uses
#                the unicode full block char (█) as default
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
# The reason that it is a string that is printed is to support the printing of
# escape character sequences around the character so that fancy effects are
# supported. Printing more than one character when not using escape sequences
# will have undefined behaviour.
#
# The tuple describing a position on the grid is (R, C) and not (C, R).
# Terminals were designed to print text top to bottom, left to right. Their
# underlying control structures are built on this assumption. Thus the row
# number comes before the column number. The origin (0, 0) is at the top left of
# the xfce4-terminal window. Below is an ascii diagram of the notation used in
# the comments of the subroutine. The numbers 1,2,3,4 correspond to the
# quadrants.
#
#  (0,0)
#    /--------------------------------------> Col
#    |            |
#    |            |
#    |           ███
#    |         ██ | ██
#    |        █   |   █
#    |       █    |    █
#    |      █  2  |  1  █
#    |      █     |     █
#    |     █      |      █
#    | ----█------+------█----
#    |     █      |      █
#    |      █     |     █
#    |      █  3  |  4  █
#    |       █    |    █
#    |        █   |   █
#    |         ██ | ██
#    |           ███
#    |            |
#    |            |
#    v
#    Row
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

        # Set address of string to use for printing
        add     s4, a4, zero                    # s4 = StrAddress
        bne     a4, zero, PrintCircle_StrIsSet  # If a4 != 0 then do nothing
        # Else set the StrAddress to use default unicode full block char
        la      s4, PrintCircle_Char

        PrintCircle_StrIsSet:
        addi    s5, a0, 0                       # s5 <- RowCenter
        addi    s6, a1, 0                       # s6 <- ColCenter
        addi    s7, a3, 0                       # s7 <- PrintSettings

        PrintCircle_Loop:                       # While (Col <= Row)
                addi    t1, s2, -1
                slt     t0, t1, s1
                beq     t0, zero, PrintCircle_LoopEnd
                # Draw a pixel to each octant of the screen (R,C)
                la      t0, PrintCircle_List

                # Draw first pixel in 4th quadrant
                add     t1, s5, s1              # R <- RowCenter + Row
                add     t2, s6, s2              # C <- ColCenter + Col
                # Store pixel location
                sh      t1, 0(t0)               # Store print row
                sh      t2, 2(t0)               # Store print col
                sw      s7, 4(t0)               # Store PrintSettings
                sw      s4, 8(t0)               # Store string to print
                addi    t0, t0, 12

                # Draw second pixel in 4th quadrant reflection on R = C
                add     t1, s5, s2              # R <- RowCenter + Col
                add     t2, s6, s1              # C <- ColCenter + Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw first pixel in 1st quadrant
                sub     t1, s5, s2              # R <- RowCenter - Col
                add     t2, s6, s1              # C <- ColCenter + Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw second pixel in 1st quadrant reflection on:
                # R = ColCenter + RowCenter - C
                sub     t1, s5, s1              # R <- RowCenter - Row
                add     t2, s6, s2              # C <- ColCenter + Col
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw first pixel in 2nd quadrant
                sub     t1, s5, s1              # R <- RowCenter - Row
                sub     t2, s6, s2              # C <- ColCenter - Col
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw second pixel in 2nd quadrant reflection on R = C
                sub     t1, s5, s2              # R <- RowCenter - Col
                sub     t2, s6, s1              # C <- ColCenter - Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw first pixel in 3rd quadrant
                add     t1, s5, s2              # R <- RowCenter + Col
                sub     t2, s6, s1              # C <- ColCenter - Row
                sh      t1, 0(t0)
                sh      t2, 2(t0)
                sw      s7, 4(t0)
                sw      s4, 8(t0)
                addi    t0, t0, 12

                # Draw second pixel in 3rd quadrant reflection on:
                # R = ColCenter + RowCenter - C
                add     t1, s5, s1              # R <- RowCenter + Row
                sub     t2, s6, s2              # C <- ColCenter - Col
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
                addi    t0, zero, 0             # I = 0
                addi    t1, zero, 8             # Loop 8 times
                la      t2, PrintCircle_List
                PrintCircle_GuardLoop:
                lhu     t3, 0(t2)               # Print row
                li      t4, 0xFFFF              # Guard
                bne     t3, t4, PrintCircle_Sterile
                sb      zero, 4(t2)             # Set print code 0
                sh      zero, 0(t2)             # Reset print row
                PrintCircle_Sterile:
                addi    t2, t2, 12              # Increment by 3 words (1 job)
                addi    t0, t0, 1               # I++
                bne     t0, t1, PrintCircle_GuardLoop

                PrintCircle_GuardEnd:
                la      a0, PrintCircle_List
                jal     ra, GLIR_BatchPrint

                addi    s2, s2, 1               # C += 1
                blt     zero, s3, PrintCircle_MoveRow   # If (Err <= 0)
                add     s3, s3, s2              # Err += 2 * C + 1
                add     s3, s3, s2
                addi    s3, s3, 1
                jal     zero, PrintCircle_LoopCont
                PrintCircle_MoveRow:            # Else
                addi    s1, s1, -1              # R -= 1
                sub     t0, s2, s1              # Err += 2(C - R) + 1
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

# PRIVATE
.data
.align 2
HideCursor_String:  .byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c, 0x00
.text
#-------------------------------------------------------------------------------
# _GLIR_HideCursor
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
# _GLIR_ShowCursor
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
SetCursor_String:   .byte 0x1b, 0x5b, 0x30, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30,
                    0x30, 0x30, 0x48, 0x00
.text
#-------------------------------------------------------------------------------
# _GLIR_SetCursor
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

.data
.align 2
SetDisplaySize_String:  .byte 0x1b, 0x5b, 0x38, 0x3b, 0x30, 0x30, 0x30, 0x30,
                        0x3b, 0x30, 0x30, 0x30, 0x30, 0x74, 0x00
.text
#-------------------------------------------------------------------------------
# _GLIR_SetDisplaySize
# Args:     a0 = number of rows
#           a1 = number of columns
#
# Prints the escape sequence that changes the size of the display to match the
# parameters passed. The number of rows and cols are ints R and C such that:
# 0 <= R,C <= 999.
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
# Storing 4 bytes, potentially up to 9999
IntToChar_Space:    .space 4
.text
#-------------------------------------------------------------------------------
# _GLIR_IntToChar
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

.text
#-------------------------------------------------------------------------------
# _GLIR_Abs
# Args:     a0 = int to convert; x
# Returns:  a0 = abs(x)
#
# Branch-less absolute value calculation of a 32-bit int.
#-------------------------------------------------------------------------------
_GLIR_Abs:
        srai    t0, a0, 31
        # If x is +ve t0 will equal 0, otherwise t0 will equal 0xFFFF FFFF
        xor     a0, a0, t0
        # Inverted each bit if t0 is 0xFFFF FFFF, otherwise left unchanged
        sub     a0, a0, t0
        # Sutract -1 from inversion if x was negative, otherwise subtract 0

        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
#                                   END OF GLIR
#-------------------------------------------------------------------------------
