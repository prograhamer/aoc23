.section rodata, "a"
usage_msg:
.ascii "usage: 4 <file>\n\0"
file_error_msg:
.ascii "failed to read file\n\0"
part1_msg:
.ascii "part1: \0"

.text
.global _start
_start:
	ldr x0, [sp]
	cmp x0, 2
	b.ne .Lprint_usage_exit

	ldr x0, [sp, 0x10]
	bl read_file
	cbz x0, .Lprint_file_error_exit

	mov x19, x0
	adr x0, part1_msg
	bl put_string
	mov x0, x19
	bl part1
	bl put_int

	mov w0, wzr
	mov w8, 93
	svc 0

.Lprint_usage_exit:
	adr x0, usage_msg
	bl put_string
	mov w0, 1
	mov w8, 93
	svc 0
.Lprint_file_error_exit:
	adr x0, file_error_msg
	bl put_string
	mov w0, 1
	mov w8, 93
	svc 0

part1:
	stp x19, lr, [sp, -0x10]!
	stp x20, x21, [sp, -0x10]!
	str x22, [sp, -0x10]!
	// sp  -> winning numbers [u8; 16]
	sub sp, sp, 0x10
	// x19 -> puzzle input
	// x20 -> pointer to next empty location in list
	// w21 -> line value
	// w22 -> running total
	mov x19, x0
	mov x20, sp
	mov w21, wzr
	mov w22, wzr

.Lpart1_find_colon_loop:
	ldrb w0, [x19], 1
	cmp w0, ':'
	b.ne .Lpart1_find_colon_loop

.Lpart1_winning_number_loop:
	mov x0, x19
	bl parse_number
	strb w1, [x20], 1
	mov x19, x0
	ldrb w0, [x19, 1]
	cmp w0, '|'
	b.ne .Lpart1_winning_number_loop
	add x19, x19, 2

.Lpart1_card_number_loop:
	ldrb w0, [x19]
	cmp w0, '\n'
	b.eq .Lpart1_line_done
	mov x0, x19
	bl parse_number
	mov x19, x0
	mov x0, sp
.Lpart1_card_number_check_loop:
	cmp x0, x20
	b.eq .Lpart1_card_number_loop
	ldrb w2, [x0], 1
	cmp w1, w2
	b.ne .Lpart1_card_number_check_loop
	cbz w21, .Lpart1_card_number_match_init
	lsl w21, w21, 1
	b .Lpart1_card_number_loop
.Lpart1_card_number_match_init:
	mov w21, 1
	b .Lpart1_card_number_loop

.Lpart1_line_done:
	add w22, w22, w21
	mov w21, wzr
	mov x20, sp
	ldrb w0, [x19, 1]
	cbnz w0, .Lpart1_find_colon_loop

.Lpart1_done:
	mov w0, w22

	add sp, sp, 0x10
	ldr x22, [sp], 0x10
	ldp x20, x21, [sp], 0x10
	ldp x19, lr, [sp], 0x10
	ret

// parse number, updating x0 to reflect consumed characters
// number returned in w1
parse_number:
	mov w3, 10
	mov w1, wzr
.Lparse_number_chomp_loop:
	ldrb w2, [x0], 1
	cmp w2, ' '
	b.eq .Lparse_number_chomp_loop
	sub x0, x0, 1
.Lparse_number_loop:
	ldrb w2, [x0]
	cmp w2, '0'
	b.lt .Lparse_number_return
	cmp w2, '9'
	b.gt .Lparse_number_return
	sub w2, w2, 0x30
	madd w1, w1, w3, w2
	add x0, x0, 1
	b .Lparse_number_loop
.Lparse_number_return:
	ret
