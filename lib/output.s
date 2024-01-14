.global put_string
put_string:
	stp x19, x30, [sp, -0x10]!
	mov x19, x0
	bl string_len
	mov w2, w0
	mov x1, x19
	mov w0, 1
	mov w8, 64
	svc 0

	ldp x19, x30, [sp], 0x10
	ret

.global put_int
put_int:
	sub sp, sp, 0x20

	mov x1, sp
	mov w5, 10

	mov w2, 1

	mov w4, 0x0a
	strb w4, [x1, -1]!

.Lput_int_loop:
	udiv w3, w0, w5
	msub w4, w3, w5, w0
	mov w0, w3

	add w4, w4, 0x30
	strb w4, [x1, -1]!
	add w2, w2, 1

	tst w0, w0
	b.ne .Lput_int_loop

	mov w0, 1
	mov w8, 64
	svc 0

	add sp, sp, 0x20
	ret

string_len:
	mov x1, x0
	mov w0, -1
.Lstring_len_loop:
	add w0, w0, 1
	ldrb w2, [x1]
	add x1, x1, 1
	tst w2, w2
	b.ne .Lstring_len_loop
	ret
