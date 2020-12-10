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


	.balign	4
	.global	randomNum

init_subr_x()
min_size = 4
max_size = 4
negative_size = 4
min_s = dealloc
max_s = min_s + min_size
alloc = (alloc - min_size - max_size) & -16
dealloc = -alloc

/**
 * Generates a random float number between min and 
 * max inclusive. 
 * This implementation works unexpectedly if min is negative or
 * max != (2^n) - 1.
 * @param  min      min value expected to be generated
 * @param  max      max value expected to be generated
 * @param  negative specifies if generated number is negative
 * @return          |float| between |min| and |max|
 */

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

