#! /usr/bin/perl -w

# $Id: mp3sum.pl,v 1.2 2001-12-13 11:41:48 bj Exp $

# tiny script to generate md5sums for mp3data (skipping their header)

use strict;
use MP3::Offset;
use MP3::Digest;

if( $#ARGV >= 0 ){
	foreach (@ARGV){
		&file( $_ );
	}
} else {
	while(<>){
		chomp;
		&file( $_ );
	}
}

sub file {
	my $fname = shift;

	my $of = new MP3::Offset( $fname );
	my $dg = new MP3::Digest( $of );
	print $dg->datadigest ." $fname\n";
}

