readfile:
	stp x29, lr, [sp, -0x10]!
	mov x29, sp

	// [x29, -0x08]: filename
	// [x29, -0x0c]: file handle
	// [x29, -0x10]: buffer length
	// [x29, -0x18]: buffer
	// [x29, -0x1c]: offset
	sub sp, sp, 0x20
	str x0, [x29, -0x08]

	// openat(AT_FDCWD, arg0, O_RDONLY, 0)
	mov x0, -100 // AT_FDCWD
	ldr x1, [x29, -0x08]
	mov x2, 0
	mov x3, 0
	mov w8, 56 // openat
	svc 0
	tst w0, w0
	b.mi .Lreadfile_err
	str w0, [x29, -0x0c]

	// allocate buffer
	mov w0, 0x1000
	str w0, [x29, -0x10]
	mov w1, 1
	bl calloc
	tst x0, x0
	b.eq .Lreadfile_err
	str x0, [x29, -0x18]

	// offset = 0
	mov w1, 0
	str w1, [x29, -0x1c]

.Lreadfile_loop:
	// read(fd, &buffer[offset], buffer_len - offset)
	ldr w0, [x29, -0x0c]
	ldr x1, [x29, -0x18]
	ldr w3, [x29, -0x1c]
	add x1, x1, w3, sxtw
	ldr w2, [x29, -0x10]
	sub w2, w2, w3
	mov w8, 63 // read
	svc 0
	cmp w0, 0
	b.mi .Lreadfile_err
	b.eq .Lreadfile_term

	ldr w2, [x29, -0x1c]
	add w2, w2, w0
	str w2, [x29, -0x1c]

	ldr w1, [x29, -0x10]
	add w2, w2, 1
	cmp w1, w2
	b.gt .Lreadfile_loop

	ldr x0, [x29, -0x18]
	ldr w1, [x29, -0x10]
	lsl w1, w1, 1
	str w1, [x29, -0x10]
	bl realloc
	tst x0, x0
	b.eq .Lreadfile_err
	str x0, [x29, -0x18]
	b .Lreadfile_loop

.Lreadfile_term:
	ldr x0, [x29, -0x18]
	ldr w1, [x29, -0x1c]
	//add x1, x0, w1, uxtw
	mov w2, 0
	strb w2, [x0, w1, uxtw]
.Lreadfile_ret:
	mov sp, x29
	ldp x29, lr, [sp], 0x10
	ret
.Lreadfile_err:
	// return null pointer
	mov x0, 0
	b .Lreadfile_ret
