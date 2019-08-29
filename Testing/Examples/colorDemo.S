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
# A demo meant to show off a subroutine created for GLIR called GLIR_ColorDemo.
# This demo attempts to print the 16-256 color gamut of the terminal. It prints
# 40 rows of 6 unicode full block char starting at color 16 and incrementing
# the color after each print. This demo's source code illustrates how easy it is
# to create beautiful displays on the terminal using GLIR's subroutines.
#
# Use the runColorDemo shell script to run this demonstration.
#-------------------------------------------------------------------------------

.include        "../../src/GLIR.S"

.text
main:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -4                      # Adjust stack to save variables
        sw      ra, -4(s0)                      # Save ra

        # Pass the size of terminal
        li      a0, 42                          # Number of rows
        li      a1, 7                           # Number of cols
        jal     ra, GLIR_Start

        jal     ra, GLIR_ColorDemo

        # Wait 5 seconds to admire
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 5000
        ecall

        jal     ra, GLIR_End

        # Stack Restore
        lw      ra, -4(s0)
        addi    sp, sp, 4
        lw      s0, 0(sp)
        addi    sp, sp, 4

        # Exit program
        la      a7, _EXIT
        lw      a7, 0(a7)
        ecall

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
# Requires that the terminal size be at least 41 rows and 7 cols big.
# Currently skips the first 15 colors because it's prettier.
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
