CFLAGS=
CXXFLAGS=-std=c++17 -O2 -Wall -Wextra -Wpedantic $(shell pkg-config --cflags libpressio_cxx)
LDFLAGS=$(shell pkg-config --libs libpressio_cxx)
run:
	$(CC) $(CXXFLAGS) metrics.o svd.o $(LDFLAGS) -o compress_analysis
check: metrics
	./compress_analysis
clean:
	$(RM) compress_analysis
