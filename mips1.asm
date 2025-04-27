.data
	boardBuffer: .space 1024  # Buffer for board contents
	fileContents: .space 1024  # Buffer for file contents
	rowNumBuffer: .space 3
	resultFile:   .asciiz "result.txt"
	fileWriteError: .asciiz "Error writing to result file\n"
	charX: .asciiz "X"
	charO: .asciiz "O"
    playerInput: .space 10
    board: .word '.':225
    newLine: .asciiz "\n"
    columnIndex: .asciiz "\n   0  1  2  3  4  5  6  7  8  9 10 11 12 13 14"
    space: .asciiz " "
   	messageError: .asciiz "\nInput is not valid, please try again"
   	playerOneWinMsg: .asciiz "\nPlayer X wins!\n"
	playerTwoWinMsg: .asciiz "\nPlayer O wins!\n"
	promptX: .asciiz "\nPlayer X's turn (row col): "
	promptO: .asciiz "\nPlayer O's turn (row col): "
	tie: .asciiz "\nTie!"




# ... (your existing data section remains the same)

.text
    # Initialize game
    jal printBoard           # Print initial board
    jal playerOne            # PlayerOne's turn
	li $s7, 225
    # Infinite loop for alternating between players
gameLoop:
    jal printBoard           # Print the board after PlayerOne's move
    jal playerTwo            # PlayerTwo's turn

    jal printBoard           # Print the board after PlayerTwo's move
    jal playerOne            # PlayerOne's turn again
    
    j gameLoop               # Continue the loop indefinitely (or until a win condition is added)

# PlayerOne's turn
playerOne:
    addi $sp, $sp, -4           # Save return address on stack
    sw $ra, 0($sp)

inputLoopPlayerOne:
    # Print prompt
    li $v0, 4
    la $a0, promptX
    syscall

    # Read input
    li $v0, 8
    la $a0, playerInput
    li $a1, 16
    syscall

    # Process input
    la $t0, playerInput
    
    # Read row (could be 1 or 2 digits)
    li $s0, 0                   # Initialize row
    lb $t1, 0($t0)              # First digit
    blt $t1, 48, inputError     # Check if digit
    bgt $t1, 57, inputError
    subi $t1, $t1, 48           # Convert to number
    add $s0, $s0, $t1
    
    # Check for second digit in row
    lb $t1, 1($t0)
    beq $t1, 32, singleDigitRow # If space, single digit row
    blt $t1, 48, inputError     # Check if digit
    bgt $t1, 57, inputError
    subi $t1, $t1, 48
    mul $s0, $s0, 10            # First digit * 10
    add $s0, $s0, $t1           # + second digit
    addi $t0, $t0, 1            # Move past second digit
    
singleDigitRow:
    addi $t0, $t0, 2            # Move past space
    
    # Read column (could be 1 or 2 digits)
    li $s1, 0                   # Initialize column
    lb $t1, 0($t0)              # First digit
    blt $t1, 48, inputError     # Check if digit
    bgt $t1, 57, inputError
    subi $t1, $t1, 48           # Convert to number
    add $s1, $s1, $t1
    
    # Check for second digit in column
    lb $t1, 1($t0)
    beq $t1, 10, singleDigitCol # If newline, single digit column
    blt $t1, 48, inputError     # Check if digit
    bgt $t1, 57, inputError
    subi $t1, $t1, 48
    mul $s1, $s1, 10            # First digit * 10
    add $s1, $s1, $t1           # + second digit
    
singleDigitCol:
    # Validate input range (0-14)
    blt $s0, 0, inputError
    bge $s0, 15, inputError
    blt $s1, 0, inputError
    bge $s1, 15, inputError

    # Call function to add symbol for PlayerOne (X)
    jal addSymbolX
    beq $s7 ,0, tieGame
    jal checkHorizontal
    bnez $v0, playerOneWin
    jal checkVertical
    bnez $v0, playerOneWin
    jal checkDiagonalDown
    bnez $v0, playerOneWin
    jal checkDiagonalUp
    bnez $v0, playerOneWin
    
    # Return address management after PlayerOne's turn
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# PlayerTwo's turn (similar to PlayerOne)
playerTwo:
    addi $sp, $sp, -4           # Save return address on stack
    sw $ra, 0($sp)

inputLoopPlayerTwo:
    # Print prompt
    li $v0, 4
    la $a0, promptO
    syscall

    # Read input
    li $v0, 8
    la $a0, playerInput
    li $a1, 16
    syscall

    # Process input
    la $t0, playerInput
    
    # Read row (could be 1 or 2 digits)
    li $s0, 0                   # Initialize row
    lb $t1, 0($t0)              # First digit
    blt $t1, 48, inputError2     # Check if digit
    bgt $t1, 57, inputError2
    subi $t1, $t1, 48           # Convert to number
    add $s0, $s0, $t1
    
    # Check for second digit in row
    lb $t1, 1($t0)
    beq $t1, 32, singleDigitRowTwo # If space, single digit row
    blt $t1, 48, inputError2     # Check if digit
    bgt $t1, 57, inputError2
    subi $t1, $t1, 48
    mul $s0, $s0, 10            # First digit * 10
    add $s0, $s0, $t1           # + second digit
    addi $t0, $t0, 1            # Move past second digit
    
singleDigitRowTwo:
    addi $t0, $t0, 2            # Move past space
    
    # Read column (could be 1 or 2 digits)
    li $s1, 0                   # Initialize column
    lb $t1, 0($t0)              # First digit
    blt $t1, 48, inputError2    # Check if digit
    bgt $t1, 57, inputError2
    subi $t1, $t1, 48           # Convert to number
    add $s1, $s1, $t1
    
    # Check for second digit in column
    lb $t1, 1($t0)
    beq $t1, 10, singleDigitColTwo # If newline, single digit column
    blt $t1, 48, inputError2     # Check if digit
    bgt $t1, 57, inputError2
    subi $t1, $t1, 48
    mul $s1, $s1, 10            # First digit * 10
    add $s1, $s1, $t1           # + second digit
    
singleDigitColTwo:
    # Validate input range (0-14)
    blt $s0, 0, inputError2
    bge $s0, 15, inputError2
    blt $s1, 0, inputError2
    bge $s1, 15, inputError2

    # Call function to add symbol for PlayerTwo (O)
    jal addSymbolO
    beq $s7 ,0, tieGame
    jal checkHorizontal
    bnez $v0, playerTwoWin
    jal checkVertical
    bnez $v0, playerTwoWin
    jal checkDiagonalDown
    bnez $v0, playerTwoWin
    jal checkDiagonalUp
    bnez $v0, playerTwoWin
    
    # Return address management after PlayerTwo's turn
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Function to add symbol for PlayerX (PlayerOne's symbol 'X')
addSymbolX:
    # Calculate index in the 2D array (row * 15 + col)
    mul $t1, $s0, 15             # (row) * 15
    add $t1, $t1, $s1            # (row) * 15 + column
    mul $t1, $t1, 4              # (row * 15 + col) * 4 (word address)

    lw $t2, board($t1)           # Load the value from the board at calculated index

    bne $t2, 46, inputError   # If the cell is not empty, go to inputError

    # Load 'X' into $t2 and store it in the board
    la $t9, charX
    lb $t2, 0($t9)               # Load ASCII value for 'X'
    sw $t2, board($t1)           # Store 'X' in the board at the calculated index
	subi $s7, $s7, 1			 # reduces the total number of avaialble cells
    jr $ra                       # Return to caller (in this case, playerOne)

# Function to add symbol for PlayerO (PlayerTwo's symbol 'O')
addSymbolO:
    # Calculate index in the 2D array (row * 15 + col)
    mul $t1, $s0, 15             # (row) * 15
    add $t1, $t1, $s1            # (row) * 15 + column
    mul $t1, $t1, 4              # (row * 15 + col) * 4 (word address)

    lw $t2, board($t1)           # Load the value from the board at calculated index

    bne $t2, 46, inputError   # If the cell is not empty, go to inputError

    # Load 'O' into $t2 and store it in the board
    la $t9, charO
    lb $t2, 0($t9)               # Load ASCII value for 'O'
    sw $t2, board($t1)           # Store 'O' in the board at the calculated index
	subi $s7, $s7, 1			 # reduces the total number of avaialble cells
    jr $ra                       # Return to caller (in this case, playerTwo)

inputError:
    li $v0, 4
    la $a0, messageError         # Load error message
    syscall                      # Print error message

    j playerOne                  # Go back to input again
    
    li $v0, 10
    syscall

inputError2:
    li $v0, 4
    la $a0, messageError         # Load error message
    syscall                      # Print error message

    j playerTwo                	# Go back to input again
    
    li $v0, 10
    syscall

printBoard:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Print column headers
    li $v0, 4
    la $a0, newLine
    syscall
    li $v0, 4
    la $a0, columnIndex
    syscall
    li $v0, 4
    la $a0, newLine
    syscall

    li $t0, 0              # t0 = row counter (0..14)
row_loop:
    bge $t0, 15, endPrintBoard

    # Print row number
    li $v0, 1
    move $a0, $t0
    syscall

    # Print spaces based on row number (1 for >=10, 2 for <10)
    li $v0, 4
    la $a0, space
    syscall
    blt $t0, 10, print_extra_space
    j row_continue_space

print_extra_space:
    li $v0, 4
    la $a0, space
    syscall

row_continue_space:
    li $t1, 0              # t1 = column counter (0..14)
column_loop:
    bge $t1, 15, next_row

    # Calculate index = (row * 15 + col) * 4 (word address)
    mul $t2, $t0, 15
    add $t2, $t2, $t1
    sll $t2, $t2, 2

    lw $t3, board($t2)     # load board value into $t3 
    
    # Print the board value
    li $v0, 11
    move $a0, $t3
    syscall 
    
    # Print spaces - consistent 2 spaces after each character
    li $v0, 4
    la $a0, space
    syscall
    la $a0, space
    syscall

    addi $t1, $t1, 1
    j column_loop

next_row:
    # Print newline after each row
    li $v0, 4
    la $a0, newLine
    syscall

    addi $t0, $t0, 1
    j row_loop

endPrintBoard:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
   
checkHorizontal:
    # Input: $s0 = row, $s1 = col
    # Output: $v0 = 1 if 5 in a row horizontally, 0 otherwise
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)

    li $v0, 1               # Start with win assumption
    li $t0, 0               # Counter for consecutive symbols
    move $t1, $s1           # Current column (start at input col)
    
    # Determine current player symbol
    la $t9, charX
    lb $s2, 0($t9)          # Load 'X'
    la $t9, charO
    lb $s3, 0($t9)          # Load 'O'
    
    # Check which player we're checking for
    mul $t2, $s0, 15
    add $t2, $t2, $s1
    sll $t2, $t2, 2
    lw $t3, board($t2)
    beq $t3, $s2, checkXHorizontal
    beq $t3, $s3, checkOHorizontal
    j noHorizontalWin

checkXHorizontal:
    li $t4, 0               # Left counter
    move $t5, $s1           # Column index
    
    # Check to the left
    leftCheck:
        blt $t5, 0, rightCheck  # Stop if out of bounds
        mul $t6, $s0, 15
        add $t6, $t6, $t5
        sll $t6, $t6, 2
        lw $t7, board($t6)
        bne $t7, $s2, rightCheck
        addi $t4, $t4, 1
        addi $t5, $t5, -1
        j leftCheck
    
    # Check to the right
    rightCheck:
        move $t5, $s1
        addi $t5, $t5, 1
        rightLoop:
            bge $t5, 15, endHorizontalCheck
            mul $t6, $s0, 15
            add $t6, $t6, $t5
            sll $t6, $t6, 2
            lw $t7, board($t6)
            bne $t7, $s2, endHorizontalCheck
            addi $t4, $t4, 1
            addi $t5, $t5, 1
            j rightLoop
    
    endHorizontalCheck:
        bge $t4, 5, horizontalWin
        j noHorizontalWin

checkOHorizontal:
    # Same logic as checkXHorizontal but for 'O'
    li $t4, 0               # Left counter
    move $t5, $s1           # Column index
    
    # Check to the left
    leftCheckO:
        blt $t5, 0, rightCheckO
        mul $t6, $s0, 15
        add $t6, $t6, $t5
        sll $t6, $t6, 2
        lw $t7, board($t6)
        bne $t7, $s3, rightCheckO
        addi $t4, $t4, 1
        addi $t5, $t5, -1
        j leftCheckO
    
    # Check to the right
    rightCheckO:
        move $t5, $s1
        addi $t5, $t5, 1
        rightLoopO:
            bge $t5, 15, endHorizontalCheckO
            mul $t6, $s0, 15
            add $t6, $t6, $t5
            sll $t6, $t6, 2
            lw $t7, board($t6)
            bne $t7, $s3, endHorizontalCheckO
            addi $t4, $t4, 1
            addi $t5, $t5, 1
            j rightLoopO
    
    endHorizontalCheckO:
        bge $t4, 5, horizontalWin
        j noHorizontalWin

horizontalWin:
    li $v0, 1
    j endHorizontal

noHorizontalWin:
    li $v0, 0

endHorizontal:
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    addi $sp, $sp, 12
    jr $ra

checkVertical:
    # Input: $s0 = row, $s1 = col
    # Output: $v0 = 1 if 5 in a row vertically, 0 otherwise
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)

    li $v0, 1               # Start with win assumption
    li $t0, 0               # Counter for consecutive symbols
    
    # Determine current player symbol
    la $t9, charX
    lb $s2, 0($t9)          # Load 'X'
    la $t9, charO
    lb $s3, 0($t9)          # Load 'O'
    
    # Check which player we're checking for
    mul $t2, $s0, 15
    add $t2, $t2, $s1
    sll $t2, $t2, 2
    lw $t3, board($t2)
    beq $t3, $s2, checkXVertical
    beq $t3, $s3, checkOVertical
    j noVerticalWin

checkXVertical:
    li $t4, 0               # Up counter
    move $t5, $s0           # Row index
    
    # Check upwards
    upCheck:
        blt $t5, 0, downCheck
        mul $t6, $t5, 15
        add $t6, $t6, $s1
        sll $t6, $t6, 2
        lw $t7, board($t6)
        bne $t7, $s2, downCheck
        addi $t4, $t4, 1
        addi $t5, $t5, -1
        j upCheck
    
    # Check downwards
    downCheck:
        move $t5, $s0
        addi $t5, $t5, 1
        downLoop:
            bge $t5, 15, endVerticalCheck
            mul $t6, $t5, 15
            add $t6, $t6, $s1
            sll $t6, $t6, 2
            lw $t7, board($t6)
            bne $t7, $s2, endVerticalCheck
            addi $t4, $t4, 1
            addi $t5, $t5, 1
            j downLoop
    
    endVerticalCheck:
        bge $t4, 5, verticalWin
        j noVerticalWin

checkOVertical:
    # Same logic as checkXVertical but for 'O'
    li $t4, 0               # Up counter
    move $t5, $s0           # Row index
    
    # Check upwards
    upCheckO:
        blt $t5, 0, downCheckO
        mul $t6, $t5, 15
        add $t6, $t6, $s1
        sll $t6, $t6, 2
        lw $t7, board($t6)
        bne $t7, $s3, downCheckO
        addi $t4, $t4, 1
        addi $t5, $t5, -1
        j upCheckO
    
    # Check downwards
    downCheckO:
        move $t5, $s0
        addi $t5, $t5, 1
        downLoopO:
            bge $t5, 15, endVerticalCheckO
            mul $t6, $t5, 15
            add $t6, $t6, $s1
            sll $t6, $t6, 2
            lw $t7, board($t6)
            bne $t7, $s3, endVerticalCheckO
            addi $t4, $t4, 1
            addi $t5, $t5, 1
            j downLoopO
    
    endVerticalCheckO:
        bge $t4, 5, verticalWin
        j noVerticalWin

verticalWin:
    li $v0, 1
    j endVertical

noVerticalWin:
    li $v0, 0

endVertical:
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    addi $sp, $sp, 12
    jr $ra


checkDiagonalDown:
    # Checks diagonal \ (top-left to bottom-right)
    # Input: $s0 = row, $s1 = col
    # Output: $v0 = 1 if 5 in a row diagonally, 0 otherwise
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)

    # Determine current player symbol
    la $t9, charX
    lb $s2, 0($t9)          # Load 'X'
    la $t9, charO
    lb $s3, 0($t9)          # Load 'O'
    
    # Check which player we're checking for
    mul $t2, $s0, 15
    add $t2, $t2, $s1
    sll $t2, $t2, 2
    lw $t3, board($t2)
    beq $t3, $s2, checkXDiagonalDown
    beq $t3, $s3, checkODiagonalDown
    j noDiagonalDownWin

checkXDiagonalDown:
    li $t4, 1               # Count includes current position
    move $t5, $s0           # Row index
    move $t6, $s1           # Column index
    
    # Check up-left direction
    upLeftLoop:
        addi $t5, $t5, -1
        addi $t6, $t6, -1
        blt $t5, 0, downRightCheck
        blt $t6, 0, downRightCheck
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s2, downRightCheck
        addi $t4, $t4, 1
        j upLeftLoop
    
    # Check down-right direction
    downRightCheck:
        move $t5, $s0
        move $t6, $s1
    downRightLoop:
        addi $t5, $t5, 1
        addi $t6, $t6, 1
        bge $t5, 15, endDiagonalDownCheck
        bge $t6, 15, endDiagonalDownCheck
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s2, endDiagonalDownCheck
        addi $t4, $t4, 1
        j downRightLoop
    
    endDiagonalDownCheck:
        bge $t4, 5, diagonalDownWin
        j noDiagonalDownWin

checkODiagonalDown:
    # Same logic for 'O'
    li $t4, 1               # Count includes current position
    move $t5, $s0           # Row index
    move $t6, $s1           # Column index
    
    # Check up-left direction
    upLeftLoopO:
        addi $t5, $t5, -1
        addi $t6, $t6, -1
        blt $t5, 0, downRightCheckO
        blt $t6, 0, downRightCheckO
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s3, downRightCheckO
        addi $t4, $t4, 1
        j upLeftLoopO
    
    # Check down-right direction
    downRightCheckO:
        move $t5, $s0
        move $t6, $s1
    downRightLoopO:
        addi $t5, $t5, 1
        addi $t6, $t6, 1
        bge $t5, 15, endDiagonalDownCheckO
        bge $t6, 15, endDiagonalDownCheckO
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s3, endDiagonalDownCheckO
        addi $t4, $t4, 1
        j downRightLoopO
    
    endDiagonalDownCheckO:
        bge $t4, 5, diagonalDownWin
        j noDiagonalDownWin

diagonalDownWin:
    li $v0, 1
    j endDiagonalDown

noDiagonalDownWin:
    li $v0, 0

endDiagonalDown:
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    addi $sp, $sp, 12
    jr $ra

checkDiagonalUp:
    # Checks diagonal / (bottom-left to top-right)
    # Input: $s0 = row, $s1 = col
    # Output: $v0 = 1 if 5 in a row diagonally, 0 otherwise
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s2, 4($sp)
    sw $s3, 8($sp)

    # Determine current player symbol
    la $t9, charX
    lb $s2, 0($t9)          # Load 'X'
    la $t9, charO
    lb $s3, 0($t9)          # Load 'O'
    
    # Check which player we're checking for
    mul $t2, $s0, 15
    add $t2, $t2, $s1
    sll $t2, $t2, 2
    lw $t3, board($t2)
    beq $t3, $s2, checkXDiagonalUp
    beq $t3, $s3, checkODiagonalUp
    j noDiagonalUpWin

checkXDiagonalUp:
    li $t4, 1               # Count includes current position
    move $t5, $s0           # Row index
    move $t6, $s1           # Column index
    
    # Check down-left direction
    downLeftLoop:
        addi $t5, $t5, 1
        addi $t6, $t6, -1
        bge $t5, 15, upRightCheck
        blt $t6, 0, upRightCheck
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s2, upRightCheck
        addi $t4, $t4, 1
        j downLeftLoop
    
    # Check up-right direction
    upRightCheck:
        move $t5, $s0
        move $t6, $s1
    upRightLoop:
        addi $t5, $t5, -1
        addi $t6, $t6, 1
        blt $t5, 0, endDiagonalUpCheck
        bge $t6, 15, endDiagonalUpCheck
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s2, endDiagonalUpCheck
        addi $t4, $t4, 1
        j upRightLoop
    
    endDiagonalUpCheck:
        bge $t4, 5, diagonalUpWin
        j noDiagonalUpWin

checkODiagonalUp:
    # Same logic for 'O'
    li $t4, 1               # Count includes current position
    move $t5, $s0           # Row index
    move $t6, $s1           # Column index
    
    # Check down-left direction
    downLeftLoopO:
        addi $t5, $t5, 1
        addi $t6, $t6, -1
        bge $t5, 15, upRightCheckO
        blt $t6, 0, upRightCheckO
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s3, upRightCheckO
        addi $t4, $t4, 1
        j downLeftLoopO
    
    # Check up-right direction
    upRightCheckO:
        move $t5, $s0
        move $t6, $s1
    upRightLoopO:
        addi $t5, $t5, -1
        addi $t6, $t6, 1
        blt $t5, 0, endDiagonalUpCheckO
        bge $t6, 15, endDiagonalUpCheckO
        mul $t7, $t5, 15
        add $t7, $t7, $t6
        sll $t7, $t7, 2
        lw $t8, board($t7)
        bne $t8, $s3, endDiagonalUpCheckO
        addi $t4, $t4, 1
        j upRightLoopO
    
    endDiagonalUpCheckO:
        bge $t4, 5, diagonalUpWin
        j noDiagonalUpWin

diagonalUpWin:
    li $v0, 1
    j endDiagonalUp

noDiagonalUpWin:
    li $v0, 0

endDiagonalUp:
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    addi $sp, $sp, 12
    jr $ra
    

# ... (your existing data section remains the same)

# Modified win/tie functions to include board printing:


playerOneWin:
    # First print to console
    jal printBoard
    li $v0, 4
    la $a0, playerOneWinMsg
    syscall
    
    # Prepare file contents
    jal prepareFileContentsWithBoard
    la $t0, fileContents
    la $t1, playerOneWinMsg
    jal appendToBuffer
    
    # Write to file
    jal writeToResultFile
    
    li $v0, 10
    syscall

playerTwoWin:
    # First print to console
    jal printBoard
    li $v0, 4
    la $a0, playerTwoWinMsg
    syscall
    
    # Prepare file contents
    jal prepareFileContentsWithBoard
    la $t0, fileContents
    la $t1, playerTwoWinMsg
    jal appendToBuffer
    
    # Write to file
    jal writeToResultFile
    
    li $v0, 10
    syscall

tieGame:
    # First print to console
    li $v0, 4
    la $a0, tie
    syscall
    
    # Prepare file contents
    jal prepareFileContentsWithBoard
    la $t0, fileContents
    la $t1, tie
    jal appendToBuffer
    
    # Write to file
    jal writeToResultFile
    
    li $v0, 10
    syscall

# New helper functions:

prepareFileContentsWithBoard:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # First get the board string
    jal getBoardAsString
    
    # Copy board to fileContents
    la $t0, fileContents
    la $t1, boardBuffer
copyBoardLoop:
    lb $t2, 0($t1)
    beqz $t2, doneCopyBoard
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j copyBoardLoop
doneCopyBoard:
    
    # Add newlines after board
    li $t2, '\n'
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

appendToBuffer:
    # $t0 = current position in buffer
    # $t1 = message to append
appendLoop:
    lb $t2, 0($t1)
    beqz $t2, doneAppend
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j appendLoop
doneAppend:
    sb $zero, 0($t0)  # null terminate
    jr $ra

getBoardAsString:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, boardBuffer
    
    # Copy column headers
    la $t1, columnIndex
copyHeaderLoop:
    lb $t2, 0($t1)
    beqz $t2, doneHeader
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j copyHeaderLoop
doneHeader:
    
    # Add newline
    li $t2, '\n'
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    
    # Now copy each row
    li $t3, 0              # row counter
boardRowLoop:
    bge $t3, 15, doneBoardCopy
    
    # Add row number
    addi $t2, $t3, 48      # convert to ASCII
    blt $t3, 10, singleDigit
    # Two-digit number
    li $t4, '1'
    sb $t4, 0($t0)
    addi $t0, $t0, 1
    addi $t2, $t2, -10
singleDigit:
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    
    # Add spaces
    li $t2, ' '
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    blt $t3, 10, addExtraSpace
    j spaceDone
addExtraSpace:
    sb $t2, 0($t0)
    addi $t0, $t0, 1
spaceDone:
    
    # Now copy row contents
    li $t4, 0              # column counter
boardColLoop:
    bge $t4, 15, nextBoardRow
    
    # Get board value
    mul $t5, $t3, 15
    add $t5, $t5, $t4
    sll $t5, $t5, 2
    lw $t6, board($t5)
    sb $t6, 0($t0)
    addi $t0, $t0, 1
    
    # Add spaces
    li $t2, ' '
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    
    addi $t4, $t4, 1
    j boardColLoop
    
nextBoardRow:
    # Add newline
    li $t2, '\n'
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    
    addi $t3, $t3, 1
    j boardRowLoop
    
doneBoardCopy:
    sb $zero, 0($t0)  # null terminate
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Existing file writing function (unchanged)
writeToResultFile:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Open file for writing
    li $v0, 13
    la $a0, resultFile
    li $a1, 1        # 1 for write (create if doesn't exist)
    li $a2, 0        # mode is ignored
    syscall
    bltz $v0, fileError  # if file descriptor is negative, error
    
    move $s6, $v0    # save the file descriptor
    
    # Write to file
    li $v0, 15
    move $a0, $s6
    la $a1, fileContents
    la $a2, 1024     # maximum number of characters to write
    syscall
    bltz $v0, fileError  # if write failed
    
    # Close file
    li $v0, 16
    move $a0, $s6
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

fileError:
    li $v0, 4
    la $a0, fileWriteError
    syscall
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra