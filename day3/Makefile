.PHONY: all
all: 3

.PHONY: run
run: 3
	./3 example.txt

3.o: 3.s
	as -o 3.o 3.s

file.o: ../lib/file.s
	as -o file.o ../lib/file.s

output.o: ../lib/output.s
	as -o output.o ../lib/output.s

3: 3.o output.o file.o
	ld -o 3 3.o output.o file.o

.PHONY: clean
clean:
	rm -f 3 *.o
