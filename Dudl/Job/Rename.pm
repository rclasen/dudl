#!/usr/bin/perl -w

# $Id: Rename.pm,v 1.5 2001-12-20 16:38:30 bj Exp $

package Dudl::Job::Rename;

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

sub album_valid {
	my $self = shift;
	
	my $cur = $self->{album};
	my $err = 0;
	if( ! $cur->{type} ){
		$self->bother( "no album type set");
		$err++;
		
	}

	$self->{naming}->album_valid( $cur ) || $err++;
	$self->SUPER::album_valid || $err++;

	return !$err;
}

sub file_valid {
	my $self = shift;
	
	my $cur = $self->{file};
	my $err = 0;
	if( ! $cur->{mp3} ){
		$self->bother( "no mp3 name for file");
		$err++;
		
	}

	$self->SUPER::file_valid || $err++;

	return !$err;
}

sub file_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{file};

	if( $key eq "mp3" ){
		$cur->{$key} = $val;
		return 1;
	
	}

	return $self->SUPER::file_key( $key, $val );
}

sub title_valid {
	my $self = shift;
	
	my $cur = $self->{title};
	my $err = 0;

	$self->{naming}->title_valid( $self->album, $cur ) || $err++;
	$self->SUPER::title_valid || $err++;

	return !$err;
}

sub write_file {
	my $self = shift;
	my $fh = shift;
	my $fil = shift;

	print $fh "file_mp3 \t". ($fil->{mp3} || "") ."\n";
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
