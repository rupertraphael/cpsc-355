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
	f_topscoreinfo:			.string "%3d. %s\t%.2f\t%d\n"
	param_R:			.string "r"
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
	txt_bombradiusinfo:		.string "\x1B[33mBang to the power of %d! Your next bomb's radius is now %d \x1B[0m\n"
	scanf_bombcoords:		.string "%d %d"
	scanf_playinfo:			.string "%s %f %d"
	txt_bombposition:		.string "Bombing position: %d, %d...\n"
	txt_roundscore:			.string "Round Score: %.2f\n"
	txt_totalscore:			.string "Total Score: %.2f\n"
	txt_gameover:			.string	"\x1B[31mGame Over!\x1B[0m\n"
	txt_playinfo:			.string "%s\t%.2f\t%d\n"
	txt_lives:			.string "Lives Left: %d\n"
	txt_askscores:			.string "How many top scores would you like to see? "
	scanf_d:			.string "%d"
	txt_noscores:			.string "Leaderboard file missing."
	leaderboard_file:		.string "leaderboard.txt"
	tst_args:			.string "name: %s \trows: %d\tcols: %d"
	test_s:				.string "%s\n"
	test_d:				.string "%d\n"
	test_f:				.string "%f\n"

	.balign	4
	.global	main

numRows_size = 4
numCols_size = 4
name_size = 8
n_s = 4
 
numRows_s = 16
numCols_s = numRows_s + numRows_size
name_s = numCols_s + numCols_size
n_s = name_s + name_size

alloc = -(numRows_size + numCols_size + name_size + name_size) & -16
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

	// Set minimum number of rows and columns
	ldr	w19,	[x29, numRows_s]
	cmp	w19,	10
	b.lt	invalidargs
	ldr	w19,	[x29, numCols_s]
	cmp	w19,	10
	b.lt	invalidargs

	// Seed rand
	mov	x0,	xzr
	bl	time
	bl	srand

	// Allocate space for two boards: 
	// 1. Board containing floats: (rows * cols * 4) bytes
	// 2. Board(bool board) defining which cells are covered/uncovered: (rows * cols * 2) bytes
	// (rows * cols * 4) + (rows * cols * 1) = (rows * cols * 5)
	// So first, we load the needed values
	ldr	w19,	[x29,	numRows_s]
	ldr	w20,	[x29,	numCols_s]

	mov 	x21,	-5		// remember 5
	mul	x21,	x21,	x19	// 5 * rows
	mul	x21,	x21,	x20	// 5rows * cols	
	mov	x22,	-16
	and	x21,	x21,	x22	// pad bytes if necessary
	// x21 now contains the number of bytes to be allocated for both arrays

	add	sp,	sp,	x21	// allocate space for two boards

startGame:
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

	// Ask for number of top scores to display:
	ldr	x0,	=txt_askscores
	bl	printf
	ldr	x0,	=scanf_d
	mov	x1,	xzr
	add	x1,	x29,	n_s
	bl	scanf	

	// Display top scores
	ldr	w0,	[x29, n_s]
	bl	displayTopScores

	//b	startGame	

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

/**
 * Populate the main board with numbers and
 * cover the bool game board
 * @param board           the board that should contain numbers
 * @param covered         the board that determines of a cell is covered or not
 * @param numberOfRows    the boards' number of rows
 * @param numberOfColumns the boards' number of columns
 */

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

/**
 * Display the board.
 * X - covered/not bombed yet
 * $ - bomb powerup (radius doubler)
 * - - negative score
 * + - positive score
 * @param board           main board with numbers
 * @param covered         board that determines which cells are covered
 * @param numberOfRows    boards' number of rows
 * @param numberOfColumns boards' number of columns
 */

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
roundscore_s = exitfoundp_s + exitfoundp_size
score_s = roundscore_s  + roundscore_size
startx_s = score_s + score_size
starty_s = startx_s + startx_size
endx_s = starty_s + starty_size
endy_s = endx_s + endx_size
row_s = endy_s + endy_size
col_s = row_s + row_size

alloc = (alloc - fboardp_size - bboardp_size - numRows_size - numCols_size - x_size - y_size)
alloc = (alloc - bombradius_size - totalscorep_size - livesp_size - bombpowerupsp_size - exitfoundp_size)
alloc = (alloc - roundscore_size - score_size - startx_size - starty_size - endx_size - endy_size - row_size - col_size) & -16
dealloc = -alloc

/**
 * Calculates the player's score,
 * lives, bomb powerups count, and determines
 * if exit is found.
 * @param 	board             main board with values
 * @param 	covered           board that determines which cells are covered
 * @param 	numberOfRows      the boards' number of rows
 * @param 	numberOfColumns   boards' number of columns
 * @param 	x                 x coordinate to bomb
 * @param 	y                 y coordinate to bomb
 * @param 	bombRadius        determines how large the bomb area is going to be
 * @param 	totalScore        player's score; becomes 0 when it becomes negative and lives > 0
 * @param 	lives             player's number of lives
 * @param 	bombPowerupsCount player's number of bomb powerups for the round
 * @param 	exitFound         determines whether the exit has been found
 * @return 	roundScore		  player's score for the round (not reset)		
 */

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

	// Initialize scores
	scvtf	s19,	wzr	
	str	s19,	[x29, roundscore_s]

	// Calculate start position (top left)
	ldr	w19,	[x29, x_s]
	ldr	w20,	[x29, y_s]
	ldr	w21,	[x29, bombradius_s]	

	sub	w22,	w19,	w21		// x - bombradius
	cmp	w22,	wzr
	b.lt	calculateScore_limit_startx
calculateScore_store_startx:
	str	w22,	[x29, startx_s]

	sub	w22,	w20,	w21		// y - bombradius
	cmp	w22,	wzr
	b.lt	calculateScore_limit_starty
calculateScore_store_starty:
	str	w22,	[x29, starty_s]

	// Calculate end position (bottom right)
	ldr	w19,	[x29, x_s]
	ldr	w20,	[x29, y_s]
	ldr	w21,	[x29, bombradius_s]	
	add	w22,	w19,	w21		// x + bombradius
	ldr	w23,	[x29, numRows_s]	
	sub	w23,	w23,	1		// numRows - 1
	cmp	w22,	w23
	b.gt	calculateScore_limit_endx
calculateScore_store_endx:
	str	w22,	[x29, endx_s]

	add	w22,	w20,	w21		// y + bombradius
	ldr	w23,	[x29, numCols_s]	
	sub	w23,	w23,	1		// numCols - 1
	cmp	w22,	w23
	b.gt	calculateScore_limit_endy
calculateScore_store_endy:
	str	w22,	[x29, endy_s]

	b	calculateScore_loop

calculateScore_limit_startx:
	mov	w22,	wzr	
	b	calculateScore_store_startx
	
calculateScore_limit_starty:
	mov	w22,	wzr	
	b	calculateScore_store_starty
	
calculateScore_limit_endx:
	ldr	w23,	[x29, numRows_s]	
	sub	w22,	w23,	1		// numRows - 1
	b	calculateScore_store_endx

calculateScore_limit_endy:
	ldr	w23,	[x29, numCols_s]	
	sub	w22,	w23,	1		// numCols - 1
	b	calculateScore_store_endy

calculateScore_loop:
	ldr	w19,	[x29, startx_s]
	str	w19,	[x29, row_s]		// row = start_x

calculateScore_loop_row:
	b	calculateScore_loop_row_test

calculateScore_loop_row_body:

	ldr	w19,	[x29, starty_s]
	str	w19,	[x29, col_s]		// col = start_y	

calculateScore_loop_col:
	b	calculateScore_loop_col_test

calculateScore_loop_col_body:

	// skip if uncovered already	
	ldr	x19,	[x29, bboardp_s]
	ldr	w20,	[x29, row_s]
	ldr	w21,	[x29, col_s]
	ldr	w22,	[x29, numCols_s]
	load_bool_from_array2d(x19, x20, x21, x22, w23)
	cmp	w23,	wzr
	b.eq	calculateScore_increment_column	

	// uncover
	store_bool_to_array2d(x19, x20, x21, x22, wzr)	

	// calculate round score
	ldr	x19,	[x29, fboardp_s]
	load_float_from_array2d(x19, x20, x21, x22, s19)
	str	s19,	[x29, score_s]

	mov	w19,	69	
	scvtf	s20,	w19
	fcmp	s19,	s20
	b.eq	calculateScore_increment_bombpowerups
	mov	w19,	0	
	scvtf	s20,	w19	
	fcmp	s19,	s20
	b.eq	calculateScore_exitfound
	b	calculateScore_addscores

calculateScore_increment_bombpowerups:
	ldr	x19,	[x29, bombpowerupsp_s]
	ldr	w20,	[x19]
	add	w20,	w20,	1
	str	w20,	[x19]
	b	calculateScore_increment_column	

calculateScore_exitfound:	
	ldr	x19,	[x29, exitfoundp_s]
	mov	w20,	1
	strb	w20,	[x19]
	b	calculateScore_increment_column	

calculateScore_addscores:
	ldr	x19,	[x29, totalscorep_s]
	ldr	s20,	[x19]
	ldr	s21,	[x29, score_s]
	fadd	s20,	s20,	s21		// totalScore += score
	str	s20,	[x19]
	ldr	s22,	[x29, roundscore_s]	
	fadd	s22,	s22,	s21		// roundScore += score	
	str	s22,	[x29, roundscore_s]

calculateScore_increment_column:
	// increment col
	ldr	w19,	[x29, col_s]
	add	w19,	w19,	1
	str	w19,	[x29, col_s]	

calculateScore_loop_col_test:
	ldr	w19,	[x29, col_s]
	ldr	w20,	[x29, endy_s]
	cmp	w19,	w20
	b.le	calculateScore_loop_col_body

	// reset column
	str	wzr,	[x29, col_s]	
	
calculateScore_increment_row:
	// increment row
	ldr	w19,	[x29, row_s]
	add	w19,	w19,	1
	str	w19,	[x29, row_s]	

calculateScore_loop_row_test:
	ldr	w19,	[x29, row_s]
	ldr	w20,	[x29, endx_s]
	cmp	w19,	w20
	b.le	calculateScore_loop_row_body

calculateScore_make_total_zero:
	ldr	x19,	[x29, totalscorep_s]
	ldr	s20,	[x19]
	scvtf	s9,	wzr	
	fcmp	s20,	s9
	b.ge	calculateScore_end
	// Decrement lives
	ldr	x20,	[x29, livesp_s]	
	ldr	w21,	[x20]
	sub	w21,	w21,	1
	str	w21,	[x20]
	cmp	w21,	wzr		// if lives <= 0, skip totalscore = 0
	b.le	calculateScore_end
	str	s9,	[x19]		// totalscore = 0

calculateScore_end:
	ldr	s0,	[x29, roundscore_s]

	ldr_x()
	endfunction(dealloc)

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

init_subr_x()
name_size = 8
score_size = 4
time_size = 4
fd_size = 4
stringbuf_size = 50
name_s = dealloc
score_s = name_s + name_size
time_s = score_s + score_size
fd_s = time_s + time_size 
stringbuf_s = fd_s + fd_size
alloc = (alloc - name_size - score_size - time_size - fd_size - stringbuf_s) & -16
dealloc = -alloc

/**
 * Logs the given name, score, and time 
 * in a file.
 * @param name            player's name
 * @param score           player's score
 * @param time            time in seconds between starting the game and exit
 * @param numberOfRows    board's number of rows
 * @param numberOfColumns board's number of columns
 */

logScore:
	startfunction(alloc)
	str_x()

	str	x0,	[x29, name_s]
	fcvt	s0,	d0
	str	s0,	[x29, score_s]
	str	x1,	[x29, time_s]	

logScore_open_file:
	mov     w0,     -100
        ldr     x1,     =leaderboard_file
        mov     w2,     0101
	mov	w3,	0700
        mov     x8,     56
        svc     0
	str	w0,	[x29, fd_s]

logScore_append_file:
	mov     w0,     -100
        ldr     x1,     =leaderboard_file
        mov     w2,     02001
        mov     x8,     56
        svc     0
	str	w0,	[x29, fd_s]

	mov	x0,	xzr
	add	x0,	x29,	stringbuf_s
	ldr	x1,	=txt_playinfo	
	ldr	x2,	[x29, name_s]
	ldr	s0,	[x29, score_s]
	fcvt	d0,	s0
	ldr	x3,	[x29, time_s]
	bl	sprintf
	mov	w20,	w0

	ldr	w19,	[x29, fd_s]
	fwrite_reg(w19, x29, stringbuf_s, x20)

	ldr_x()
	endfunction(dealloc)

init_subr_x()
n_size = 4
filep_size = 8
string_size = 30
name_size = 20
score_size = 4
time_size = 4
count_size = 4
scoresp_size = 8
timesp_size = 8
namesp_size = 8
row_size = 4
swapped_size = 1
temprow_size = 4
n_s = dealloc
filep_s = n_s + n_size
string_s = filep_s + filep_size
name_s = string_s + string_size
score_s = name_s + name_size
time_s = score_s + score_size
count_s = time_s + time_size
scoresp_s = count_s + count_size
timesp_s = scoresp_s + scoresp_size
namesp_s = timesp_s + timesp_size 
row_s = namesp_s + namesp_size
swapped_s = row_s + row_size
temprow_s = swapped_s + swapped_size
alloc = (alloc - n_size - filep_size - string_size - name_size - score_size - time_size - count_size)
alloc = (alloc - scoresp_size - timesp_size - namesp_size - row_size - swapped_size - temprow_size) & -16
dealloc = -alloc

/**
 * Display n top scores which is saved
 * in a log file in the same directory.
 * @param n number of top scores to display
 */

displayTopScores:
	startfunction(alloc)
	str_x()

	str	w0,	[x29, n_s]
	// open file
	ldr	x0, 	=leaderboard_file	
	ldr	x1,	=param_R
	bl	fopen
	str	x0,	[x29, filep_s]		// Store file pointer

	cmp	x0,	xzr
	b.eq 	displayTopScores_doesnt_exist
		
	str	wzr,	[x29, count_s]		// count = 0

	// scoresp, timesp, namesp are pointers to bases of arrays 
	// namesp shall be a pointer to an array of pointers which point
	// to bases of strings
	// allocate bytes for scores (allocates at the heap)
	mov	x0,	4
	bl	malloc
	str	x0,	[x29, scoresp_s]
	// allocate bytes for times (allocates at the heap)
	mov	x0,	4
	bl	malloc
	str	x0,	[x29, timesp_s]
	// allocate bytes for names (allocates at the heap)
	mov	x0,	1
	bl	malloc
	str	x0,	[x29, namesp_s]

displayTopScores_scan_file:
	b	displayTopScores_scan_file_test
displayTopScores_scan_file_body:
	ldr	x0,	[x29, filep_s]
	ldr	x1,	=scanf_playinfo
	mov	x2,	xzr
	add	x2,	x29,	name_s
	mov	x3,	xzr
	add	x3,	x29, 	score_s
	mov	x4,	xzr
	add	x4,	x29, 	time_s	
	bl	fscanf	

	// reallocate bytes for names
	ldr	x0,	[x29, namesp_s]	
	mov	w19,	20	
	ldr	w20,	[x29, count_s]
	add	w20,	w20,	1
	mul	w1,	w20,	w19 		// count * 20
	bl	realloc
	str	x0,	[x29, namesp_s]
	// copy scanned name into name array
	ldr	x0,	[x29, namesp_s]
	ldr	w20,	[x29, count_s]
	mul	w20,	w20,	w19 		// count * 20
	add	x0,	x0,	x20
	mov	x1,	xzr
	add	x1,	x29,	name_s	
	bl	strcpy

	// reallocate bytes for scores
	ldr	x0,	[x29, scoresp_s]	
	ldr	w20,	[x29, count_s]
	add	w20,	w20,	1
	lsl	w1,	w20,	2 		// count * 4
	bl	realloc
	// score[count] = score
	str	x0,	[x29, scoresp_s]
	ldr	w20,	[x29, count_s]
	lsl	w20,	w20,	2 		// count * 4
	ldr	s21,	[x29, score_s]
	str	s21,	[x0, x20]

	// reallocate bytes for times
	ldr	x0,	[x29, timesp_s]	
	ldr	w20,	[x29, count_s]
	add	w20,	w20,	1
	lsl	w1,	w20,	2 		// count * 4
	bl	realloc
	// times[count] = time
	str	x0,	[x29, timesp_s]
	ldr	w20,	[x29, count_s]
	lsl	w20,	w20,	2 		// count * 4
	ldr	w21,	[x29, time_s]
	str	w21,	[x0, x20]

	// skip to eol
	add	x0,	x29,	string_s
	mov	x1,	string_size
	ldr	x2,	[x29, filep_s]
	bl	fgets	

	// increment count
	ldr	w19,	[x29, count_s]
	add	w19,	w19,	1
	str	w19,	[x29, count_s]	
		
displayTopScores_scan_file_test:
	ldr	x0,	[x29, filep_s]
	bl	feof
	cmp	x0,	xzr
	b.eq	displayTopScores_scan_file_body	

	// Subtract 1 from count
	ldr	w19,	[x29, count_s]
	sub	w19,	w19,	1
	str	w19,	[x29, count_s]
	
	mov	w19,	wzr
	str	w19,	[x29, row_s]
	// declare sortedRows
	// allocate bytes
	ldr	w19,	[x29, count_s]
	sub	x19,	xzr,	x19	
	lsl	x19,	x19,	2		// multiply by 4
	and	x19,	x19,	-16
	add	sp,	sp,	x19

displayTopScores_init_sort:
	b	displayTopScores_init_sort_test
displayTopScores_init_sort_body:

	ldr	w19,	[x29, row_s]
	lsl	x20,	x19,	2
	sub	x20,	xzr,	x20
	str	w19,	[x29, x20]
	
	// increment row
	ldr	w19,	[x29, row_s]
	add	w19,	w19,	1
	str	w19,	[x29, row_s]
displayTopScores_init_sort_test:
	ldr	w19,	[x29, row_s]
	ldr	w20,	[x29, count_s]
	cmp	w19,	w20
	b.lt	displayTopScores_init_sort_body	
	
	// Sort the unsorted array of indices using bubble sort by 
	// comparing the corresponding scores.
	// This loop ends after the iteration where it has gone through all of 
	// the sorted rows and hasn't swapped any of them anymore. 	
displayTopScores_sort:
	strb	wzr,	[x29, swapped_s]	

	str	wzr,	[x29, row_s]
displayTopScores_sort_inner:
	b	displayTopScores_sort_inner_test

displayTopScores_sort_inner_body:
	
	// get sorted rows offset
	ldr	w19,	[x29, row_s]
	sub	x19,	xzr,	x19		// negate row
	lsl	x19,	x19,	2		// * 4
	ldr	w20,	[x29, x19]		// w20 is the index		
	lsl	x25,	x20,	2		// make the index an offset
	ldr	x21,	[x29, scoresp_s]	// get base address of scores
	ldr	s22,	[x21, x25]		// load scores[sortedRows[row]]
	sub	x19,	x19,	4		
	ldr	w23,	[x29, x19]		// w23 is the index		
	lsl	x26,	x23,	2		// make the index an offset
	ldr	s24,	[x21, x26]		// load scores[sortedRows[row + 1]]

	fcmp	s22,	s24			
	b.ge	displayTopScores_sort_inner_body_increment_row
	
	str	x20,	[x29, temprow_s]	// store in temprow	
	add	x19,	x19,	4		
	str	w23,	[x29, x19]		// sortedRows[row] = sortedRows[row + 1]	
	ldr	x27,	[x29, temprow_s]
	sub	x19,	x19,	4		
	str	w27,	[x29,	x19]

	mov	w28,	1
	strb	w28,	[x29, swapped_s]

displayTopScores_sort_inner_body_increment_row:
	// increment row
	ldr	w19,	[x29, row_s]
	add	w19,	w19,	1
	str	w19,	[x29, row_s]

displayTopScores_sort_inner_test:
	ldr	w19,	[x29, row_s]
	ldr	w20,	[x29, count_s]
	sub	w20,	w20,	1
	cmp	w19,	w20
	b.lt	displayTopScores_sort_inner_body	
	
displayTopScores_sort_test:
	ldrb	w19,	[x29, swapped_s]
	cmp	w19,	wzr
	b.ne	displayTopScores_sort

	str	wzr,	[x29, row_s]

	ldr	w19,	[x29, n_s]
	ldr	w20,	[x29, count_s]
	cmp	w19,	w20
	b.le	displayTopScores_display
	str	w20,	[x29, n_s]

displayTopScores_display:	
	b	displayTopScores_display_test
displayTopScores_display_body:
	ldr	x0,	=f_topscoreinfo
	ldr	w1,	[x29, row_s]
	add	w1,	w1, 	1	// row + 1
	
	sub	x21,	x1,	1
	// get sortedRows' offset
	sub	x20,	xzr,	x21	// negate row
	lsl	x20,	x20,	2	// multiply by 4
	// load top scores index
	ldr	w21,	[x29, x20]
	// load name, x22 has name offset
	mov	x23,	20
	mul	x22,	x21,	x23
	// load name base
	ldr	x24,	[x29, namesp_s]
	mov	x2,	xzr
	add	x2,	x24, 	x22
	// calculate scores/times offset
	lsl	x22,	x21,	2
	// load score
	ldr	x24,	[x29, scoresp_s]
	ldr	s3,	[x24, x22]		
	fcvt	d0,	s3
	// load time
	ldr	x24,	[x29, timesp_s]
	ldr	w3,	[x24, x22]
	bl	printf	

	// increment row
	ldr	w19,	[x29, row_s]
	add	w19,	w19,	1
	str	w19,	[x29, row_s]

displayTopScores_display_test:
	ldr	w19,	[x29, row_s]
	ldr	w20, 	[x29, n_s]
	cmp	w19,	w20
	b.lt	displayTopScores_display_body	

	// deallocate bytes
	ldr	w19,	[x29, count_s]
	sub	x19,	xzr,	x19	
	lsl	x19,	x19,	2		// multiply by 4
	and	x19,	x19,	-16
	sub	sp,	sp,	x19
	b 	displayTopScores_return

	ldr	x0,	[x29, namesp_s]
	bl	free	
	ldr	x0,	[x29, scoresp_s]
	bl	free	
	ldr	x0,	[x29, timesp_s]
	bl	free	

displayTopScores_doesnt_exist:
	ldr	x0,	=txt_noscores
	bl	printf

displayTopScores_return:
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

/**
 * Prompt for bomb coordinates,
 * uncover board, calculate scores
 * and bomb radius, and,
 * determine whether game is still on.
 * @param board           main board with numbers
 * @param covered         board which determines which cells are covered
 * @param name            player's name
 * @param numberOfRows    boards' number of rows
 * @param numberOfColumns boards' number of columns
 */

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

	// start time
	mov	x0,	xzr
	bl	time
	mov	x28,	x0

	
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

	// roundScore = calculateScore
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
	str	s0,	[x29, roundscore_s]	

	// Reset bomb radius
	mov	w19,	1
	str	w19,	[x29, bombradius_s]

	// Display game
	ldr	x0,	[x29, fboardp_s]
	ldr	x1,	[x29, bboardp_s]
	ldr	w2,	[x29, numRows_s]
	ldr	w3,	[x29, numCols_s]
	bl	displayGame

playGame_calculate_bombradius:
	ldr	w19,	[x29, bombpowerups_s]
	cmp	w19,	wzr			// bombpowerups <= 0, skip to displaying scores
	b.le	playGame_display_roundscore
	ldr	w20,	[x29, bombs_s]
	cmp	w20,	1			// bombs <= 1, skip to displaying scores
	b.le	playGame_display_roundscore
	ldr	w20,	[x29, bombradius_s]	
	lsl	w20,	w20,	w19
	str	w20,	[x29, bombradius_s]

	// limit max bomb radius
	// make sure it doesnt go back to single digits
	mov	w22,	30
	cmp	w19,	w22
	b.le	playGame_display_bombradius
	mov	w20,	2147483647
	str	w20,	[x29, bombradius_s]

playGame_display_bombradius:		
	ldr	x0,	=txt_bombradiusinfo
	mov	w1,	w19
	mov	w2,	w20
	bl	printf

playGame_display_roundscore:
	ldr	x0,	=txt_roundscore
	ldr	s0,	[x29, roundscore_s]
	fcvt	d0,	s0
	bl	printf
playGame_display_totalscore:
	ldr	x0,	=txt_totalscore
	ldr	s0,	[x29, totalscore_s]
	fcvt	d0,	s0
	bl	printf

playGame_display_lives:
	ldr	x0,	=txt_lives
	ldr	w1,	[x29, lives_s]
	bl	printf

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

	// end time
	mov	x0,	xzr
	bl	time
	sub	x28,	x0,	x28

	ldr	x0,	=txt_gameover
	bl	printf

	ldr	x0,	=txt_playinfo
	ldr	x1,	[x29, name_s]
	ldr	s2,	[x29, totalscore_s]
	fcvt	d0,	s2
	mov	x2,	x28
	bl	printf

	ldr	x0,	[x29, name_s]
	ldr	s2,	[x29, totalscore_s]
	fcvt	d0,	s2
	mov	x1,	x28
	bl	logScore

	ldr_x()
	endfunction(dealloc)
