#
# Makefile 
#

CC = gcc

#CFLAGS = -c -Wall -O2 -s -DNDEBUG
CFLAGS = -c -O2 -s -DNDEBUG

HEADER = -I/usr/local/include

LIB = -L/usr/local/lib -lwiringPi -lcrypt -lpthread -lm -lrt

EXEC = rpi_i2c_oled

SRCS := $(wildcard *.c)
BINS := $(SRCS:.c=.o)

all: $(EXEC)

$(EXEC): $(BINS)
	$(CC) $(BINS) $(LIB) -o $(EXEC)

%.o: %.c
	$(CC) $(CFLAGS) $(HEADER) $< 

clean:
	rm *.o
	rm $(EXEC)
