// --------------------------------------------------------
// Author: Rupert Raphael Amodia
// Date:
// Description:
//	Asks users for N number of words, 
//	generates N numbers as occurences each word,
//	and returns the highest and lowest frequencies. 
// --------------------------------------------------------

	.text
	instructions: .string "Number of words must be between %d-%d (inclusive).\n"
	question: .string "How many words do you want? "
	theD: .string "%d"
	occurenceFor: .string "Occurence for word %d: %d\n"
	displayResult: .string "Highest and lowest frequencies, respectively: %d, %d\n"

	define(randomNumber_r, x19)
	define(numerator_r, x20)
	define(divisor_r, x21)
	define(multiplier_r, x23)
	define(min_r, x24)	// Use for min allowed number of random numbers
				// and min occurence
	define(max_r, x25)	// Use for max allowed number of random numbers
				// and max occurence
	define(size_r, x26)
	define(loopCounter_r, x27)
	define(numbersCount_r, x28)

	.balign 4
	.global main

main:
	stp	x29,	x30,	[sp, -16]!
	mov	x29,	sp

// Seed
	mov	x0,	xzr
	bl	time
	bl	srand
// End Seed

	mov	max_r,	20			// max number of numbers/words
	mov	min_r,	5			// min number of numbers/words

ask:
// Print instructions
	ldr	x0,	=instructions
	mov	x1,	min_r
	mov	x2,	max_r
	bl	printf
// Ask for number of words
	ldr	x0,	=question
	bl	printf

	ldr	x0,	=theD
	ldr	x1,	=varN
	bl	scanf

// Save user input into non-temp register
	ldr	x1,	=varN
	ldr	numbersCount_r,	[x1]

	cmp	numbersCount_r,	max_r
	b.gt	ask
	cmp	numbersCount_r,	min_r
	b.lt	ask

// Start Loop
	mov	loopCounter_r,	xzr			// numbersCount_r_r loop max
	mov 	size_r,	xzr			// init size size_r
	mov	max_r,	xzr			// init max max_r
	mov 	min_r,	9			// init min min_r

	b	pretest	

loop:
	bl	rand				// Generate random number
	// Limit number from 0 - 9
	mov	randomNumber_r,	x0			// randomNumber_r Random Number
	mov	divisor_r,	10			// divisor_r divisor
	udiv	numerator_r,	randomNumber_r,	divisor_r
	msub	randomNumber_r,	numerator_r,	divisor_r,	randomNumber_r	// randomNumber_r now 0-9		
	

	ldr 	x0,	=occurenceFor
	mov	x1,	loopCounter_r
	mov	x2,	randomNumber_r
	bl	printf

ifMax:
	cmp	randomNumber_r,	max_r
	b.le	ifMin
	mov	max_r,	randomNumber_r	

ifMin:
	cmp	randomNumber_r,	min_r
	b.ge	endIfMin
	mov	min_r,	randomNumber_r	

endIfMin:

	// Total Size (size_r)
	add	size_r,	size_r,	randomNumber_r		// add number to size

	add	loopCounter_r,	loopCounter_r,	1		// increment counter

pretest:
	cmp	loopCounter_r,	numbersCount_r

	b.le	loop	// Go again if loopCounter_r <= numbersCount_r


	mov	multiplier_r,	100			// store 100 (% multiplier) in register

	// Calculate frequencies
	// highest
	mul	max_r,	max_r,	multiplier_r
	udiv	max_r,	max_r,	size_r
	// lowest
	mul	min_r,	min_r,	multiplier_r
	udiv	min_r,	min_r,	size_r

	// Display highest and lowest frequencies
	ldr	x0,	=displayResult
	mov	x1,	max_r
	mov	x2,	min_r
	bl	printf	

exit:
	ldp	x29,	x30,	[sp], 16
	ret


	.data
	varN:		.int	0
