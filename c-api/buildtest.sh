#!/bin/sh
gcc -otest -O3 test.c ./libdmech.so -lGL -lGLU -lglut
