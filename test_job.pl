#!/usr/bin/perl -w

# $Id: test_job.pl,v 1.2 2001-12-13 11:41:48 bj Exp $

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
