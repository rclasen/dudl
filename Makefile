
# $Id: Makefile,v 1.12 2004-08-28 13:24:31 bj Exp $

prefix		:= /usr/local
perllib		:= $(prefix)/lib/site_perl
bindir		:= $(prefix)/bin

libs	:= $(shell find -name \*.pm)
bins	:= \
	dudl_cdscan.pl \
	dudl-checkavail.pl \
	dudl-cleanup.pl \
	dudl-yearadd.pl \
	dudl-mus2id.pl \
	dudl_musdirs.pl \
	dudl_musbatch.sh \
	dudl_musgen.pl \
	dudl_mushave.pl \
	dudl-muslinks \
	dudl_musimport.pl \
	dudl_status.pl \
	dudl_storhave.pl

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
