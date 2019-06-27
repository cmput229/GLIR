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
# A test for the GLIR_RestoreSettings and GLIR_ClearScreen functionalities of
# the library. Prints three lines of unicode block characters with different
# foreground colors seperated by 3 lines of text on black backgrounds and
# different foreground colors. Resets terminal color settings using
# GLIR_RestoreSettings and clears the screen using GLIR_ClearScreen. With the
# restored color settings, prints one final line of text.
#
# Use the runRestoreClear shell script to run this test.
#-------------------------------------------------------------------------------

.include        "../GLIR.s"

.data
# Here we store the RARS syscall service numbers which are needed.
# Before a syscall we load from the label.
# They are saved and loaded in this way to promote code portability.
_EXIT:          .word 10
_SLEEP:         .word 32

MessySquares:   .asciz "█ █ █████████████████ █ █"
.align 2
String1:        .asciz "There is a mess on the screen..."
.align 2
String2:        .asciz "We should clean it up..."
.align 3
String3:        .asciz "Cleaning up now please wait..."
.align 2
String4:        .asciz "Reverted settings and cleared screen."
.text
main:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -4                      # Adjust stack to save variables
        sw      ra, -4(s0)                      # Save ra

        # Pass the size of terminal
        li      a0, 6                           # Number of rows
        li      a1, 39                          # Number of cols
        jal     ra, GLIR_Start

        # Set the colors of the foreground for the messy line of text
        li      a0, 154                         # Color; GreenYellow
        li      a1, 1                           # Foreground
        jal     ra, GLIR_SetColor

        # Print the messy string
        la      a0, MessySquares
        li      a1, 0                           # First row
        li      a2, 1                           # Second col
        jal     ra, GLIR_PrintString

        # Set the colors of the background and foreground for first line of
        # printing
        li      a0, 0                           # Color; Black
        li      a1, 0                           # Background
        jal     ra, GLIR_SetColor
        li      a0, 159                         # Color; PaleTurquoise1
        li      a1, 1                           # Foreground
        jal     ra, GLIR_SetColor

        # Print the first string
        la      a0, String1
        li      a1, 1                           # Second row
        li      a2, 1                           # Second col
        jal     ra, GLIR_PrintString

        # Set the colors of the foreground for the messy line of text
        li      a0, 212                         # Color; Orchid2
        li      a1, 1                           # Foreground
        jal     ra, GLIR_SetColor

        # Print the messy string
        la      a0, MessySquares
        li      a1, 2                           # Third row
        li      a2, 1                           # Second col
        jal     ra, GLIR_PrintString

        # Set the colors of the background and foreground for second line of
        # printing
        li      a0, 0                           # Color; Black
        li      a1, 0                           # Background
        jal     ra, GLIR_SetColor
        li      a0, 208                         # Color; DarkOrange
        li      a1, 1                           # Foreground
        jal     ra, GLIR_SetColor

        # Print the second string
        la      a0, String2
        li      a1, 3                           # Fourth row
        li      a2, 1                           # Second col
        jal     ra, GLIR_PrintString

        # Set the colors of the foreground for the messy line of text
        li      a0, 33                          # Color; DodgerBlue1
        li      a1, 1                           # Foreground
        jal     ra, GLIR_SetColor

        # Print the messy string
        la      a0, MessySquares
        li      a1, 4                           # Fifth row
        li      a2, 1                           # Second col
        jal     ra, GLIR_PrintString

        # Set the colors of the background and foreground for third line of
        # printing
        li      a0, 0                           # Color; Black
        li      a1, 0                           # Background
        jal     ra, GLIR_SetColor
        li      a0, 9                           # color; Red
        li      a1, 1                           # Foreground
        jal     ra, GLIR_SetColor

        # Print the third string
        la      a0, String3
        li      a1, 5                           # Sixth row
        li      a2, 1                           # Second col
        jal     ra, GLIR_PrintString

        # Wait 5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 5000
        ecall

        # Restore default terminal color settings
        jal     ra, GLIR_RestoreSettings
        # Clear the screen
        jal     ra, GLIR_ClearScreen

        # Print final string
        la      a0, String4
        li      a1, 2                           # Third row
        li      a2, 1                           # Second col
        jal     ra, GLIR_PrintString

        # Wait 2 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 2000
        ecall

        jal     ra, GLIR_End

        # Stack restore
        lw      ra, -4(s0)
        addi    sp, sp, 4
        lw      s0, 0(sp)
        addi    sp, sp, 4

        # Exit program
        la      a7, _EXIT
        lw      a7, 0(a7)
        ecall
