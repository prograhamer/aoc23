.global read_file
read_file:
	stp x29, lr, [sp, -0x10]!
	// x19: filename / mapped addr
	// w20: file handle
	stp x19, x20, [sp, -0x10]!
	mov x29, sp

	mov x19, x0

	// sizeof(struct stat) = 0x80
	sub sp, sp, 0x80

	// fstatat(AT_FDCWD, arg0, sp, 0)
	mov x0, -100 // AT_FDCWD
	mov x1, x19
	mov x2, sp
	mov x3, 0
	mov w8, 79
	svc 0
	tst w0, w0
	b.mi .Lreadfile_err

	// openat(AT_FDCWD, arg0, O_RDONLY, 0)
	mov x0, -100 // AT_FDCWD
	mov x1, x19
	mov x2, 0
	mov x3, 0
	mov w8, 56 // openat
	svc 0
	tst w0, w0
	b.mi .Lreadfile_err
	mov w20, w0

	// mmap(NULL, stat_buf.st_size, PROT_READ, MAP_PRIVATE, fd, 0)
	mov x0, 0
	ldr x1, [sp, 0x30]
	mov w2, 1 // PROT_READ
	mov w3, 2 // MAP_PRIVATE
	mov w4, w20
	mov x5, 0
	mov w8, 222
	svc 0
	tst x0, x0
	b.mi .Lreadfile_err
	mov x19, x0

	// close(fd)
	mov w0, w20
	mov w8, 57
	svc 0
	tst w0, w0
	b.mi .Lreadfile_err

	mov x0, x19
.Lreadfile_ret:
	mov sp, x29
	ldp x19, x20, [sp], 0x10
	ldp x29, lr, [sp], 0x10
	ret
.Lreadfile_err:
	// return null pointer
	mov x0, 0
	b .Lreadfile_ret
