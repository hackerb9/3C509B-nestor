all: 3c509.com

OBJECTS=head.o 3c509.o tail.o
# Note: $< and $^ cannot be used as WLINK disagrees with GNU Make on
# what they mean. Hence, the need for OBJECTS to be defined.

.SUFFIXES: .asm

.asm.o:
	wasm -q $*

3c509.com: $(OBJECTS)
	wlink   option quiet  option noextension  format dos com  \
		option map  name $@  file {$(OBJECTS)}

.PHONY: clean .symbolic
clean: .symbolic
	rm -f *.o
	rm -f *.err
	rm -f *.map
	rm -f 3c509.com

