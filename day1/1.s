.data
filename:
.ascii "input.txt\0"
newline:
.ascii "\a\0"
part1_answer:
.ascii "part1: %d\n\0"
part2_answer:
.ascii "part2: %d\n\0"

numbers:
.ascii "one\0\0\0\0\0"
.ascii "two\0\0\0\0\0"
.ascii "three\0\0\0"
.ascii "four\0\0\0\0"
.ascii "five\0\0\0\0"
.ascii "six\0\0\0\0\0"
.ascii "seven\0\0\0"
.ascii "eight\0\0\0"
.ascii "nine\0\0\0\0"

.text
.include "../lib/file.s"

.globl main
main:
	stp x29, lr, [sp, -0x10]!
	str x19, [sp, -0x10]!

	adr x0, filename
	bl readfile
	tst x0, x0
	b.eq .Lmain_err
	mov x19, x0

	bl part1

	mov w1, w0
	adr x0, part1_answer
	bl printf

	mov x0, x19
	bl part2

	mov w1, w0
	adr x0, part2_answer
	bl printf

	mov x0, 0
.Lmain_ret:
	ldr x19, [sp], 0x10
	ldp x29, lr, [sp], 0x10
	ret
.Lmain_err:
	mov x0, 1
	b .Lmain_ret

part1:
	// x0 = buffer (argument)
	// w1 = running total
	// w2 = first
	// w3 = last
	mov w1, 0
	mov w2, -1
	mov w3, -1

.Lpart1_loop:
	ldrb w4, [x0]

	cmp w4, 0
	beq .Lpart1_ret
	cmp w4, 0xa
	beq .Lpart1_newline

	cmp w4, 0x30
	blt .Lpart1_next
	cmp w4, 0x39
	bgt .Lpart1_next
	sub w4, w4, 0x30
	cmp w2, 0
	bge .Lpart1_last
	mov w2, w4
.Lpart1_last:
	mov w3, w4

.Lpart1_next:
	add x0, x0, 1
	b .Lpart1_loop
.Lpart1_newline:
	mov w4, 10
	madd w4, w2, w4, w3
	add w1, w1, w4
	mov w2, -1
	mov w3, -1
	add x0, x0, 1
	b .Lpart1_loop

.Lpart1_ret:
	mov w0, w1
	ret

part2:
	// x0 = buffer (argument)
	// w1 = running total
	// w2 = first
	// w3 = last
	mov w1, 0
	mov w2, -1
	mov w3, -1

.Lpart2_loop:
	ldr x4, [x0]

	adr x6, numbers
	and x5, x4, 0xffffffffff
	ldr x7, [x6, 16]
	cmp x5, x7
	beq .Lpart2_three
	ldr x7, [x6, 48]
	cmp x5, x7
	beq .Lpart2_seven
	ldr x7, [x6, 56]
	cmp x5, x7
	beq .Lpart2_eight

	and x5, x4, 0xffffffff
	ldr x7, [x6, 24]
	cmp x5, x7
	beq .Lpart2_four
	ldr x7, [x6, 32]
	cmp x5, x7
	beq .Lpart2_five
	ldr x7, [x6, 64]
	cmp x5, x7
	beq .Lpart2_nine

	and w5, w4, 0xffffff
	ldr x7, [x6]
	cmp w5, w7
	beq .Lpart2_one
	ldr x7, [x6, 8]
	cmp w5, w7
	beq .Lpart2_two
	ldr x7, [x6, 40]
	cmp w5, w7
	beq .Lpart2_six

	and w4, w4, 0xff
	cmp w4, 0
	beq .Lpart2_ret
	cmp w4, 0xa
	beq .Lpart2_newline

	cmp w4, 0x30
	blt .Lpart2_next
	cmp w4, 0x39
	bgt .Lpart2_next
	sub w4, w4, 0x30
.Lpart2_set:
	cmp w2, 0
	bge .Lpart2_last
	mov w2, w4
.Lpart2_last:
	mov w3, w4

.Lpart2_next:
	add x0, x0, 1
	b .Lpart2_loop
.Lpart2_one:
	mov w4, 1
	b .Lpart2_set
.Lpart2_two:
	mov w4, 2
	b .Lpart2_set
.Lpart2_three:
	mov w4, 3
	b .Lpart2_set
.Lpart2_four:
	mov w4, 4
	b .Lpart2_set
.Lpart2_five:
	mov w4, 5
	b .Lpart2_set
.Lpart2_six:
	mov w4, 6
	b .Lpart2_set
.Lpart2_seven:
	mov w4, 7
	b .Lpart2_set
.Lpart2_eight:
	mov w4, 8
	b .Lpart2_set
.Lpart2_nine:
	mov w4, 9
	b .Lpart2_set

.Lpart2_newline:
	mov w4, 10
	madd w4, w2, w4, w3
	add w1, w1, w4
	mov w2, -1
	mov w3, -1
	add x0, x0, 1
	b .Lpart2_loop

.Lpart2_ret:
	mov w0, w1
	ret
