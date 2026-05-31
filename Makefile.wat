all: 3c509.com

.SUFFIXES: .asm

.asm.o:
	wasm -q $*

# A note on "$?":
# Watcom's WMAKE treats $< as the list of all dependent files.
# In GNU Make, $< is only the first prerequisite file.
# WMAKE doesn't have gmake's $^ for all prerequisites.
# However, they both have $? which means all prerequisites which are
# newer than the target.

3c509.com: head.o 3c509.o tail.o
	wlink   option quiet  option noextension  format dos com  \
		option map  name $@  file $< $^

.PHONY: clean .symbolic
clean: .symbolic
	rm -f *.o
	rm -f *.err
	rm -f *.map
	rm -f 3c509.com
