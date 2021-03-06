#!/usr/bin/perl -w

#
# Copyright (c) 2008 Rainer Clasen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

# $Id: DB.pm,v 1.5 2008-12-28 11:39:23 bj Exp $

package Dudl::DB;

use strict;
use Carp;
use EzDBI;
use Dudl::Config;
use Dudl::File;



BEGIN {
	use Exporter ();
	use vars	qw($VERSION @ISA @EXPORT @EXPORT_VAR @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION	= 1.00;
	@ISA		= qw(
		Dudl::Config
		);

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

sub new {
	my $proto	= shift;
	if( !defined $proto ){
		croak "must be called as method";
	}

	my $class	= ref($proto) || $proto;
	my $self = $class->SUPER::new(
		# Database
		db_host		=> "",
		db_user		=> "reader",
		db_pass		=> "reader",
		db_name		=> "dudl",

		# files
		cdinfo		=> "/usr/local/bin/cdinfo",
		cdpath		=> "/vol/cd/MP3",
		);
	return undef unless $self;

	$self->{DB}	=> undef,
	return $self;
}

sub DESTROY {
	my $self	= shift;

	$self->{DB}->disconnect if defined $self->{DB};
}

sub db {
	my $self	= shift;

	if( ! defined $self->{DB} ){
		my $cmd = "dbi:Pg:".
			"dbname=". $self->conf("db_name");
		if( $self->conf("db_host") ){
			$cmd .= ";host=". $self->conf("db_host");
		}

		$self->{DB} = EzDBI->connect( $cmd,
			$self->conf("db_user"),
			$self->conf("db_pass"), {
				'AutoCommit' => 0,
				'RaiseError' => 1,
				'ShowErrorStatement' => 1,
				'FetchHashKeyName' => 'NAME_lc',
				'ChopBlanks' => 1,
			}) ||
			croak $DBI::errstr;
	}

	return $self->{DB};
}

# transaction stuff ...
sub commit {
	my $self	= shift;
	return $self->db->commit;
}
sub rollback {
	my $self	= shift;
	return $self->db->rollback;
}

1;
