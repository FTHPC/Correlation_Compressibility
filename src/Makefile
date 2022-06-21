CC=g++
CFLAGS=
CXXFLAGS=-std=c++2a -O2 -Wall -Wextra -Wpedantic $(shell pkg-config --cflags libpressio_cxx) $(shell pkg-config --cflags eigen3) -march=native -mtune=native
LDFLAGS=$(shell pkg-config --libs libpressio_cxx) $(shell pkg-config --libs libpressio_tthresh)

compress_analysis: metrics.o svd.o analysis.o qentropy.o
	$(CC) $(CXXFLAGS) metrics.o svd.o analysis.o qentropy.o $(LDFLAGS) -o compress_analysis

check:
	./compress_analysis

clean:
	$(RM) compress_analysis 
	$(RM) *.o
