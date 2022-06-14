CFLAGS=
CXXFLAGS=-std=c++17 -O2 -Wall -Wextra -Wpedantic $(shell pkg-config --cflags libpressio_cxx)
LDFLAGS=$(shell pkg-config --libs libpressio_cxx)
all:
check2D: svd2D_test 
	./svd2D_test $COMPRESS_HOME/datasets/SDRBENCH-Miranda-256x384x384/velocityx.d64
check3D: svd3D_test
	./svd3D_test $COMPRESS_HOME/datasets/SDRBENCH-Miranda-256x384x384/velocityx.d64
clean:
	$(RM) svd2D_test  svd3D_test
