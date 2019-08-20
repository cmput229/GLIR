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
# Date: July 2019
#-------------------------------------------------------------------------------
# A test for the GLIR_PrintLine, GLIR_PrintRect, and GLIR_PrintTriangle
# primitives. Checks printing of both minimal and larger size shape prints.
# Checks out of bounds printing. Checks stacking of shapes. Checks that the
# order that points are specififed for GLIR_PrintLine is irrelevant to the
# end drawing. Checks that providing a string to use for printing primitives
# works as intended.
#
# Note that many shapes look much better when drawn larger. Small shapes will
# suffer from the restrictions of printing to a terminal (terminals and fonts
# are not square even if they are monospace, thus a square grid renders a
# rectangular shape) and the alignment of how characters are printed may look
# off.
#
# Use the runPrimitives shell script to run this test.
#-------------------------------------------------------------------------------

.include        "../../src/GLIR.s"

.data
# Here we store the RARS syscall service numbers which are needed.
# Before a syscall we load from the label.
# They are saved and loaded in this way to promote code portability.
_EXIT:          .word 10
_SLEEP:         .word 32

# Chars to use to test whether specifying a string to print with works
VerticalBar:    .asciz "|"
.align 2
Hash:           .asciz "#"
.align 2
ForwardSlash:   .asciz "/"
.text
main:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -48                     # Adjust stack to save variables
        sw      ra, -4(s0)                      # Save ra
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

        # Pass the size of terminal
        addi    s1, zero, 50                    # ScreenRows
        addi    s2, zero, 90                    # ScreenColumns
        add     a0, s1, zero
        add     a1, s2, zero
        jal     ra, GLIR_Start

        # Load some colors to use to distinguish different prints
        addi    s3, zero, 6                     # s3 = Teal
        addi    s4, zero, 5                     # s4 = Purple

        ## Negative bounds check
        # Check if the primitives correctly handle points being out of bounds in
        # the negative directions; ie. they dont print anything
        # Print a square in the top left corner s.t. it extends off the terminal
        # in the negative of both axes
        addi    a0, zero, -1                    # Row
        addi    a1, zero, -1                    # Col
        addi    a2, zero, 2                     # Height
        addi    a3, zero, 2                     # Width
        add     a4, zero, s3                    # Color
        add     a5, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintRect

        # Wait 1 second to illustrate how printing primitives on top of each
        # other will print the most recent primitive over the older
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        # Print a triangle similar to above with one point on screen and two
        # points out of bounds
        addi    a0, zero, -2                    # Row1
        addi    a1, zero, -2                    # Col1
        addi    a2, zero, -2                    # Row2
        addi    a3, zero, 2                     # Col2
        addi    a4, zero, 2                     # Row3
        addi    a5, zero, 2                     # Col3
        add     a6, zero, s4                    # Color
        add     a7, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintTriangle

        # Wait 1 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        ## Lines
        # Print smallest line segments with two unique points
        # Check if printing strictly horizontal and vertical lines works
        # Horizontal lines
        addi    a0, zero, 2                     # Row1
        addi    a1, zero, 4                     # Col1
        addi    a2, zero, 2                     # Row2
        addi    a3, zero, 5                     # Col2
        add     a4, zero, s3                    # Color
        add     a5, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintLine
        # Specify rightmost point first to show that order points are provided
        # doesn't matter
        addi    a0, zero, 0
        addi    a1, zero, 5
        addi    a2, zero, 0
        addi    a3, zero, 4
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Vertical line
        addi    a0, zero, 0
        addi    a1, zero, 7
        addi    a2, zero, 1
        addi    a3, zero, 7
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Diagonal line down and right
        addi    a0, zero, 0
        addi    a1, zero, 9
        addi    a2, zero, 1
        addi    a3, zero, 10
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Diagonal line up and right
        addi    a0, zero, 1
        addi    a1, zero, 12
        addi    a2, zero, 0
        addi    a3, zero, 13
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine

        # Print a cross pattern to illustrate stacking
        addi    a0, zero, 1
        addi    a1, zero, 15
        addi    a2, zero, 1
        addi    a3, zero, 17
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Specify lower point first to check that order points are provided
        # doesn't matter
        addi    a0, zero, 2
        addi    a1, zero, 16
        addi    a2, zero, 0
        addi    a3, zero, 16
        add     a4, zero, s4
        add     a5, zero, zero
        jal     GLIR_PrintLine

        # Wait 1 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        ## Lines with varying delta
        # Order of execution of the GLIR_PrintLine subroutine can execute
        # differently depending on whether or not the difference between the
        # Rows or Cols of the two points is larger
        # This section checks that the algorithm is printing correctly in all
        # cases and demonstrates how lines look with a large delta Col but small
        # delta Row
        addi    a0, zero, 4
        addi    a1, zero, 1
        addi    a2, zero, 6
        addi    a3, zero, 6
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        addi    a0, zero, 6
        addi    a1, zero, 8
        addi    a2, zero, 4
        addi    a3, zero, 13
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine

        addi    a0, zero, 0
        addi    a1, zero, 20
        addi    a2, zero, 6
        addi    a3, zero, 21
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        addi    a0, zero, 6
        addi    a1, zero, 23
        addi    a2, zero, 0
        addi    a3, zero, 24
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine

        # Print a crossing pattern
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        addi    a0, zero, 0
        addi    a1, zero, 27
        addi    a2, zero, 6
        addi    a3, zero, 37
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        addi    a0, zero, 6
        addi    a1, zero, 27
        addi    a2, zero, 0
        addi    a3, zero, 37
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        addi    a0, zero, 3
        addi    a1, zero, 27
        addi    a2, zero, 3
        addi    a3, zero, 37
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        addi    a0, zero, 0
        addi    a1, zero, 32
        addi    a2, zero, 6
        addi    a3, zero, 32
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintLine
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall

        # Check that GLIR_PrintLine correctly prints non-default string
        addi    a0, zero, 0
        addi    a1, zero, 40
        addi    a2, zero, 6
        addi    a3, zero, 40
        add     a4, zero, s3
        la      a5, VerticalBar
        jal     GLIR_PrintLine

        # Wait 1 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        ## Rectangles
        addi    a0, zero, 9                     # Row
        addi    a1, zero, 1                     # Col
        addi    a2, zero, 4                     # Height
        addi    a3, zero, 3                     # Width
        add     a4, zero, s3                    # Color
        add     a5, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintRect

        # Printing a rectangle with two triangles
        addi    a0, zero, 9                     # Row1
        addi    a1, zero, 7                     # Col1
        addi    a2, zero, 9                     # Row2
        addi    a3, zero, 10                    # Col2
        addi    a4, zero, 13                    # Row3
        addi    a5, zero, 7                     # Col3
        add     a6, zero, s3                    # Color
        add     a7, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintTriangle
        addi    a0, zero, 9
        addi    a1, zero, 10
        addi    a2, zero, 13
        addi    a3, zero, 7
        addi    a4, zero, 13
        addi    a5, zero, 10
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle

        # Check that rect prints correctly when given negative height and widths
        addi    a0, zero, 13
        addi    a1, zero, 13
        addi    a2, zero, -4
        addi    a3, zero, 3
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 9
        addi    a1, zero, 22
        addi    a2, zero, 4
        addi    a3, zero, -3
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 13
        addi    a1, zero, 28
        addi    a2, zero, -4
        addi    a3, zero, -3
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect

        # Long rectangles
        addi    a0, zero, 9
        addi    a1, zero, 31
        addi    a2, zero, 4
        addi    a3, zero, 0
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 9
        addi    a1, zero, 34
        addi    a2, zero, 4
        addi    a3, zero, 1
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 9
        addi    a1, zero, 38
        addi    a2, zero, 4
        addi    a3, zero, 2
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 9
        addi    a1, zero, 43
        addi    a2, zero, 0
        addi    a3, zero, 4
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect

        # Rectangles one cell high by one cell wide have 0 height and 0 width
        # In terms of output, this equivalent to just calling GLIR_PrintString
        addi    a0, zero, 13
        addi    a1, zero, 43
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 12
        addi    a1, zero, 46
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 12
        addi    a1, zero, 47
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 13
        addi    a1, zero, 46
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect
        addi    a0, zero, 13
        addi    a1, zero, 47
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        add     a5, zero, zero
        jal     GLIR_PrintRect

        # Check that GLIR_PrintRect correctly prints non-default string
        addi    a0, zero, 9
        addi    a1, zero, 50
        addi    a2, zero, 4
        addi    a3, zero, 5
        add     a4, zero, s3
        la      a5, Hash
        jal     GLIR_PrintRect

        # Wait 1 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        ## Triangles
        # Print smallest triangles possible with three unique points
        addi    a0, zero, 16                    # Row1
        addi    a1, zero, 1                     # Col1
        addi    a2, zero, 16                    # Row2
        addi    a3, zero, 2                     # Col2
        addi    a4, zero, 17                    # Row3
        addi    a5, zero, 1                     # Col3
        add     a6, zero, s3                    # Color
        add     a7, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16
        addi    a1, zero, 4
        addi    a2, zero, 16
        addi    a3, zero, 5
        addi    a4, zero, 17
        addi    a5, zero, 5
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16
        addi    a1, zero, 8
        addi    a2, zero, 17
        addi    a3, zero, 8
        addi    a4, zero, 17
        addi    a5, zero, 7
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16
        addi    a1, zero, 10
        addi    a2, zero, 17
        addi    a3, zero, 11
        addi    a4, zero, 17
        addi    a5, zero, 10
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        # Print other small triangles
        addi    a0, zero, 16
        addi    a1, zero, 13
        addi    a2, zero, 16
        addi    a3, zero, 15
        addi    a4, zero, 17
        addi    a5, zero, 14
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16
        addi    a1, zero, 17
        addi    a2, zero, 17
        addi    a3, zero, 18
        addi    a4, zero, 18
        addi    a5, zero, 17
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        addi    a0, zero, 18
        addi    a1, zero, 20
        addi    a2, zero, 17
        addi    a3, zero, 22
        addi    a4, zero, 18
        addi    a5, zero, 22
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16
        addi    a1, zero, 24
        addi    a2, zero, 16
        addi    a3, zero, 26
        addi    a4, zero, 17
        addi    a5, zero, 24
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle

        # Wait 1 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        ## Larger triangles
        addi    a0, zero, 21
        addi    a1, zero, 1
        addi    a2, zero, 21
        addi    a3, zero, 13
        addi    a4, zero, 35
        addi    a5, zero, 7
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        addi    a0, zero, 23
        addi    a1, zero, 4
        addi    a2, zero, 23
        addi    a3, zero, 10
        addi    a4, zero, 27
        addi    a5, zero, 7
        add     a6, zero, s4
        add     a7, zero, zero
        jal     GLIR_PrintTriangle

        addi    a0, zero, 21
        addi    a1, zero, 16
        addi    a2, zero, 21
        addi    a3, zero, 26
        addi    a4, zero, 24
        addi    a5, zero, 26
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle
        addi    a0, zero, 26
        addi    a1, zero, 16
        addi    a2, zero, 26
        addi    a3, zero, 26
        addi    a4, zero, 35
        addi    a5, zero, 16
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle

        addi    a0, zero, 21
        addi    a1, zero, 47
        addi    a2, zero, 25
        addi    a3, zero, 33
        addi    a4, zero, 35
        addi    a5, zero, 28
        add     a6, zero, s3
        add     a7, zero, zero
        jal     GLIR_PrintTriangle

        # Check that GLIR_PrintRect correctly prints non-default string
        addi    a0, zero, 23
        addi    a1, zero, 50
        addi    a2, zero, 29
        addi    a3, zero, 72
        addi    a4, zero, 33
        addi    a5, zero, 66
        add     a6, zero, s3
        la      a7, ForwardSlash
        jal     GLIR_PrintTriangle

        # Wait 1 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        ## Fill empty space with long diagonal lines
        # 89 is 90th column
        addi    s5, zero, 49                    # Col1
        addi    s6, zero, 35                    # Row2

        FillLoop:
        # Wait 0.1 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 100
        ecall
        # If Col1 <= 89 || Row2 >= 0
        addi     t0, s2, -1                     # Last column is ScreenColumns
                                                # - 1
        bge     t0, s5, Fill
        blt     s6, zero, DoneFill
        Fill:
        addi    a0, zero, 0                     # Row1
        add     a1, s5, zero                    # Col1
        add     a2, s6, zero                    # Row2
        addi    a3, zero, 89                    # Col2
        add     a4, zero, s3                    # Color
        add     a5, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintLine
        addi    s5, s5, 2                       # Col1 = Col1 + 2
        addi    s6, s6, -2                      # Row2 = Row2 + -2
        jal     zero, FillLoop

        DoneFill:
        # Wait 0.5 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall

        ## Layering shapes into a design
        addi    s7, zero, 196                   # Colors ; to distinguish prints
        addi    s8, zero, 1                     # Offset
        addi    s9, zero, 37                    # Row
        addi    s10, zero, 0                    # Col
        sub     s11, s1, s9                     # NearestRow = ScreenRows - Row

        RectLoop:
        addi    t0, zero, 7                     # (ScreenRows - Row + 1) / 2 = 7
        # Boxes will fill in after 7 iterations for the given terminal size
        # Col increments by 1 starting at 0... use that as the loop iterator
        bge     s10, t0, DoneRects

        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall

        # Draw a rectangle up to edge of screen or last rectangle
        add     a0, s9, zero                    # Row
        add     a1, s10, zero                   # Col
        sub     a2, s11, s8                     # Height = NearestRow - offset
        sub     a3, s2, s8                      # Width = ScreenCols - offset
        add     a4, zero, s7                    # Color
        add     a5, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintRect

        addi    s7, s7, 1                       # Color++
        addi    s8, s8, 2                       # Offset = Offset - 2
        addi    s9, s9, 1                       # Row++
        addi    s10, s10, 1                     # Col++
        jal     zero, RectLoop

        DoneRects:
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall
        ## Positive bounds check
        # Check if the primitives correctly handle points being out of bounds in
        # the positive directions; ie. they dont print anything
        # Print a square in the bottom right corner s.t. it extends off the
        # terminal in the positive of both axes
        addi    a0, zero, 48                    # Row
        addi    a1, zero, 88                    # Col
        addi    a2, zero, 2                     # Height
        addi    a3, zero, 2                     # Width
        add     a4, zero, s3                    # Color
        add     a5, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintRect

        # Wait 1 second
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        # Print a triangle similar to above with one point on screen and two
        # points out of bounds
        addi    a0, zero, 47                    # Row1
        addi    a1, zero, 87                    # Col1
        addi    a2, zero, 47                    # Row2
        addi    a3, zero, 91                    # Col2
        addi    a4, zero, 51                    # Row3
        addi    a5, zero, 91                    # Col3
        add     a6, zero, s4                    # Color
        add     a7, zero, zero                  # StrAddress; use default
        jal     GLIR_PrintTriangle

        # Wait 5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 5000
        ecall

        jal     ra, GLIR_End

        # Stack restore
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
        addi    sp, sp, 48
        lw      s0, 0(sp)
        addi    sp, sp, 4

        # Exit program
        la      a7, _EXIT
        lw      a7, 0(a7)
        ecall