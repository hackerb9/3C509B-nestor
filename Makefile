# This Makefile can be used by GNU make, MS nmake, or Watcom WMAKE.
# (Watcom requires 'WMAKE -u' to handle backslash and SUFFIXES)

all: 3c509.com

OBJECTS=head.o 3c509.o tail.o
# Note: WMAKE disagrees with GNU Make on what $< and $^ mean.

.SUFFIXES: .asm
.asm.o:
	wasm -q $*

3c509.com: $(OBJECTS)
	wlink   option quiet  format dos com  \
			option map  \
		name $@  file {$(OBJECTS)}

# Note: WMAKE doesn't allow ".symbolic" to be PHONY or a target.
clean:
	rm -f *.o
	rm -f *.err
	rm -f *.map
	rm -f 3c509.com


## Alternative compilation via DOSBOX and tasm/TASM.EXE.
## This should be byte-for-byte identical to Wacom's WASM.
## (See also: tasm/MAKEFILE)
tasm/3C509.COM:
	cd tasm; \
	dosbox -c "MOUNT C: ." -c "C:" -c "MAKE" -c exit

