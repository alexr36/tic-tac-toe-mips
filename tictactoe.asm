#*
# * ****************************************************************************
# * @file           : tictactoe.asm
# * @author         : Alex Rogoziński
# * @brief          : This is a simple Tic Tac Toe game implemented in MIPS 
# 					  assembly language.
# * ****************************************************************************
# *

#	TIC TAC TOE GAME
#
#	Saved registers:
#	$s0 - pointer to the current position on the board
#	$s1 - auxiliary pointer to the position on the board
#	$s2 - value of the player's move
#	$s3 - pointer to the turn
#	$s4 - move counter
#	$s5 - pointer to the offset (column/row) / (auxiliary value when traversing the board while checking for a win)
#	$s6 - id of the player who played the last round
#	$s7 - round counter (reversed)
#
#	Temporary registers:
#	$t0 - last return register value
#	$t6 - player wins counter
#	$t7 - computer wins counter
#	$t8 - draws counter
#	$t9 - rounds counter

.data

welcomeMsg: 	 .asciiz "\n========= TIC TAC TOE ========="
exitMsg:    	 .asciiz "\Exiting the game..."
playerWinMsg: 	 .asciiz "\nPlayer won!\n"
cpuWinMsg: 		 .asciiz "\Computer won!\n"
drawMsg: 		 .asciiz "\Draw!\n"
resultMsg: 		 .asciiz "\nResult: "
askForInputMsg:  .asciiz "\nEnter move (1-9): "
roundNumMsg: 	 .asciiz "\nRound number: "
askForRoundsMsg: .asciiz "\nNumber of rounds to play (1-5): "
invalidInputMsg: .asciiz "\nIvalid number of rounds entered.\n"
invalidMoveMsg:  .asciiz "\nSelected position on the board unavailable.\n"
playerSymbolMsg: .asciiz "\nPlayer symbol: O"
cpuSymbolMsg: 	 .asciiz "\nComputer symbol: X"
boardMsg: 	 	 .asciiz "\nBoard with field indices:\n"
roundMsg: 		 .asciiz "\nRound: "
turnMsg: 		 .asciiz "\n\nTurn: "
player: 		 .asciiz "Player\n"
cpu: 		     .asciiz "Computer\n"
draws: 		     .asciiz "\nDraws: "
playerWins: 	 .asciiz "\nPlayer: "
cpuWins: 		 .asciiz "\nComputer: "
sumUp: 			 .asciiz "\n\nSummary: "
newline: 		 .asciiz "\n"
space: 			 .asciiz " "

row1: 			 .asciiz "1|2|3"
row2: 			 .asciiz "4|5|6"
row3: 			 .asciiz "7|8|9"

board: 			 .space  9

.text

# -- Starting procedures -------------------------------------------------------

main:
	li $v0, 4		    			# Display welcome message
	la $a0, welcomeMsg
	syscall
	
	addi $t9, $t9, 1				# Set rounds counter to 1
	
	jal askForRounds				# Ask for number of rounds
	
continueGame:						# Continue point in case of more than one round
	jal roundNumberInfo				# Display information about the current round

	li $v0, 4		    			# Display board information
	la $a0, boardMsg
	syscall
	
	jal printBoardIds				# Display board with indices
	
	li $v0, 4		    			# Display player symbol information
	la $a0, playerSymbolMsg
	syscall
	
	li $v0, 4		    			# Display computer symbol information
	la $a0, cpuSymbolMsg
	syscall
	
	jal printNewline	
	j manageTurn					# Proceed to the next round
	
# -- Procedures for managing rounds --------------------------------------------
	
manageTurn:
	beq $s4, 9, draw				# If after 9 moves there is no winner -> it's a draw
	
	li $v0, 4		    			# Display message about whose turn it is
	la $a0, turnMsg
	syscall
	
	beq $s3, 1, playerTurn			# Check if it's the player's turn
	beq $s3, 2, cpuTurn				# Check if it's the computer's turn
	
playerTurn:							# Handle player's turn
	li $v0, 4
	la $a0, player
	syscall

	j playRound 
	
cpuTurn:							# Handle computer's turn
	li $v0, 4
	la $a0, cpu
	syscall
	
	jal cpuMove
	j saveInput
	
playRound:							# Main game management for player's turn
	jal askForInput					# Request input
	jal checkInput					# Verify input validity
	j saveInput						# Save input value
	
# -- Procedures for displaying the game board ----------------------------------
	
displayBoardStart:					# Start displaying the board
	li $s0, 0						# Set the current position pointer to the beginning of the board
	li $s1, 0						# Set the auxiliary pointer to the beginning of the board
	
	j displayLine					# Proceed to display a new line
	
displayLine:						# Display the current row of the board
	addi $s1, $s1, 3				# Increment the auxiliary pointer to determine the end of the row
	
	jal printNewline
	
	j displayBoard					# Proceed to the actual board display
	
displayBoard:						# Actual board display
	beq $s0, 9, lookForWin			# Check if there is a win after displaying all board positions
	beq $s0, $s1, displayLine		# Check if it's time to move to the next line
	
	move $t2, $s0					# Set the current position pointer on the board
	la $t1, board					# Load the current address of the board
	add $t1, $t1, $t2				# Shift the current board address to the value of the position pointer
	lb $t3, 0($t1)					# Load the current character from the board into register $t3, which will be analyzed
	
	beq $t3, 0, displayEmptySlot 	# Check which character should be displayed on the board
	beq $t3, 1, displayO
	beq $t3, 2, displayX
	
displayEmptySlot:					# Display empty slot symbol on the board
	li $v0, 11
	li $a0, 45 						# ASCII code for '-'
	syscall
	
	j addBorder
	
displayO:							# Display 'O' symbol on the board
	li $v0, 11		
	li $a0, 79 						# ASCII code for 'O'
	syscall
	
	j addBorder
	
displayX:							# Display 'X' symbol on the board
	li $v0, 11
	li $a0, 88 						# ASCII code for 'X'
	syscall
	
	j addBorder	
	
# -- Procedures for handling computer's move -----------------------------------		
	
cpuMove:							# Handling computer's move - it searches for the first empty spot on the board and fills it (fields sorted in ascending order by indices)
	li $t0, 0						# Set the pointer to the board position to the very beginning
	
findEmptySlot:						# Searching for an empty spot
	la $t1, board					# Load the current address of the board
	add $t1, $t1, $t0				# Increment/initialize the pointer to the current position on the board
	lb $t2, 0($t1)					# Load the value of the current position on the board into register $t2
	
	beqz $t2, foundEmptySlot		# Check if an empty spot has been found
	
	addi $t0, $t0, 1				# Increment the pointer to the board position
		
	blt $t0, 9, findEmptySlot		# If the pointer to the board position has not reached the end (has not exceeded the maximum value of 9)
	
	jr $ra
	
foundEmptySlot:						# Handling found empty spot
	move $s2, $t0					# Save the value of the found spot on the board to register $s2 (set as the value of the computer's move)
	
	jr $ra	
	
# -- Procedures for saving the move value on the board -------------------------

saveInput:
	addi $s4, $s4, 1				# Increment the move counter
	
	beq $s3, 1, saveO				# Check if it's the player's or computer's turn
	beq $s3, 2, saveX	
	
saveO:
	la $t1, board					# Load the current address of the board
	add $t1, $t1, $s2			 	# Shift the board address to the one indicated by the entered move	
	li $t2, 1						# Set the value pointer of the spot to 1 (player id)
	sb $t2, 0($t1)					# Save the value of register $t2 (player id) to the appropriate spot on the board
	li $s3, 2						# Change to computer's turn		
	
	j displayBoardStart				# Display the board
	
saveX:
	la $t1, board					# Load the current address of the board
	add $t1, $t1, $s2			 	# Shift the board address to the one indicated by the entered move
	li $t2, 2						# Set the value pointer of the spot to 2 (computer id)
	sb $t2, 0($t1)					# Save the value of register $t2 (computer id) to the appropriate spot on the board
	li $s3, 1						# Change to player's turn
	
	j displayBoardStart				# Display the board
	
# -- Procedures for handling win -----------------------------------------------
			
lookForWin:							# Start searching for a win
	bge $s4, 5, condition1			# If the move counter >= 5 -> proceed to check conditions
	
	j manageTurn					# Otherwise -> proceed to the next round without checking 	
	
condition1:							# Check diagonal 1-5-9
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 0						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (first place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)
	
	addi $t1, $t1, 4				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)
	
	addi $t1, $t1, 4				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, condition2		# If the value (1) is not equal to the value (2) -> check condition 2
	bne $t3, $t4, condition2		# If the value (2) is not equal to the value (3) -> check condition 2
	beqz $t2, condition2			# If the value (1) is equal to zero (empty spot) -> check condition 2
	
	j manageWin 					# Jump to manage win
	
condition2:							# Check diagonal 3-5-7
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 2						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (third place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)
	
	addi $t1, $t1, 2				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)
	
	addi $t1, $t1, 2				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, condition3		# If the value (1) is not equal to the value (2) -> check condition 3
	bne $t3, $t4, condition3		# If the value (2) is not equal to the value (3) -> check condition 3
	beqz $t2, condition3			# If the value (1) is equal to zero (empty spot) -> check condition 3
	
	j manageWin						# Jump to manage win
	
condition3:							# Check first column
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 0						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (first place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)	
	
	addi $t1, $t1, 3				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)
	
	addi $t1, $t1, 3				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, condition4		# If the value (1) is not equal to the value (2) -> check condition 4
	bne $t3, $t4, condition4		# If the value (2) is not equal to the value (3) -> check condition 4
	beqz $t2, condition4			# If the value (1) is equal to zero (empty spot) -> check condition 4
	
	j manageWin						# Jump to manage win
	
condition4:							# Check second column
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 1						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (second place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)
	
	addi $t1, $t1, 3				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)
	
	addi $t1, $t1, 3				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, condition5		# If the value (1) is not equal to the value (2) -> check condition 5
	bne $t3, $t4, condition5		# If the value (2) is not equal to the value (3) -> check condition 5
	beqz $t2, condition5			# If the value (1) is equal to zero (empty spot) -> check condition 5
	
	j manageWin						# Jump to manage win
	
condition5:							# Check third column
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 2						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (third place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)	
	
	addi $t1, $t1, 3				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)	
	
	addi $t1, $t1, 3				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, condition6		# If the value (1) is not equal to the value (2) -> check condition 6
	bne $t3, $t4, condition6		# If the value (2) is not equal to the value (3) -> check condition 6
	beqz $t2, condition6			# If the value (1) is equal to zero (empty spot) -> check condition 6
	
	j manageWin						# Jump to manage win
	
condition6:							# Check first row
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 0						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board 
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (first place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)
	
	addi $t1, $t1, 1				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)
	
	addi $t1, $t1, 1				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, condition7		# If the value (1) is not equal to the value (2) -> check condition 7
	bne $t3, $t4, condition7		# If the value (2) is not equal to the value (3) -> check condition 7
	beqz $t2, condition7			# If the value (1) is equal to zero (empty spot) -> check condition 7
	
	j manageWin						# Jump to manage win
	
condition7:							# Check second row
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 3						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (fourth place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)
	
	addi $t1, $t1, 1				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)
	
	addi $t1, $t1, 1				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, condition8		# If the value (1) is not equal to the value (2) -> check condition 8
	bne $t3, $t4, condition8		# If the value (2) is not equal to the value (3) -> check condition 8
	beqz $t2, condition8			# If the value (1) is equal to zero (empty spot) -> check condition 8
	
	j manageWin						# Jump to manage win
		
condition8:							# Check third row
	li $s6, 0						# Set the value of the player who played the last round to neutral (0)
	li $s5, 6						# Set the offset pointer (column/row)
	la $t1, board					# Load the current address of the board
	
	add $t1, $t1, $s5				# Shift the pointer of the place on the board to the appropriate starting value (seventh place)
	lb $t2, 0($t1)					# Load the current value of the place on the board indicated by the pointer (1)
	
	addi $t1, $t1, 1				# Increment the pointer
	lb $t3, 0($t1)					# Load the current value of the place on the board indicated by the pointer (2)
	
	addi $t1, $t1, 1				# Increment the pointer
	lb $t4, 0($t1)					# Load the current value of the place on the board indicated by the pointer (3)
	
	add $s6, $s6, $t2				# Update the player id
	
	bne $t2, $t3, manageTurn		# If the value (1) is not equal to the value (2) -> jump to manage turn
	bne $t3, $t4, manageTurn		# If the value (2) is not equal to the value (3) -> jump to manage turn
	beqz $t2, manageTurn			# If the value (1) is equal to zero (empty spot) -> jump to manage turn
	
	j manageWin						# Jump to manage win
																																					
# -- Procedures for displaying constant static elements ------------------------
	
printBoardIds:						# Displaying the board
	move $t0, $ra					# Saving the return register

	li $v0, 4						# Displaying the first row
	la $a0, row1
	syscall
	
	jal printNewline
	
	li $v0, 4						# Displaying the second row
	la $a0, row2
	syscall
	
	jal printNewline
	
	li $v0, 4						# Displaying the third row
	la $a0, row3
	syscall
	
	jal printNewline
	
	jr $t0	
	
printNewline:						# Displaying the newline character
	li $v0, 4
	la $a0, newline
	syscall
	
	jr $ra	
	
addBar:								# Displaying the bar on the board
	li $v0, 11
	li $a0, 124						# ASCII code for '|'
	syscall	
	
	jr $ra 
	
addBorder:							# Adding the internal border of the board	
	addi $s0, $s0, 1				# Incrementing the pointer of the place on the board
	bne $s0, $s1, addBar			# Displaying the bar ('|')
	j displayBoard					# Jumping to the actual board display		
	
# -- Procedures for determining the win ----------------------------------------
	
manageWin:							# Handling the win
	beq $s6, 1, playerWin			# Check if the player or the computer won
	beq $s6, 2, cpuWin	
	
playerWin:							# Handling the display of the player's win
	li $v0, 4
	la $a0, playerWinMsg
	syscall
	
	addi $t6, $t6, 1				# Incrementing the player's win counter
	
	jal playerWinSound
	
	j checkRemainingRounds			# Checking the number of remaining rounds
	
cpuWin:								# Handling the display of the computer's win
	li $v0, 4
	la $a0, cpuWinMsg
	syscall
	
	addi $t7, $t7, 1				# Incrementing the computer's win counter	
	
	jal cpuWinSound
	
	j checkRemainingRounds			# Checking the number of remaining rounds
	
draw:								# Handling the display of a draw
	li $v0, 4
	la $a0, drawMsg
	syscall	
	
	addi $t8, $t8, 1				# Incrementing the draw counter
	
	jal drawSound
	
	j checkRemainingRounds			# Checking the number of remaining rounds	
	
displayResults:						# Displaying the game results
	li $v0, 4
	la $a0, resultMsg
	syscall
	
	li $v0, 4						# Displaying the number of player wins
	la $a0, playerWins
	syscall
	
	li $v0, 1
	move $a0, $t6
	syscall
	
	li $v0, 4						# Displaying the number of computer wins
	la $a0, cpuWins
	syscall
	
	li $v0, 1
	move $a0, $t7
	syscall
	
	li $v0, 4						# Displaying the number of draws	
	la $a0, draws
	syscall
	
	li $v0, 1
	move $a0, $t8
	syscall
	
	li $v0, 4						# Displaying the final game result
	la $a0, sumUp
	syscall
	
	blt $t7, $t6, ultimatePlayerWin	# Checking if the player won
	blt $t6, $t7, ultimateCpuWin	# Checking if the computer won
	
	j ultimateDraw					# Otherwise -> draw
	
ultimatePlayerWin:					# Displaying information about the player winning the match
	li $v0, 4
	la $a0, playerWinMsg
	syscall
	
	jal playerWinSound
	
	j exit							# Exiting the program
	
ultimateCpuWin:						# Displaying information about the computer winning the match
	li $v0, 4
	la $a0, cpuWinMsg
	syscall
	
	jal cpuWinSound
	
	j exit							# Exiting the program	
	
ultimateDraw:						# Displaying information about the draw in the match
	li $v0, 4
	la $a0, drawMsg
	syscall
	
	jal drawSound
	
	j exit							# Exiting the program			
	
# -- Helper procedures ---------------------------------------------------------
	
exit:
	li $v0, 4						# Displaying the exit message
	la $a0, exitMsg
	syscall
	
	li $v0, 10		# Exiting the program
	syscall	
	
# -- Helper procedures for managing rounds -------------------------------------	
	
askForRounds:
	li $v0, 4						# Asking for the number of rounds to be played
	la $a0, askForRoundsMsg
	syscall

	li $v0, 5						# Getting the number of rounds from the keyboard
	syscall
	
	blt $v0, 1, invalidRoundsAmount # Checking if the entered rounds counter is within the appropriate range
	bgt $v0, 5, invalidRoundsAmount
	
	move $s7, $v0					# Saving the rounds counter
    
	jr $ra
	
checkRemainingRounds:				# Managing the rounds counter
	addi $s7, $s7, -1				# Decrementing the rounds counter
	
	bnez $s7, resetBoard			# If there are still rounds left -> reset the board
	
	j displayResults				# Otherwise -> go to game exit	
	
invalidRoundsAmount:				# Displaying information about invalid input
	li $v0, 4
	la $a0, invalidInputMsg
	syscall
	
	j main  	
	
roundNumberInfo:					# Displaying information about the round number
	li $v0, 4
	la $a0, roundMsg
	syscall	
	
	li $v0, 1						# Displaying the round number
	move $a0, $t9
	syscall
	
	jr $ra
	
# -- Helper procedures for managing the input value ----------------------------
	
askForInput:						# Asking for the player's move input
	li $v0, 4
	la $a0, askForInputMsg
	syscall
	
	li $v0, 5						# Getting the value from the keyboard
	syscall
	
	move $s2, $v0					# Saving the player's move value
	addi $s2, $s2, -1				# Adjusting the entered move value (appropriate offset, like array indices)
	
	jr $ra	
	
checkInput:
	la $t1, board					# Loading the current address of the board
	add $t1, $t1, $s2				# Adjusting the current board address to the pointer value of the position	
	lb $t2, 0($t1)					# Loading the freshly saved value into register $t2, whose content will be analyzed
	
	bnez $t2, invalidInputValue		# Checking if the entered value is within the appropriate range
	bge $s2, 9, invalidInputValue
	blt $s2, 0, invalidInputValue
	
	jr $ra							# If so -> proceed further
	
invalidInputValue:					# Displaying information about invalid move input
	li $v0, 4
	la $a0, invalidMoveMsg
	syscall
	
	j manageTurn	
	
# -- Helper procedures for clearing the board ----------------------------------	

resetBoard:							# Resetting the game board at the beginning of each round
	la $t0, board					# Loading the current address of the board
	li $t1, 0						# Setting register $t1 to the value of the beginning of the board
	li $t2, 9						# Setting the loop repetition counter
	
	addi $t9, $t9, 1				# Incrementing the rounds counter

resetLoop:
	sb $t1, 0($t0)					# Storing the value 0 (empty space) at the beginning of the board address
	addi $t0, $t0, 1				# Incrementing the board address pointer
	addi $t2, $t2, -1				# Decrementing the loop repetition counter
	bnez $t2, resetLoop				# If the loop repetition counter is not zero -> repeat the loop

	li $s3, 1						# Changing the turn to the player
	li $s4, 0						# Resetting the move counter

	j continueGame					# Continuing the game
	
# -- Helper procedures for managing sounds -------------------------------------

playerWinSound:						# Sound for player win
	li $v0, 33
	li $a0, 82
	li $a1, 150
	li $a2, 30
	li $a3, 100
	
	syscall
	
	li $v0, 33
	li $a0, 84
	li $a1, 400
	li $a2, 30
	li $a3, 100
	
	syscall
	
	jr $ra	
	
cpuWinSound:						# Sound for Computer win
	li $v0, 33
	li $a0, 82
	li $a1, 150
	li $a2, 30
	li $a3, 100
	
	syscall
	
	li $v0, 33
	li $a0, 80
	li $a1, 400
	li $a2, 30
	li $a3, 100
	
	syscall
	
	jr $ra	
	
drawSound:							# Sound for draw
	li $v0, 33
	li $a0, 82
	li $a1, 150
	li $a2, 30
	li $a3, 100
	
	syscall
	
	li $v0, 33
	li $a0, 82
	li $a1, 400
	li $a2, 30
	li $a3, 100
	
	syscall
	
	jr $ra					
	
				# END OF PROGRAM
