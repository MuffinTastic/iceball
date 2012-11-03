# I personally don't care if you steal this makefile. --GM

CFLAGS = -O2 -g `sdl-config --cflags` -Wall -Wextra \
	-Wno-unused-variable -Wno-unused-parameter \
	-Wno-unused-but-set-variable

LDFLAGS = -g
LIBS = -lm `sdl-config --libs`
BINNAME = bts

INCLUDES = common.h
OBJS = \
	main.o \
	vecmath.o \
	map.o model.o \
	render.o

all: $(BINNAME)

clean:
	rm -f $(OBJS)

$(BINNAME): $(OBJS)
	$(CC) -o $(BINNAME) $(LDFLAGS) $(OBJS) $(LIBS)

%.o: %.c $(INCLUDES)
	$(CC) -c -o $@ $(CFLAGS) $<

