#!/usr/bin/perl -w

# $Id: test_riff.pl,v 1.3 2002-04-28 11:54:41 bj Exp $

use strict;

my $f = shift;
my $o = shift;

# $f = "/vol/cd/MP3/jk0001/James Brown - Sex Machine The Very Best of James Brown/01 - Please Please Please!.mp3";
open F, $f or die "open '$f' failed: $!";


my( $head, $len, $subtype );
my $buf;
my $got = 1;
my $hlen = 0;

$hlen = $got = read( F, $buf, 12 );
($head, $len, $subtype ) = unpack( "A4lA4", $buf );

if( $head ne "RIFF" ){
	die "no riff file";
}

print "len: $len\n";

while( $got && ($got = read( F, $buf, 8 )) ){
	$hlen += $got;

	($head, $len ) = unpack( "A4l", $buf );
	print "head=$head, len=$len\n";

	last if $head eq "data";

	$got = read( F, $buf, $len );
	$hlen += $got;
}

print "hlen: $hlen\n";

if( ! defined $o  || -e $o ){
	close F;
	exit 0;
}

print "copy file to $o? (INTR to abort)";
$_ = <STDIN>;

open( O, ">$o" ) || die "cannot open output '$o': $!";
seek F,$hlen+1,0;
while( 0 < read( F, $buf, 10240)){
	print O $buf;
}

close(O);
close(F);

