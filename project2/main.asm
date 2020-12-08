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
	f_f2:				.string "%.2f"
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

	mov 	x21,	-5		// remember 6
	mul	x21,	x21,	x19	// 6 * rows
	mul	x21,	x21,	x20	// 6rows * cols	
	mov	x22,	-16
	and	x21,	x21,	x22	// pad bytes if necessary
	// x21 now contains the number of bytes to be allocated for both arrays

	add	sp,	sp,	x21	// allocate space for two boards

	// Here we supply args for initializeGame and call it	
	mov	x0,	x29		// pass base address of float board 

	// base address of bool board would be end of float board
	mul	x1,	x19,	x20	// so, we calculate the bytes allocated for float board and
	lsl	x1,	x1,	2	// sub (go down) that from the frame pointer and we get
	sub	x1,	x29,	x1	// the address of the bool board

	mov	x2,	x19		// pass rows
	mov	x3,	x20		// pass cols
	bl	initializeGame	

test_randNum:
	mov	x0,	0
	mov	x1,	15
	mov	x2,	1
	bl	randomNum
	fcvt	d0,	s0
	ldr	x0, 	=f_f2
	bl	printf

	// Deallocate space for two boards:
	ldr	w19,	[x29, numRows_s]
	ldr	w20,	[x29, numCols_s]

	mov 	x21,	-5		// remember 6
	mul	x21,	x21,	x19	// 6 * rows
	mul	x21,	x21,	x20	// 6rows * cols	
	and	x21,	x21,	-16	// pad bytes if necessary
	// x21 now contains the number of bytes to be allocated for both arrays

	sub	sp,	sp,	x21	// deallocate space for two boards

	b	end

invalidargs:
	ldr	x0,	=txt_invalidargs
	bl	printf
	b	end

end:
	endfunction(dealloc)

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


// macro for storing an float value into a 2D array
// store_float_to_array2d(&array_r, row_r, col_r, numcols_r, value_sr) 
define(
	store_float_to_array2d,
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

// macro for storing a boolean  value into a 2D array
// store_bool_to_array2d(&array_r, row_r, col_r, numcols_r, value_sr) 
define(
	store_bool_to_array2d,
	`
	// row_r is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	$2,	xzr,	$2	// negate row
	mul	$2,	$2,	$4	// row = row * numcols
	sub	$2,	$2,	$3	// row -= col
	strb	$5,	[$1, $2]	// store value into array
	add 	$2,	$2,	$3	// row += col
	sdiv	$2,	$2,	$4	// row /= numcols
	sub	$2,	xzr,	$2	// make row positive again
	// row is now positive and restored
	'
)



init_subr_x()
fboardp_size = 8
bboardp_size = 8
numRows_size = 4
numCols_size = 4
row_size = 4
col_size = 4
maxups_size  = 4
maxnegs_size = 4
numups_size = 4
numnegs_size = 4
dice_size = 4
number_size = 4
fboardp_s = dealloc
bboardp_s = fboardp_s + fboardp_size
numRows_s = bboardp_s + bboardp_size
numCols_s = numRows_s + numRows_size
row_s = numCols_s + numCols_size
col_s = row_s + row_size
maxups_s = col_s + col_size
maxnegs_s = maxups_s + maxups_size
numups_s = maxnegs_s + maxnegs_size
numnegs_s = numups_s + numups_size
dice_s = numnegs_s + numnegs_size
number_s = dice_s + dice_size
alloc = (alloc - fboardp_size - bboardp_size - numRows_size - numCols_size - number_size)
alloc = (alloc - row_size - col_size - maxups_size - maxnegs_size - numups_size - numnegs_size - dice_size) & -16
dealloc = -alloc

initializeGame:
	startfunction(alloc)
	str_x()

init:

	str	x0,	[x29, fboardp_s]
	str	x1,	[x29, bboardp_s]
	str	w2,	[x29, numRows_s]
	str	w3,	[x29, numCols_s]

	// calculate max number of powerups
	mul	w19,	w2,	w3
	mov	w20,	20
	mul	w19,	w19,	w20		// 20% powerups
	str	w19,	[x29, maxups_s]
	
	// calculate max negatives
	mul	w19,	w2,	w3		
	mov	w20,	40
	mul	w19,	w19,	w20		// 40% negatives
	str	w19,	[x29, maxnegs_s]

	str	wzr,	[x29, row_s]		// row = 0
	str	wzr,	[x29, numnegs_s]	// number of negatives = 0
	str	wzr,	[x29, numups_s]		// number of powerups = 0
init_game_loop_row:
	b	init_game_loop_row_test

init_game_loop_row_body:
	mov	w19,	0
	str	w19,	[x29, col_s]		// col = 0
init_game_loop_col:
	b	init_game_loop_col_test

init_game_loop_col_body:

	mov	x0,	1
	mov	x1,	15
	mov	x2,	0	
	bl	randomNum
	str	s0,	[x29, dice_s]

add_negative:
	// diceMax * percentageOfNegatives / 100
	mov	w19,	40
	mov	w20,	15
	mul	w19,	w19, 	w20	// percentageOfNegatives * diceMax
	scvtf	s19,	w19
	mov	w19,	100
	scvtf	s20,	w19		// convert 100 to float	
	fdiv	s19,	s19,	s20	// percentageOfNeegatives * diceMax / 100
	fcmp	s0,	s19		// compare dice and diceMax * percentageOfNegatives / 100
	b.gt	add_powerup	
	ldr	w19, 	[x29, numnegs_s]
	ldr	w20,	[x29, maxnegs_s]
	cmp	w19,	w20		// compare number of negatives and max number of negatives
	b.gt	add_powerup
	add	w19,	w19,	1	// increment number of negatives	
	str	w19,	[x29, numnegs_s]

	mov	x0,	xzr
	mov	x1,	15
	mov	x2,	1
	bl	randomNum
	str	s0,	[x29,	number_s]
	b	init_game_store

add_powerup:
	// diceMax * (percentageofPowerups + percentageOfNegatives) / 100
	mov	w19,	60		// 60 = percentageofPowerups + percentageOfNegatives
	mov	w20,	15		// 15 = dice Max
	mul	w19,	w19, 	w20	// (% of powerups + percentageOfNegatives) * diceMax
	scvtf	s19,	w19		
	mov	w19,	100
	scvtf	s20,	w19		// convert 100 to float	
	fdiv	s19,	s19,	s20	// (% ups + % negatives) * diceMax / 100
	fcmp	s0,	s19		// compare dice and diceMax * (% ups + % negatives) / 100
	b.gt	add_positive	
	ldr	w19, 	[x29, numups_s]
	ldr	w20,	[x29, maxups_s]
	cmp	w19,	w20		// compare number of powerups and max number of powerups
	b.gt	add_positive
	add	w19,	w19,	1	// increment number of powerups
	str	w19,	[x29, numups_s]

	mov	w19,	69
	scvtf	s19,	w19		
	str	s19,	[x29, number_s]
	b	init_game_store

add_positive:
	mov	x0,	xzr
	mov	x1,	15
	mov	x2,	0
	bl	randomNum
	str	s0,	[x29, number_s]

init_game_store:
	ldr	s19,	[x29,	number_s]
	// store float in float board			
	ldr	x19,	[x29, fboardp_s]
	ldr	w20,	[x29, row_s]
	ldr	w21,	[x29, col_s]
	ldr	w22,	[x29, numCols_s]
	store_float_to_array2d(x19, x20 ,x21, x22, s19)
	// initialize boolean board - 1 means covered
	ldr	x19,	[x29, bboardp_s]
	mov	w23,	1
	store_bool_to_array2d(x19, x20, x21, x22, w23)
	// increment column
	ldr	w19,	[x29, col_s]
	add	w19,	w19,	1
	str	w19,	[x29, col_s]

init_game_loop_col_test:
	ldr	w19,	[x29, col_s]
	ldr	w20,	[x29, numCols_s]
	cmp	w19,	w20
	b.lt	init_game_loop_col_body


	// reset column to zero
	ldr	w19,	[x29, col_s]
	mov	w19,	wzr
	str	w19,	[x29, col_s]
	
	// increment row 
	ldr	w19,	[x29, row_s]
	add	w19,	w19,	1
	str	w19,	[x29, row_s]

init_game_loop_row_test:
	ldr	w19,	[x29, row_s]
	ldr	w20,	[x29, numRows_s]
	cmp	w19,	w20
	b.lt	init_game_loop_row_body

	ldr_x()
	mov	x1, 	dealloc
	endfunction(dealloc)



init_subr_x()
min_size = 4
max_size = 4
negative_size = 4
min_s = dealloc
max_s = min_s + min_size
alloc = (alloc - min_size - max_size) & -16
dealloc = -alloc
randomNum:
	startfunction(alloc)

	str_x()

	str	x0,	[x29, min_s]
	str	x1,	[x29, max_s]
	mov	x28,	x2

generateNum:
	bl	rand
	mov	x19,	x0		// num = rand

	ldr	x20,	[x29, min_s]
	add	x19,	x19,	x20	// num += min

	ldr	x21,	[x29, max_s]
	and	x19,	x19,	x21	// num &= max	

	cmp	x19,	x20
	b.eq	generateNum

	cmp	x19,	x21
	b.eq	generateNum
	
	scvtf	s19,	x19	

makeNumFloat:
	bl	rand
	and	x0,	x0,	255
	scvtf	s21,	x0
	
	mov	x22,	255
	scvtf	s20,	x22

	fdiv	s21,	s21,	s20
	fadd	s19,	s19,	s21		

makeNegative:
	cmp	x28,	1
	b.ne	end_randNum
	mov	x19,	xzr
	scvtf	s20,	x19		// Make 0 float
	fsub	s19,	s20,	s19	// Make random float negative
	
end_randNum:
	fmov	s0,	s19

	ldr_x()
	endfunction(dealloc)

