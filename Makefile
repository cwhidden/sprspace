CC=g++
CC_OPT=-O2

all: matrix2pairs fill_matrix

matrix2pairs: matrix2pairs.cpp
	${CC} ${CC_OPT} ${LD_OPT} -o matrix2pairs matrix2pairs.cpp

fill_matrix: fill_matrix.cpp
	${CC} ${CC_OPT} ${LD_OPT} -o fill_matrix fill_matrix.cpp
