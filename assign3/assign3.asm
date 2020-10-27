// --------------------------------------------------------
// Author: Rupert Raphael Amodia
// Date: October 26, 2020
// Description:	Multiply numbers -15 to 15 with randomly generated numbers 0-15
// --------------------------------------------------------

	define(multiplier_r, x27)
	define(multiplicand_r, x19)
	define(lsb_r, x20)		// nth least significant bit
	define(numbits_r, x21)		// number of bits.. 64 since we're using x registers
	define(bitpos_r, x22)		// current bit position during the multiplication process
	define(powof2_r, x23)		// we shall use this as an op2 for bitwise and when calculating lsb_r
	define(max_r, x24)		// multiplicand max value
	define(result_r, x25)		// stores result at bit position for bit multiplication
	define(sum_r, x26)		// sum of all results will eventually equal to the product
	define(end_r, x28)		// max multiplier value

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


	mov	end_r,		15	// we end at 15
	mov	multiplier_r,	-15	// we start at -15	
loop:
	cmp	multiplier_r,	end_r 	// loop until multiplier = 15
	b.gt	end

	// Generate multiplicand
	mov	max_r,	15
	bl	rand
	mov	multiplicand_r,	x0	
	and	multiplicand_r,	multiplicand_r,	max_r // similar to multiplicand % 16	

	mov	sum_r,		xzr 	// initialize sum as 0	
	mov	bitpos_r,	xzr	// start at least significant/right most bit
	mov	numbits_r,	64	// we're working with 64 bits


multiply:		
	cmp	bitpos_r,	numbits_r	// multiply until we get to bitpos 64 which doesn't exist anymore
	b.eq	answer

	mov	powof2_r,	1
	// Get multiplicand LSB
	lsl	powof2_r,	powof2_r,	bitpos_r
	and	lsb_r,		multiplicand_r,	powof2_r	// isolate the bit at bitpos since powof2 will have only 1 bit with a value of 1
	lsr	lsb_r,		lsb_r,		bitpos_r	// shift it to the right most pos
	
	cmp	lsb_r,	xzr
	
	// result is just 0 or the value of multiplier
	// depending on whether the bit at bitpos is 0 or 1. 
	b.eq	times0
	b	times1

aftertimes:
	lsl	result_r,	result_r,	bitpos_r	// algorithm says so; shift bits of result to the left one time
	add	sum_r,		sum_r,		result_r	// add result to sum.. eventually should give the product when bitpos = 63

	add	bitpos_r,	bitpos_r,	1		// go to next bit position

	b	multiply					// do it again!

times0:
	mov	result_r,	xzr				// result is 0
	b	aftertimes

times1:
	mov	result_r,	multiplier_r			// result is the value of multiplier cuz multiplier * 1
	b	aftertimes
	
// print answer
answer:		
	ldr	x0,	=theD
	mov	x1,	multiplier_r
	mov	x2,	multiplicand_r
	mov	x3,	sum_r	
	bl	printf

	add	multiplier_r,	multiplier_r,	1
	b	loop

end:
	ldp	x29,	x30,	[sp], 16
	ret
 
