#!/usr/bin/make

# build tree
TOP		:= $(shell cd ..; pwd )
DIR		:= dudl

# untouched source tree
SRCDIR		:= $(TOP)

include $(SRCDIR)/Makefile.start
