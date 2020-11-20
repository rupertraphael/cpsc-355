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
define(m_r, x19)		// number of rows/documents
define(n_r, x20)		// number of columns/words
define(table_alloc_r, x21)	// number of bytes needed to allocate for table		
define(count_cells_r, x22)	// number of cells n*m
define(cell_r, x23)		// current cell
define(offset_r, x24)		// offset to get a table cell's address
define(randNum_r, x25)		// generated random number
define(struct_alloc_r, x26)	// number of bytes needed to allocate for the struct
define(row_r, x27)		// current row
define(col_r, x28)		// current column

define(table_base_r, x26)	// base address of table

define(maxword_r, x21)		// number of bytes needed to allocate for table		
define(maxoccur_r, x22)		// number of cells n*m
define(struct_base_r, x23)	// current cell
define(occur_r, x25)		// generated random number
define(size_r, x9)

TABLE_ELEMENT_SIZE = 8
table_s = 0
ALIGN = -16
MAX_RAND = 16 - 1

	.balign 4
	.global main

main:	stp	x29,	x30,	[sp, -16]!
	mov	x29,	sp

	mov	x9,	3	// exact number of args
	cmp	x0,	x9	// if not equal,
	b.ne	invalidargs	// prompt invalid args and exit

	ldr	x0, [x1, 8]	// load second argument to x0
	ldr	n_r, [x1, 16]	// load third argument into register for number of columns
	bl	atoi		// convert second argument into int
	mov	m_r,	x0	// second argument is number of rows

	
	mov	x0,	n_r	// set third command line arg as first argument for atoi
	bl 	atoi		// convert to int
	mov	n_r,	x0	// third command line argument is number of columns

	mov	x9,	4	// minimum number of rows/columns
	mov	x10,	16	// maximum number of rows/columns
	cmp	m_r,	x9	// if less than minimum number of rows,
	b.lt	invalidargs	// prompt invalid args and exit
	cmp	m_r,	x10	// if more than max number of rows,
	b.gt	invalidargs	// prompt invalid args and exit
	cmp	n_r,	x9	// if less than min number of cols
	b.lt	invalidargs     // prompt invalid args and exit
	cmp	n_r,	x10     // if more than max number of rows
	b.gt	invalidargs     // prompt invalid args and exit

	// Seed rand
	mov	x0,	0
	bl	time
	bl	srand


	// Calculate required space for table
	// number of bytes allocated for table = 8 * m * n
	mul	count_cells_r,		m_r,		n_r		// number of rows * number of columns	
	sub	table_alloc_r,		xzr,		count_cells_r	// negate table_alloc_r
	lsl	table_alloc_r,		table_alloc_r,	3		// multiply by 8
	and	table_alloc_r,		table_alloc_r,	-16		// make sure table_alloc_r is divisible by 16

	// Calculate required space for struct
	// number of bytes for struct = m * (8 + 8) = m * 2 * 8 = m * 16 
	lsl	struct_alloc_r,		m_r,	4			// number of rows * 16	
	sub	struct_alloc_r,		xzr,	struct_alloc_r		// make struct_alloc negative
	and	struct_alloc_r,		struct_alloc_r,	-16		// make sure allocation is divisible by 16

	add	sp,	sp,	table_alloc_r			// allocate space for table
	add	sp,	sp,	struct_alloc_r			// allocate space for struct

	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
	bl	generateTable

	add	x0,	x29,	table_s				// set first arg as table's base address
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
	add	x3,	x0,	table_alloc_r			// last arg is struct's base address (struct is right after table)
	bl	generateStruct

	mov	cell_r,		xzr		// start at cell 0
	mov	offset_r,	table_s		// offset for x29 - start at table base address
	mov	col_r,		xzr		// start column at 0
	mov	row_r,		xzr		// start row at 0

print:
	ldr	randNum_r,	[x29, offset_r]		// load table cell value at offset

	// print occurence at current table cell
	ldr	x0,	=theD			// load string format and use as argument for printing
	mov	x1,	randNum_r		// use loaded table cell value as argument for printing
	bl	printf

	sub     offset_r,       offset_r,       TABLE_ELEMENT_SIZE	// decrement offset by table element size

inc_col:
	add	col_r,		col_r,		1			// increment column number to keep track of current table cell column

        cmp     col_r,         n_r					// if column < number of columns:
        b.lt    print							// loop

	// otherwise, reset column to 0, go to new row
	ldr	x0,	=linebreak					// for new row,
	bl	printf							// print line break
	mov	col_r,	xzr						// reset column to 0
	
	add 	row_r,		row_r,		1			// increment row number to keep track of current table cell row
	cmp	row_r,		m_r					// if row < number of rows:
	b.lt	print							// loop

	// At this point column = number of columns and row = number of rows
	// this row and column does not exist in the table so the printing loop
	// has been completely executed. 	

	ldr	x0,	=linebreak
	bl	printf

	ldr	x0,	=header
	bl	printf

	mov	row_r,		xzr			// start at row 0
printStruct:
	ldr	x0,	=linebreak
	bl	printf

	lsl	offset_r,	row_r,	4
	sub	offset_r,	table_alloc_r, offset_r	// offset for max word = table_alloc_r - (row * 2) * 8 
	ldr	x3,		[x29, offset_r]		// load max word
	
	mul	offset_r,	row_r,		n_r		// offset = row * numcols
	add	offset_r,	offset_r,	x3		// offset = (offset + maxword) * 8 where maxword is a col index		
	lsl	offset_r,	offset_r,	3
	sub	offset_r,	xzr,		offset_r
	ldr 	x4,		[x29, offset_r]	

	lsl	offset_r,	row_r,	1
	add	offset_r,	offset_r,	1	// offset for max freq = table_alloc_r - (row * 2 + 1) * 8
	lsl	offset_r,	offset_r,	3	// multiply by 8 (as per above)
	sub	offset_r,	table_alloc_r,	offset_r// subtract offset from table_alloc which is the offset (from fp) base address for struct

	ldr	x2,	[x29, offset_r]			// load highest frequency(struct.frequency) for printing

	ldr	x0,	=struct				// load string format for printing struct
	mov	x1,	row_r				// add row/document number to printing
	bl	printf					// print struct info

	add	row_r,	row_r,	1			// keep track of current row
	cmp	row_r,	m_r				// if row < number of rows,	
	b.lt	printStruct				// loop printing struct data

	ldr	x0,	=linebreak
	bl	printf		

	// Deallocate space used by table
	sub	sp,	sp,	table_alloc_r		// deallocate memory used for table
	sub	sp,	sp,	struct_alloc_r		// deallocate memory used for struct
	b	exitMain				// jump to exit; dont prompt invalid args
			

invalidargs:
	ldr	x0,	=error
	bl	printf	

exitMain:	
	ldp	x29,	x30,	[sp], 16
	ret

// macro for calculating needed memory and address offsets
// for temporarily storing caller-saved registers
// into memory
define(
	init_subr_x,
	`alloc = -(16 + 8 * 9) & -16
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
	x28_s = x27_s + 8'
)

// macro for storing caller-saved register values 
// into memory
// Ideally should be used after initializing subroutine FP
// and before using caller-saved registers
define(
	str_x,	
	`str	x19,	[x29, x19_s]
	str	x20,	[x29, x20_s]
	str	x21,	[x29, x21_s]
	str	x22,	[x29, x22_s]
	str	x23,	[x29, x23_s]
	str	x24,	[x29, x24_s]
	str	x25,	[x29, x25_s]
	str	x26,	[x29, x26_s]
	str	x27,	[x29, x27_s]
	str	x28,	[x29, x28_s]'
)

// macro for restoring caller-saved register
// values from memory
// Ideally should be used before restoring frame pointer and stack pointer and returning.
define(
	ldr_x,
	`ldr	x19,	[x29, x19_s]
	ldr	x20,	[x29, x20_s]
	ldr	x21,	[x29, x21_s]
	ldr	x22,	[x29, x22_s]
	ldr	x23,	[x29, x23_s]
	ldr	x24,	[x29, x24_s]
	ldr	x25,	[x29, x25_s]
	ldr	x26,	[x29, x26_s]
	ldr	x27,	[x29, x27_s]
	ldr	x28,	[x29, x28_s]'
)

init_subr_x()

// generateTable(&table, numrows, numcols)
// populates random occurences (0 - 15) into the given table
generateTable:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp

	str_x()		// store caller-saved register values

	mov	table_base_r,	x0	// get table base address from given arguments	

	mul	count_cells_r,		x1,	x2	 // calculate number of cells the table has
	
	mov	offset_r,	xzr		// start offset for table base address at 0
	mov	cell_r,		xzr		// start at cell 0 
loop:
	// Store random numbers in each table cell
	// First, we generate the random number
	bl	rand				// Generate random number
	mov	randNum_r,	x0

	and	randNum_r,	randNum_r,	MAX_RAND	// limit number from 0 - MAX_RAND		
	add	randNum_r,	randNum_r,	1		// number is now 1 - MAX_RAND + 1 (i.e. 1-16)

	str	randNum_r,	[table_base_r, offset_r]	// store number in array

	sub	offset_r,	offset_r,	TABLE_ELEMENT_SIZE	// keep track of offset for where to store number in stack
	add	cell_r,		cell_r,		1		// keep track of cell number

	// Loop until current cell number = number of cells
	cmp	cell_r,		count_cells_r		
	b.lt	loop
	
	ldr_x()	

	ldp	x29,	x30,	[sp], dealloc
	ret

init_subr_x()
alloc = (alloc - 8) & -16 	// will be allocating extra 8 bytes to store the size of current row
dealloc = -alloc
size_s = x28_s + 8		// position of size value relative to frame pointer 


// generateStruct(&table, numcols, numrows, &struct)
// populates an array of structs (with attrs word with highest frequency and highest frequency)
// each struct represents each document and by convention, their indices match
// e.g. structs[0] represents table[0]
generateStruct:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp

	str_x()
	str	xzr,	[x29, size_s]	// initialize size to 0

	mov	table_base_r,	x0	// get table base from args
	mov	m_r,		x1	// get number of rows from args
	mov	n_r,		x2	// get number of cols from args
	mov	struct_base_r,	x3	// get struct base from args			

	mov	row_r,		xzr	// start at row/doc 0
	mov	col_r,		xzr	// start at col/word 0
	mov	offset_r,	xzr	// start at 0 offset
	mov	maxword_r,	col_r	// highest frequency word is the first one, for now
	mov	maxoccur_r,	xzr	// highest frequency is zero, for now

structloop:
	// calculate table offset = (row * numcols + col) * 8
	mul	offset_r,	row_r,		n_r		// row * numcols
	add	offset_r,	offset_r,	col_r		// row * numcols + col
	lsl	offset_r,	offset_r,	3		// 8 * (rows * numcols + col )
	sub	offset_r,	xzr,		offset_r	// negate offset
	ldr	occur_r,	[table_base_r, offset_r]	// load occurence from table

	// to replace or not to replace max occurence and max word
	cmp	occur_r,	maxoccur_r	// don't replace max occurence
	b.le	addsize				// if current occurence isn't greater than max occurence
	mov	maxoccur_r,	occur_r		// set new max occurence	
	mov	maxword_r,	col_r		// set new word with highest occurence/frequency

addsize:
	// add to size for document
	ldr	size_r,		[x29, size_s]	
	add	size_r,		size_r,		occur_r		// add occurence to total size for document	
	str	size_r,		[x29, size_s]			// store size to memory

	add	col_r,	col_r,	1	// increment column
	
	cmp	col_r,	n_r	// if column < numcols, 
	b.lt	structloop	// loop
	mov	col_r,	xzr	// else reset column,

	// store index and frequency in struct
	// calculate offset for struct
	lsl	offset_r,	row_r,	4			// calculate offset for document index	
	sub	offset_r,	xzr,	offset_r		// make offset negative
	str	maxword_r,	[struct_base_r, offset_r]	// store document index to struct
	lsl	offset_r,	row_r,	1			// calculate offset for frequency
	add	offset_r,	offset_r,	1
	lsl	offset_r,	offset_r,	3
	sub	offset_r,	xzr,	offset_r		// make offset negative

	mov	x0,	maxoccur_r		// set maxoccur as first argument
	ldr	x1,	[x29, size_s]		// set size as second argument
	bl	calculateFrequency
	mov	maxoccur_r,	x0		// replace maxoccur with calculated frequency

	str	maxoccur_r,	[struct_base_r, offset_r]	// store frequency to struct

	mov	maxword_r,	xzr	// reset max word
	mov	maxoccur_r,	xzr	// reset max occurence
	str	xzr,		[x29, size_s] // reset size	
	mov 	size_r,		xzr

	// increment row
	add	row_r,	row_r,	1	

	// if row < numrows, loop 
	cmp	row_r,	m_r
	b.lt	structloop
	
	ldr_x()

	ldp	x29,	x30,	[sp], dealloc
	ret

init_subr_x()
// frequency = word occurences in doc * 100 / size of doc
// calculateFrequency(occurences, size)
calculateFrequency:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp

	str_x()

	mov	x9,	100

	// Multiply by 100
	mul	x0,	x0,	x9	
	// Divide
	udiv	x0,	x0,	x1

	ldr_x()

	ldp	x29,	x30,	[sp], dealloc
	ret
