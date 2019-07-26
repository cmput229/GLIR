# Note that many shapes look much better when drawn larger. 
# Small shapes will suffer from the restrictions of printing to a grid and thus the alignment of how characters are printed may look off.
.include        "../GLIR.s"

.data
# Here we store the RARS syscall service numbers which are needed.
# Before a syscall we load from the label.
# They are saved and loaded in this way to promote code portability.
_EXIT:          .word 10
_SLEEP:         .word 32

.text
main:
        # Stack Adjustments
        addi    sp, sp, -4                      # Adjust the stack to save fp
        sw      s0, 0(sp)                       # Save fp
        add     s0, zero, sp                    # fp <- sp
        addi    sp, sp, -32                     # Adjust stack to save variables
        sw      ra, -4(s0)                      # Save ra
        sw      s1, -8(s0)
        sw      s2, -12(s0)
        sw      s3, -16(s0)
        sw      s4, -20(s0)
        sw      s5, -24(s0)
        sw      s6, -28(s0)
        sw      s7, -32(s0)

        # Pass the size of terminal
        addi    s1, zero, 50                    # ScreenRows
        addi    s2, zero, 90                    # ScreenColumns
        add     a0, s1, zero                      
        add     a1, s2, zero                         
        jal     ra, GLIR_Start
        
        # Load some colors to use to distinguish different prints
        addi    s3, zero, 6                     # s3 = Teal
        addi    s4, zero, 5                     # s4 = Purple

        # Check if the primitives handle point being out of bounds in the 
        # negative direction correctly; ie. they dont print anything
        # Print a square in the top left corner s.t. it extends off the terminal
        # in the negative of both axes
        addi    a0, zero, -1                    # Row
        addi    a1, zero, -1                    # Col
        addi    a2, zero, 2                     # Height
        addi    a3, zero, 2                     # Width
        add     a4, zero, s3                    # Color
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
        jal     GLIR_PrintLine
        # Specify rightmost point first to show that order points are provided
        # doesn't matter
        addi    a0, zero, 0              
        addi    a1, zero, 5              
        addi    a2, zero, 0               
        addi    a3, zero, 4               
        add     a4, zero, s3                 
        jal     GLIR_PrintLine
        # Vertical line
        addi    a0, zero, 0
        addi    a1, zero, 7
        addi    a2, zero, 1
        addi    a3, zero, 7
        add     a4, zero, s3
        jal     GLIR_PrintLine
        # Diagonal line down and right
        addi    a0, zero, 0
        addi    a1, zero, 9
        addi    a2, zero, 1
        addi    a3, zero, 10
        add     a4, zero, s3
        jal     GLIR_PrintLine
        # Diagonal line up and right
        addi    a0, zero, 1
        addi    a1, zero, 12
        addi    a2, zero, 0
        addi    a3, zero, 13
        add     a4, zero, s3
        jal     GLIR_PrintLine

        # Print a cross pattern to illustrate stacking
        addi    a0, zero, 1
        addi    a1, zero, 15
        addi    a2, zero, 1
        addi    a3, zero, 17
        add     a4, zero, s3
        jal     GLIR_PrintLine
        # Specify lower point first to check that order points are provided
        # doesn't matter
        addi    a0, zero, 2
        addi    a1, zero, 16
        addi    a2, zero, 0
        addi    a3, zero, 16
        add     a4, zero, s4
        jal     GLIR_PrintLine

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
        jal     GLIR_PrintLine
        addi    a0, zero, 6
        addi    a1, zero, 8
        addi    a2, zero, 4
        addi    a3, zero, 13
        add     a4, zero, s3
        jal     GLIR_PrintLine

        addi    a0, zero, 0
        addi    a1, zero, 20
        addi    a2, zero, 6
        addi    a3, zero, 21
        add     a4, zero, s3
        jal     GLIR_PrintLine
        addi    a0, zero, 6
        addi    a1, zero, 23
        addi    a2, zero, 0
        addi    a3, zero, 24
        add     a4, zero, s3
        jal     GLIR_PrintLine

        addi    a0, zero, 0
        addi    a1, zero, 27
        addi    a2, zero, 6
        addi    a3, zero, 37
        add     a4, zero, s3
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
        jal     GLIR_PrintLine
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall

        ## Rectangles
        addi    a0, zero, 9                     # Row
        addi    a1, zero, 1                     # Col
        addi    a2, zero, 4                     # Height
        addi    a3, zero, 3                     # Width
        add     a4, zero, s3                    # Color
        jal     GLIR_PrintRect

        # Printing a rectangle with two triangles
        addi    a0, zero, 9                     # Row1
        addi    a1, zero, 7                     # Col1
        addi    a2, zero, 9                     # Row2
        addi    a3, zero, 10                    # Col2
        addi    a4, zero, 13                    # Row3
        addi    a5, zero, 7                     # Col3
        add     a6, zero, s3                    # Color
        jal     GLIR_PrintTriangle
        addi    a0, zero, 9                     
        addi    a1, zero, 10                
        addi    a2, zero, 13                  
        addi    a3, zero, 7               
        addi    a4, zero, 13                    
        addi    a5, zero, 10                 
        add     a6, zero, s3               
        jal     GLIR_PrintTriangle

        # Check that rect prints correctly when given negative height and widths
        addi    a0, zero, 13                    
        addi    a1, zero, 13                    
        addi    a2, zero, -4                    
        addi    a3, zero, 3                     
        add     a4, zero, s3                    
        jal     GLIR_PrintRect
        addi    a0, zero, 9                     
        addi    a1, zero, 22                    
        addi    a2, zero, 4                   
        addi    a3, zero, -3                    
        add     a4, zero, s3                
        jal     GLIR_PrintRect
        addi    a0, zero, 13                    
        addi    a1, zero, 28                   
        addi    a2, zero, -4                   
        addi    a3, zero, -3
        add     a4, zero, s3
        jal     GLIR_PrintRect

        # Long rectangles
        addi    a0, zero, 9
        addi    a1, zero, 31
        addi    a2, zero, 4
        addi    a3, zero, 0
        add     a4, zero, s3
        jal     GLIR_PrintRect
        addi    a0, zero, 9
        addi    a1, zero, 34
        addi    a2, zero, 4
        addi    a3, zero, 1
        add     a4, zero, s3
        jal     GLIR_PrintRect
        addi    a0, zero, 9
        addi    a1, zero, 38
        addi    a2, zero, 4
        addi    a3, zero, 2
        add     a4, zero, s3
        jal     GLIR_PrintRect
        addi    a0, zero, 9
        addi    a1, zero, 43
        addi    a2, zero, 0
        addi    a3, zero, 4
        add     a4, zero, s3
        jal     GLIR_PrintRect

        # Rectangles one cell high by one cell wide have 0 height and 0 width
        # In terms of output, this equivalent to just calling GLIR_PrintString
        addi    a0, zero, 13
        addi    a1, zero, 43
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        jal     GLIR_PrintRect
        addi    a0, zero, 12
        addi    a1, zero, 46
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        jal     GLIR_PrintRect
        addi    a0, zero, 12
        addi    a1, zero, 47
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        jal     GLIR_PrintRect
        addi    a0, zero, 13
        addi    a1, zero, 46
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        jal     GLIR_PrintRect
        addi    a0, zero, 13
        addi    a1, zero, 47
        addi    a2, zero, 0
        addi    a3, zero, 0
        add     a4, zero, s3
        jal     GLIR_PrintRect

        ## Triangles
        # Print smallest triangles possible with three unique points
        addi    a0, zero, 16                    # Row1
        addi    a1, zero, 1                     # Col1
        addi    a2, zero, 16                    # Row2
        addi    a3, zero, 2                     # Col2
        addi    a4, zero, 17                    # Row3
        addi    a5, zero, 1                     # Col3
        add     a6, zero, s3                    # Color
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16                   
        addi    a1, zero, 4                    
        addi    a2, zero, 16                   
        addi    a3, zero, 5                   
        addi    a4, zero, 17                
        addi    a5, zero, 5                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16                   
        addi    a1, zero, 8                    
        addi    a2, zero, 17                   
        addi    a3, zero, 8                   
        addi    a4, zero, 17                
        addi    a5, zero, 7                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16                   
        addi    a1, zero, 10                    
        addi    a2, zero, 17                   
        addi    a3, zero, 11                   
        addi    a4, zero, 17                
        addi    a5, zero, 10                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        # Print other small triangles
        addi    a0, zero, 16                   
        addi    a1, zero, 13                    
        addi    a2, zero, 16                   
        addi    a3, zero, 15                   
        addi    a4, zero, 17                
        addi    a5, zero, 14                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16                   
        addi    a1, zero, 17                    
        addi    a2, zero, 17                   
        addi    a3, zero, 18                   
        addi    a4, zero, 18                
        addi    a5, zero, 17                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        addi    a0, zero, 18                   
        addi    a1, zero, 20                    
        addi    a2, zero, 17                   
        addi    a3, zero, 22                   
        addi    a4, zero, 18                
        addi    a5, zero, 22                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        addi    a0, zero, 16                   
        addi    a1, zero, 24                    
        addi    a2, zero, 16                   
        addi    a3, zero, 26                   
        addi    a4, zero, 17                
        addi    a5, zero, 24                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle

        ## Larger triangles
        addi    a0, zero, 21                   
        addi    a1, zero, 1                    
        addi    a2, zero, 21                   
        addi    a3, zero, 13                   
        addi    a4, zero, 35                
        addi    a5, zero, 7                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        addi    a0, zero, 23                   
        addi    a1, zero, 4                    
        addi    a2, zero, 23                   
        addi    a3, zero, 10                   
        addi    a4, zero, 27                
        addi    a5, zero, 7                     
        add     a6, zero, s4                    
        jal     GLIR_PrintTriangle

        addi    a0, zero, 21                   
        addi    a1, zero, 16                    
        addi    a2, zero, 21                   
        addi    a3, zero, 26                   
        addi    a4, zero, 24                
        addi    a5, zero, 26                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle
        addi    a0, zero, 26                   
        addi    a1, zero, 16                    
        addi    a2, zero, 26                   
        addi    a3, zero, 26                   
        addi    a4, zero, 35                
        addi    a5, zero, 16                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle

        addi    a0, zero, 21                   
        addi    a1, zero, 47                    
        addi    a2, zero, 25                   
        addi    a3, zero, 33                   
        addi    a4, zero, 35                
        addi    a5, zero, 28                     
        add     a6, zero, s3                    
        jal     GLIR_PrintTriangle

        ## Fill empty space with long diagonal lines
        # 89 is 90th column
        addi    s5, zero, 49                    # Col1
        addi    s6, zero, 35                    # Row2
        
        fillLoop:
        # Wait 0.1 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 100
        ecall
        # If Col1 <= 89 || Row2 >= 0
        addi     t0, s2, -1                     # Last column is ScreenColumns
                                                # - 1
        bge     t0, s5, fill
        blt     s6, zero, doneFill
        fill:
        addi    a0, zero, 0                     # Row1
        add     a1, s5, zero                    # Col1
        add     a2, s6, zero                    # Row2
        addi    a3, zero, 89                    # Col2
        add     a4, zero, s3                    # Color
        jal     GLIR_PrintLine
        addi    s5, s5, 2                       # Col1 = Col1 + 2
        addi    s6, s6, -2                      # Row2 = Row2 + -2
        jal     zero, fillLoop

        doneFill:
        ## Layering shapes into a design
        # Draw a rectangle in remaining space up to the edges of the screen
        addi    a0, zero, 37                    # Row
        addi    a1, zero, 0                     # Col
        addi    t0, s1, -37                     # Number of spaces from current
                                                # row to last row
        addi    a2, t0, -1                      # Height = ScreenRows - 1
        addi    a3, s2, -1                      # Width = ScreenCols - 1
        add     a4, zero, s3                    # Color
        jal     GLIR_PrintRect

        # Load some colors to use to distinguish different prints
        addi    s7, zero, 2                     # s7 = Green

        # 'Animate' a ball rolling down a hill
        # Print a hill
        addi    a0, zero, 41                    # Row1
        addi    a1, zero, 88                    # Col1
        addi    a2, zero, 48                    # Row2
        addi    a3, zero, 88                    # Col2
        addi    a4, zero, 48                    # Row3
        addi    a5, zero, 75                    # Col3
        add     a6, zero, s7                    # Color
        jal     GLIR_PrintTriangle
        # Print the ball
        li      a0, 39                          # Row
        li      a1, 87                          # Col
        li      a2, 1                           # Radius
        # Byte code; REMEMBER this is little endian so now it's [empty]
        # [bgcolor] [fgcolor] [printing code]
        # 0x07 is the color Silver
        li      a3, 0x00070003
        jal     ra, GLIR_PrintCircle
        # Reset that position and print new position
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        li      a0, 39                       
        li      a1, 87                         
        li      a2, 1                           
        li      a3, 0x00000001
        jal     ra, GLIR_PrintCircle
        li      a0, 39                       
        li      a1, 86                         
        li      a2, 1                           
        li      a3, 0x00070003
        jal     ra, GLIR_PrintCircle
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        # Continue animation
        li      a0, 39                       
        li      a1, 86                         
        li      a2, 1                           
        li      a3, 0x00000001
        jal     ra, GLIR_PrintCircle
        li      a0, 40                       
        li      a1, 86                         
        li      a2, 1                           
        li      a3, 0x00070003
        jal     ra, GLIR_PrintCircle
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        li      a0, 40                       
        li      a1, 86                         
        li      a2, 1                           
        li      a3, 0x00000001
        jal     ra, GLIR_PrintCircle
        li      a0, 40                       
        li      a1, 85                         
        li      a2, 1                           
        li      a3, 0x00070003
        jal     ra, GLIR_PrintCircle
        # Wait 0.5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 500
        ecall
        li      a0, 40                       
        li      a1, 85                         
        li      a2, 1                           
        li      a3, 0x00000001
        jal     ra, GLIR_PrintCircle
        li      a0, 40                       
        li      a1, 84                         
        li      a2, 1                           
        li      a3, 0x00070003
        jal     ra, GLIR_PrintCircle


        # Wait 5 seconds
        la      a7, _SLEEP
        lw      a7, 0(a7)
        li      a0, 50000
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
        addi    sp, sp, 32
        lw      s0, 0(sp)
        addi    sp, sp, 4

        # Exit program
        la      a7, _EXIT
        lw      a7, 0(a7)
        ecall