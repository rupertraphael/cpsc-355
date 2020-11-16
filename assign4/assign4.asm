// --------------------------------------------------------
// Author:
// Date:
// Description:
// --------------------------------------------------------

	.text
	theD: .string "%-3d\n"
	linebreak: .string "\n"	

				// Eventually, registers for:
define(m_r, x19)		// number of rows/documents
define(n_r, x20)		// number of columns/words
define(table_alloc_r, x21)	// number of bytes needed to allocate for table		
define(count_cells_r, x22)	// number of cells n*m
define(cell_r, x23)		// current cell
define(offset_r, x24)		// offset to get a cell address
define(randNum_r, x25)		// generated random number

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
	mov	m_r,	4
	mov	n_r,	4


	// Calculate required space for table
	// number of bytes allocated for table = 4 * m * n
	mul	count_cells_r,		m_r,		n_r
	sub	table_alloc_r,		xzr,		count_cells_r
	lsl	table_alloc_r,		table_alloc_r,	3
	and	table_alloc_r,		table_alloc_r,	ALIGN
	add	sp,	sp,	table_alloc_r

	mov	cell_r,		xzr
	mov	offset_r,	-8
store:
	// Store random numbers in each table cell
	// First, we generate the random number
	bl	rand				// Generate random number
	mov	randNum_r,	x0

	and	randNum_r,	randNum_r,	MAX_RAND		


	str	randNum_r,	[x29, offset_r]

	add	offset_r,	offset_r,	TABLE_ELEMENT_SIZE
	add	cell_r,		cell_r,		1

	// Loop until current cell number = number of cells
	cmp	cell_r,		count_cells_r		
	b.lt	store
	
	mov	cell_r,		xzr
	mov	offset_r,	TABLE_ELEMENT_SIZE
print:
	ldr	x0,	=theD
	ldr	x1,	[x29, offset_r]
	bl	printf

	add     offset_r,       offset_r,       TABLE_ELEMENT_SIZE
        add     cell_r,         cell_r,         1


	// Loop until current cell number = number of cells
        cmp     cell_r,         count_cells_r
        b.lt    print
	

	// Deallocate space used by table
	sub	sp,	sp,	table_alloc_r

exitMain:	ldp	x29,	x30,	[sp], 16
		ret
 
