#!/usr/bin/perl -w

use strict;

open F, "/vol/cd/MP3/jk0001/James Brown - Sex Machine The Very Best of James Brown/01 - Please Please Please!.mp3" or die "open failed: $!";


my( $head, $len, $subtype );
my $buf;
my $got = 1;

$got = read( F, $buf, 12 );
($head, $len, $subtype ) = unpack( "A4lA4", $buf );
while( $got && ($got = read( F, $buf, 8 )) ){
	($head, $len ) = unpack( "A4l", $buf );
	print "head=$head, len=$len\n";

	last if $head=data;
	$got = read( F, $buf, $len );
}
close F;
