// --------------------------------------------------------
// Author: Rupert Raphael Amodia
// Date: October 26, 2020
// Description:	Multiply numbers -15 to 15 with randomly generated numbers 0-15
// --------------------------------------------------------

	
	
			// nth least significant bit
			// number of bits.. 64 since we're using x registers
			// current bit position during the multiplication process
			// we shall use this as an op2 for bitwise and when calculating x20
			// multiplicand max value
			// stores result at bit position for bit multiplication
			// sum of all results will eventually equal to the product
			// max multiplier value

	.text
	theD: .string "\n%d x %d = %d\n" // string format to print when displaying the answer multiplier x mulitplicand = sum (product)

	.balign 4
	.global main


main:
	stp	x29,	x30,	[sp, -16]!
	mov	x29,	sp

	// seed rand num generator
	mov	x0,	0
	bl	time
	bl	srand


	mov	x28,		15	// we end at 15
	mov	x27,	-15	// we start at -15	
loop:
	cmp	x27,	x28 	// loop until multiplier = 15
	b.gt	end

	// Generate multiplicand
	mov	x24,	15
	bl	rand
	mov	x19,	x0	
	and	x19,	x19,	x24 // similar to multiplicand % 16	

	mov	x26,		xzr 	// initialize sum as 0	
	mov	x22,	xzr	// start at least significant/right most bit
	mov	x21,	64	// we're working with 64 bits


multiply:		
	cmp	x22,	x21	// multiply until we get to bitpos 64 which doesn't exist anymore
	b.eq	answer

	mov	x23,	1
	// Get multiplicand LSB
	lsl	x23,	x23,	x22
	and	x20,		x19,	x23	// isolate the bit at bitpos since powof2 will have only 1 bit with a value of 1
	lsr	x20,		x20,		x22	// shift it to the right most pos
	
	cmp	x20,	xzr
	
	// result is just 0 or the value of multiplier
	// depending on whether the bit at bitpos is 0 or 1. 
	b.eq	times0
	b	times1

aftertimes:
	lsl	x25,	x25,	x22	// algorithm says so; shift bits of result to the left one time
	add	x26,		x26,		x25	// add result to sum.. eventually should give the product when bitpos = 63

	add	x22,	x22,	1		// go to next bit position

	b	multiply					// do it again!

times0:
	mov	x25,	xzr				// result is 0
	b	aftertimes

times1:
	mov	x25,	x27			// result is the value of multiplier cuz multiplier * 1
	b	aftertimes
	
// print answer
answer:		
	ldr	x0,	=theD
	mov	x1,	x27
	mov	x2,	x19
	mov	x3,	x26	
	bl	printf

	add	x27,	x27,	1
	b	loop

end:
	ldp	x29,	x30,	[sp], 16
	ret
 
