#!/usr/bin/perl -w

# $Id: test_job.pl,v 1.3 2002-07-26 17:49:25 bj Exp $

use strict;
use Dudl::Config;
use Dudl::Job::Rename;

my $dudl = new Dudl::Config;

my $j = new Dudl::Job::Rename( naming => $dudl->naming );
foreach( @ARGV ){
	$j->read( $_ );
}

while( my( $alb, $fil, $tit ) = $j->next ){
	print $alb->{name}, " ", $fil->{id}, " ", $tit->{num}, "\n";
}


$j->write( \*STDOUT );
