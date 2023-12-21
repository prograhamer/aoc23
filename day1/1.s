.data
filename:
.ascii "input.txt\0"
newline:
.ascii "\a\0"
part1_answer:
.ascii "part1: %d\n\0"

.text
.include "../lib/file.s"

.globl main
main:
	stp x29, lr, [sp, -0x10]!

	adr x0, filename
	bl readfile
	tst x0, x0
	b.eq .Lmain_err

	bl part1

	mov w1, w0
	adr x0, part1_answer
	bl printf

	mov x0, 0
.Lmain_ret:
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
