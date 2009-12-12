#!/usr/bin/perl -w

# $Id: Music.pm,v 1.9 2008-12-28 11:39:23 bj Exp $

#
# Copyright (c) 2008 Rainer Clasen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

package Dudl::Job::Music;

use strict;
use Carp qw( :DEFAULT cluck);
use Dudl::Job::Base;

BEGIN {
	use Exporter ();
	use vars	qw($VERSION @ISA @EXPORT @EXPORT_VAR @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION	= 1.00;
	@ISA		= qw( Dudl::Job::Base );

	# exported by default:
	@EXPORT_VAR	= qw();
	@EXPORT		= ( qw(),
			@EXPORT_VAR );

	# shortcuts for in demand exports
	%EXPORT_TAGS	= ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK	= ( qw(),
			@EXPORT );
}
use vars	@EXPORT_VAR;

# non-exported package globals go here

# initialize package globals, first exported ones


sub file_valid {
	my $self = shift;
	my $cur = shift || $self->{file};

	my $err = 0;
	if( ! $cur->{id} ){
		$self->bother( "no id for file");
		$err++;

	}

	$self->SUPER::file_valid( $cur ) || $err++;

	return !$err;
}

sub title_valid {
	my $self = shift;
	my $cur = shift || $self->{title};

	my $err = 0;
	if( ! defined $cur->{segf} ){
		$self->bother( "missing segment start");
		#$err++; # TODO: make segments a requirement

	} elsif( ! defined $cur->{segt} ){
		$self->bother( "missing segment end");
		#$err++; # TODO: make segments a requirement

	}

	$self->SUPER::title_valid( $cur ) || $err++;

	return !$err;
}

sub write_file {
	my $self = shift;
	my $fh = shift;
	my $fil = shift;

	print $fh "# ". $fil->{mp3} ."\n" if $fil->{mp3};
	$self->SUPER::write_file( $fh, $fil );
}

sub write_title {
	my $self = shift;
	my $fh = shift;
	my $tit = shift;

	print $fh "# sug: ". $tit->{source} ."\n" if $tit->{source};
	$self->SUPER::write_title( $fh, $tit );
}

1;
