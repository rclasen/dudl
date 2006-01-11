
# $Id: Makefile,v 1.17 2006-01-11 14:30:23 bj Exp $

prefix		:= /usr/local
perllib		:= $(prefix)/lib/site_perl
bindir		:= $(prefix)/bin

libs	:= $(shell find -name \*.pm)
bins	:= \
	dudl-dbavcheck \
	dudl-dbmaintenance \
	dudl-dbstatus \
	dudl-docdimg \
	dudl-doout \
	dudl-doren \
	dudl-dosort \
	dudl-dotest \
	dudl-fclean \
	dudl-fname \
	dudl-mus2id \
	dudl-musbatch \
	dudl-musdirs \
	dudl-musgen \
	dudl-mushave \
	dudl-musimport \
	dudl-muslinks \
	dudl-musyearadd \
	dudl-storhave \
	dudl-storscan 

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
