#!/usr/bin/perl -w

package Dudl::Job::Music;
# base class for jobfile parser

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

sub new {
	my $proto	= shift;
	if( !defined $proto ){
		carp "must be called as method";
	}
	my $class	= ref($proto) || $proto;
	return $class->SUPER::new( @_ );
}


sub album_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{album};

	if( $key eq "id" ){
		$cur->{$key} = $val;
		return 1;

	} 

	return $self->SUPER::album_key( $key, $val );
}


sub file_check {
	my $self = shift;
	
	my $cur = $self->{file};
	my $err = 0;
	if( ! $cur->{id} ){
		$self->bother( "no id for file");
		$err++;
		
	}

	$self->SUPER::file_check || $err++;

	return !$err;
}

sub file_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{file};

	if( $key eq "id" ){
		$cur->{$key} = $val;
		return 1;
	
	}

	return $self->SUPER::file_key( $key, $val );
}

sub title_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{title};

	if( $key eq "id" ){
		$cur->{$key} = $val;
		return 1;

	}

	return $self->SUPER::title_key( $key, $val );
}



1;