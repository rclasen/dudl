
# $Id: Makefile,v 1.10 2002-07-26 09:51:12 bj Exp $

prefix		:= /usr/local
perllib		:= $(prefix)/lib/site_perl
bindir		:= $(prefix)/bin

libs	:= $(shell find -name \*.pm)
bins	:= \
	dudl_cdscan.pl \
	dudl_musdirs.pl \
	dudl_musbatch.sh \
	dudl_musgen.pl \
	dudl_mushave.pl \
	dudl_musimport.pl \
	dudl_rename.pl \
	dudl_rengen.pl \
	dudl_status.pl \
	dudl_storhave.pl \
	mkmserv.pl

other	:= \
	README

all:

dist:
	tar -czf ../Dudl.tgz Makefile $(other) $(libs) $(bins)

todo:
	find -type f | xargs grep -i todo 

install: install-bin install-lib

install-bin:
	install -c $(bins) $(bindir)

install-lib:
	set -xe ; \
	for i in $(libs); do \
		mkdir -p `dirname $(perllib)/$$i` ; \
		install -c $$i $(perllib)/$$i ; \
	done
