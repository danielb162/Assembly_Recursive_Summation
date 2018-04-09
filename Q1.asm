# COMP 273 - Assignment 4
# Author: Daniel Busuttil
# ID: 260608427
# Date: 2nd April 2018 - 7th April 2018
# Registers used: $v0, $a0, $a1, $t0, $t1, $t2, $s0, $s1, $s2, $s3
# Description:
#	This program is designed to mimic a C-program which rescursively sums a series of numbers
#	in an array of 10 words. Registers are used in the following manner:
#		$v0: Used to return values up the stack once base-case is reached during tail-recursion
#		$a0: Used during recursion to store the address of array[i] onto the stack at 0($sp)
#		$a1: Used during recursion to store the address of array[n-1] onto the stack at 4($sp)
#
#		$t0: Stores the word '10', used as upper limit for I/O loop to populate word data structure
#		$t1: Used in I/O loop to store the address of array[i]
#		$t2: Used during tail-recursion to load the word at 0($sp) (i.e. at array[i])
#
#		$s0: Represents the variable 'i' from the C-program
#		$s1: Represents the variable 'sum' from the C-program
#		$s2: Contains the addres of array[0]

# Data segment
.data
	array: .space 40 # Uninitialized 'array' of 10 ints
	prompt: .asciiz "enter a number: " # Equivalent of the printf statement
	fin_print: .asciiz "the sum is " # Post for-loop printf statement

# Code segment
.text
.globl __start # Indicate to OS where to run our program from

# Load/init our various variable into their registers
__start:
	# Load our variables into registers:
	li $s0, 0		# Variable 'i', init at 0
	li $s1, 0		# Variable 'sum', init at 0
	la $s2, array		# Represents start of array
	li $t0, 10		# Upper limit of the for loop
	la $t1, array		# Used to track the location (in memory) of 'array[i]'

# C equiavalent of the main method (before we begin recursion)
main:
	# Beginning of our loop to read input into 'array':
	beq $s0, $t0, pre_sum	# Exit condition: i == 10
	
	# Print statement to prompt the user for input:
	la $a0, prompt		# String to prompt the user to enter a number
	li $v0, 4		# Tell the OS to use library code 4 (print a string)
	syscall
	
	# Scanf equivalent:
	li $v0, 5		# Ask for user input
	syscall
	sw $v0, ($t1)		# Save result from $v0 into $t1, i.e. into 'array[i]' 
	
	# End of for-loop control flow:
	addi $s0, $s0, 1	# Increment i for control flow
	# Moving through array word-many bytes at a time (in step with i):
	add $t1, $s0, $s0	# $t1 = i * 2
	add $t1, $t1, $t1	# $t1 = i * 4 -> final offset
	add $t1, $t1, $s2	# Add offset to array base
	
	# Begin next loop iteration:
	j main

# Setup some variables before we enter recursion:
pre_sum:
	li $v0, 0		# 'Reset' $v0 to equal 0
	move $a0, $s2		# Start recursion with $a0 = array[0], i.e. address of array[0]
	move $a1, $t1		# N.b. $t1 = $s2 + 40 bytes at end of 'main loop'

# Once we finish reading 10 ints into array:
sumPt1:
	subi $sp, $sp, 12	# We make space for 3 registers
	sw $a0, 0($sp)		# Function call params, -> a
	sw $a1, 4($sp)		# Function call params, -> last
	sw $ra, 8($sp)		# To remember the return address of our caller
	bne $a0, $a1, sumPt2	# Recur again if a != last
	lw $t2, -4($a0)		# -> $t2 = *last
	add $v0, $v0, $t2	# -> Return *last
	addi $sp, $sp, 12	# We pop 3 from the stack
	jr $ra

sumPt2:
	addi $a0, $a0, 4	# -> a + 1
	jal sumPt1		# Recur another time
	# Load variables into registers (from the stack) once we return from recursion:
	lw $a0, 0($sp)
	lw $ra, 8($sp)
	# Check if we should keep tail-recurring
	beq $ra, $zero, fin_rec	# If $ra == 0, then we have finished all recursion
	lw $t2, -4($a0)		# -> $t2 = *a
	addi $sp, $sp, 12	# Once loaded we want to pop 3 words from stack
	add $v0, $v0, $t2	# Add the result of recursion to 'result'
	
	jr $ra			# Go back up the stack (to sumPt2)

# After 'sum-recursion' finishes:
fin_rec:
	move $s1, $v0		# Move result of recursion into $t2
	li $v0, 4
	la $a0, fin_print	# Print final print statement
	syscall
	
	li $v0, 1
	move $a0, $s1		# Print result of summation
	syscall

# Exit our program
exit:
	# Hasta la vista~
	li $v0, 10		# Tell OS to use library 10 (exit program)
	syscall 		# Call library function