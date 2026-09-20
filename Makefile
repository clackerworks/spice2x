CC = gcc
CFLAGS = -g -O0 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-return-type -Wno-pointer-to-int-cast
FC = gfortran
FFLAGS = -g -O0 -finteger-4-integer-8 -std=legacy -Wno-argument-mismatch 

ENGINE_SRCS = engine/matrix.f engine/dcop.f engine/devices.f engine/mosfet.f \
	engine/poly.f engine/acanal.f engine/disto.f
ENGINE_OBJS = $(ENGINE_SRCS:.f=.o)

OBJS = spice_main.o ui/spice_ui.o $(ENGINE_OBJS) spice_memmgr.o unix.o

all: spice

spice: $(OBJS)
	$(FC) $(OBJS) -o spice

spice_main.o: spice_main.f
	$(FC) -c $(FFLAGS) spice_main.f -o spice_main.o

ui/spice_ui.o: ui/spice_ui.f
	$(FC) -c $(FFLAGS) $< -o $@

engine/%.o: engine/%.f
	$(FC) -c $(FFLAGS) $< -o $@

spice_memmgr.o: spice_memmgr.f
	$(FC) -c $(FFLAGS) spice_memmgr.f -o spice_memmgr.o

unix.o: unix.c
	$(CC) $(CFLAGS) -std=gnu89 -c unix.c -o unix.o

test:
	tests/run_tests.sh

clean:
	rm -f $(OBJS) spice
