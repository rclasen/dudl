#!/usr/bin/perl -w

package MP3::Digest;

use strict;
use Carp qw( :DEFAULT cluck);
use Digest::MD5;

BEGIN {
	use Exporter ();
	use vars	qw($VERSION @ISA @EXPORT @EXPORT_VAR @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION	= 1.00;
	@ISA		= qw(Exporter);

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
	my $os = shift;
	if( ! defined $os ){
		carp "must be called with offset object reference"
	}

	my $self	= {
		OFFSET		=> $os,
		FILEDIGEST	=> '',
		DATADIGEST	=> '',
		};

	bless $self, $class;

	return $self->digest;
}

sub filedigest {
	my $self	= shift;
	return $self->{FILEDIGEST};
}

sub datadigest {
	my $self	= shift;
	return $self->{DATADIGEST};
}


sub digest {
	my $self	= shift;

	my $os = $self->{OFFSET};
	my $fsum = new Digest::MD5;
	my $dsum = new Digest::MD5;

	local *F;
	unless( open( F, $os->file ) ){
		cluck "cannot open ". $os->file .": $!";
		return;
	}

	# go back to start, read all headers and feed them to fsum
	seek( \*F, 0, 0 ) || croak "seek failed";

	my $buf;
	my $r;
	if( $os->offset ){
		$r = read( \*F, $buf, $os->offset );
		if( $os->offset != $r ){
			croak "whoops cannot read as much as I wanted!";
		}

		$fsum->add( $buf );
	}


	# read everything (except of tail to ignore) and feed to fsum and
	# dsum
	my $size = 8192;
	while( $size < $os->tail ){
		$size *= 2;
	}

	while( $r = read( \*F, $buf, $size ) ){
		$fsum->add( $buf );

		# chop off tail
		if( $os->tail ){
			if( eof( \*F ) || $r < $size  ){
				$buf = substr( $buf, 0, $r -
				$os->tail );
			}

			$dsum->add( $buf );
		}
	} 
	
	$self->{FILEDIGEST} = $fsum->hexdigest;
	$self->{DATADIGEST} = ( $os->fsize == $os->dsize ) ?
		$self->{FILEDIGEST} :
		$dsum->hexdigest;

	close( F );
	return $self;
}



1;

