#!/usr/bin/perl -w

use strict;
use Dudl::Job::Rename;

my $j = new Dudl::Job::Rename;
foreach( @ARGV ){
	$j->read( $_ );
}

while( my( $alb, $fil, $tit ) = $j->next ){
	print $alb->{name}, " ", $fil->{id}, " ", $tit->{num}, "\n";
}


$j->write( \*STDOUT );
