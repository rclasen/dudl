#! /usr/bin/perl -w


use strict;
use Mp3sum;

my $sum = Mp3sum->new;

foreach (@ARGV){
	print $_, "\n";
	$sum->scan($_);
	print "file:   ". $sum->filedigest ."\n";
	print "data:   ". $sum->datadigest ."\n";
	print "id3v1:  ". $sum->id3v1 ."\n";
	print "id3v2:  ". $sum->id3v2 ."\n";
	print "riff:   ". $sum->riff ."\n";
	print "fsize:  ". $sum->fsize ."\n";
	print "offset: ". $sum->offset ."\n";
	print "dsize:  ". $sum->dsize ."\n";
	print "tail:   ". $sum->tail ."\n";
}

