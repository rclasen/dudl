#!/usr/bin/perl -w

package Dudl::StorExport;

# suggest fields for Musik database from filenames
# based on stor_export table containing regular expressions

# TODO: migrate rgexps from stor_export table to this file

use strict;
use Carp qw{ :DEFAULT cluck };
use DBI;
use Dudl::Base;


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
		BASE		=> shift,
		regexps		=> [],
		cur		=> 0,
		debug		=> shift,
		};

	bless $self, $class;
	return $self->get_regexp();
}

# load regexps from database
sub get_regexp {
	my $self	= shift;

	my $db = $self->{BASE}->db;
	my $query = 
		"SELECT ".
			"id, ".
			"regexp, ".
			"fields, ".
			"description ".
		"FROM stor_export ".
		"WHERE ".
			"regexp NOTNULL ".
		"ORDER BY ".
			"priority ";
	my $dbre = $db->prepare( $query );
	if( ! $dbre ){
		warn "query failed: ". $query ."\n". $db->errstr;
		return undef;
	}
	if( ! $dbre->execute ){
		warn "query failed: ". $query ."\n". $dbre->errstr;
		return undef;
	}

	my $i = 0;
	my(
		$id,
		$regexp,
		$fields,
		$desc
		);
	$dbre->bind_columns( \(
		$id,
		$regexp,
		$fields,
		$desc
		));

	while( $dbre->fetch ){
		$regexp = "" unless defined $regexp;
		$fields = "" unless defined $fields;

		print STDERR "$id, $regexp, $fields\n" if $self->{debug};

		$self->{regexps}[$i] = {
			id	=> $id,
			re	=> $regexp,
			fields	=> {},
			desc	=> $desc,
			};

		my @f = split /\s*,\s*/, $fields;
		foreach( 0..$#f ){
			if( defined $f[$_] && $f[$_] ){
				$self->{regexps}[$i]{fields}{$f[$_]} = $_;
			}
		}

		$i++;
	}

	$dbre->finish;
	return $self;
}

# move internal pointer back to start
sub rewind {
	my $self	=shift;

	$self->{cur} = 0;
}

sub id {
	my $self	= shift;
	
	return $self->{regexps}[$self->{cur}]{id};
}

sub desc {
	my $self	= shift;
	
	return $self->{regexps}[$self->{cur}]{desc};
}

# return hashref with next suggestion
sub suggest {
	my $self	= shift;
	my $dir		= shift;
	my $fname	= shift;

	my $path = $dir ."/". $fname;

	while( $self->{cur} < $#{$self->{regexps}} ){

		my $re = $self->{regexps}[$self->{cur}]{re} ."\\.mp3\$";
		my $fields = $self->{regexps}[$self->{cur}]{fields};

		my @match = $path =~ m:$re:i;
		$self->{cur}++;

		# return hashref on match
		return( {
			artist	=> &sugitem( "artist", \@match, $fields ),
			album	=> &sugitem( "album", \@match, $fields ),
			titlenum => &sugitem( "titlenum", \@match, $fields ),
			title	=> &sugitem( "title", \@match, $fields ),
		}) if @match;
	}

	return undef;
};

sub sugitem {
	my $item = shift;
	my $match = shift;
	my $fields = shift;

	my $val = "";
	if( exists $fields->{$item} ){
		my $f = $fields->{$item};

		if( defined $match->[$f] ){
			$val = $match->[$f];
		}
	}

	$val =~ s/\.+/ /g;
	return $val;
}

1;
