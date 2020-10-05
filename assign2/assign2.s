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

	mov	x25,	20			// max number of numbers/words
	mov	x24,	5			// min number of numbers/words

ask:
// Print instructions
	ldr	x0,	=instructions
	mov	x1,	x24
	mov	x2,	x25
	bl	printf
// Ask for number of words
	ldr	x0,	=question
	bl	printf

	ldr	x0,	=theD
	ldr	x1,	=varN
	bl	scanf

// Save user input into non-temp register
	ldr	x1,	=varN
	ldr	x28,	[x1]

	cmp	x28,	x25
	b.gt	ask
	cmp	x28,	x24
	b.lt	ask

// Start Loop
	mov	x27,	xzr			// x28 loop max
	mov 	x26,	xzr			// init size x26
	mov	x25,	xzr			// init max x25
	mov 	x24,	9			// init min x24
loop:
	cmp	x27,	x28
	b.eq	end	

	bl	rand				// Generate random number
	// Limit number from 0 - 9
	mov	x19,	x0			// x19 Random Number
	mov	x21,	10			// x21 divisor
	udiv	x20,	x19,	x21
	msub	x19,	x20,	x21,	x19	// x19 now 0-9		
	

	ldr 	x0,	=occurenceFor
	mov	x1,	x27
	mov	x2,	x19
	bl	printf

ifMax:
	cmp	x19,	x25
	b.le	ifMin
	mov	x25,	x19	

ifMin:
	cmp	x19,	x24
	b.ge	endIfMin
	mov	x24,	x19	

endIfMin:

	// Total Size (x26)
	add	x26,	x26,	x19		// add number to size

	add	x27,	x27,	1		// increment counter

	b	loop
	// Go again

end:
	mov	x23,	100			// store 100 in register

	// Calculate frequencies
	// highest
	mul	x25,	x25,	x23
	udiv	x25,	x25,	x26
	// lowest
	mul	x24,	x24,	x23
	udiv	x24,	x24,	x26

	ldr	x0,	=displayResult
	mov	x1,	x25
	mov	x2,	x24
	bl	printf	

exit:
	ldp	x29,	x30,	[sp], 16
	ret


	.data
	varN:		.int	0
