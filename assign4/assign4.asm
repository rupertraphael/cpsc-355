// --------------------------------------------------------
// Author:
// Date:
// Description:
// --------------------------------------------------------

	.text
	theD: .string "%-6d"
	linebreak: .string "\n"	

				// Eventually, registers for:
define(m_r, x19)		// number of rows/documents
define(n_r, x20)		// number of columns/words
define(table_alloc_r, x21)	// number of bytes needed to allocate for table		
define(count_cells_r, x22)	// number of cells n*m
define(cell_r, x23)		// current cell
define(offset_r, x24)		// offset to get a table cell's address
define(randNum_r, x25)		// generated random number
define(table_base_r, x26)	// base address of table
define(row_r, x27)		// current row
define(col_r, x28)		// current column

define(maxocc_r)		// maximum occurence

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
	mov	m_r,	4
	mov	n_r,	4


	// Calculate required space for table
	// number of bytes allocated for table = 4 * m * n
	mul	count_cells_r,		m_r,		n_r
	sub	table_alloc_r,		xzr,		count_cells_r
	lsl	table_alloc_r,		table_alloc_r,	4
	and	table_alloc_r,		table_alloc_r,	ALIGN
	add	sp,	sp,	table_alloc_r

	add	x0,	x29,	table_s
	mov	x1,	m_r
	mov	x2,	n_r
	bl	generateTable

	mov	cell_r,		xzr
	mov	offset_r,	table_s
	mov	col_r,		xzr
	mov	row_r,		xzr
print:
	mov	x1, 	xzr

	ldr	x0,	=theD
	ldr	x1,	[x29, offset_r]
	bl	printf

	sub     offset_r,       offset_r,       TABLE_ELEMENT_SIZE

	add	col_r,		col_r,		1

	// loop if still in the same row
        cmp     col_r,         n_r
        b.lt    print

	// otherwise, reset column, go to new row
	ldr	x0,	=linebreak
	bl	printf
	mov	col_r,	xzr	
	
	add 	row_r,		row_r,		1
	cmp	row_r,		m_r	
	b.lt	print

	

	// Deallocate space used by table
	sub	sp,	sp,	table_alloc_r

exitMain:	ldp	x29,	x30,	[sp], 16
		ret


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
generateTable:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp

	str_x()

	mov	table_base_r,	x0		

	mul	count_cells_r,		x1,	x2
	
	mov	row_r,		xzr
	mov	col_r,		xzr
	mov	offset_r,	xzr
	mov	cell_r,		xzr
loop:
	// Store random numbers in each table cell
	// First, we generate the random number
	bl	rand				// Generate random number
	mov	randNum_r,	x0

	and	randNum_r,	randNum_r,	MAX_RAND		

	str	randNum_r,	[table_base_r, offset_r]

	sub	offset_r,	offset_r,	TABLE_ELEMENT_SIZE
	add	cell_r,		cell_r,		1

	// Loop until current cell number = number of cells
	cmp	cell_r,		count_cells_r		
	b.lt	loop
	
	ldr_x()

	ldp	x29,	x30,	[sp], dealloc
	ret

// frequency = word occurences in doc * 100 / size of doc
// calculateFrequency(occurences, size)
calculateFrequency:
	stp	x29,	x30,	[sp, alloc]!
	mov	x29,	sp

	str_x()

	// Multiply by 100

	// Divide

	// Store to x0

	ldr_x()

	ldp	x29,	x30,	[sp], dealloc
	ret
