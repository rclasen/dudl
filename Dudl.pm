#!/usr/bin/perl -w

package Dudl;

use strict;
use Dudl::Base;
use Dudl::Unit;
use Dudl::File;

BEGIN {
	use Exporter ();
	use vars	qw($VERSION @ISA @EXPORT @EXPORT_VAR @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION	= 1.00;
	@ISA		= qw(
		Exporter
		Dudl::Base
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

sub newunit {
	my $self	= shift;

	return Dudl::Unit->new( $self );
}

sub findunitpath {
	my $self	= shift;
	my $name	= shift;

	my $unit = Dudl::Unit->new( $self );
	if( ! $unit ){
		return undef;
	}

	if( $unit->get_collection( &Dudl::Unit::splitpath($name) )){
		return $unit;
	} else {
		return undef;
	}
}

1;
