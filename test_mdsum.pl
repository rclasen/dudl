#! /usr/bin/perl -w


use strict;
use MP3::Offset;
use MP3::Digest;


foreach (@ARGV){
	my $of = new MP3::Offset( $_ );
	my $dg = new MP3::Digest( $of );
	print $_, "\n";
	print "file:   ". $dg->filedigest ."\n";
	print "data:   ". $dg->datadigest ."\n";
	print "id3v1:  ". $of->id3v1 ."\n";
	print "id3v2:  ". $of->id3v2 ."\n";
	print "riff:   ". $of->riff ."\n";
	print "fsize:  ". $of->fsize ."\n";
	print "offset: ". $of->offset ."\n";
	print "dsize:  ". $of->dsize ."\n";
	print "tail:   ". $of->tail ."\n";
}

