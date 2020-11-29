// --------------------------------------------------------
// Author: 	Rupert Raphael Amodia
// Date:	November 18, 2020
// Description:	Simple emulation of search engine
// --------------------------------------------------------

	.text
	theD: 		.string "%d"
	theS:		.string "%s\n"
	cell:		.string "%-6d"
	testint:	.string "%d\n"
	testfloat:	.string "%f\n"
	header: 	.string	"Document\tWord\tOccurences\tFrequency\n"
	askcolumn:	.string	"Which word? "
	askretrieve:	.string	"How many documents do you want to retrieve? "
	rowinfo:	.string "%5d\t%12d\t%10d\t%9.3f\n"
	error:		.string "Invalid arguments.\n"
	linebreak: 	.string "\n"	
	space:		.string " "
	comma:		.string ","
	logfile:	.string "assign5.log"


				// Eventually, registers for:
		// number of rows/documents
		// number of columns/words
	// number of bytes needed to allocate for table		
	// number of cells n*m
		// current cell
		// file descriptor
		// offset to get a table cell's address
	// number of top docs to retrieve
	// number of bytes needed to allocate for the indices array
		// current row
		// current column

		// generated random number

	// base address of table

		// number of bytes needed to allocate for table		
		// number of cells n*m
	// base for array of document indices
		// generated random number






// macro for loading an integer value from a 1D array into a given register
// load_int_from_array1d(&array_r, x27, value_wr)
// &array_r - base address of a 1D array in memory
// x27 - greater than or equal to 0
// value_wr - 32-bit register that will contain the value in the 1D array at given row

// macro for storing an integer value into a 1D array
// store_int_from_array1d(&array_r, x27, value_wr)
// &array_r - base address of a 1D array in memory
// x27 - greater than or equal to 0
// value_wr - 32-bit register that will contain the value in the 1D array at given row

// macro for loading an integer value from a 2D array into a given register
// load_int_from_array2d(&array_r, x27, x28, numcols_r, value_wr) 

// macro for storing an integer value into a 2D array
// store_int_from_array2d(&array_r, x27, x28, numcols_r, value_wr) 



TABLE_ELEMENT_SIZE = 4
table_s = 0
ALIGN = -16
MAX_RAND = 16 - 1

.balign 4
.global main

main:	

	stp	x29,	x30,	[sp, -32]!
	mov	x29,	sp
	


	cmp	x0,	3	// if argc < 3,
	b.lt	invalidargs	// prompt invalid args and exit

	cmp	x0,	4	// if argc > 4	
	b.gt	invalidargs	// prompt invalid args and exit

	ldr	x19, 	[x1, 8]		// load second argument to x0
	ldr	x20, 	[x1, 16]	// load third argument into register for number of columns
	mov	w23,	wzr		// initialize file descriptor to 0

	store_filenamepointer:
	cmp	x0,	3
	b.eq	store_args

	// open file
	mov     w0,     -100
	ldr	x1,	[x1, 24]
	mov     w2,     wzr
	mov     x8,     56
	svc     0
	cmp     w0,     0
	mov	w23,	w0
	b.le    close_file
	b	store_args

	close_file:
	// close file
	mov     w0,     w23
	mov     x8,     57
	svc     0
	//ldr     x0,     =error
	//bl      printf
	b       invalidargs

	store_args:
	mov	x0,	x19
	bl	atoi		// convert second argument into int
	mov	x19,	x0	// second argument is number of rows

	mov	x0,	x20	// set third command line arg as first argument for atoi
	bl 	atoi		// convert to int
	mov	x20,	x0	// third command line argument is number of columns

	mov	x9,	4	// minimum number of rows/columns
	mov	x10,	20	// maximum number of rows/columns
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

	// Calculate required space for indices
	// number of bytes allocated for table = 4 * m
	sub	x26,	xzr,			x19	// negate number of rows
	lsl	x26,	x26,	2	// multiply by 4
	and	x26,	x26,	-16	// make sure x26 is divisible by 16

	add	sp,	sp,	x26			// allocate space for indices

	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	x19					// second arg is number of rows
	mov	x2,	x20					// third arg is number of cols
	mov	w3,	w23					// fourth arg is file descriptor
	bl	initialize


	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	x19					// second arg is number of rows
	mov	x2,	x20					// third arg is number of cols
	bl	display

	ldr	x0,	=linebreak
	bl	printf

	// Ask for which column
	ldr	x0,	=askcolumn
	bl	printf

	ldr	x0,	=theD
	ldr	x1,	=col_i
	bl	scanf
	ldr	x3,	=col_i
	ldr	x28,	[x3]

	// Ask for number of docs to retrieve
	ldr	x0,	=askretrieve
	bl	printf

	ldr	x0,	=theD
	ldr	x1,	=num_docs
	bl	scanf
	ldr	x4,	=num_docs
	ldr	x25,	[x4]
	
	add	x0,	x29,	table_s				// first arg is table's base address
	mov	x1,	x19					// second arg is number of rows
	mov	x2,	x20					// third arg is number of cols
	mov	x3,	x28
	mov	x4,	x25
	add	x5,	x29,	x21			// fifth arg is indices array base address
	bl	topRelevantDocs

	add	x0,	x29,	table_s				// first arg is table's base address
	mov	x1,	x19					// second arg is number of rows
	mov	x2,	x20					// third arg is number of cols
	mov	x3,	x25
	mov	x4,	x28
	add	x5,	x29,	x21			// fifth arg is indices array base address
	bl	logToFile

	// Calculate required space for table
	// number of bytes allocated for table = 4 * m * n
	mul	x22,		x19,		x20		// number of rows * number of columns	
	sub	x21,		xzr,		x22	// negate x21
	lsl	x21,		x21,	2		// multiply by 4
	and	x21,		x21,	-16		// make sure x21 is divisible by 16
	// Calculate required space for indices
	// number of bytes allocated for table = 4 * m
	sub	x26,	xzr,		x19		// negate number of rows
	lsl	x26,	x26,	2	// multiply by 4
	and	x26,	x26,	-16	// make sure x26 is divisible by 16

	sub	sp,	sp,	x21		// deallocate memory used for table
	sub	sp,	sp,	x26		// deallocate memory used for indices array

	b 	exitMain

invalidargs:
	ldr	x0,	=error
	bl	printf	

exitMain:	
	
	ldp	x29,	x30,	[sp], 32
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


buf_size = 4
buf_s = dealloc + 8
alloc = (alloc - buf_size) & -16 
dealloc = -alloc

// initialize(&table, numrows, numcols, fd)
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

	str	xzr,	[x29, buf_s]

	mov	x26,	x0	// get table base address from given arguments	
	mov	x19,		x1
	mov	x20,		x2
	mov	w23,		w3

	cmp	w23,		0
	b.eq	initialize_with_rand

	mov	x27,		xzr
initialize_with_file:
	b	initialize_with_file_test
initialize_with_file_col:

	mov     w0,    w23
        add     x1,    x29,    buf_s
        mov     x2,     1
        mov     x8,     63
        svc     0

	add	x0,	x29,	buf_s
	bl	atoi
	
		// x27 is gonna be used an offset for loading int value from memory
		// offset = (row * numcols + col) * 4
		sub	x27,	xzr,	x27	// negate row
		mul	x27,	x27,	x20	// row = row * numcols
		sub	x27,	x27,	x28	// row -= col
		str	w0,	[x26, x27, LSL 2] // store value into array
		add 	x27,	x27,	x28	// row += col
		sdiv	x27,	x27,	x20	// row /= numcols
		sub	x27,	xzr,	x27	// make row positive again
		// row is now positive and restored
		
       

	// skip space	
	mov     w0,    w23
        add     x1,    x29,    buf_s
        mov     x2,     1
        mov     x8,     63
        svc     0

	add	x28,		x28,		1	
	cmp	x28,		x20
	b.lt	initialize_with_file_col

	add	x27,		x27,		1
initialize_with_file_test:
	mov	x28,		xzr
	cmp	x27,		x19
	b.lt	initialize_with_file_col

	b	end_initialize

initialize_with_rand:
	mul	x22,		x19,	x20	 // calculate number of cells the table has
	
	mov	x24,	xzr		// start offset for table base address at 0
	mov	x23,		xzr		// start at cell 0 

initialize_with_rand_loop:
	// Store random numbers in each table cell
	// First, we generate the random number
	mov	w0,	0
	mov	w1,	9
	bl	randomNum			// Generate random number
	mov	w25,	w0

	str	w25,	[x26, x24]	// store number in array

	sub	x24,	x24,	TABLE_ELEMENT_SIZE	// keep track of offset for where to store number in stack
	add	x23,		x23,		1		// keep track of cell number

	// Loop until current cell number = number of cells
	cmp	x23,		x22		
	b.lt	initialize_with_rand_loop
	
end_initialize:
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

	mov	w21,		w0		
	mov	w19,	w1
	sub	w19,	w19,	w21
	add	w19,	w19,	1
	bl	rand
	mov	w25,	w0
	udiv	w20,	w25,	w19
	msub	w25,	w20,	w19,	w25	
	add	w25,	w25,	w21

	mov	w0,	w25

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

	
	// x27 is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	x27,	xzr,	x27	// negate row
	mul	x27,	x27,	x20	// row = row * numcols
	sub	x27,	x27,	x28	// row -= col
	ldr	w25,	[x26, x27, LSL 2] // load value from array
	add 	x27,	x27,	x28	// row += col
	sdiv	x27,	x27,	x20	// row /= numcols
	sub	x27,	xzr,	x27	// make row positive again
	// row is now positive and restored
	
      	

	// print occurence at current table cell
	ldr	x0,	=cell			// load string format and use as argument for printing
	mov	w1,	w25		// use loaded table cell value as argument for printing
	bl	printf

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









//topRelevantDocs(&table, numrows, numcolumns, col, numtoretrieve, &indices)
topRelevantDocs: 

	
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


	mov	x26,		x0		// remember table base address
	mov	x19,			x1		// remember num rows
	mov	x20,			x2		// remember num cols
	mov	x28,			x3		// remember column to retrieve
	mov	x25,	x4		// remember num top docs to retrieve
	mov	x23,		x5		// remember indices array base address		

	// initialize unsorted array of indices 
	mov	x0,	x23
	bl	init_indices

	mov	x27,		xzr		// start at row 0	
	sub	x11,	x19,	1	// initialize numrows - 1
	// sort indices using frequency
sorting_outer_loop:
	mov	x21,	xzr
	
	mov	x27,		xzr
sorting_inner_loop:
	b	sorting_inner_test
sorting_inner_body:
	// if frequency(row, col) < frequency(row + 1, col), swap	

	// get frequency(row, col)
	mov	x0,	x26
	mov	x1,	x20
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w2,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	
		
	mov	x3,	x28
	bl	calculateFrequency
	fmov	d9,	d0	

	// get frequency(row + 1, col)
	mov	x0,	x26
	mov	x1,	x20
	add	x27,	x27,	1
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w2,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	
		
	mov	x3,	x28
	bl	calculateFrequency
	fmov	d10,	d0	

	fcmp	d9,	d10
	b.ge	sorting_inner_test

sorting_inner_loop_swap:
	sub	x27,	x27, 1
	
	// tempRow = indices[row]
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w10,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	


	add	x27,	x27, 1

	// indices[row] = indices[row + 1]	
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w14,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	

	sub	x27,	x27, 1
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	str	w14,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	


	// indices[row + 1] = tempRow
	add	x27,	x27, 1
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	str	w10,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	


	mov	x21,	1

sorting_inner_test:	
	sub	x11,	x19,	1	// initialize numrows - 1
	cmp	x27,		x11			// if row < numrows - 1
	b.lt	sorting_inner_body			// arrange next items	

	mov	x27,		xzr

sorting_outer_test:
	cmp	x21,	xzr
	b.ne	sorting_outer_loop
	
	ldr	x0,	=header
	bl	printf

	mov	x27,		xzr
display_topdocs:
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w10,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	

	mov	w2,	w10
	
	// get frequency(row, col)
	mov	x0,	x26
	mov	x1,	x20
	mov	x3,	x28
	bl	calculateFrequency
	fmov	d4,	d0	

		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w10,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	

	mov	x1,	xzr
	add	x1,	x1,	w10, UXTW
	mov	x2,	x28
	
	// x27 is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	x1,	xzr,	x1	// negate row
	mul	x1,	x1,	x20	// row = row * numcols
	sub	x1,	x1,	x28	// row -= col
	ldr	w10,	[x26, x1, LSL 2] // load value from array
	add 	x1,	x1,	x28	// row += col
	sdiv	x1,	x1,	x20	// row /= numcols
	sub	x1,	xzr,	x1	// make row positive again
	// row is now positive and restored
	
      
	mov	w3,	w10	
	ldr	x0,	=rowinfo
	bl	printf

	add	x27,		x27,		1

	cmp	x27,		x25
	b.lt	display_topdocs

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

		// Register for unsorted row index
//init_indices(&indices, numrows)
// generates an unsorted indices array
init_indices:
	
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


	mov	x23,		x0		// remember base address of indices array			
	mov	x19,			x1		// remember number of rows

	mov	w27,		wzr

init_indices_loop:
	b	init_indices_loop_test			// execute loop test

init_indices_loop_body:
	mov	x24,	xzr
	//calculate offset: offset = -row * 4
	sub	x24,	x24,		w27, UXTB #0	// offset = -row
	lsl	x24,	x24,	2			// offset *= 4
	str	w27,		[x23, x24]		// store index in indices array	

	add	w27,		w27,		1	// next row

init_indices_loop_test:
	cmp	x19,		w27, UXTB #0			// if row < number of rows
	b.le	reload_init_indices			// essentially, quit loop	
	b	init_indices_loop_body			// execute loop body

reload_init_indices:
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
	



// calculateSize(&table, numcols, row)
calculateSize:
	
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


	mov	x26,	x0		// remember table base address
	mov	x20,		x1		// remember num of cols
	mov	x27,		x2		// remember row to calculate size of

	mov	w9,	wzr		// initialize total to 0
	mov	x28,		xzr		// start at col 0
size_loop:
	// calculate offset = ( row * numcols + col ) * 4
	
	// x27 is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	x27,	xzr,	x27	// negate row
	mul	x27,	x27,	x20	// row = row * numcols
	sub	x27,	x27,	x28	// row -= col
	ldr	w25,	[x26, x27, LSL 2] // load value from array
	add 	x27,	x27,	x28	// row += col
	sdiv	x27,	x27,	x20	// row /= numcols
	sub	x27,	xzr,	x27	// make row positive again
	// row is now positive and restored
	
      	
	add	w9,	w9,	w25	// add occurence to total to eventually get size
	
	add	x28,		x28,		1		// next column

	cmp	x28,		x20	// loop if col < numcols
	b.lt	size_loop

	mov	w0,	w9		// return total size of row

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



// frequency = word occurences in doc * 100 / size of doc
// calculateFrequency(&table, numcols, row, col)
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


	mov	x26,	x0		// remember table base address
	mov	x20,		x1		// remember num cols
	mov	x27,		x2		// remember row
	mov	x28,		x3		// remember col

	bl 	calculateSize			// calculate size with &table, numcols, row
	scvtf	d12,	x0		// remember size

	mov	x10,	1
	scvtf	d10,	x10

	// calculate offset = ( row * numcols + col ) * 4
	
	// x27 is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	x27,	xzr,	x27	// negate row
	mul	x27,	x27,	x20	// row = row * numcols
	sub	x27,	x27,	x28	// row -= col
	ldr	w25,	[x26, x27, LSL 2] // load value from array
	add 	x27,	x27,	x28	// row += col
	sdiv	x27,	x27,	x20	// row /= numcols
	sub	x27,	xzr,	x27	// make row positive again
	// row is now positive and restored
	
      	

	scvtf	d11,	w25			// convert occurence to double
	
	fmul	d11,	d11,	d10		// multiply occurence with 100
	fdiv	d0,		d11,	d12		// return frequency as float

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


buf_size = 4
scol_size = 4
ndocs_size = 4
pointer_indices_size = 8
stringbuf_size = 50
fd_size = 4
buf_s = dealloc + 8
scol_s = buf_s + 4
ndocs_s = scol_s + 4 
pointer_indices_s = ndocs_s + ndocs_size
fd_s = pointer_indices_s + pointer_indices_size
stringbuf_s = fd_s + fd_size
alloc = (alloc - buf_size - scol_size - ndocs_size - pointer_indices_size - fd_size - stringbuf_size) & -16 
dealloc = -alloc




// logToFile(*table, numrows, numcols, num_docs, col_i)
logToFile: 

	
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
	

	mov	x26,		x0
	mov	x19,			x1
	mov	x20,			x2
	mov	w25,	w3
	mov	w28,			w4
	mov	x23,		x5

	// store variables
	str	w25,	[x29, ndocs_s] 	
	str	w28,			[x29, scol_s]	
	str	x23,		[x29, pointer_indices_s]

	// open log file
	mov     w0,     -100
        ldr     x1,     =logfile
        mov     w2,     0101
	mov	w3,	0700
        mov     x8,     56
        svc     0
	mov	w23,	w0		// remember file descriptor	
	str	w23,	[x29, fd_s]

	mov	x27,	xzr
	mov	x28,	xzr
log_table:
	
	// x27 is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	x27,	xzr,	x27	// negate row
	mul	x27,	x27,	x20	// row = row * numcols
	sub	x27,	x27,	x28	// row -= col
	ldr	w25,	[x26, x27, LSL 2] // load value from array
	add 	x27,	x27,	x28	// row += col
	sdiv	x27,	x27,	x20	// row /= numcols
	sub	x27,	xzr,	x27	// make row positive again
	// row is now positive and restored
	
      	

	// convert to string
	
	scvtf	d0,	w25
	mov	x0,	1
	add	x1,	x29,	buf_s
	bl	gcvt
	

	// write to file
	
	mov	w0,	w23	
	add	x1,	x29,	 buf_s
	mov	x2,	1
	mov	x8,	64
	svc 	0
	

	// write space
	
	mov	w0,	w23	
	ldr	x1,	=space
	mov	x2,	1
	mov	x8,	64
	svc 	0
	


log_inc_col:
	add	x28,		x28,		1			// increment column number to keep track of current table cell column

        cmp     x28,         x20					// if column < number of columns:
        b.lt    log_table						// loop

	mov	x28,	xzr						// reset column to 0
	
	add 	x27,		x27,		1			// increment row number to keep track of current table cell row
	
	
	mov	w0,	w23	
	ldr	x1,	=linebreak
	mov	x2,	1
	mov	x8,	64
	svc 	0
	


	cmp	x27,		x19					// if row < number of rows:
	b.lt	log_table						// loop

log_search_col:
	// write question
	
	mov	w0,	w23	
	ldr	x1,	=askcolumn
	mov	x2,	11
	mov	x8,	64
	svc 	0
	
	

	ldr	x28,		[x29, scol_s]
	// convert to string
	
	scvtf	d0,	w28
	mov	x0,	1
	add	x1,	x29,	buf_s
	bl	gcvt
	

	// write to file
	
	mov	w0,	w23	
	add	x1,	x29,	 buf_s
	mov	x2,	1
	mov	x8,	64
	svc 	0
	

	// write space
	
	mov	w0,	w23	
	ldr	x1,	=space
	mov	x2,	1
	mov	x8,	64
	svc 	0
	


	
	mov	w0,	w23	
	ldr	x1,	=linebreak
	mov	x2,	1
	mov	x8,	64
	svc 	0
	


log_numtoretrieve:
	// write question
	
	mov	w0,	w23	
	ldr	x1,	=askretrieve
	mov	x2,	44
	mov	x8,	64
	svc 	0
	
	

	ldr	w25,	[x29, ndocs_s]
	// convert to string
	
	scvtf	d0,	x25
	mov	x0,	4
	add	x1,	x29,	buf_s
	bl	gcvt
	

	// write to file
	// write to file
	
	mov	w0,	w23	
	add	x1,	x29,	 buf_s
	mov	x2,	4
	mov	x8,	64
	svc 	0
	

	// write space
	
	mov	w0,	w23	
	ldr	x1,	=space
	mov	x2,	1
	mov	x8,	64
	svc 	0
	


	
	mov	w0,	w23	
	ldr	x1,	=linebreak
	mov	x2,	1
	mov	x8,	64
	svc 	0
	


log_topheader:
	// write header
	
	mov	w0,	w23	
	ldr	x1,	=header
	mov	x2,	36
	mov	x8,	64
	svc 	0
	
	

	mov	x27,		xzr
log_topdocs:
	b	log_topdocs_test

log_topdocs_body:
			
	ldr	w28,		[x29, scol_s]		// load word being searched

	ldr	x23,	[x29, pointer_indices_s]
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w10,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	

	mov	w2,	w10
	
	// get frequency(row, col)
	mov	x0,	x26
	mov	x1,	x20
	mov	x3,	x28
	bl	calculateFrequency
	fmov	d4,	d0	

	ldr	x23,	[x29, pointer_indices_s]
		
	sub	x27,	xzr,	x27		// make row negative so that offset is negative
	ldr	w10,	[x23, x27, LSL 2] 	// load value in memory into given register 
	sub	x27,	xzr,	x27		// make row positive again
	

	mov	x2,	xzr
	add	x2,	x2,	w10, UXTW
	mov	x3,	x28
load_occurence:
	
	// x27 is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	x2,	xzr,	x2	// negate row
	mul	x2,	x2,	x20	// row = row * numcols
	sub	x2,	x2,	x28	// row -= col
	ldr	w10,	[x26, x2, LSL 2] // load value from array
	add 	x2,	x2,	x28	// row += col
	sdiv	x2,	x2,	x20	// row /= numcols
	sub	x2,	xzr,	x2	// make row positive again
	// row is now positive and restored
	
      
start_sprint:
	mov	w4,	w10	
	ldr	x1,	=rowinfo
	mov	x0,	xzr
	add	x0,	x29,	stringbuf_s
	bl	sprintf

after_sprint:
	ldr	w23,	[x29, fd_s]
	
	mov	w0,	w23	
	add	x1,	x29,	 stringbuf_s
	mov	x2,	40
	mov	x8,	64
	svc 	0
	


	add	x27,	x27,	1 		

log_topdocs_test:
	ldr	w25,	[x29, ndocs_s]
	cmp	x27,		w25, UXTW	
	b.lt	log_topdocs_body

log_close_file:
	// close file
	mov     w0,     w23
        mov     x8,     57
        svc     0

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
	


	.data
	col_i:		.int	0
	num_docs:	.int	0
