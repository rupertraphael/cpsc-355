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
define(randNum_r, w25)		// generated random number
define(struct_alloc_r, x26)	// number of bytes needed to allocate for the struct
define(row_r, x27)		// current row
define(col_r, x28)		// current column

define(table_base_r, x26)	// base address of table

define(maxword_r, x21)		// number of bytes needed to allocate for table		
define(maxoccur_r, x22)		// number of cells n*m
define(struct_base_r, x23)	// current cell
define(occur_r, x25)		// generated random number
define(size_r, x9)

define(
	startfunction, 
	`
	stp	x29,	x30,	[sp, $1]!
	mov	x29,	sp
	'
)

define(
	endfunction,
	`
	ldp	x29,	x30,	[sp], $1
	ret
	'
)

TABLE_ELEMENT_SIZE = 4
table_s = 0
ALIGN = -16
MAX_RAND = 16 - 1

	.balign 4
	.global main

main:	
	startfunction(-16)

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
	// number of bytes allocated for table = 4 * m * n
	mul	count_cells_r,		m_r,		n_r		// number of rows * number of columns	
	sub	table_alloc_r,		xzr,		count_cells_r	// negate table_alloc_r
	lsl	table_alloc_r,		table_alloc_r,	2		// multiply by 4
	and	table_alloc_r,		table_alloc_r,	-16		// make sure table_alloc_r is divisible by 16

	add	sp,	sp,	table_alloc_r			// allocate space for table

	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
	bl	initialize

	
	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
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
	sub	sp,	sp,	table_alloc_r		// deallocate memory used for table

	endfunction(16)

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

// initialize(&table, numrows, numcols)
// populates random occurences (0 - 15) into the given table
initialize:
	startfunction(alloc)

	str_x()		// store caller-saved register values

	mov	table_base_r,	x0	// get table base address from given arguments	

	mul	count_cells_r,		x1,	x2	 // calculate number of cells the table has
	
	mov	offset_r,	xzr		// start offset for table base address at 0
	mov	cell_r,		xzr		// start at cell 0 
loop:
	// Store random numbers in each table cell
	// First, we generate the random number
	bl	randomNum			// Generate random number
	mov	randNum_r,	w0

	and	randNum_r,	randNum_r,	MAX_RAND	// limit number from 0 - MAX_RAND		
	add	randNum_r,	randNum_r,	1		// number is now 1 - MAX_RAND + 1 (i.e. 1-16)

	str	randNum_r,	[table_base_r, offset_r]	// store number in array

	sub	offset_r,	offset_r,	TABLE_ELEMENT_SIZE	// keep track of offset for where to store number in stack
	add	cell_r,		cell_r,		1		// keep track of cell number

	// Loop until current cell number = number of cells
	cmp	cell_r,		count_cells_r		
	b.lt	loop
	
	ldr_x()				// reload caller-saved register values	

	endfunction(dealloc)

// randomNum(min, max)
randomNum:
	startfunction(alloc)
	str_x()		// store caller-saved register values

	bl	rand

	ldr_x()				// reload caller-saved register values	
	endfunction(dealloc)

// display(&table, numrows, numcolumns)
display: 
	startfunction(alloc)

	str_x()		// store caller-saved register values

	mov	table_base_r,	x0			// remember table base address
	mov	offset_r,	xzr			// start at 0 offset
	mov	m_r,		x1			// init number of rows
	mov	n_r,		x2			// init number of columns
	mov	row_r,		xzr			// start at row 0
	mov 	col_r,		xzr			// start at col 0

displayloop:

	ldr	randNum_r,	[table_base_r, offset_r]		// load table cell value at offset

	// print occurence at current table cell
	ldr	x0,	=theD			// load string format and use as argument for printing
	mov	w1,	randNum_r		// use loaded table cell value as argument for printing
	bl	printf

	sub     offset_r,       offset_r,       TABLE_ELEMENT_SIZE	// decrement offset by table element size

inc_col:
	add	col_r,		col_r,		1			// increment column number to keep track of current table cell column

        cmp     col_r,         n_r					// if column < number of columns:
        b.lt    displayloop						// loop

	// otherwise, reset column to 0, go to new row
	ldr	x0,	=linebreak					// for new row,
	bl	printf							// print line break
	mov	col_r,	xzr						// reset column to 0
	
	add 	row_r,		row_r,		1			// increment row number to keep track of current table cell row
	cmp	row_r,		m_r					// if row < number of rows:
	b.lt	displayloop						// loop

	// At this point column = number of columns and row = number of rows
	// this row and column does not exist in the table so the printing loop
	// has been completely executed. 	

	ldr_x()				// reload caller-saved register values	

	endfunction(dealloc)



init_subr_x()
alloc = (alloc - 8) & -16 	// will be allocating extra 8 bytes to store the size of current row
dealloc = -alloc
size_s = x28_s + 8		// position of size value relative to frame pointer 

init_subr_x()
// frequency = word occurences in doc * 100 / size of doc
// calculateFrequency(occurences, size)
calculateFrequency:
	startfunction(alloc)

	str_x()

	mov	x9,	100

	// Multiply by 100
	mul	x0,	x0,	x9	
	// Divide
	udiv	x0,	x0,	x1

	ldr_x()

	endfunction(dealloc)
