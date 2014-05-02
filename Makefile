CC=g++
CC_OPT=-O2

all: matrix2pairs

matrix2pairs: matrix2pairs.cpp
	${CC} ${CC_OPT} ${LD_OPT} -o matrix2pairs matrix2pairs.cpp
