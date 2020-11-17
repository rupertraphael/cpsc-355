// --------------------------------------------------------
// Author:
// Date:
// Description:
// --------------------------------------------------------

	.text
	theD: .string "%-6d"
	linebreak: .string "\n"	

				// Eventually, registers for:
		// number of rows/documents
		// number of columns/words
	// number of bytes needed to allocate for table		
	// number of cells n*m
		// current cell
		// offset to get a table cell's address
		// generated random number
	// base address of table
		// current row
		// current column

		// maximum occurence

TABLE_ELEMENT_SIZE = 8
table_s = -16
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
	lsl	x21,		x21,	4
	and	x21,		x21,	ALIGN
	add	sp,	sp,	x21

	// Calculate required space for struct
	// number of bytes for struct = 

	add	x0,	x29,	table_s
	mov	x1,	x19
	mov	x2,	x20
	bl	generateTable

	mov	x23,		xzr		// start at cell 0
	mov	x24,	table_s		// offset for x29 - start at table base address
	mov	x28,		xzr		// start column at 0
	mov	x27,		xzr		// start row at 0
	mov	x22,	xzr		// max occurence is set to 0

print:
	ldr	x25,	[x29, x24]		// load table cell value at offset

	// print occurence at current table cell
	ldr	x0,	=theD			// load string format and use as argument for printing
	mov	x1,	x25		// use loaded table cell value as argument for printing
	bl	printf

	sub     x24,       x24,       TABLE_ELEMENT_SIZE	// decrement offset by table element size

	// if table cell value is greater than
	// currently stored max occurence,
	// set it as the max occurence 
	cmp	x25,	x22
	b.le	inc_col				// otherwise, skip
	mov	x22,	x25	// set new max occurence

inc_col:
	add	x28,		x28,		1			// increment column number to keep track of current table cell column

        cmp     x28,         x20					// if column < number of columns:
        b.lt    print							// loop

	// otherwise, reset column to 0, go to new row
	ldr	x0,	=linebreak
	bl	printf
	mov	x28,	xzr
	
	ldr	x0,	=theD			// load string format and use as argument for printing
	mov	x1,	x22		// use loaded table cell value as argument for printing
	bl	printf
	mov	x22,	xzr		// new row, so set max occurence back to zero

	ldr	x0,	=linebreak
	bl	printf

	add 	x27,		x27,		1			// increment row number to keep track of current table cell row
	cmp	x27,		x19					// if row < number of rows:
	b.lt	print							// loop

	// At this point column = number of columns and row = number of rows
	// this row and column does not exist in the table so the printing loop
	// has been completely executed. 	

	// Deallocate space used by table
	sub	sp,	sp,	x21

exitMain:	ldp	x29,	x30,	[sp], 16
		ret








alloc = -(16 + 8 * 9) & -16
	dealloc = -alloc

	x19_s = 16
	x20_s = x19_s + 8
	x21_s = x20_s + 8 
	x22_s = x21_s + 8
	x23_s = x22_s + 8
	x24_s = x23_s + 8
	x25_s = x24_s + 8
	x26_s = x25_s + 8
	x27_s = x26_s + 8
	x28_s = x27_s + 8


// generateTable(&table, numrows, numcols)
generateTable:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp

	str	x19,	[x29, x19_s]
	str	x20,	[x29, x20_s]
	str	x21,	[x29, x21_s]
	str	x22,	[x29, x22_s]
	str	x23,	[x29, x23_s]
	str	x24,	[x29, x24_s]
	str	x25,	[x29, x25_s]
	str	x26,	[x29, x26_s]
	str	x27,	[x29, x27_s]
	str	x28,	[x29, x28_s]


	mov	x26,	x0		

	mul	x22,		x1,	x2
	
	mov	x27,		xzr
	mov	x28,		xzr
	mov	x24,	xzr
	mov	x23,		xzr
loop:
	// Store random numbers in each table cell
	// First, we generate the random number
	bl	rand				// Generate random number
	mov	x25,	x0

	and	x25,	x25,	MAX_RAND		

	str	x25,	[x26, x24]

	sub	x24,	x24,	TABLE_ELEMENT_SIZE
	add	x23,		x23,		1

	// Loop until current cell number = number of cells
	cmp	x23,		x22		
	b.lt	loop
	
	ldr	x19,	[x29, x19_s]
	ldr	x20,	[x29, x20_s]
	ldr	x21,	[x29, x21_s]
	ldr	x22,	[x29, x22_s]
	ldr	x23,	[x29, x23_s]
	ldr	x24,	[x29, x24_s]
	ldr	x25,	[x29, x25_s]
	ldr	x26,	[x29, x26_s]
	ldr	x27,	[x29, x27_s]
	ldr	x28,	[x29, x28_s]


	ldp	x29,	x30,	[sp], dealloc
	ret

// frequency = word occurences in doc * 100 / size of doc
// calculateFrequency(occurences, size)
calculateFrequency:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp

	str	x19,	[x29, x19_s]
	str	x20,	[x29, x20_s]
	str	x21,	[x29, x21_s]
	str	x22,	[x29, x22_s]
	str	x23,	[x29, x23_s]
	str	x24,	[x29, x24_s]
	str	x25,	[x29, x25_s]
	str	x26,	[x29, x26_s]
	str	x27,	[x29, x27_s]
	str	x28,	[x29, x28_s]


	// Multiply by 100

	// Divide

	// Store to x0

	ldr	x19,	[x29, x19_s]
	ldr	x20,	[x29, x20_s]
	ldr	x21,	[x29, x21_s]
	ldr	x22,	[x29, x22_s]
	ldr	x23,	[x29, x23_s]
	ldr	x24,	[x29, x24_s]
	ldr	x25,	[x29, x25_s]
	ldr	x26,	[x29, x26_s]
	ldr	x27,	[x29, x27_s]
	ldr	x28,	[x29, x28_s]


	ldp	x29,	x30,	[sp], dealloc
	ret
