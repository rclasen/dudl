#!/usr/bin/perl -w

# $Id: Offset.pm,v 1.3 2001-12-13 11:41:49 bj Exp $

package MP3::Offset;

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
	my $self	= {
		FILE		=> shift,
		RIFF		=> 0,	# riff header length
		ID3V1		=> 0,	# id3v1 header length 
		ID3V2		=> 0,	# id3v2 header length 
		FSIZE		=> 0,	# File size
		OFFSET		=> 0,	# where does data start
		DSIZE		=> 0,	# data size without headers
		TAIL		=> 0,	# tail size
		};

	bless $self, $class;
	return $self->scan;
}


sub file {
	my $self	= shift;
	return $self->{FILE};
}

sub id3v1 {
	my $self	= shift;
	return $self->{ID3V1};
}


sub id3v2 {
	my $self	= shift;
	return $self->{ID3V2};
}


sub riff {
	my $self	= shift;
	return $self->{RIFF};
}


sub offset {
	my $self	= shift;
	return $self->{OFFSET};
}


sub fsize {
	my $self	= shift;
	return $self->{FSIZE};
}


sub dsize {
	my $self	= shift;
	return $self->{DSIZE};
}


sub tail {
	my $self	= shift;
	return $self->{TAIL};
}




sub head_id3v2 {
	my $fh = shift;

	my $pos = tell( $fh );

	my $buf;
	my $hlen = 10;
	my $r = read( $fh, $buf, $hlen );
	return 0 unless $r;

	if( $r == $hlen && substr($buf,0,3) eq "ID3" ){
		# get the total header size
		my $size=0;
		foreach( unpack("x6C4", $buf) ){
			$size = ($size << 7) + $_;
		}

		# and skip all header data
		seek( $fh, $size, 1 );
		return $size + $hlen;
	} 

	seek( $fh, $pos, 0 );
	return 0;
}
	

sub head_riff {
	my $fh = shift;

	my $pos = tell( $fh );

	my $buf;
	my $hlen = 12;
	my $r = read( $fh, $buf, $hlen );
	return 0 unless $r;

	if( $r == $hlen ){
		my( $head, $len ) = unpack( "A4lx4", $buf );

		if( $head eq "RIFF" ){

			while(1) {
				# read next subheader
				$r = read( $fh, $buf, 8 );
				if( ! $r || $r != 8 ){
					last;
				}
				$hlen += 8;

				( $head, $len ) = unpack( "A4l", $buf );
				if( $head eq "data" ){
					last;
				}
				
				# skip data of last subheader
				seek( $fh, $len, 1 ) || last;
				$hlen += $len;
			};
		
			# HACK: ignore too large RIFF headers
			return $hlen if $hlen < 600000;
		}
	}

	seek( $fh, $pos, 0 );
	return 0;
}


sub tail_id3v1 {
	my $fh = shift;

	my $pos = tell( $fh );

	seek( $fh, -128, 1 ) || return 0;
	
	my $hlen = 3;
	my $buf;
	my $r = read( $fh, $buf, $hlen );
	return 0 unless $r;

	if( $r == $hlen && $buf eq "TAG" ){
		return 128;
	}

	seek( $fh, $pos, 0 );
	return 0;
}


sub scan {
	my $self	= shift;

	local *F;
	unless( open( F, $self->file ) ){
		cluck "cannot open ". $self->file .": $!";
		return;
	}


	$self->{ID3V1}	= 0;
	$self->{ID3V2}	= 0;
	$self->{RIFF}	= 0;

	$self->{OFFSET} = 0;
	$self->{DSIZE} = 0;
	$self->{FSIZE} = 0;
	$self->{TAIL} = 0;

	my $skipped;

	# count junk at beginning ...
	#
	# TODO: search real mp3 data instead of known junk.
	# see MP3::Info on how to recognize a MP3 Data.
	do {
		my $skip;

		$skipped = 0;

		$skip = &head_id3v2( \*F );
		if( $skip ){
			$self->{ID3V2} += $skip;
		}
		$skipped += $skip;

		$skip = &head_riff( \*F );
		if( $skip ){
			$self->{RIFF} += $skip;
		}
		$skipped += $skip;

		$self->{OFFSET} += $skipped;

	} while( $skipped );

	
	# go to tail
	seek( \*F, 0, 2 );
	$self->{FSIZE} = tell( \*F );

	# count junk at tail
	do {
		my $skip;

		$skipped = 0;

		$skip = &tail_id3v1( \*F );
		if( $skip ){
			$self->{ID3V1} += $skip;
		}
		$skipped += $skip;

		$self->{TAIL} += $skipped;

	} while( $skipped );

	$self->{DSIZE} = $self->{FSIZE} - $self->{OFFSET} - $self->{TAIL};

	close( F );
	return $self;
}




1;

