#!/usr/bin/perl -w

# $Id: Misc.pm,v 1.2 2008-12-28 11:39:23 bj Exp $

#
# Copyright (c) 2008 Rainer Clasen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

=pod

=head1 NAME

Dudl::Misc - several helper functions for dudl applications

=head1 DESCRIPTION

This module combines several helper functions.

=head1 FUNCTIONS

=over 4

=cut

package Dudl::Misc;

use strict;
use Carp qw{ :DEFAULT cluck };

our $VERSION = 1.00;
our @ISA = qw(Exporter);

# exported by default:
our @EXPORT_VAR = qw();
our @EXPORT = qw(
	&get_fstab
	&fnames_arg
	&parentdir
	&samedir
	&unitsplit
	&checkgenre
);
# shortcuts for in demand exports
our %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

# your exported package globals go here,
# as well as any optionally exported functions
our @EXPORT_OK	= ( qw(), @EXPORT );



=pod

=item get_fstab( $mpoint )

=item get_fstab( $dev )

returns matching ($device, $mountpoint) tuple from fstab.

=cut
sub get_fstab
{
	my $ent		= shift;

	if( ! open FS, "/etc/fstab" ){
		cluck "cannot open fstab";
		return undef;
	}

	while( <FS> ){
		s/#.*//;
		s/^\s*//;

		next if( /^$/ );

		my( $fs, $mp, $type, $opt) = split;
		if( ($fs eq $ent) || ($mp eq $ent) ){
			close FS;
			return( $fs, $mp );
		}
	}

	close FS;

	return undef;
}

=pod

=item fnames_arg( \@ARGV )

expand each item from the supplied arrayref:

=over 2

=item '-'

reads filenames from stdin

=item a directory name

all .mp3 and .wav filenames from this directory are picked

=item filename (other)

kept as is

=back

All filenames are returned as arrayref.

=cut
sub fnames_arg {
	my $arg = shift;

	my @f;
	my $stdin = 0;
	foreach( @$arg ){
		if( $_ eq "-" ){
			&fnames_stdin( \@f ) if ! $stdin++;

		} elsif( -d $_ ){
			&fnames_dir( \@f, $_ );

		} else {
			push @f, $_;
		}
	}

	return \@f;
}

# add files from stdin to list
sub fnames_stdin {
	my $files = shift;;

	while( <STDIN> ){
		chomp;
		push @$files, $_;
	}
}

# add files in current dir to list
sub fnames_dir {
	my $files = shift;
	my $dir = shift;

	my @f;
	local *DIR;

	# TODO: make filename pattern configurable
	opendir( DIR, $dir ) || croak "cannot opendir \"$dir\": $! ";
	while( defined( $_ = readdir( DIR )) ){
		next if /^\.\.?$/;
		next unless /\.(mp3|wav)$/i;
		push @f, "$dir/$_";
	}
	closedir( DIR );

	push @$files, sort { $a cmp $b } @f;
}

=pod

=item parentdir( $fname )

returns name of the file's parent directory.

=cut

sub parentdir {
	my( $fname ) = @_;

	if( $fname !~ /^\// ){
		$fname = "./$fname";
	}
	$fname =~ /^(.*\/)[^\/]+\/*$/;
	return $1
}

=pod

=item samedir( $dirA, $dirB )

returns true if both directory names point to the same directory.

=cut

sub samedir {
	my( $a, $b ) = @_;

	my @sa = stat $a;
	my @sb = stat $b;

	# compare dev + inode
	return $sa[0] == $sb[0] && $sa[1] == $sb[1];
}

=pod

=item ( $collection, $colnum ) = unitsplit( $dir )

returns the collection and collection number from a directory name.

=cut


sub unitsplit {
	my ( $path ) = @_;

	return $path =~ /(?:\/|^)([a-z]+)0*(\d+)\/*$/;
}

=pod

=item checkgenre( $genre )

returns the normalized genre or undef

=cut


sub checkgenre {
	my $genre = shift || "";

	return $genre =~ /^(comedy|dance|klassik|pop|rock|metal|sampler)$/i ? uc $genre : undef;
}


1;
__END__

=head1 AUTHOR

Rainer Clasen

=cut


