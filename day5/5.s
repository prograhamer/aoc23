.section rodata, "a"
usage_msg:
.ascii "usage: 5 <file>\n\0"
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
	stp x22, x23, [sp, -0x10]!

	// sp -> seeds [u32, 20]
	sub sp, sp, 0x50

	// x19 -> input
	// w20 -> seed count
	mov x19, x0
	mov w20, wzr

	mov x21, sp
.Lpart1_read_seed_loop:
	mov x0, x19
	bl parse_number
	str w1, [x21], 4
	mov x19, x0
	ldrb w1, [x0]
	add w20, w20, 1
	cmp w1, '\n'
	b.ne .Lpart1_read_seed_loop

.Lpart1_mapping_loop:
	mov x0, x19
	mov x1, sp
	mov w2, w20
	bl do_mapping
	mov x19, x0
	ldrh w2, [x19]
	cmp w2, 0x0a
	b.ne .Lpart1_mapping_loop

	mov x0, sp
	mov w1, w20
	bl min_u32

	add sp, sp, 0x50

	ldp x22, x23, [sp], 0x10
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
	cmp w2, '0'
	b.lt .Lparse_number_chomp_loop
	cmp w2, '9'
	b.gt .Lparse_number_chomp_loop
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

// assumes a min length of 1
// x0 -> array
// w1 -> length
min_u32:
	mov w2, 4
	madd x2, x1, x2, x0
	mov x1, x0
	ldr w0, [x1], 4
.Lmin_u32_loop:
	cmp x1, x2
	b.eq .Lmin_u32_done
	ldr w3, [x1], 4
	cmp w3, w0
	b.hi .Lmin_u32_loop
	mov w0, w3
	b .Lmin_u32_loop
.Lmin_u32_done:
	ret

// x0 -> input
// x1 -> ptr to seed values
// w2 -> seed count
do_mapping:
	stp x19, lr, [sp, -0x10]!
	stp x20, x21, [sp, -0x10]!
	str x22, [sp, -0x10]!
	sub sp, sp, 0x50

	// x19 -> input
	// x20 -> seed values [u32; 20]
	// w21 -> seed count
	// x22 -> mapped seed values [u32; 20]
	mov x19, x0
	mov x20, x1
	mov w21, w2
	mov x22, sp

.Ldo_mapping_start_line:
	mov x0, x19
	bl parse_number
	mov w5, w1
	bl parse_number
	mov w6, w1
	bl parse_number
	add w7, w6, w1
	sub w7, w7, 1
	mov x19, x0

	mov x0, x20
	mov w1, 4
	madd x1, x21, x1, x0

.Ldo_mapping_check_seed_loop:
	cmp x0, x1
	b.eq .Ldo_mapping_check_seed_done
	ldr w2, [x0], 4
	add w3, w2, 1
	cmp w3, w6
	b.ls .Ldo_mapping_check_seed_loop
	cmp w2, w7
	b.hi .Ldo_mapping_check_seed_loop
	sub w2, w2, w6
	add w2, w2, w5
	str w2, [x22], 4
	ldr w2, [x1, -4]!
	str w2, [x0, -4]!
	sub w21, w21, 1
	b .Ldo_mapping_check_seed_loop

.Ldo_mapping_check_seed_done:
	ldrh w2, [x19]
	cmp w2, 0x0a
	b.eq .Ldo_mapping_block_done
	cmp w2, 0x0a0a
	b.ne .Ldo_mapping_start_line

.Ldo_mapping_block_done:
	mov x0, sp
.Ldo_mapping_write_back_loop:
	cmp x0, x22
	b.eq .Ldo_mapping_done
	ldr w2, [x0], 4
	str w2, [x1], 4
	b .Ldo_mapping_write_back_loop

.Ldo_mapping_done:
	mov x0, x19

	add sp, sp, 0x50
	ldr x22, [sp], 0x10
	ldp x20, x21, [sp], 0x10
	ldp x19, lr, [sp], 0x10
	ret
