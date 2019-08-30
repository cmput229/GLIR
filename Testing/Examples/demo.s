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
# A demo meant to show off GLIR's basic functions (GLIR_BatchPrint,
# GLIR_PrintString, and GLIR_PrintCircle). First, iterates through printable
# characters and colors while performing a batch print between each iteration.
# Next, uses GLIR_PrintString to carve out a message (HI!). Lastly, performs a
# series of calls to GLIR_PrintCircle. The circle is meant to appear to spread
# towards the edges of the terminal eventually going off screen. Looking at this
# demo's source code can give one a good idea of how GLIR is meant to be
# started/stopped as well as how one can use the various methods of printing
# jobs.
#
# Use the runDemo shell script to run this demonstration.
#-------------------------------------------------------------------------------

.include        "../../src/GLIR.s"

.data
# Here we store the RARS syscall service numbers which are needed.
# Before a syscall we load from the label.
# They are saved and loaded in this way to promote code portability.
_EXIT:          .word 10
_SLEEP:         .word 32

Char:           .asciz " "

.align 2
# Only using 1 job at a time
# 3 words + 1 halfword (sentinel)  = 3 * 4 + 2 = 14
PrintList:      .space 14
.text
main:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -24                     # Adjust stack to save variables
        sw      ra, -4(s0)                      # Save ra
        sw      s1, -8(s0)
        sw      s2, -12(s0)
        sw      s3, -16(s0)
        sw      s4, -20(s0)
        sw      s5, -24(s0)

        # Pass the size of terminal
        li      a0, 30                          # Number of rows
        li      a1, 60                          # Number of cols
        jal     ra, GLIR_Start

        # This section shows off batch printing. It prints a single job at a
        # time, but in theory you could add all the jobs to the list at once
        # and have all of them print at the same time. It's slowed here so you
        # have a chance to see it.

        li      s1, 0                           # Row
        li      s2, 0                           # Col
        # Valid colors are between 0 and 255
        li      s3, 0                           # Fgcolor
        li      s4, 100                         # Bgcolor
        # Printable chars are between 0x20 and 0x7e
        li      s5, 0x20                        # Char
        Loop:
                li      t0, 20
                beq     s1, t0, LoopEnd
                # Create a print job by adding to the list
                la      a0, PrintList
                sh      s1, 0(a0)               # Halfword row
                sh      s2, 2(a0)               # Halfword col
                li      t0, 4
                sb      t0, 4(a0)               # Print code 4 (both foreground
                                                # and background colors)
                sb      s3, 5(a0)               # Foreground color
                sb      s4, 6(a0)               # Background color
                # 7th byte is empty
                la      t0, Char
                sb      s5, 0(t0)               # Update the Char string
                sw      t0, 8(a0)               # Then provide it to the job
                li      t0, 0xFFFF
                sh      t0, 12(a0)              # Terminate the job list
                jal     ra, GLIR_BatchPrint

                # Wait 0.001 seconds
                la      a7, _SLEEP
                lw      a7, 0(a7)
                li      a0, 1
                ecall

                addi    s4, s4, 1               # Goto next Bgcolor
                li      t0, 255
                bne     s4, t0, LoopFgColor
                li      s4, 0
                LoopFgColor:
                addi    s3, s3, 1               # Goto next Fgcolor
                li      t0, 255
                bne     s3, t0, LoopChar
                li      s3, 0
                LoopChar:
                addi    s5, s5, 1               # Goto next character
                li      t0, 0x7e
                bne     s5, t0, LoopCont
                li      s5, 0x20


                LoopCont:
                addi    s2, s2, 1
                li      t0, 60
                bne     s2, t0, Loop
                li      s2, 0
                addi    s1, s1, 1
                jal     zero, Loop

        LoopEnd:
        # Wait
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        # Then carve out a message
        # This section shows off GLIR_PrintString; just simply printing the
        # string we want directly to a location using the current settings

        # Restore default color settings since they probably are messed up from
        # the earlier demo
        jal     ra, GLIR_RestoreSettings


        # The goal is to print:

        #    @  @ @@@@   @
        #    @  @  @@    @
        #    @@@@  @@    @
        #    @  @  @@
        #    @  @ @@@@   @

        la      a0, Char
        # Print using spaces (it's black background white text)
        li      t1, 0x20
        sw      t1, 0(a0)

        li      a1, 0
        li      a2, 4
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 1
        li      a2, 4
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 2
        li      a2, 4
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 3
        li      a2, 4
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 4
        li      a2, 4
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 2
        li      a2, 5
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 2
        li      a2, 6
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 0
        li      a2, 7
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 1
        li      a2, 7
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 2
        li      a2, 7
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 3
        li      a2, 7
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 4
        li      a2, 7
        jal     ra, GLIR_PrintString            # Done printing H

        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall

        la      a0, Char
        li      a1, 0
        li      a2, 9
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 4
        li      a2, 9
        jal     ra, GLIR_PrintString

        la      a0, Char
        li      a1, 0
        li      a2, 10
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 1
        li      a2, 10
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 2
        li      a2, 10
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 3
        li      a2, 10
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 4
        li      a2, 10
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 0
        li      a2, 11
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 1
        li      a2, 11
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 2
        li      a2, 11
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 3
        li      a2, 11
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 4
        li      a2, 11
        jal     ra, GLIR_PrintString

        la      a0, Char
        li      a1, 0
        li      a2, 12
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 4
        li      a2, 12
        jal     ra, GLIR_PrintString            # Done printing "I"

        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall

        la      a0, Char
        li      a1, 0
        li      a2, 15
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 1
        li      a2, 15
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 2
        li      a2, 15
        jal     ra, GLIR_PrintString
        la      a0, Char
        li      a1, 4
        li      a2, 15
        jal     ra, GLIR_PrintString            # Done printing "!"

        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall



        # Print circles! 2 pixels wide, and only 3 on screen at a time
        li      a0, 15
        li      a1, 30
        li      a2, 0
        # REMEMBER this is little endian so now it's [empty] [bgcolor] [fgcolor]
        # [printing code]
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 1
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle

        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        li      a0, 15
        li      a1, 30
        li      a2, 0
        li      a3, 0x00001202
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 1
        li      a3, 0x00001202
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 2
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 3
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle

        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        li      a0, 15
        li      a1, 30
        li      a2, 0
        li      a3, 0x00001102
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 1
        li      a3, 0x00001102
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 2
        li      a3, 0x00001202
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 3
        li      a3, 0x00001202
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 4
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 5
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle

        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        li      a0, 15
        li      a1, 30
        li      a2, 0
        li      a3, 0x00001002
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 1
        li      a3, 0x00001002
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 2
        li      a3, 0x00001102
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 3
        li      a3, 0x00001102
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 4
        li      a3, 0x00001202
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 5
        li      a3, 0x00001202
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 6
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle
        li      a0, 15
        li      a1, 30
        li      a2, 7
        li      a3, 0x00001302
        add     a4, zero, zero
        jal     ra, GLIR_PrintCircle

        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 1000
        ecall

        li      s1, 2                           # Radius = 2 (0 and 1 already
                                                # covered)
        li      s2, 0                           # Counter = 0
        li      s4, 15                          # Max = 30

        MainCircleLoop:
                beq     s2, s4, MainCircleLoopEnd
                li      a0, 15                  # Row to print at
                li      a1, 30                  # Col to print at
                add     a2, s1, s2              # Radius of circle to print
                li      a3, 0x00001002          # PrintSettings
                add     a4, zero, zero          # StrAddress; use default
                jal     ra, GLIR_PrintCircle
                li      a0, 15
                li      a1, 30
                add     a2, s1, s2
                addi    a2, a2, 1
                li      a3, 0x00001002
                add     a4, zero, zero
                jal     ra, GLIR_PrintCircle
                li      a0, 15
                li      a1, 30
                add     a2, s1, s2
                addi    a2, a2, 2
                li      a3, 0x00001102
                add     a4, zero, zero
                jal     ra, GLIR_PrintCircle
                li      a0, 15
                li      a1, 30
                add     a2, s1, s2
                addi    a2, a2, 3
                li      a3, 0x00001102
                add     a4, zero, zero
                jal     ra, GLIR_PrintCircle
                li      a0, 15
                li      a1, 30
                add     a2, s1, s2
                addi    a2, a2, 4
                li      a3, 0x00001202
                add     a4, zero, zero
                jal     ra, GLIR_PrintCircle
                li      a0, 15
                li      a1, 30
                add     a2, s1, s2
                addi    a2, a2, 5
                li      a3, 0x00001202
                add     a4, zero, zero
                jal     ra, GLIR_PrintCircle
                li      a0, 15
                li      a1, 30
                add     a2, s1, s2
                addi    a2, a2, 6
                li      a3, 0x00001302
                add     a4, zero, zero
                jal     ra, GLIR_PrintCircle
                li      a0, 15
                li      a1, 30
                add     a2, s1, s2
                addi    a2, a2, 7
                li      a3, 0x00001302
                add     a4, zero, zero
                jal     ra, GLIR_PrintCircle

                la      a7, _SLEEP
                lw      a7, 0(a7)
                li      a0, 1000
                ecall

                addi    s1, s1, 1
                addi    s2, s2, 1
                jal     zero, MainCircleLoop

        MainCircleLoopEnd:
        # MUST BE CALLED BEFORE ENDING PROGRAM
        jal     ra, GLIR_End

        # Stack Restore
        lw      ra, -4(s0)
        lw      s1, -8(s0)
        lw      s2, -12(s0)
        lw      s3, -16(s0)
        lw      s4, -20(s0)
        lw      s5, -24(s0)
        addi    sp, sp, 24
        lw      s0, 0(sp)
        addi    sp, sp, 4

        # Exit program
        la      a7, _EXIT
        lw      a7, 0(a7)
        ecall
