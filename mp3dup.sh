#!/bin/sh

# read a sorted list and show duplicates. uniq -c won't cut it.
#
# input:
#  <sum> <filename>

# $Id: mp3dup.sh,v 1.1 2002-07-25 10:38:53 bj Exp $

osum=""
oname=""
omatch=false

cat "$@" | while read sum name ; do
	if [ "$osum"x = "$sum"x ]; then
		echo "$osum $oname"

		omatch=true
	else
		if $omatch; then
			echo "$osum $oname"

			omatch=false

		fi
	fi

	osum="$sum"
	oname="$name"
done
