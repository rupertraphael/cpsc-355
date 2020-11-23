// --------------------------------------------------------
// Author: 	Rupert Raphael Amodia
// Date:	November 18, 2020
// Description:	Simple emulation of search engine
// --------------------------------------------------------

	.text
	theD: 		.string "%-6d"
	header: 	.string	"Document\tHighest Frequency\tWord\tOccurence"
	struct:		.string "%5d\t%25d\t%4d\t%9d"
	error:		.string "Invalid arguments.\n"
	linebreak: 	.string "\n"	

				// Eventually, registers for:
		// number of rows/documents
		// number of columns/words
	// number of bytes needed to allocate for table		
	// number of cells n*m
		// current cell
		// offset to get a table cell's address
		// generated random number
	// number of bytes needed to allocate for the struct
		// current row
		// current column

	// base address of table

		// number of bytes needed to allocate for table		
		// number of cells n*m
	// current cell
		// generated random number






TABLE_ELEMENT_SIZE = 4
table_s = 0
ALIGN = -16
MAX_RAND = 16 - 1

	.balign 4
	.global main

main:	
	
	stp	x29,	x30,	[sp, -16]!
	mov	x29,	sp
	


	mov	x9,	3	// exact number of args
	cmp	x0,	x9	// if not equal,
	b.ne	invalidargs	// prompt invalid args and exit

	ldr	x0, [x1, 8]	// load second argument to x0
	ldr	x20, [x1, 16]	// load third argument into register for number of columns
	bl	atoi		// convert second argument into int
	mov	x19,	x0	// second argument is number of rows

	
	mov	x0,	x20	// set third command line arg as first argument for atoi
	bl 	atoi		// convert to int
	mov	x20,	x0	// third command line argument is number of columns

	mov	x9,	4	// minimum number of rows/columns
	mov	x10,	16	// maximum number of rows/columns
	cmp	x19,	x9	// if less than minimum number of rows,
	b.lt	invalidargs	// prompt invalid args and exit
	cmp	x19,	x10	// if more than max number of rows,
	b.gt	invalidargs	// prompt invalid args and exit
	cmp	x20,	x9	// if less than min number of cols
	b.lt	invalidargs     // prompt invalid args and exit
	cmp	x20,	x10     // if more than max number of rows
	b.gt	invalidargs     // prompt invalid args and exit

	// Seed rand
	mov	x0,	0
	bl	time
	bl	srand


	// Calculate required space for table
	// number of bytes allocated for table = 4 * m * n
	mul	x22,		x19,		x20		// number of rows * number of columns	
	sub	x21,		xzr,		x22	// negate x21
	lsl	x21,		x21,	2		// multiply by 4
	and	x21,		x21,	-16		// make sure x21 is divisible by 16

	add	sp,	sp,	x21			// allocate space for table

	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	x19					// second arg is number of rows
	mov	x2,	x20					// third arg is number of cols
	bl	initialize

	
	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	x19					// second arg is number of rows
	mov	x2,	x20					// third arg is number of cols
	bl	display

	ldr	x0,	=linebreak
	bl	printf

	ldr	x0,	=header
	bl	printf
	b 	exitMain

invalidargs:
	ldr	x0,	=error
	bl	printf	

exitMain:	
	sub	sp,	sp,	x21		// deallocate memory used for table

	
	ldp	x29,	x30,	[sp], 16
	ret
	


// macro for calculating needed memory and address offsets
// for temporarily storing caller-saved registers
// into memory


// macro for storing caller-saved register values 
// into memory
// Ideally should be used after initializing subroutine FP
// and before using caller-saved registers


// macro for restoring caller-saved register
// values from memory
// Ideally should be used before restoring frame pointer and stack pointer and returning.


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


// initialize(&table, numrows, numcols)
// populates random occurences (0 - 15) into the given table
initialize:
	
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
		// store caller-saved register values

	mov	x26,	x0	// get table base address from given arguments	

	mul	x22,		x1,	x2	 // calculate number of cells the table has
	
	mov	x24,	xzr		// start offset for table base address at 0
	mov	x23,		xzr		// start at cell 0 
loop:
	// Store random numbers in each table cell
	// First, we generate the random number
	bl	randomNum			// Generate random number
	mov	w25,	w0

	and	w25,	w25,	MAX_RAND	// limit number from 0 - MAX_RAND		
	add	w25,	w25,	1		// number is now 1 - MAX_RAND + 1 (i.e. 1-16)

	str	w25,	[x26, x24]	// store number in array

	sub	x24,	x24,	TABLE_ELEMENT_SIZE	// keep track of offset for where to store number in stack
	add	x23,		x23,		1		// keep track of cell number

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
				// reload caller-saved register values	

	
	ldp	x29,	x30,	[sp], dealloc
	ret
	


// randomNum(min, max)
randomNum:
	
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
		// store caller-saved register values

	bl	rand

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
				// reload caller-saved register values	
	
	ldp	x29,	x30,	[sp], dealloc
	ret
	


// display(&table, numrows, numcolumns)
display: 
	
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
		// store caller-saved register values

	mov	x26,	x0			// remember table base address
	mov	x24,	xzr			// start at 0 offset
	mov	x19,		x1			// init number of rows
	mov	x20,		x2			// init number of columns
	mov	x27,		xzr			// start at row 0
	mov 	x28,		xzr			// start at col 0

displayloop:

	ldr	w25,	[x26, x24]		// load table cell value at offset

	// print occurence at current table cell
	ldr	x0,	=theD			// load string format and use as argument for printing
	mov	w1,	w25		// use loaded table cell value as argument for printing
	bl	printf

	sub     x24,       x24,       TABLE_ELEMENT_SIZE	// decrement offset by table element size

inc_col:
	add	x28,		x28,		1			// increment column number to keep track of current table cell column

        cmp     x28,         x20					// if column < number of columns:
        b.lt    displayloop						// loop

	// otherwise, reset column to 0, go to new row
	ldr	x0,	=linebreak					// for new row,
	bl	printf							// print line break
	mov	x28,	xzr						// reset column to 0
	
	add 	x27,		x27,		1			// increment row number to keep track of current table cell row
	cmp	x27,		x19					// if row < number of rows:
	b.lt	displayloop						// loop

	// At this point column = number of columns and row = number of rows
	// this row and column does not exist in the table so the printing loop
	// has been completely executed. 	

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
				// reload caller-saved register values	

	
	ldp	x29,	x30,	[sp], dealloc
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

alloc = (alloc - 8) & -16 	// will be allocating extra 8 bytes to store the size of current row
dealloc = -alloc
size_s = x28_s + 8		// position of size value relative to frame pointer 

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


	mov	x9,	100

	// Multiply by 100
	mul	x0,	x0,	x9	
	// Divide
	udiv	x0,	x0,	x1

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
	

