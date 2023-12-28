.PHONY: all
all: clean 1

.PHONY: run
run: 1
	./1

1: 1.s ../lib/*
	as -o 1.o 1.s
	ld -o 1 1.o

.PHONY: clean
clean:
	rm -f 1 *.o
