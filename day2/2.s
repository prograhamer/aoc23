.data
filename:
.ascii "input.txt\0"
part1_str:
.ascii "part 1: \0"
part2_str:
.ascii "part 2: \0"
red:
.ascii " red\0\0\0\0"
green:
.ascii " green\0\0"
blue:
.ascii " blue\0\0\0"

.text
.include "../lib/file.s"
.include "../lib/output.s"

.globl _start
_start:
	adr x0, filename
	bl read_file
	tst x0, x0
	b.eq .Lfail

	mov x19, x0

	adr x0, part1_str
	bl put_string

	mov x0, x19
	bl part1
	bl put_int

	adr x0, part2_str
	bl put_string
	mov x0, x19
	bl part2
	bl put_int

	mov w0, 0
	mov w8, 93
	svc 0
.Lfail:
	mov w0, 1
	mov w8, 93
	svc 0

part1:
	stp lr, x19, [sp, -0x10]!
	stp x20, x21, [sp, -0x10]!

	// x0 = input pointer
	// w19 = game number
	// w20 = line ok
	// w21 = result

	mov w21, 0

.Lpart1_start_line:
	ldrb w1, [x0, 1]
	tst w1, w1
	b.eq .Lpart1_done

	mov w20, 1
	bl parse_number
	mov w19, w1
.Lpart1_loop:
	bl parse_number
	bl check_colour
	and w20, w20, w1

	tst w20, w20
	b.eq .Lpart1_next_line

	ldrb w1, [x0]
	cmp w1, 0xa
	b.ne .Lpart1_loop

	madd w21, w19, w20, w21
	b .Lpart1_start_line

.Lpart1_next_line:
	ldrb w1, [x0], 1
	cmp w1, 0xa
	b.ne .Lpart1_next_line
	b .Lpart1_start_line

.Lpart1_done:
	mov w0, w21

	ldp x20, x21, [sp], 0x10
	ldp lr, x19, [sp], 0x10
	ret

part2:
	stp lr, x19, [sp, -0x10]!
	stp x20, x21, [sp, -0x10]!
	str x22, [sp, -0x10]!

	// x0 = input pointer
	// w19 = line max red
	// w20 = line max green
	// w21 = line max blue
	// w22 = result

	mov w22, 0

.Lpart2_start_line:
	ldrb w1, [x0, 1]
	tst w1, w1
	b.eq .Lpart2_done

	mov w19, 0
	mov w20, 0
	mov w21, 0

	bl parse_number
.Lpart2_loop:
	bl parse_number

	ldr x2, [x0]
	adr x3, red

	ldr x4, [x3], 8
	and x5, x2, 0xffffffff
	cmp x5, x4
	b.eq .Lpart2_set_line_max_red
	ldr x4, [x3], 8
	and x5, x2, 0xffffffffffff
	cmp x5, x4
	b.eq .Lpart2_set_line_max_green
	ldr x4, [x3], 8
	and x5, x2, 0xffffffffff
	cmp x5, x4
	b.eq .Lpart2_set_line_max_blue

	// should never happen ¯\_(ツ)_/¯
	b .Lpart2_done

.Lpart2_loop_cont:
	ldrb w1, [x0]
	cmp w1, 0xa
	b.ne .Lpart2_loop

	mul w19, w19, w20
	madd w22, w19, w21, w22
	b .Lpart2_start_line

.Lpart2_set_line_max_red:
	add x0, x0, 4
	cmp w19, w1
	b.ge .Lpart2_loop_cont
	mov w19, w1
	b .Lpart2_loop_cont
.Lpart2_set_line_max_green:
	add x0, x0, 6
	cmp w20, w1
	b.ge .Lpart2_loop_cont
	mov w20, w1
	b .Lpart2_loop_cont
.Lpart2_set_line_max_blue:
	add x0, x0, 5
	cmp w21, w1
	b.ge .Lpart2_loop_cont
	mov w21, w1
	b .Lpart2_loop_cont

.Lpart2_done:
	mov w0, w22

	ldr x22, [sp], 0x10
	ldp x20, x21, [sp], 0x10
	ldp lr, x19, [sp], 0x10
	ret

// parse number from x0, chomping until it finds a numeric char
// unconventional return values: parsed number in w1, updated pointer in x0
parse_number:
	mov w1, 0
	mov w2, 10

.Lpart1_start_init_loop:
	ldrb w3, [x0], 1
	cmp w3, 0x30
	b.lt .Lpart1_start_init_loop
	cmp w3, 0x39
	b.gt .Lpart1_start_init_loop
	b .Lparse_number_add

.Lparse_number_loop:
	ldrb w3, [x0], 1
	cmp w3, 0x30
	b.lt .Lparse_number_done
	cmp w3, 0x39
	b.gt .Lparse_number_done
.Lparse_number_add:
	sub w3, w3, 0x30
	madd w1, w1, w2, w3
	b .Lparse_number_loop

.Lparse_number_done:
	sub x0, x0, 1
	ret

// parse colour from x0, w1 = number of cubes to check, update x0 to reflect consumed chars
// determine colour in input and set w1 = 1 if number valid for colour, w1 = 0 otherwise
check_colour:
	ldr x2, [x0]
	adr x3, red

	ldr x4, [x3], 8
	and x5, x2, 0xffffffff
	cmp x5, x4
	b.eq .Lcheck_colour_red
	ldr x4, [x3], 8
	and x5, x2, 0xffffffffffff
	cmp x5, x4
	b.eq .Lcheck_colour_green
	ldr x4, [x3], 8
	and x5, x2, 0xffffffffff
	cmp x5, x4
	b.eq .Lcheck_colour_blue

	// should never happen, who needs input validation?
	b .Lcheck_colour_negative

.Lcheck_colour_red:
	add x0, x0, 4
	cmp w1, 12
	b.le .Lcheck_colour_positive
	b .Lcheck_colour_negative

.Lcheck_colour_green:
	add x0, x0, 6
	cmp w1, 13
	b.le .Lcheck_colour_positive
	b .Lcheck_colour_negative

.Lcheck_colour_blue:
	add x0, x0, 5
	cmp w1, 14
	b.le .Lcheck_colour_positive
	b .Lcheck_colour_negative

.Lcheck_colour_positive:
	mov w1, 1
	ret
.Lcheck_colour_negative:
	mov w1, 0
	ret
