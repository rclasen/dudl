#!/usr/bin/perl -w

package Dudl::Suggester;

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
		sugs		=> [],
		cur		=> 0,
		};

	bless $self, $class;
	return $self->get_regexps;
}

# move internal pointer back to start
sub rewind {
	my $self	=shift;

	$self->{cur} = 0;
}

# get next suggestion
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

sub clear {
	my $self	= shift;

	$self->{sugs} = [];
	$self->{cur} = 0;
}

sub rate {
	my $self = shift;
	my $dat = shift;

	$dat->{sug_quality} = 0;

	# + jedes feld
	$dat->{sug_quality} +=3 if $dat->{titlenum};
	$dat->{sug_quality} +=1 if $dat->{title};
	$dat->{sug_quality} +=1 if $dat->{artist};
	#$dat->{sug_quality} +=2 if $dat->{album};

	# + הצ`´' enthalten
	$dat->{sug_quality} +=1 if $dat->{title} =~ /[üצהÜײִ`´']/;

	# - 0-9- enthalten
	$dat->{sug_quality} -=1 if $dat->{title} =~ /[0-9-]/;
	#$dat->{sug_quality} -=2 if $dat->{album} =~ /--/;
}

sub order {
	my $self = shift;

	@{$self->{sugs}} = sort { 
		$b->{sug_quality} <=> $a->{sug_quality} 
	} @{$self->{sugs}};

	$self->{cur} = 0;
}

# add a suggestion
sub add {
	my $self = shift;
	my $dat;
	if( ref($_[0]) ){
		$dat = shift;
	} else {
		$dat = { @_ };
	}

	foreach my $k ( qw( artist album title )){
		$dat->{$k} = lc $dat->{$k} | "";
		$dat->{$k} =~ s/\bi\b/I/g;
		$dat->{$k} =~ s/\bii\b/2/g;
		$dat->{$k} =~ s/\biii\b/3/g;
		$dat->{$k} =~ s/\biv\b/4/g;
		$dat->{$k} =~ s/´/'/g;
		$dat->{$k} =~ s/n t\b/n't/g;
	}
	$dat->{titlenum} = $dat->{titlenum} || 0;
	$dat->{titlenum} =~ int( $dat->{titlenum} );
	$dat->{source} = $dat->{source} || '';

	$self->rate( $dat );
	push @{$self->{sugs}}, $dat;
}

sub add_regexp {
	my $self	= shift;
	my $path	= shift;
	my $re		= shift;
	my $fields	= shift;
	my $source	= shift;	# only comment

	$re .= "\\.(?:mp3|wav)\$";
	my @match = $path =~ m:$re:i;

	# return hashref on match
	$self->add(
		artist	=> &sugitem( "artist", \@match, $fields ),
		album	=> &sugitem( "album", \@match, $fields ),
		titlenum => &sugitem( "titlenum", \@match, $fields ),
		title	=> &sugitem( "title", \@match, $fields ),
		source	=> $source,
		);
}

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


# return hashref with next suggestion
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

sub add_stor {
	my $self	= shift;
	my $path	= shift;
	
	return $self->add_relist( $path, $self->{regexps} );
}

# load regexps from database
sub get_regexps {
	my $self	= shift;

	# TODO: move regexps from database to code
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
			source	=> "stor_export:$id",
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



1;
