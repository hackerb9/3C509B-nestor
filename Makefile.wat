all: 3c509.com

.SUFFIXES: .asm

.asm.o:
	wasm -q $*

3c509.com: head.o 3c509.o tail.o .symbolic
	wlink   option quiet  option noextension  format dos com  \
		option map  name $@  file {$?}

.PHONY: clean .symbolic 3c509.com
clean: .symbolic
	rm -f *.o
	rm -f *.err
	rm -f *.map
	rm -f 3c509.com


#####
# A note on why "$?" (younger prereqs) is being used:
#
# GNU make uses $^ for all prerequisites but WMAKE uses $<.
# In GNU Make, $< is only the first prerequisite file.
#
# Both have $? which means all prerequisites which are _newer_ than
# the target. To force them to always be newer, one can tell GNU make
# that 3c509.com is a "PHONY" target, and WMAKE that it is
# ".symbolic". 

