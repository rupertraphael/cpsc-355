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
	cell_value:			.string "%8.2f"
	br:				.string	"\n"
	exit_info:			.string "Exit Position: %d\n"
	numpos_info:			.string "Positives: %d / %d - %.2f\n"
	numnegs_info:			.string "Negatives: %d / %d - %.2f\n"
	numups_info:			.string "Powerups: %d / %d - %.2f\n"
	f_board:			.string "%s%-3s\x1B[0m"
	txt_covered:			.string "X"
	txt_positive:			.string "+"
	txt_negative:			.string "-"
	txt_powerup:			.string "$"
	txt_exit:			.string "*"
	color_cyan:			.string "\x1B[36m"
	color_normal:			.string "\x1B[0m"		
	color_red:			.string "\x1B[31m"
	color_green: 			.string "\x1B[32m"
	color_yellow:			.string "\x1B[33m"
	txt_bombsleft:			.string "You have %d bombs left\n"
	txt_stopprompt:			.string "If you want to stop playing input \"-1 -1\".\n"
	txt_dropbombprompt:		.string "Drop the bomb at (x y): "
	txt_playinvalidinput:		.string "\x1B[31mSorry, invalid input! Try again.\x1B[0m\n"
	scanf_bombcoords:		.string "%d %d"
	txt_bombposition:		.string "Bombing position: %d, %d...\n"
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

	// Display Board
	mov	x0,	x29		// pass base address of float board 
	mul	x1,	x19,	x20	// so, we calculate the bytes allocated for float board and
	lsl	x1,	x1,	2	// sub (go down) that from the frame pointer and we get
	sub	x1,	x29,	x1	// the address of the bool board

	mov	x2,	x19		// pass rows
	mov	x3,	x20		// pass cols
	bl	displayGame

	// Play Game
	mov	x0,	x29		// pass base address of float board 
	mul	x1,	x19,	x20	// so, we calculate the bytes allocated for float board and
	lsl	x1,	x1,	2	// sub (go down) that from the frame pointer and we get
	sub	x1,	x29,	x1	// the address of the bool board

	mov	x2,	x19		// pass rows
	mov	x3,	x20		// pass cols
	ldr	x4,	[x29, name_s]	// pass name
	bl	playGame

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

// macro for loading a float value into a 2D array
// load_float_from_array2d(&array_r, row_r, col_r, numcols_r, value_sr) 
define(
	load_float_from_array2d,
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

// macro for loading a boolean value into a 2D array
// load_bool_from_array2d(&array_r, row_r, col_r, numcols_r, value_wr) 
define(
	load_bool_from_array2d,
	`
	// row_r is gonna be used an offset for loading int value from memory
	// offset = (row * numcols + col) * 4
	sub	$2,	xzr,	$2	// negate row
	mul	$2,	$2,	$4	// row = row * numcols
	sub	$2,	$2,	$3	// row -= col
	ldrb	$5,	[$1, $2] 	// load value from array
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

	// Determine max position for exit tile
	// Since randomNum only works with a max of
	// 2^n - 1, here we select a max that is a power
	// of 2 that is within the bounds of the board
	mov	w19,	1			// w19 is max exit position
init_game_det_exit:
	ldr	w20,	[x29, numRows_s]
	ldr	w21,	[x29, numCols_s]
	mul	w20,	w20, 	w21
	cmp	w19,	w20
	b.lt	init_game_exit_pow
	b.gt	init_game_exit_limit
	b 	init_game_exit_store

init_game_exit_pow:
	lsl	w19,	w19,	1	
	b	init_game_det_exit
	
init_game_exit_limit:	
	lsr	w19,	w19,	1	
	
init_game_exit_store:
	mov	w0,	1		// set min as 1
	sub	w1,	w19,	1	// set max as powof2 - 1
	mov	w2,	wzr		// get positive numbers
	bl	randomNum
	fcvtns	w19,	s0		// convert single to int

	sub	x19,	xzr,	x19	// negate to use as offset
	ldr	x20,	[x29, fboardp_s]// load address of float board
	
	scvtf	s20,	wzr			// convert zero to float
	ldr	s19,	[x20, x19, LSL 2]	// load float value in board at chosen offset
	fcmp	s19,	s20			// check float value to be replaced: if its < 0
	b.lt	init_game_dec_neg		// decrement number of negatives if so
	mov	w21,	69			// 69 is the integer representing powerups
	scvtf	s21,	w21			// convert 69 to float
	fcmp	s19,	s21			// compare float value to replaced: if its = 69
	b.eq	init_game_dec_ups		// decrement num of power-ups if so
	
	b	init_game_exit_store_zero	// else, just directly store exit tile in board

init_game_dec_neg:
	ldr	w22,	[x29, numnegs_s]
	sub	w22,	w22,	1
	str	w22,	[x29, numnegs_s]
	b	init_game_exit_store_zero

init_game_dec_ups:
	ldr	w22,	[x29, numups_s]
	sub	w22,	w22,	1
	str	w22,	[x29, numups_s]

init_game_exit_store_zero:
	scvtf	s20,	wzr
	str	s20,	[x20, x19, LSL 2]	
	sub	x19,	xzr, 	x19

	ldr	x0,	=exit_info
	mov	x1,	x19
	bl	printf

	str	wzr,	[x29, row_s]
init_game_display_row:
	b	init_game_display_row_test

init_game_display_row_body:
	str	wzr,	[x29, col_s]

init_game_display_col:
	b	init_game_display_col_test
init_game_display_col_body:
	
	ldr	x19,	[x29, fboardp_s]
	ldr	w20,	[x29, row_s]
	ldr	w21,	[x29, col_s]
	ldr	w22,	[x29, numCols_s]
	load_float_from_array2d(x19, x20, x21, x22, s0)
	fcvt	d0,	s0
	ldr	x0,	=cell_value
	bl	printf
		
	//increment column
	ldr	w19,	[x29, col_s]
	add	w19,	w19,	1
	str	w19,	[x29, col_s]

init_game_display_col_test:
	ldr	w19,	[x29, col_s]
	ldr	w20,	[x29, numCols_s]
	cmp	w19,	w20
	b.lt	init_game_display_col_body

	//increment row
	ldr	w19,	[x29, row_s]
	add	w19,	w19,	1
	str	w19,	[x29, row_s]

	str	wzr,	[x29, col_s]

	ldr	x0,	=br
	bl	printf
init_game_display_row_test:
	ldr	w19,	[x29, row_s]
	ldr	w20,	[x29, numRows_s]
	cmp	w19,	w20
	b.lt	init_game_display_row_body

init_game_display_info:
	// Calculate total number of cells
	ldr	w27,	[x29, numRows_s]	
	ldr	w28,	[x29, numCols_s]
	mul	w28,	w27, 	w28

	// Positives info
	mov	w2,	w28
	ldr	w19,	[x29, numnegs_s]
	ldr	w20,	[x29, numups_s]
	sub	w1,	w2,	w19
	sub	w1,	w1,	w20
	scvtf	d19,	x1
	scvtf	d20,	x2
	fdiv	d0,	d19,	d20
	ldr	x0,	=numpos_info
	bl	printf

	// Negatives info
	mov	w2,	w28
	ldr	w1,	[x29, numnegs_s]
	scvtf	d19,	x1
	scvtf	d20,	x2
	fdiv	d0,	d19,	d20
	ldr	x0,	=numnegs_info
	bl	printf

	// Powerups info
	mov	w2,	w28
	ldr	w1,	[x29, numups_s]
	scvtf	d19,	x1
	scvtf	d20,	x2
	fdiv	d0,	d19,	d20
	ldr	x0,	=numups_info
	bl	printf

	ldr_x()
	mov	x1, 	dealloc
	endfunction(dealloc)

init_subr_x()
fboardp_size = 8
bboardp_size = 8
numRows_size = 4
numCols_size = 4
row_size = 4
col_size = 4
fboardp_s = dealloc
bboardp_s = fboardp_s + fboardp_size
numRows_s = bboardp_s + bboardp_size
numCols_s = numRows_s + numRows_size
row_s = numCols_s + numCols_size
col_s = row_s + row_size
alloc = (alloc - fboardp_size - bboardp_size - numRows_size - numCols_size - row_size - col_size) & -16
dealloc = -alloc
displayGame:
	startfunction(alloc)
	str_x()

	str	x0,	[x29, fboardp_s]
	str	x1,	[x29, bboardp_s]
	str	w2,	[x29, numRows_s]
	str	w3,	[x29, numCols_s]

	str	wzr,	[x29, row_s]
display_game_display_row:
	b	display_game_display_row_test

display_game_display_row_body:
	str	wzr,	[x29, col_s]

display_game_display_col:
	b	display_game_display_col_test
display_game_display_col_body:
	
	ldr	x19,	[x29, fboardp_s]
	ldr	w20,	[x29, row_s]
	ldr	w21,	[x29, col_s]
	ldr	w22,	[x29, numCols_s]
	load_float_from_array2d(x19, x20, x21, x22, s19)
	
	ldr	x19,	[x29, bboardp_s]
	load_bool_from_array2d(x19, x20, x21, x22, w23)

	ldr	x0,	=f_board

	cmp	w23,	1
	b.ne 	display_game_display_uncovered

display_game_display_covered:
	ldr	x1,	=color_cyan	
	ldr	x2,	=txt_covered
	bl	printf
	b 	display_game_inc_col	

display_game_display_uncovered:
	mov	w19,	69
	scvtf	s20,	w19
	fcmp	s19,	s20	// if value in board equals 69,
	b.eq	display_game_display_powerup	
	mov	w19,	0
	scvtf	s20,	w19
	fcmp	s19,	s20	// if value in board equals 0,
	b.eq	display_game_display_exit	
	b.lt	display_game_display_negative
	b.gt	display_game_display_positive

display_game_display_exit:	
	ldr	x1,	=color_normal	
	ldr	x2,	=txt_exit
	bl	printf
	b 	display_game_inc_col	

display_game_display_powerup:	
	ldr	x1,	=color_yellow	
	ldr	x2,	=txt_powerup
	bl	printf
	b 	display_game_inc_col	

display_game_display_negative:	
	ldr	x1,	=color_red	
	ldr	x2,	=txt_negative
	bl	printf
	b 	display_game_inc_col	

display_game_display_positive:	
	ldr	x1,	=color_green	
	ldr	x2,	=txt_positive
	bl	printf

display_game_inc_col:
	//increment column
	ldr	w19,	[x29, col_s]
	add	w19,	w19,	1
	str	w19,	[x29, col_s]

display_game_display_col_test:
	ldr	w19,	[x29, col_s]
	ldr	w20,	[x29, numCols_s]
	cmp	w19,	w20
	b.lt	display_game_display_col_body

	//increment row
	ldr	w19,	[x29, row_s]
	add	w19,	w19,	1
	str	w19,	[x29, row_s]

	str	wzr,	[x29, col_s]

	ldr	x0,	=br
	bl	printf
display_game_display_row_test:
	ldr	w19,	[x29, row_s]
	ldr	w20,	[x29, numRows_s]
	cmp	w19,	w20
	b.lt	display_game_display_row_body

	ldr_x()
	endfunction(dealloc)

init_subr_x()
fboardp_size = 8
bboardp_size = 8
numRows_size = 4
numCols_size = 4
x_size = 4
y_size = 4
bombradius_size = 4
totalscorep_size = 8
livesp_size = 8
bombpowerupsp_size = 8
exitfoundp_size = 8

roundscore_size = 4
score_size = 4
startx_size = 4
starty_size = 4
endx_size = 4
endy_size = 4
row_size = 4
col_size = 4

fboardp_s = dealloc
bboardp_s = fboardp_s + fboardp_size
numRows_s = bboardp_s + bboardp_size
numCols_s = numRows_s + numRows_size
x_s = numCols_s + numCols_size
y_s = x_s + x_size
bombradius_s = y_s + y_size
totalscorep_s = bombradius_s + bombradius_size
livesp_s = totalscorep_s + totalscorep_size
bombpowerupsp_s = livesp_s + livesp_size
exitfoundp_s = bombpowerupsp_s + bombpowerupsp_size 
roundscore_s = exitfoundp_s
alloc = (alloc - fboardp_size - bboardp_size - numRows_size - numCols_size - x_size - y_size)
alloc = (alloc - bombradius_size - totalscorep_size - livesp_size - bombpowerupsp_size - exitfoundp_size)
dealloc = -alloc
calculateScore:
	startfunction(alloc)
	str_x()

	str	x0,	[x29, fboardp_s]
	str	x1,	[x29, bboardp_s]
	str	w2,	[x29, numRows_s]
	str	w3,	[x29, numCols_s]
	str	w4,	[x29, x_s]
	str	w5,	[x29, y_s]
	str	w6,	[x29, bombradius_s]
	str	x7,	[x29, totalscorep_s]
	str	x9,	[x29, livesp_s]
	str	x10,	[x29, bombpowerupsp_s]
	str	x11,	[x29, exitfoundp_s]

	

	ldr_x()
	endfunction(dealloc)


init_subr_x()
fboardp_size = 8
bboardp_size = 8
numRows_size = 4
numCols_size = 4
row_size = 4
col_size = 4
bombs_size = 4
x_size = 4
y_size = 4
bombradius_size = 4
bombpowerups_size = 4
lives_size = 4
exitfound_size = 1
totalscore_size = 4
roundscore_size = 4
name_size = 8
fboardp_s = dealloc
bboardp_s = fboardp_s + fboardp_size
numRows_s = bboardp_s + bboardp_size
numCols_s = numRows_s + numRows_size
row_s = numCols_s + numCols_size
col_s = row_s + row_size
bombs_s = col_s + col_size
x_s = bombs_s + bombs_size
y_s = x_s + x_size
bombradius_s = y_s + y_size
bombpowerups_s = bombradius_s + bombradius_size
lives_s = bombpowerups_s + bombpowerups_size
exitfound_s = lives_s + lives_size
totalscore_s = exitfound_s + exitfound_size
roundscore_s = totalscore_s + totalscore_size
name_s = roundscore_s + roundscore_size
alloc = (alloc - fboardp_size - bboardp_size - numRows_size - numCols_size - row_size - col_size - bombs_size)
alloc = (alloc - x_size - y_size - bombradius_size - bombpowerups_size - lives_size - exitfound_size - totalscore_size)
alloc = (alloc - roundscore_size - name_size) & -16
dealloc = -alloc
playGame:
	startfunction(alloc)
	str_x()

	str	x0,	[x29, fboardp_s]
	str	x1,	[x29, bboardp_s]
	str	w2,	[x29, numRows_s]
	str	w3,	[x29, numCols_s]
	str	x4,	[x29, name_s]

	// Calculate bombs = 1 + numrows * numcols * 0.02
	mov	w19,	1
	mul	w20,	w2,	w3
	mov	w21,	50
	sdiv	w20,	w20,	w21
	add	w19,	w19,	w20
	str	w19,	[x29, bombs_s]	

	// Initialize bomb radius
	mov	w19,	1
	str	w19,	[x29, bombradius_s]
	// Initialize bomb powerups
	str	wzr,	[x29, bombpowerups_s]

	// Set lives
	mov	w19,	3
	str	w19,	[x29, lives_s]

	// Initialize exit found
	strb	wzr,	[x29, exitfound_s]

	// Initialize scores
	scvtf	s19,	wzr
	str	s19,	[x29, totalscore_s]
	str	s19,	[x29, roundscore_s]

	
playGame_loop:
	b	playGame_loop_test

playGame_loop_body:
	// Print bombs left
	ldr	x0,	=txt_bombsleft
	ldr	x1,	[x29, bombs_s]
	bl	printf
	// Prompt to stop playing
	ldr	x0,	=txt_stopprompt
	bl	printf
	// Prompt to drop the bomb
	ldr	x0,	=txt_dropbombprompt
	bl	printf

	// Read user input for x and y
	ldr	x0,	=scanf_bombcoords
	add	x1,	x29,	x_s
	add	x2,	x29,	y_s
	bl	scanf	
	
	cmp	x0,	2
	b.ne	playGame_invalid_input

	// if x or y is -1, end game loop
	ldr	w19,	[x29, x_s]
	mov	w21,	-1
	cmp	w19,	w21
	b.eq	playGame_loop_end	
	ldr	w20,	[x29, y_s]
	cmp	w20,	w21
	b.eq	playGame_loop_end	

	ldr	x0,	=txt_bombposition
	mov	w1,	w19
	mov	w2,	w20
	bl	printf	

	// Reset round score to 0
	str	wzr,	[x29, roundscore_s]
	// Reset powerups count
	str	wzr,	[x29, bombpowerups_s]

	// TODO: roundScore = calculateScore
	ldr	x0,	[x29, fboardp_s]
	ldr	x1,	[x29, bboardp_s]
	ldr	w2,	[x29, numRows_s]
	ldr	w3,	[x29, numCols_s]
	ldr	w4,	[x29, x_s]
	ldr	w5,	[x29, y_s]
	ldr	w6,	[x29, bombradius_s]
	add	x7,	x29, 	totalscore_s
	add	x9,	x29, 	lives_s
	add	x10,	x29,	bombpowerups_s
	add	x11,	x29, 	exitfound_s
	bl	calculateScore

	// Reset bomb radius
	mov	w19,	1
	str	w19,	[x29, bombradius_s]

	// Display game
	ldr	x0,	[x29, fboardp_s]
	ldr	x1,	[x29, bboardp_s]
	ldr	w2,	[x29, numRows_s]
	ldr	w3,	[x29, numCols_s]
	bl	displayGame

	// TODO: Calculate bombradius

	// TODO: Printing of scores and lives

	// Decrement bombs
	ldr	w19,	[x29, bombs_s]
	sub	w19,	w19,	1
	str	w19,	[x29,	bombs_s]

playGame_loop_test:
	ldr	w19,	[x29, bombs_s]
	cmp	w19,	wzr
	b.le	playGame_loop_end
	ldrb	w19,	[x29, exitfound_s]
	cmp	w19,	wzr
	b.ne	playGame_loop_end
	ldr	w19,	[x29, lives_s]
	cmp	w19,	wzr		
	b.le	playGame_loop_end
	b	playGame_loop_body	

playGame_invalid_input:
	ldr	x0,	=txt_playinvalidinput
	bl	printf
	b	playGame_loop_body

playGame_loop_end:

	ldr_x()
	endfunction(dealloc)



