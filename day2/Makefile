.PHONY: all
all: clean 2

.PHONY: run
run: clean 2
	./2

2: 2.s
	as -o 2.o 2.s
	ld -o 2 2.o

.PHONY: clean
clean:
	rm -f 2 *.o
