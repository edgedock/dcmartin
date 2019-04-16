#
# Makefile
#

CC = gcc

#CFLAGS = -c -Wall -O2 -s -DNDEBUG
CFLAGS = -c -O2 -s -DNDEBUG

HEADER = -I/usr/local/include

LIB = -L/usr/local/lib -lwiringPi -lcrypt -lpthread -lm -lrt

all: rpi_i2c_oled

rpi_i2c_oled: display.o ssd1306_i2c.o
	$(CC) display.o ssd1306_i2c.o $(LIB) -o rpi_i2c_oled

display.o: display.c
	$(CC) $(CFLAGS) $(HEADER) display.c

ssd1306_i2c.o: ssd1306_i2c.c
	$(CC) $(CFLAGS) $(HEADER) ssd1306_i2c.c

clean:
	rm *.o
	rm display
