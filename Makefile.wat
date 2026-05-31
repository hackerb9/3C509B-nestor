all: 3c509.com

.SUFFIXES: .asm

.asm.o:
	wasm $*

3c509.com: head.o 3c509.o tail.o
	wlink format dos com option map name $* file $<

.PHONY: clean .symbolic
clean: .symbolic
	rm -f *.o
	rm -f *.err
	rm -f *.map
	rm -f 3c509.com
