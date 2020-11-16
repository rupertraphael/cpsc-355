// --------------------------------------------------------
// Author:
// Date:
// Description:
// --------------------------------------------------------

	.text
	theD: .string "%-3d\n"
	linebreak: .string "\n"	

				// Eventually, registers for:
		// number of rows/documents
		// number of columns/words
	// number of bytes needed to allocate for table		
	// number of cells n*m
		// current cell
		// offset to get a cell address

		// generated random number

TABLE_ELEMENT_SIZE = -8
ALIGN = -16
MAX_RAND = 16 - 1

	.balign 4
	.global main

main:	stp	x29,	x30,	[sp, -16]!
	mov	x29,	sp

	// Seed rand
	mov	x0,	0
	bl	time
	bl	srand

	// Temporarily set fixed m and n
	mov	x19,	4
	mov	x20,	4


	// Calculate required space for table
	// number of bytes allocated for table = 4 * m * n
	mul	x22,		x19,		x20
	sub	x21,		xzr,		x22
	lsl	x21,		x21,	3
	and	x21,		x21,	ALIGN
	add	sp,	sp,	x21

	mov	x23,		xzr
	mov	x24,	-8
store:
	// Store random numbers in each table cell
	// First, we generate the random number
	bl	rand				// Generate random number
	mov	x25,	x0

	and	x25,	x25,	MAX_RAND		


	str	x25,	[x29, x24]

	ldr	x0,	=theD
	ldr	x1,	[x29, x24]
	bl	printf

	add	x24,	x24,	TABLE_ELEMENT_SIZE
	add	x23,		x23,		1

	// Loop until current cell number = number of cells
	cmp	x23,		x22		
	b.lt	store
	
	ldr	x0,	=linebreak
	bl	printf

	mov	x23,		xzr
	mov	x24,	TABLE_ELEMENT_SIZE
print:
	ldr	x0,	=theD
	ldr	x1,	[x29, x24]
	bl	printf

	add     x24,       x24,       TABLE_ELEMENT_SIZE
        add     x23,         x23,         1


	// Loop until current cell number = number of cells
        cmp     x23,         x22
        b.lt    print
	

	// Deallocate space used by table
	sub	sp,	sp,	x21

exitMain:	ldp	x29,	x30,	[sp], 16
		ret
 
