CC = gcc
CFLAGS = -g -O0 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-return-type -Wno-pointer-to-int-cast
FC = gfortran
FFLAGS = -g -O0 -finteger-4-integer-8 -std=legacy -Wno-argument-mismatch 

OBJS = spice_main.o spice_ui.o spice_engine.o spice_memmgr.o unix.o

all: spice

spice: $(OBJS)
	$(FC) $(OBJS) -o spice

spice_main.o: spice_main.f
	$(FC) -c $(FFLAGS) spice_main.f -o spice_main.o

spice_ui.o: spice_ui.f
	$(FC) -c $(FFLAGS) spice_ui.f -o spice_ui.o

spice_engine.o: spice_engine.f
	$(FC) -c $(FFLAGS) spice_engine.f -o spice_engine.o

spice_memmgr.o: spice_memmgr.f
	$(FC) -c $(FFLAGS) spice_memmgr.f -o spice_memmgr.o

unix.o: unix.c
	$(CC) $(CFLAGS) -std=gnu89 -c unix.c -o unix.o

clean:
	rm -f $(OBJS) spice
