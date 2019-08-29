
.text
#-------------------------------------------------------------------------------
# WaitCycle
# Args:     a0 = The number of clock cycles to wait
#
# Performs a busy-wait ending after a0 clock cycles have passed.
#-------------------------------------------------------------------------------
WaitCycle:
        csrr    t0, mcycle                      # t0 <- mcycle[0:32]
        csrr    t1, mcycleh                     # t1 <- mcycle[32:64]
        add     t0, t0, a0                      # Add wait cycles to current time
        bge     t0, a0, WaitCycle_Loop          # Check for overflow
        jal     zero, WaitCycle_Overflow
        WaitCycle_Overflow:
        addi    t1, t1, 1
        jal     zero, WaitCycle_Loop
        WaitCycle_Loop:
                csrr    t2, mcycleh
                addi    t2, t2, -1
                blt     t2, t1, WaitCycle_LoopEqualUpper
                jal     zero, WaitCycle_Loop
                WaitCycle_LoopEqualUpper:
                csrr    t2, mcycle
                blt     t0, t2, WaitCycle_LoopEnd
                jal     zero, WaitCycle_Loop
        WaitCycle_LoopEnd:
        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
# WaitCycle64
# Args:     a0 = The lower 32 bits for the amount of clock cycles to wait
#           a1 = The upper 32 bits for the amount of clock cycles to wait
#
# Performs a busy-wait ending after a0 clock cycles have passed.
#-------------------------------------------------------------------------------
WaitCycle64:
        csrr    t0, mcycle                      # t0 <- mcycle[0:32]
        csrr    t1, mcycleh                     # t1 <- mcycle[32:64]
        add     t1, t1, a1
        add     t0, t0, a0                      # Add wait cycles to current time
        bge     t0, a0, WaitCycle64_Loop        # Check for overflow
        jal     zero, WaitCycle64_Overflow
        WaitCycle64_Overflow:
        addi    t1, t1, 1
        jal     zero, WaitCycle64_Loop
        WaitCycle64_Loop:
                csrr    t2, mcycleh
                addi    t2, t2, -1
                blt     t2, t1, WaitCycle64_LoopEqualUpper
                jal     zero, WaitCycle64_Loop
                WaitCycle64_LoopEqualUpper:
                csrr    t2, mcycle
                blt     t0, t2, WaitCycle64_LoopEnd
                jal     zero, WaitCycle64_Loop
        WaitCycle64_LoopEnd:
        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
# WaitSec
# Args:     a0 = The number of seconds to wait
#
# Performs a busy-wait ending after a0 sec have passed.
#
# Bugs: The wait time is only accurate if the clock speed is at the default 16
# MHz.
#-------------------------------------------------------------------------------
WaitSec:
        addi    sp, sp, -4
        sw      ra, 0(sp)

        addi    t0, zero, 1
        slli    t0, t0, 24
        mulhu   a1, a0, t0
        mul     a0, a0, t0
        jal     ra, WaitCycle64

        lw      ra, 0(sp)
        addi    sp, sp, 4
        jalr    zero, ra, 0

#-------------------------------------------------------------------------------
# WaitMilli
# Args:     a0 = The number of milliseconds to wait
#
# Performs a busy-wait ending after a0 millisec have passed.
#
# Bugs: The wait time is only accurate if the clock speed is at the default 16
# MHz.
#-------------------------------------------------------------------------------
WaitMilli:
        addi    sp, sp, -4
        sw      ra, 0(sp)

        addi    t0, zero, 1
        slli    t0, t0, 24
        addi    t1, zero, 1000
        div     t0, t0, t1
        mulhu   a1, a0, t0
        mul     a0, a0, t0
        jal     ra, WaitCycle64

        lw      ra, 0(sp)
        addi    sp, sp, 4
        jalr    zero, ra, 0

