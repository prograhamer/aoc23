.data
heap_addr:
.dword 0
brk_addr:
.dword 0

.section rodata, "a"
start_alloc_size:
.word 0x1000
free_list_reserved:
.word 0x100 // must divide evenly by block entry size

.text
.global malloc
malloc:
	// x19 = requested size
	stp x19, lr, [sp, -0x10]!
	str x20, [sp, -0x10]!

	mov x19, x0

	// add 8 bytes for block meta to request and align to 8 byte boundary
	add x19, x19, 0x08
	and x0, x19, 0x07
	cbz x0, .Lmalloc_skip_align
	add x19, x19, 0x08
	and x19, x19, -0x08

.Lmalloc_skip_align:
	adr x20, heap_addr
	ldr x20, [x20]
	cbz x20, .Lmalloc_heap_init
.Lmalloc_allocate:
	// w1 = free block length
	ldr w1, [x20, 0x04]
	mov w2, 0x10 // block entry size

	// x19 = request + metadata, 8 byte aligned
	// x20 = heap address

.Lmalloc_allocate_loop:
	subs w1, w1, 1
	b.mi .Lmalloc_add_memory
	madd x3, x1, x2, x20 // TODO: handle more than one free list block
	ldr x5, [x3, 0x10] // offset of addr in entry + block header size => load entry addr
	ldr x4, [x3, 0x18] // offset of size in entry + block header size => load size of entry

	cmp x19, x4
	b.gt .Lmalloc_allocate_loop

	// found block, allocate and split
	sub x6, x4, x19
	cmp x6, 16
	b.gt .Lmalloc_split_existing

	// remove this entry
	ldr w6, [x20, 0x04]
	sub w6, w6, 1
	str w6, [x20, 0x04]
	cmp w6, w1
	b.eq .Lmalloc_done
	madd x6, x6, x2, x20 // TODO: handle more than one free list block
	ldr x7, [x6, 0x10]
	str x7, [x3, 0x10]
	ldr x7, [x6, 0x18]
	str x7, [x3, 0x18]
	b .Lmalloc_done

.Lmalloc_split_existing:
	// split existing entry
	ldr x4, [x3, 0x10]
	add x4, x4, x19
	str x4, [x3, 0x10]
	str x6, [x3, 0x18]

.Lmalloc_done:
	str x19, [x5]
	add x0, x5, 8 // allocated entry offset by block meta
.Lmalloc_ret:
	ldr x20, [sp], 0x10
	ldp x19, lr, [sp], 0x10
	ret
.Lmalloc_fail:
	mov x0, 0
	b .Lmalloc_ret

.Lmalloc_add_memory:
	// call brk to allocate more memory from the OS
	adr x0, brk_addr
	ldr x0, [x0]
	adr x8, start_alloc_size
	ldr w8, [x8]
	add x0, x0, x8
	mov w8, 214
	svc 0
	adr x1, brk_addr
	ldr x1, brk_addr
	str x0, [x1]

	// add a free entry for x1...x0

	// x1 = old brk_addr
	// x0 = brk_addr
	// w2 = free block length
	ldr w2, [x20, 0x04]
	mov w3, 0x10 // block entry size

.Lmalloc_add_memory_loop:
	subs w2, w2, 1
	b.mi .Lmalloc_add_memory_new_entry

	madd x4, x2, x3, x20 // TODO: more than one block at base of heap
	ldr x6, [x4, 0x10] // offset of addr in entry + block header size => load entry addr
	ldr x5, [x4, 0x18] // offset of size in entry + block header size => load size of entry

	add x6, x6, x5
	cmp x6, x1
	b.ne .Lmalloc_add_memory_loop

	// merge new memory into existing block if contiguous
	sub x0, x0, x1
	add x5, x5, x0
	str w5, [x4, 0x18]
	b .Lmalloc_allocate

.Lmalloc_add_memory_new_entry:
	ldr w2, [x20, 0x04]
	ldr w3, [x20]
	cmp w2, w3
	b.ge .Lmalloc_fail // TODO: handle more than one list block at base of heap
	mov w3, 0x10 // block entry size
	madd x3, x2, x3, x20 // TODO: handle more than one list block at base of heap
	sub x0, x0, x1
	str x1, [x3, 0x10]
	str x0, [x3, 0x18]
	add w2, w2, 1
	str w2, [x20, 0x04] // TODO: handle more than one list block at base of heap
	b .Lmalloc_allocate

.Lmalloc_heap_init:
	mov x0, 0
	mov w8, 214
	svc 0 // TODO: handle error

	mov x20, x0
	adr x1, heap_addr
	str x0, [x1]

	adr x1, start_alloc_size
	ldr w1, [x1]
	add x0, x0, x1
	mov w8, 214
	svc 0 // TODO: handle error
	adr x1, brk_addr
	str x0, [x1]

	adr x1, free_list_reserved
	ldr w1, [x1]

	// initialize first entry in free list
	adr x2, start_alloc_size
	ldr w2, [x2]
	sub w2, w2, w1
	str x2, [x20, 0x18]
	add x2, x20, x1
	str x2, [x20, 0x10]

	// initialize block header
	sub w1, w1, 0x10 // reserved space for block header (cap + len + nextptr)
	mov w2, 0x10
	udiv w1, w1, w2
	str w1, [x20]
	mov w2, 1
	str w2, [x20, 0x04]
	and x1, x1, xzr
	str x1, [x20, 0x08]

	b .Lmalloc_allocate

.global free
free:
	stp x19, lr, [sp, -0x10]!
	stp x20, x21, [sp, -0x10]!

	// x19 = address to free (address of header, not user data)
	// x20 = heap addr
	// x21 = size of block to free
	mov x19, x0
	sub x19, x19, 8
	ldr x21, [x19]

	adr x20, heap_addr
	ldr x20, [x20]
	cbz x20, .Lfree_ret

	ldr w1, [x20, 0x04]
	mov w2, 0x10 // block entry length
.Lfree_find_entry_loop:
	subs w1, w1, 1
	b.mi .Lfree_add_entry

	madd x3, x1, x2, x20
	ldr x4, [x3, 0x10]
	ldr x5, [x3, 0x18]

	// merge to end of entry
	add x6, x4, x5
	cmp x19, x6
	b.eq .Lfree_merge_end

	// merge to start of entry
	add x6, x19, x21
	cmp x6, x4
	b.eq .Lfree_merge_start

	b .Lfree_find_entry_loop

.Lfree_merge_end:
	add x5, x21, x5
	str x5, [x3, 0x18]
	b .Lfree_ret

.Lfree_merge_start:
	add x5, x21, x5
	str x5, [x3, 0x18]
	str x19, [x3, 0x10]
	b .Lfree_ret

.Lfree_add_entry:
	ldr w1, [x20, 0x04]
	ldr w2, [x20]
	cmp w1, w2
	b.ge .Lfree_ret // TODO: handle more than one list block
	mov w2, 0x10 // block entry size
	madd x2, x1, x2, x20
	add w1, w1, 1
	str w1, [x20, 0x04]
	str x19, [x2, 0x10]
	str x21, [x2, 0x18]

	// TODO: merge more entries if free'd entry bridged a gap

.Lfree_ret:
	mov x0, xzr
	ldp x20, x21, [sp], 0x10
	ldp x19, lr, [sp], 0x10
	ret
