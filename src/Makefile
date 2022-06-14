CFLAGS=
CXXFLAGS=-std=c++17 -O2 -Wall -Wextra -Wpedantic $(shell pkg-config --cflags libpressio_cxx)
LDFLAGS=$(shell pkg-config --libs libpressio_cxx)
all: metrics 
metrics:
check: metrics
	./metrics
clean:
	$(RM) metrics 
