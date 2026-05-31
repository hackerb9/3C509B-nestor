all: 3c509.com

OBJECTS=head.o 3c509.o tail.o
# Note: WMAKE disagrees with GNU Make on what $< and $^ mean.

.SUFFIXES: .asm .PHONY

.asm.o:
	wasm -q $*

3c509.com: $(OBJECTS)
	wlink   option quiet  format dos com  \
		option map  name $@  file {$(OBJECTS)}

.PHONY: clean .symbolic
clean: .symbolic
	rm -f *.o
	rm -f *.err
	rm -f *.map
	rm -f 3c509.com

