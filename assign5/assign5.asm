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
	log_header:	.string "doc,word,occur,freq"
	askcolumn:	.string	"Which word? "
	askretrieve:	.string	"How many documents do you want to retrieve? "
	rowinfo:	.string "%5d\t%12d\t%10d\t%9.3f"
	error:		.string "Invalid arguments.\n"
	linebreak: 	.string "\n"	
	space:		.string " "
	comma:		.string ","
	logfile:	.string "assign5.log"


				// Eventually, registers for:
define(m_r, x19)		// number of rows/documents
define(n_r, x20)		// number of columns/words
define(table_alloc_r, x21)	// number of bytes needed to allocate for table		
define(count_cells_r, x22)	// number of cells n*m
define(cell_r, x23)		// current cell
define(fd_wr, w23)		// file descriptor
define(offset_r, x24)		// offset to get a table cell's address
define(numtoretrieve_r, x25)	// number of top docs to retrieve
define(indices_alloc_r, x26)	// number of bytes needed to allocate for the indices array
define(row_r, x27)		// current row
define(col_r, x28)		// current column

define(randNum_r, w25)		// generated random number

define(table_base_r, x26)	// base address of table

define(maxword_r, x21)		// number of bytes needed to allocate for table		
define(maxoccur_r, x22)		// number of cells n*m
define(indices_base_r, x23)	// base for array of document indices
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

// macro for loading an integer value from a 1D array into a given register
// load_int_from_array1d(&array_r, row_r, value_wr)
// &array_r - base address of a 1D array in memory
// row_r - greater than or equal to 0
// value_wr - 32-bit register that will contain the value in the 1D array at given row
define(
	load_int_from_array1d,
	`	
	sub	$2,	xzr,	$2		// make row negative so that offset is negative
	ldr	$3,	[$1, $2, LSL 2] 	// load value in memory into given register 
	sub	$2,	xzr,	$2		// make row positive again
	'
)
// macro for storing an integer value into a 1D array
// store_int_from_array1d(&array_r, row_r, value_wr)
// &array_r - base address of a 1D array in memory
// row_r - greater than or equal to 0
// value_wr - 32-bit register that will contain the value in the 1D array at given row
define(
	store_int_from_array1d,
	`	
	sub	$2,	xzr,	$2		// make row negative so that offset is negative
	str	$3,	[$1, $2, LSL 2] 	// load value in memory into given register 
	sub	$2,	xzr,	$2		// make row positive again
	'
)
// macro for loading an integer value from a 2D array into a given register
// load_int_from_array2d(&array_r, row_r, col_r, numcols_r, value_wr) 
define(
	load_int_from_array2d,
	`
	// row_r is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	$2,	xzr,	$2	// negate row
	mul	$2,	$2,	$4	// row = row * numcols
	sub	$2,	$2,	$3	// row -= col
	ldr	$5,	[$1, $2, LSL 2] // load value from array
	add 	$2,	$2,	$3	// row += col
	sdiv	$2,	$2,	$4	// row /= numcols
	sub	$2,	xzr,	$2	// make row positive again
	// row is now positive and restored
	'
      )
// macro for storing an integer value into a 2D array
// store_int_from_array2d(&array_r, row_r, col_r, numcols_r, value_wr) 
define(
		store_int_from_array2d,
		`
		// row_r is gonna be used an offset for loading int value from memory
		// offset = (row * numcols + col) * 4
		sub	$2,	xzr,	$2	// negate row
		mul	$2,	$2,	$4	// row = row * numcols
		sub	$2,	$2,	$3	// row -= col
		str	$5,	[$1, $2, LSL 2] // store value into array
		add 	$2,	$2,	$3	// row += col
		sdiv	$2,	$2,	$4	// row /= numcols
		sub	$2,	xzr,	$2	// make row positive again
		// row is now positive and restored
		'
      )


TABLE_ELEMENT_SIZE = 4
table_s = 0
ALIGN = -16
MAX_RAND = 16 - 1

.balign 4
.global main

main:	
startfunction(-32)

	cmp	x0,	3	// if argc < 3,
	b.lt	invalidargs	// prompt invalid args and exit

	cmp	x0,	4	// if argc > 4	
	b.gt	invalidargs	// prompt invalid args and exit

	ldr	m_r, 	[x1, 8]		// load second argument to x0
	ldr	n_r, 	[x1, 16]	// load third argument into register for number of columns
	mov	fd_wr,	wzr		// initialize file descriptor to 0

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
	mov	fd_wr,	w0
	b.le    close_file
	b	store_args

	close_file:
	// close file
	mov     w0,     fd_wr
	mov     x8,     57
	svc     0
	//ldr     x0,     =error
	//bl      printf
	b       invalidargs

	store_args:
	mov	x0,	m_r
	bl	atoi		// convert second argument into int
	mov	m_r,	x0	// second argument is number of rows

	mov	x0,	n_r	// set third command line arg as first argument for atoi
	bl 	atoi		// convert to int
	mov	n_r,	x0	// third command line argument is number of columns

	mov	x9,	4	// minimum number of rows/columns
	mov	x10,	20	// maximum number of rows/columns
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

	// Calculate required space for indices
	// number of bytes allocated for table = 4 * m
	sub	indices_alloc_r,	xzr,			m_r	// negate number of rows
	lsl	indices_alloc_r,	indices_alloc_r,	2	// multiply by 4
	and	indices_alloc_r,	indices_alloc_r,	-16	// make sure indices_alloc_r is divisible by 16

	add	sp,	sp,	indices_alloc_r			// allocate space for indices

	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
	mov	w3,	fd_wr					// fourth arg is file descriptor
	bl	initialize


	add	x0,	x29,	table_s				// first arg is table's base address	
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
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
	ldr	col_r,	[x3]

	// Ask for number of docs to retrieve
	ldr	x0,	=askretrieve
	bl	printf

	ldr	x0,	=theD
	ldr	x1,	=num_docs
	bl	scanf
	ldr	x4,	=num_docs
	ldr	numtoretrieve_r,	[x4]
	
	add	x0,	x29,	table_s				// first arg is table's base address
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
	mov	x3,	col_r
	mov	x4,	numtoretrieve_r
	add	x5,	x29,	table_alloc_r			// fifth arg is indices array base address
	bl	topRelevantDocs

	add	x0,	x29,	table_s				// first arg is table's base address
	mov	x1,	m_r					// second arg is number of rows
	mov	x2,	n_r					// third arg is number of cols
	mov	x3,	numtoretrieve_r
	mov	x4,	col_r
	add	x5,	x29,	table_alloc_r			// fifth arg is indices array base address
	bl	logToFile

	// Calculate required space for table
	// number of bytes allocated for table = 4 * m * n
	mul	count_cells_r,		m_r,		n_r		// number of rows * number of columns	
	sub	table_alloc_r,		xzr,		count_cells_r	// negate table_alloc_r
	lsl	table_alloc_r,		table_alloc_r,	2		// multiply by 4
	and	table_alloc_r,		table_alloc_r,	-16		// make sure table_alloc_r is divisible by 16
	// Calculate required space for indices
	// number of bytes allocated for table = 4 * m
	sub	indices_alloc_r,	xzr,		m_r		// negate number of rows
	lsl	indices_alloc_r,	indices_alloc_r,	2	// multiply by 4
	and	indices_alloc_r,	indices_alloc_r,	-16	// make sure indices_alloc_r is divisible by 16

	sub	sp,	sp,	table_alloc_r		// deallocate memory used for table
	sub	sp,	sp,	indices_alloc_r		// deallocate memory used for indices array

	b 	exitMain

invalidargs:
	ldr	x0,	=error
	bl	printf	

exitMain:	
	endfunction(32)

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

buf_size = 4
buf_s = dealloc + 8
alloc = (alloc - buf_size) & -16 
dealloc = -alloc

// initialize(&table, numrows, numcols, fd)
// populates random occurences (0 - 15) into the given table
initialize:
	startfunction(alloc)

	str_x()		// store caller-saved register values

	str	xzr,	[x29, buf_s]

	mov	table_base_r,	x0	// get table base address from given arguments	
	mov	m_r,		x1
	mov	n_r,		x2
	mov	fd_wr,		w3

	cmp	fd_wr,		0
	b.eq	initialize_with_rand

	mov	row_r,		xzr
initialize_with_file:
	b	initialize_with_file_test
initialize_with_file_col:

	mov     w0,    fd_wr
        add     x1,    x29,    buf_s
        mov     x2,     1
        mov     x8,     63
        svc     0

	add	x0,	x29,	buf_s
	bl	atoi
	store_int_from_array2d(table_base_r, row_r, col_r, n_r, w0) 

	// skip space	
	mov     w0,    fd_wr
        add     x1,    x29,    buf_s
        mov     x2,     1
        mov     x8,     63
        svc     0

	add	col_r,		col_r,		1	
	cmp	col_r,		n_r
	b.lt	initialize_with_file_col

	add	row_r,		row_r,		1
initialize_with_file_test:
	mov	col_r,		xzr
	cmp	row_r,		m_r
	b.lt	initialize_with_file_col

	b	end_initialize

initialize_with_rand:
	mul	count_cells_r,		m_r,	n_r	 // calculate number of cells the table has
	
	mov	offset_r,	xzr		// start offset for table base address at 0
	mov	cell_r,		xzr		// start at cell 0 

initialize_with_rand_loop:
	// Store random numbers in each table cell
	// First, we generate the random number
	mov	w0,	0
	mov	w1,	9
	bl	randomNum			// Generate random number
	mov	randNum_r,	w0

	str	randNum_r,	[table_base_r, offset_r]	// store number in array

	sub	offset_r,	offset_r,	TABLE_ELEMENT_SIZE	// keep track of offset for where to store number in stack
	add	cell_r,		cell_r,		1		// keep track of cell number

	// Loop until current cell number = number of cells
	cmp	cell_r,		count_cells_r		
	b.lt	initialize_with_rand_loop
	
end_initialize:
	ldr_x()				// reload caller-saved register values	

	endfunction(dealloc)

init_subr_x()
define(divisor_r, w19)
define(numerator_r, w20)
define(min_r, w21)
// randomNum(min, max)
randomNum:
	startfunction(alloc)
	str_x()		// store caller-saved register values

	mov	min_r,		w0		
	mov	divisor_r,	w1
	sub	divisor_r,	divisor_r,	min_r
	add	divisor_r,	divisor_r,	1
	bl	rand
	mov	randNum_r,	w0
	udiv	numerator_r,	randNum_r,	divisor_r
	msub	randNum_r,	numerator_r,	divisor_r,	randNum_r	
	add	randNum_r,	randNum_r,	min_r

	mov	w0,	randNum_r

	ldr_x()				// reload caller-saved register values	
	endfunction(dealloc)

init_subr_x()
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

	load_int_from_array2d(table_base_r, row_r, col_r, n_r, randNum_r)	

	// print occurence at current table cell
	ldr	x0,	=cell			// load string format and use as argument for printing
	mov	w1,	randNum_r		// use loaded table cell value as argument for printing
	bl	printf

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
define(swapped_r, x21)
define(temprow_r, w10)
define(mless_r, x11)
define(mplus_r,	x12)
define(nextoccur_r, w13)
define(nextrow_r, w14)
define(frequency_dr, d9)
define(nextfrequency_dr, d10)
//topRelevantDocs(&table, numrows, numcolumns, col, numtoretrieve, &indices)
topRelevantDocs: 

	startfunction(alloc)

	str_x()

	mov	table_base_r,		x0		// remember table base address
	mov	m_r,			x1		// remember num rows
	mov	n_r,			x2		// remember num cols
	mov	col_r,			x3		// remember column to retrieve
	mov	numtoretrieve_r,	x4		// remember num top docs to retrieve
	mov	indices_base_r,		x5		// remember indices array base address		

	// initialize unsorted array of indices 
	mov	x0,	indices_base_r
	bl	init_indices

	mov	row_r,		xzr		// start at row 0	
	sub	mless_r,	m_r,	1	// initialize numrows - 1
	// sort indices using frequency
sorting_outer_loop:
	mov	swapped_r,	xzr
	
	mov	row_r,		xzr
sorting_inner_loop:
	b	sorting_inner_test
sorting_inner_body:
	// if frequency(row, col) < frequency(row + 1, col), swap	

	// get frequency(row, col)
	mov	x0,	table_base_r
	mov	x1,	n_r
	load_int_from_array1d(indices_base_r, row_r, w2)		
	mov	x3,	col_r
	bl	calculateFrequency
	fmov	frequency_dr,	d0	

	// get frequency(row + 1, col)
	mov	x0,	table_base_r
	mov	x1,	n_r
	add	row_r,	row_r,	1
	load_int_from_array1d(indices_base_r, row_r, w2)		
	mov	x3,	col_r
	bl	calculateFrequency
	fmov	nextfrequency_dr,	d0	

	fcmp	frequency_dr,	nextfrequency_dr
	b.ge	sorting_inner_test

sorting_inner_loop_swap:
	sub	row_r,	row_r, 1
	
	// tempRow = indices[row]
	load_int_from_array1d(indices_base_r, row_r, temprow_r)

	add	row_r,	row_r, 1

	// indices[row] = indices[row + 1]	
	load_int_from_array1d(indices_base_r, row_r, nextrow_r)
	sub	row_r,	row_r, 1
	store_int_from_array1d(indices_base_r, row_r, nextrow_r)

	// indices[row + 1] = tempRow
	add	row_r,	row_r, 1
	store_int_from_array1d(indices_base_r, row_r, temprow_r)

	mov	swapped_r,	1

sorting_inner_test:	
	sub	mless_r,	m_r,	1	// initialize numrows - 1
	cmp	row_r,		mless_r			// if row < numrows - 1
	b.lt	sorting_inner_body			// arrange next items	

	mov	row_r,		xzr

sorting_outer_test:
	cmp	swapped_r,	xzr
	b.ne	sorting_outer_loop
	
	ldr	x0,	=header
	bl	printf

	mov	row_r,		xzr
display_topdocs:
	load_int_from_array1d(indices_base_r, row_r, temprow_r)
	mov	w2,	temprow_r
	
	// get frequency(row, col)
	mov	x0,	table_base_r
	mov	x1,	n_r
	mov	x3,	col_r
	bl	calculateFrequency
	fmov	d4,	d0	

	load_int_from_array1d(indices_base_r, row_r, temprow_r)
	mov	x1,	xzr
	add	x1,	x1,	temprow_r, UXTW
	mov	x2,	col_r
	load_int_from_array2d(table_base_r, x1, col_r, n_r, temprow_r)
	mov	w3,	temprow_r	
	ldr	x0,	=rowinfo
	bl	printf
	
	ldr	x0,	=linebreak
	bl	printf

	add	row_r,		row_r,		1

	cmp	row_r,		numtoretrieve_r
	b.lt	display_topdocs

	ldr_x()

	endfunction(dealloc)

init_subr_x()
define(row_wr, w27)		// Register for unsorted row index
//init_indices(&indices, numrows)
// generates an unsorted indices array
init_indices:
	startfunction(alloc)

	str_x()

	mov	indices_base_r,		x0		// remember base address of indices array			
	mov	m_r,			x1		// remember number of rows

	mov	row_wr,		wzr

init_indices_loop:
	b	init_indices_loop_test			// execute loop test

init_indices_loop_body:
	mov	offset_r,	xzr
	//calculate offset: offset = -row * 4
	sub	offset_r,	offset_r,		row_wr, UXTB #0	// offset = -row
	lsl	offset_r,	offset_r,	2			// offset *= 4
	str	row_wr,		[indices_base_r, offset_r]		// store index in indices array	

	add	row_wr,		row_wr,		1	// next row

init_indices_loop_test:
	cmp	m_r,		row_wr, UXTB #0			// if row < number of rows
	b.le	reload_init_indices			// essentially, quit loop	
	b	init_indices_loop_body			// execute loop body

reload_init_indices:
	ldr_x()

	endfunction(dealloc)

define(total_r, w9)
// calculateSize(&table, numcols, row)
calculateSize:
	startfunction(alloc)

	str_x()

	mov	table_base_r,	x0		// remember table base address
	mov	n_r,		x1		// remember num of cols
	mov	row_r,		x2		// remember row to calculate size of

	mov	total_r,	wzr		// initialize total to 0
	mov	col_r,		xzr		// start at col 0
size_loop:
	// calculate offset = ( row * numcols + col ) * 4
	load_int_from_array2d(table_base_r, row_r, col_r, n_r, randNum_r)	
	add	total_r,	total_r,	randNum_r	// add occurence to total to eventually get size
	
	add	col_r,		col_r,		1		// next column

	cmp	col_r,		n_r	// loop if col < numcols
	b.lt	size_loop

	mov	w0,	total_r		// return total size of row

	ldr_x()

	endfunction(dealloc)	


init_subr_x()
alloc = (alloc - 8) & -16 	// will be allocating extra 8 bytes to store the size of current row
dealloc = -alloc
size_s = x28_s + 8		// position of size value relative to frame pointer 

define(occurence_dr, d11)
define(size_dr,	d12)
// frequency = word occurences in doc * 100 / size of doc
// calculateFrequency(&table, numcols, row, col)
calculateFrequency:
	startfunction(alloc)

	str_x()

	mov	table_base_r,	x0		// remember table base address
	mov	n_r,		x1		// remember num cols
	mov	row_r,		x2		// remember row
	mov	col_r,		x3		// remember col

	bl 	calculateSize			// calculate size with &table, numcols, row
	scvtf	size_dr,	x0		// remember size

	mov	x10,	1
	scvtf	d10,	x10

	// calculate offset = ( row * numcols + col ) * 4
	load_int_from_array2d(table_base_r, row_r, col_r, n_r, randNum_r)	

	scvtf	occurence_dr,	randNum_r			// convert occurence to double
	
	fmul	occurence_dr,	occurence_dr,	d10		// multiply occurence with 100
	fdiv	d0,		occurence_dr,	size_dr		// return frequency as float

	ldr_x()

	endfunction(dealloc)


define(
	fwrite_var,
	`
	mov	w0,	$1	
	ldr	x1,	=$2
	mov	x2,	$3
	mov	x8,	64
	svc 	0
	'
)

define(
	fwrite_reg,
	`
	mov	w0,	$1	
	add	x1,	$2,	 $3
	mov	x2,	$4
	mov	x8,	64
	svc 	0
	'
)

define(
	int_to_string,
	`
	scvtf	d0,	$1
	mov	x0,	$2
	add	x1,	$3,	$4
	bl	gcvt
	'
)

define(
	float_to_string,
	`
	fmov	d0,	$1
	mov	x0,	$2
	add	x1,	$3,	$4
	bl	gcvt
	'
)

init_subr_x()

buf_size = 4
scol_size = 4
ndocs_size = 4
pointer_indices_size = 8
buf_s = dealloc + 8
scol_s = buf_s + 4
ndocs_s = scol_s + 4 
pointer_indices_s = ndocs_s + ndocs_size
alloc = (alloc - buf_size - scol_size - ndocs_size - pointer_indices_size) & -16 
dealloc = -alloc

define(numtoretrieve_wr, w25)
define(col_wr, w28)

// logToFile(*table, numrows, numcols, num_docs, col_i)
logToFile: 

	startfunction(alloc)
	str_x()	

	mov	table_base_r,		x0
	mov	m_r,			x1
	mov	n_r,			x2
	mov	numtoretrieve_wr,	w3
	mov	col_wr,			w4
	mov	indices_base_r,		x5

store_variables:
	// store variables
	str	numtoretrieve_wr,	[x29, ndocs_s] 	
	str	col_wr,			[x29, scol_s]	
	str	indices_base_r,			[x29, pointer_indices_s]

	// open log file
	mov     w0,     -100
        ldr     x1,     =logfile
        mov     w2,     0101
	mov	w3,	0700
        mov     x8,     56
        svc     0
	mov	fd_wr,	w0		// remember file descriptor	

log_table:
	load_int_from_array2d(table_base_r, row_r, col_r, n_r, randNum_r)	

	// convert to string
	int_to_string(randNum_r, 1, x29, buf_s)
	// write to file
	fwrite_reg(fd_wr, x29, buf_s, 1)
	// write space
	fwrite_var(fd_wr, space, 1)

log_inc_col:
	add	col_r,		col_r,		1			// increment column number to keep track of current table cell column

        cmp     col_r,         n_r					// if column < number of columns:
        b.lt    log_table						// loop

	mov	col_r,	xzr						// reset column to 0
	
	add 	row_r,		row_r,		1			// increment row number to keep track of current table cell row
	
	fwrite_var(fd_wr, linebreak, 1)

	cmp	row_r,		m_r					// if row < number of rows:
	b.lt	log_table						// loop

log_search_col:
	// write question
	fwrite_var(fd_wr, askcolumn, 11)	

	ldr	col_r,		[x29, scol_s]
	// convert to string
	int_to_string(col_wr, 1, x29, buf_s)
	// write to file
	fwrite_reg(fd_wr, x29, buf_s, 1)
	// write space
	fwrite_var(fd_wr, space, 1)

	fwrite_var(fd_wr, linebreak, 1)

log_numtoretrieve:
	// write question
	fwrite_var(fd_wr, askretrieve, 44)	

	ldr	numtoretrieve_wr,	[x29, ndocs_s]
	// convert to string
	int_to_string(numtoretrieve_r, 4, x29, buf_s)
	// write to file
	// write to file
	fwrite_reg(fd_wr, x29, buf_s, 4)
	// write space
	fwrite_var(fd_wr, space, 1)

	fwrite_var(fd_wr, linebreak, 1)

log_topheader:
	// write header

	mov	row_r,		xzr
	ldr	col_wr,		[x29, scol_s]

log_close_file:
	// close file
	mov     w0,     fd_wr
        mov     x8,     57
        svc     0

	ldr_x()
	endfunction(dealloc)

	.data
	col_i:		.int	0
	num_docs:	.int	0
