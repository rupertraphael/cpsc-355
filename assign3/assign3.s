// --------------------------------------------------------
// Author:
// Date:
// Description:
// --------------------------------------------------------

	
	
	
	
	
	
	
	
	
	

	.text
	theD: .string "\n%d x %d = %d\n"
	lsb: .string "bitpos: %d lsb: %d\n"

	.balign 4
	.global main


main:
	stp	x29,	x30,	[sp, -16]!
	mov	x29,	sp

	mov	x0,	0
	bl	time
	bl	srand

	mov	x28,		15
	mov	x27,	-15	
loop:
	cmp	x27,	x28
	b.gt	end

	// Generate multiplicand
	mov	x24,	15
	bl	rand
	mov	x19,	x0
	and	x19,	x19,	x24	

	mov	x26,		xzr 	// initialize sum as 0	
	mov	x22,	xzr
	mov	x21,	64


multiply:		
	cmp	x22,	x21
	b.eq	answer

	mov	x23,	1
	// Get multiplicant LSB
	lsl	x23,	x23,	x22
	and	x20,		x19,	x23	// isolate the bit at bitpos
	lsr	x20,		x20,		x22	// shift it to the right most pos
	
	cmp	x20,	xzr
	b.eq	times0
	b	times1

aftertimes:
	lsl	x25,	x25,	x22
	add	x26,		x26,		x25	

	add	x22,	x22,	1

	b	multiply

times0:
	mov	x25,	xzr
	b	aftertimes

times1:
	mov	x25,	x27
	b	aftertimes	
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
 
