#!/usr/bin/perl -w

# $Id: Music.pm,v 1.6 2001-12-20 16:38:30 bj Exp $

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


sub file_valid {
	my $self = shift;
	
	my $cur = $self->{file};
	my $err = 0;
	if( ! $cur->{id} ){
		$self->bother( "no id for file");
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

sub write_album {
	my $self = shift;
	my $fh = shift;
	my $alb = shift;

	print $fh "album_id\t". $alb->{id} ."\n" if $alb->{id};
	$self->SUPER::write_album( $fh, $alb );
}

sub write_file {
	my $self = shift;
	my $fh = shift;
	my $fil = shift;

	print $fh "# ". $fil->{mp3} ."\n" if $fil->{mp3};
	print $fh "file_id \t". ($fil->{id} || 0) ."\n";
	$self->SUPER::write_file( $fh, $fil );
}

sub write_title {
	my $self = shift;
	my $fh = shift;
	my $tit = shift;

	print $fh "# sug: ". $tit->{source} ."\n" if $tit->{source};
	print $fh "title_id\t". $tit->{id} ."\n" if $tit->{id};
	$self->SUPER::write_title( $fh, $tit );
}

1;
