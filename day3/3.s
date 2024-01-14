.section rodata, "a"
usage_msg:
.ascii "usage: ./3 <input file>\n\0"
file_error_msg:
.ascii "failed to load file\n\0"
part1_msg:
.ascii "part 1 answer: \0"

.text

.global _start
_start:
	ldr x0, [sp]
	cmp x0, 2
	b.ne .Lprint_usage_exit

	ldr x0, [sp, 0x10]
	bl read_file
	cbz x0, .Lfile_error_exit
	mov x19, x0

	adr x0, part1_msg
	bl put_string
	mov x0, x19
	bl part1
	bl put_int

	mov w0, 0
	mov w8, 93
	svc 0
.Lprint_usage_exit:
	adr x0, usage_msg
	bl put_string
	mov w0, 1
	mov w8, 93
	svc 0
.Lfile_error_exit:
	adr x0, file_error_msg
	bl put_string
	mov w0, 1
	mov w8, 93
	svc 0

part1:
	stp x19, lr, [sp, -0x10]!
	stp x20, x21, [sp, -0x10]!
	stp x22, x23, [sp, -0x10]!
	stp x24, x25, [sp, -0x10]!

	// x19 = input pointer
	// w20 = running total
	// w21 = current number
	// w22 = symbol found for current number
	// w23 = row length
	// w24 = 10 (for use in madd)
	// w25 = char index
	mov x19, x0
	mov w20, wzr
	mov w21, wzr
	mov w22, wzr
	mov w23, wzr
	mov w24, 10
	mov w25, wzr

	bl find_row_length
	mov w23, w0

	// for each char in input:
	//   - if char is non-numeric
	//     - if symbol found, add number to total
	//     - reset current number to zero, symbol found to false
	//   - else (char is numeric)
	//     - add digit to current number (number = (number * 10) + digit)
	//     - if !symbol found
	//       - look for symbol in surrounding chars, if found, set symbol found

.Lpart1_loop:
	add x1, x19, x25
	ldrb w0, [x1]
	cmp w0, 0
	b.eq .Lpart1_done
	cmp w0, '0'
	b.lt .Lpart1_non_numeric
	cmp w0, '9'
	b.gt .Lpart1_non_numeric
	sub w0, w0, '0'
	madd w21, w21, w24, w0

	cbnz w22, .Lpart1_next

	mov x0, x19 // input buffer
	mov w1, w25 // char index
	mov w2, w23 // row length
	bl find_symbol
	mov w22, w0

.Lpart1_next:
	add x25, x25, 1
	b .Lpart1_loop

.Lpart1_non_numeric:
	cbz w22, .Lpart1_skip_add_number
	add w20, w20, w21
	mov w22, wzr
.Lpart1_skip_add_number:
	mov w21, wzr
	add x25, x25, 1
	b .Lpart1_loop

.Lpart1_done:
	mov w0, w20

	ldp x24, x25, [sp], 0x10
	ldp x22, x23, [sp], 0x10
	ldp x20, x21, [sp], 0x10
	ldp x19, lr, [sp], 0x10
	ret

find_row_length:
	mov x1, x0
.Lfind_row_length_loop:
	ldrb w2, [x1], 1
	cmp w2, '\n'
	b.ne .Lfind_row_length_loop
	sub x0, x1, x0
	sub x0, x0, 1
	ret

// need to determine valid chars to check
// if on first row, can't check above
// if on last row, can't check below
// if first char on row, who cares, it will be '\n'
// if last char on row, who cares, it will be '\n'
find_symbol:
	str lr, [sp, -0x10]!

	// x0 = input buffer
	// w1 = char index
	// w2 = row length

	// if this is the first character, the first position we can check is to the right
	cbz w1, .Lfind_symbol_right
	// if we're on the first row, we can't check above
	cmp w1, w2
	b.le .Lfind_symbol_left

	add x3, x0, x1
	sub x3, x3, x2
	ldrb w4, [x3]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

	ldrb w4, [x3, -1]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

	ldrb w4, [x3, -2]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

.Lfind_symbol_left:
	add x3, x0, x1
	ldrb w4, [x3, -1]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

.Lfind_symbol_right:
	add x3, x0, x1
	ldrb w4, [x3, 1]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

	// check if we're on the last row
	add w3, w2, 1
	sub w4, w2, 1
	mul w3, w3, w4
	cmp w1, w3
	b.gt .Lfind_symbol_none
	add x3, x0, x1
	add x3, x3, x2

	ldrb w4, [x3]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

	ldrb w4, [x3, 1]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

	ldrb w4, [x3, 2]
	bl .Lfind_symbol_is_symbol
	cbnz w4, .Lfind_symbol_some

.Lfind_symbol_none:
	mov w0, wzr
	ldr lr, [sp], 0x10
	ret
.Lfind_symbol_some:
	mov w0, 1
	ldr lr, [sp], 0x10
	ret

.Lfind_symbol_is_symbol:
	cmp w4, '.'
	b.eq .Lfind_symbol_is_symbol_false
	cmp w4, ' '
	b.le .Lfind_symbol_is_symbol_false
	cmp w4, '9'
	b.gt .Lfind_symbol_is_symbol_true
	cmp w4, '0'
	b.ge .Lfind_symbol_is_symbol_false
.Lfind_symbol_is_symbol_true:
	mov w4, 1
	ret
.Lfind_symbol_is_symbol_false:
	mov w4, wzr
	ret
