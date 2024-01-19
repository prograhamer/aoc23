.PHONY: all
all: 4

.PHONY: run
run: 4
	./4 example.txt

4.o: 4.s
	as -o 4.o 4.s

file.o: ../lib/file.s
	as -o file.o ../lib/file.s

output.o: ../lib/output.s
	as -o output.o ../lib/output.s

4: 4.o output.o file.o
	ld -o 4 4.o output.o file.o

.PHONY: clean
clean:
	rm -f 4 *.o
