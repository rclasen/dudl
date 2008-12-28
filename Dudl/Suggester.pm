#!/usr/bin/perl -w

# $Id: Suggester.pm,v 1.16 2008-12-28 11:39:23 bj Exp $

#
# Copyright (c) 2008 Rainer Clasen
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

=pod

=head1 NAME

Dudl::Suggester - find best suggestions for MP3 information

=head1 SYNOPSIS

 use Dudl::Suggester;
 $fname = "dir/a_strange_file_name.mp3";
 $sug = new Dudl::Suggester;
 $sug->add_stor( $fname );
 $sug->add_regexp( $fname, '(.*)-(.*)', [qw( artist title )], "manual" );
 $sug->add_id3( $fname );

 $sug->order;
 while( defined( $s = $sug->get )){
 	print "$s->{sug_quality} $s->{title} $s->{artist}\n";
 }

=head1 DESCRIPTION
 
The Suggestor can get fed with Information about MP3s from several
sources. Based on what information could be determined from a source a
suggestion is scored.

After invoking the ->order method, you can iterate through the collected
suggestions with a descending score.

=cut

package Dudl::Suggester;

use strict;
use Carp qw{ :DEFAULT cluck };
use MP3::Tag;


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
use vars '@regexps';

# TODO: move stored regexps to configurable module
@regexps = (
	{
		re	=> '\.--\.([^/]+)/([^/]+)\.--\.(\d+)_([^/]+)',
		fields	=> &re_fields( qw( album artist titlenum title )),
	},
	{
		re	=> '\([^/]+\) ([^/]+)/(\d+)[-_ .]*\[([^/]+)\][-_ .]*([^/]+)',
		fields	=> &re_fields( qw( album titlenum artist title )),
	},
	{
		re	=> '[_ .]-+[_ .]+([^/]+)/(\d+)[-_ .]*\(([^/]+)\)[-_ .]*([^/]+)',
		fields	=> &re_fields( qw( album titlenum artist title )),
	},
	{
		re	=> '(?:^|/)([^/]+) \(([^/]+) #(\d+)\) - ([^/]+)',
		fields	=> &re_fields( qw( artist album titlenum title )),
	},
	{
		re	=> '(?:[_ .]-+[_ .]+)?([^/]+)/(\d+)_([^/]+)\.--\.([^/]+)',
		fields	=> &re_fields( qw( album titlenum artist title )),
	},
	{
		re	=> '(?:[_ .]-+[_ .]+)?([^/]+)/([^/]+)\.--\.(\d+)_([^/]+)',
		fields	=> &re_fields( qw( album artist titlenum title )),
	},
	{
		re	=> '(?:[_ .]-+[_ .]+)?([^/]+)/(\d+)[-_ .]+([^/]+)[-_ .]+-[-_ .]+([^/])',
		fields	=> &re_fields( qw( album titlenum artist title )),
	},
	{
		re	=> '(?:[_ .]-+[_ .]+)?[^/]+/([^/]+)[-_ .]+-[-_ .]+([^/]+)-(\d+)-([^/]+)',
		fields	=> &re_fields( qw( artist album titlenum title )),
	},
	{
		re	=> '(?:[_ .]-+[_ .]+)?([^/]+)/([^/]+)[-_ .]+-[-_ .]+(\d+)[-_ .]+-[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( album artist titlenum title )),
	},
	{
		re	=> '\(([^/]+)\) ([^/]+)/(\d+)[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( artist album titlenum title )),
	},
	{
		re	=> '([^/]+)[_ .]-+[_ .]+([^/]+)/(\d+)[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( artist album titlenum title )),
	},
	{
		re	=> '([^/]+)/(\d+)[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( album titlenum title )),
	},
	{
		re	=> '\(([^/]+)\) ([^/]+)/([^/]+)',
		fields	=> &re_fields( qw( artist album title )),
	},
	{
		re	=> '-[-_ .]+([^/]+)/([^/]+)[-_ .]+-[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( album artist title )),
	},
	{
		re	=> '([^/]+)/([^/]+)[-_ .]+-[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( album artist title )),
	},
	{
		re	=> '\[(\d+)\][-_ .]+([^/]+)[-_ .][-_ .]+([^/]+)',
		fields	=> &re_fields( qw( titlenum artist title )),
	},
	{
		re	=> '(\d+)[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( titlenum title )),
	},
	{
		re	=> '([^/]+).+([^/]+)[-_ .]+(\d+)[-_ .]+([^/]+)',
		fields	=> &re_fields( qw( artist album titlenum title )),
	},
);

# TODO: make album-aware

foreach my $r ( 0..$#regexps ){
	$regexps[$r]->{source} = "stored:$r";
}

# initialize package globals, first exported ones

# map array to hash with index as value
sub re_fields {
	my $h = {};

	foreach( 0..$#_ ){
		next unless ( defined $_[$_] && $_[$_] );

		$h->{$_[$_]} = $_;
	}

	return $h;
}


=pod 

=head1 CONSTRUCTOR

=over 4

=item new()

create a new, empty suggestor object.

=cut
sub new {
	my $proto	= shift;
	if( !defined $proto ){
		croak "must be called as method";
	}

	my $class	= ref($proto) || $proto;
	my $self	= {
		sugs		=> [],
		cur		=> 0,
		};

	bless $self, $class;
	return $self;
}

=pod

=head1 METHODS

=item clear()

flush all suggestions to use this module for a different file.

=cut

sub clear {
	my $self	= shift;

	$self->{sugs} = [];
	$self->{cur} = 0;
}

=pod

=item add( $hashref )

=item add( key => val, ... )

add one suggestion manually. Use this only if you really know, what you're
doing. See section SUGGESTIONS for details.

Supplied data is cleaned - i.e. everything is lowercased, Roman numbers are
replaced by latin ones, common misspellings are fixed (when I'm sure this
doesn't break anything).

=cut

sub add {
	my $self = shift;
	my $dat;
	if( ref($_[0]) ){
		$dat = shift;
	} else {
		$dat = { @_ };
	}

	# TODO: move string-mangling to configurable module (as with
	# Naming/Default)
	foreach my $k ( qw( artist album title )){
		$dat->{$k} = lc $dat->{$k} | "";
		$dat->{$k} =~ s/\bi\b/I/g;
		$dat->{$k} =~ s/\bii\b/2/g;
		$dat->{$k} =~ s/\biii\b/3/g;
		$dat->{$k} =~ s/\biv\b/4/g;

		$dat->{$k} =~ s/´/'/g;
		$dat->{$k} =~ s/n t\b/n't/g;

		$dat->{$k} =~ s/\bst\b/St./g;
		$dat->{$k} =~ s/\bmr\b/Mr./g;
		$dat->{$k} =~ s/\bmrs\b/Mrs./g;
		$dat->{$k} =~ s/\bdr\b/Dr./g;

		# TODO: ue oe ae ... -> üöäÜÖÄß ?
	}
	$dat->{titlenum} = $dat->{titlenum} || 0;

	$self->add_asis( $dat );
}

=pod

=item add_asis( $hashref )

=item add_asis( key => $val, ... )

same as add(), but without any cleanups.

=cut
sub add_asis {
	my $self = shift;
	my $dat;
	if( ref($_[0]) ){
		$dat = shift;
	} else {
		$dat = { @_ };
	}

	foreach my $k ( qw( artist album title )){
		$dat->{$k} ||= "";
	}

	$dat->{titlenum} =~ /^\s*(\d+)/;
	$dat->{titlenum} = int( $1 || 0 );

	$dat->{source} ||= '';
	$dat->{year} ||= '';

	$self->rate( $dat );
	push @{$self->{sugs}}, $dat;
}

=pod

=item add_stor( $fname )

add suggestions based on the filename (including directory) using the
stored regular expressions. 

=cut
sub add_stor {
	my $self	= shift;
	my $path	= shift;
	
	return $self->add_relist( $path, \@regexps );
}

=pod

=item add_id3( $fname )

add suggestions based on ID3v1 and ID3v2 Tag of the file.

=cut
sub add_id3 {
	my $self = shift;
	my $file = shift;

	my $id3 = new MP3::Tag( $file );
	return unless $id3;
	$id3->get_tags;

	if( exists $id3->{ID3v2} ){
		my $t = $id3->{'ID3v2'};
		$self->add( 
		source		=> 'ID3v2',
		artist		=> scalar $t->artist,
		album		=> scalar $t->album,
		title		=> scalar $t->song,
		titlenum	=> scalar $t->track,
		year		=> scalar $t->get_frame('TYER'),
		);
	} elsif( exists $id3->{ID3v1} ){
		my $t = $id3->{'ID3v1'};
		$self->add( 
		source		=> 'ID3v1',
		artist		=> scalar $t->artist,
		album		=> scalar $t->album,
		title		=> scalar $t->song,
		titlenum	=> scalar $t->track,
		year		=> scalar $t->year,
		);
	}
}

=pod

=item add_regexp( $fname, $regexp, \@fields [, $source] )

add suggestion based on the filename using the specified regexp. The N'th
match $N ($1..$n) of the regexp is assigned the field $field[N]. 

Uhm - this explanation is probably not that clear, but better thann
nothing, eh?

$source is for reference only. Set it to what you like. It defaults to
"manual".

=cut
sub add_regexp {
	my $self	= shift;
	my $path	= shift;
	my $re		= shift;
	my $fields	= shift;
	my $source	= shift || "manual";	# only comment

	$path =~ s/\.(wav|mp3)$//i;
	$re .= "\$" unless $re =~ /\$$/;
	my @match = $path =~ m:$re:i;

	return unless @match;

	# return hashref on match
	$self->add(
		source	=> $source,
		artist	=> &sugitem( "artist", \@match, $fields ),
		album	=> &sugitem( "album", \@match, $fields ),
		titlenum => &sugitem( "titlenum", \@match, $fields ),
		title	=> &sugitem( "title", \@match, $fields ),
		);
}

=pod

=item add_relist( $fname, \@regexps )

add suggestions baased on the filename using a whole list of regexps.
Please take a look at the source to find out how to specify the list of
regexps.

=cut
sub add_relist {
	my $self	= shift;
	my $path	= shift;
	my $regexps	= shift;

	foreach my $re ( @$regexps ){
		$self->add_regexp( $path, 
			$re->{re}, 
			$re->{fields},
			$re->{source} );
	}
}



=pod

=item order()

order suggestions by score

=cut
sub order {
	my $self = shift;

	@{$self->{sugs}} = sort { 
		$b->{sug_quality} <=> $a->{sug_quality} 
	} @{$self->{sugs}};

	$self->{cur} = 0;
}

=pod

=head1 METHODS

=item rewind()

move internal pointer back to first suggestion.

=cut
sub rewind {
	my $self	=shift;

	$self->{cur} = 0;
}

=pod

=item get()

get next suggestion as hashref. See section SUGGESTIONS for details.

=cut
sub get {
	my $self	= shift;

	if( $self->{cur} > 0 ){
		# skip similar suggestions
		while( ! &sugcmp( $self->{sugs}[$self->{cur}-1],
			$self->{sugs}[$self->{cur}] ) ){
			$self->{cur}++;
		}
	}
	return $self->{sugs}[$self->{cur}++];
}

sub sugcmp {
	my $a = shift;
	my $b = shift;

	return 1 unless defined $a;
	return -1 unless defined $b;
	foreach my $k (qw( title artist )){
		my $r = $b->{$k} cmp $a->{$k};
		return $r if $r;
	}
	return 0;
}

=pod

=head1 INTERNAL

=item rate( $hashref )

set score

=cut
sub rate {
	my $self = shift;
	my $dat = shift;

	$dat->{sug_quality} = 0;

	$dat->{sug_quality} += $dat->{preference} if $dat->{preference};
	$dat->{sug_quality} +=10 if $dat->{titleid};

	# + jedes feld
	$dat->{sug_quality} +=3 if $dat->{titlenum};
	$dat->{sug_quality} +=1 if $dat->{title};
	$dat->{sug_quality} +=1 if $dat->{artist};
	#$dat->{sug_quality} +=2 if $dat->{album};

	# + äö`´' enthalten
	$dat->{sug_quality} +=1 if $dat->{title} =~ /[üöäÜÖÄ`´']/;

	# - 0-9- enthalten
	$dat->{sug_quality} -=1 if $dat->{title} =~ /[0-9-]/;
	#$dat->{sug_quality} -=2 if $dat->{album} =~ /--/;
}

=pod

=item sugitem( $field, \@match, \@fields )

return matched value for $field

=cut
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

	$val =~ s/[._\/]+/ /g;
	return $val;
}


1;
__END__

=head1 SUGGESTIONS

The Suggestor takes special care of these fields in Suggestions:

=item album

name of an album. Most (all?) titles belong to an album.

=item artist

name of artist who performed this title.

=item titlenum

number of this tiltle on the album.

=item title

name of the title.

=item source

only a comment for tracking the origin of this suggestion.

=item sug_quality

the "score" of this suggestio added by rate()

=back

When using add() or add_asis() you can pass in *everything* as suggestion.

=head1 AUTHOR

Rainer Clasen

=cut
