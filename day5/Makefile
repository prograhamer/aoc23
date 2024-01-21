.PHONY: all
all: 5

.PHONY: run
run: 5
	./5 example.txt

5.o: 5.s
	as -o 5.o 5.s

file.o: ../lib/file.s
	as -o file.o ../lib/file.s

output.o: ../lib/output.s
	as -o output.o ../lib/output.s

5: 5.o output.o file.o
	ld -o 5 5.o output.o file.o

.PHONY: clean
clean:
	rm -f 5 *.o
