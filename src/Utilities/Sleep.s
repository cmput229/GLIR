#-------------------------------------------------------------------------------
# Sleep
# Args:     a0 = the number of milliseconds to sleep
#
# Waits the specified number of milliseconds (very roughly) by doing nothing.
#
# This is a simple busywait implementation of sleep for RARS made in the event
# that the sleep syscall cannot be used (ie. if you are using threads).
#-------------------------------------------------------------------------------
Sleep:
        Sleep_OutterLoop:
                beq     a0, zero, Sleep_OutterEnd
                addi    a0, a0, -1

                # Number of iterations of this loop we need to do to wait 1 ms
                # You can change the loaded immediate to change the tuning
                li      t0, 592                 # Number of loops for terminal
                #li     t0, 236                 # Number of loops for GUI
                Sleep_InnerLoop:
                beq     t0, zero, Sleep_InnerEnd
                addi    zero, zero, 0
                addi    t0, t0, -1
                jal     zero, Sleep_InnerLoop

                Sleep_InnerEnd:
                jal     zero, Sleep_OutterLoop

        Sleep_OutterEnd:
        jalr    zero, ra, 0