define(
        startfunction,
        `
        stp     x29,    x30,    [sp, $1]!
        mov     x29,    sp
        '
)

define(
        endfunction,
        `
        ldp     x29,    x30,    [sp], $1
        ret
        '
)

	.text
	txt_invalidargs:		.string "Invalid arguments."
	f_9d:				.string	"%9d"
	tst_args:			.string "name: %s \trows: %d\tcols: %d"

	.balign	4
	.global	main

numRows_size = 4
numCols_size = 4
name_size = 8
 
numRows_s = 16
numCols_s = numRows_s + numRows_size
name_s = numCols_s + numCols_size

alloc = -(numRows_size + numCols_size + name_size + 16) & -16
dealloc = -alloc


main:
	startfunction(alloc)

	// arguments are exec file, num of rows, num of cols, and name
	cmp	x0,	4			// if argc == 4,
	b.ne	invalidargs			// prompt invalid arguments

	ldr	x19,	[x1, 8]			// load 1st arg (name base address)		
	str	x19,	[x29, name_s]		// save name base address to main stack

	// Get and store number of rows
	ldr	x19,	[x1, 16]		// load 2nd arg (num of rows base address)		
	mov	x0,	x19
	ldr	x20,	[x1, 24]		// load 3rd arg (num of cols base address)	
	ldr	x1,	=f_9d
	add	x2,	x29,	numRows_s
	bl	sscanf				// convert to int and store to stack
	cmp	x0,	xzr			// if sscanf return is 0,
	b.eq	invalidargs			// end
	
	// Get and store number of columns
	mov	x0,	x20
	ldr	x1,	=f_9d
	add	x2,	x29,	numCols_s
	bl	sscanf				// convert to int and store to stack
	cmp	x0,	xzr			// if sscanf return is 0,
	b.eq	invalidargs			// end

	// Seed rand
	mov	x0,	xzr
	bl	time
	bl	srand

	// Allocate space for two boards: 
	// 1. Board containing floats: (rows * cols * 4) bytes
	// 2. Board(bool board) defining which cells are covered/uncovered: (rows * cols * 2) bytes
	// (rows * cols * 4) + (rows * cols * 2) = (rows * cols * 6)
	// So first, we load the needed values
	ldr	w19,	[x29,	numRows_s]
	ldr	w20,	[x29,	numCols_s]

	mov 	x21,	6		// remember 6
	mul	x21,	x21,	x19	// 6 * rows
	mul	x21,	x21,	x20	// 6rows * cols	
	and	x21,	x21,	16	// pad bytes if necessary
	// x21 now contains the number of bytes to be allocated for both arrays

	sub	sp,	sp,	x21	// allocate space for two boards

	// Here we supply args for initializeGame and call it	
	mov	x0,	x29		// pass base address of float board 

	// base address of bool board would be end of float board
	mul	x1,	x19,	x20	// so, we calculate the bytes allocated for float board and
	lsl	x1,	x1,	2	// sub (go down) that from the frame pointer and we get
	sub	x1,	x29,	x1	// the address of the bool board

	mov	x2,	x19		// pass rows
	mov	x3,	x20		// pass cols
	//bl	initializeGame	

test_randNum:
	mov	x0,	0
	mov	x1,	15
	mov	x2,	0
	bl	randomNum

	// Deallocate space for two boards:
	ldr	x19,	[x29,	numRows_s]
	ldr	x20,	[x29,	numCols_s]

	mov 	x21,	6		// remember 6
	mul	x21,	x21,	x19	// 6 * rows
	mul	x21,	x21,	x20	// 6rows * cols	
	and	x21,	x21,	16	// pad bytes if necessary
	// x21 now contains the number of bytes to be allocated for both arrays

	add	sp,	sp,	x21	// deallocate space for two boards

	b	end

invalidargs:
	ldr	x0,	=txt_invalidargs
	bl	printf
	b	end

end:
	endfunction(dealloc)
