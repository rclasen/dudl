#!/usr/bin/perl -w

# $Id: Naming.pm,v 1.2 2002-04-12 17:53:52 bj Exp $

package Dudl::Naming;

use strict;
use Carp qw{ :DEFAULT cluck };


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
		};

	bless $self, $class;

	return $self;
}

sub bother {
	my $self = shift;
	
	print STDERR @_, "\n";
}


# return directory to place file in
sub dir {
	my $self = shift;
	my $alb = shift;

	my $name;
	if( $alb->{type} eq "sampler" ){
		$name = $alb->{name};

	} elsif( $alb->{type} eq "album" ){
		$name = sprintf( "%s.--.%s", 
			$alb->{artist}, 
			$alb->{name});

	} else {
		die "unknown album type";
	}

	return $self->fnormalize( $name );
}

# return basename of file
sub fname {
	my $self = shift;
	my $alb = shift;
	my $tit = shift;

	my $name;
	if( $alb->{type} eq "sampler" ) {
		# - a sampler, name it 
		# <album>/<nr>_<group>.--.<title> or 
		# <album>/<nr>_<title>
		if( $tit->{artist}){
			$name = sprintf( "%02d_%s.--.%s", 
				$tit->{num}, 
				$tit->{artist}, 
				$tit->{name} );
		} else {
			$name = sprintf( "%02d_%s", 
				$tit->{num}, 
				$tit->{name} );
		}

	} elsif( $alb->{type} eq "album" ){
		# - no sampler, name it 
		# <group>.--.<album>/<group>.--.<nr>_<title>
		$name = sprintf( "%s.--.%02d_%s", 
				$tit->{artist}, 
				$tit->{num}, 
				$tit->{name} );

	} else {
		die "unknown album type";
	}

	return $self->fnormalize( $name .".mp3" );
}

# normalize filename
# call this for each path component since it strips slashes
sub fnormalize {
	my $self = shift;
	my $fname = shift;

        $fname =~ s/[^a-zäöüßA-ZÖÄÜ0-9_\$()=+-]+/./g;
	$fname =~ s/^\.*(.*)\.*$/$1/;

	if( length( $fname ) > 64 ){
		print "WARINING: \"$fname\" exceeds 64 chars\n";
	}

	return $fname;
}

# return a kist of album types
sub album_types {
	my $self = shift;

	return qw( album sampler );
}

# return boolaen, wether this is a valid album type
sub album_type_valid {
	my $self = shift;
	my $type = shift;

	if( $type eq "sampler" ){
		return 1;

	} elsif( $type eq "album" ){
		return 1;

	}

	return 0;
}

# return boolean, wether all entries for this album are valid
# used by Dudl::Job::Rename::check_album
sub album_valid {
	my $self = shift;
	my $alb = shift;

	my $type = $alb->{type};
	my $err = 0;

	if( $type eq "sampler" ){
		if( ! $alb->{artist} ){
			$alb->{artist} = "VARIOUS";
		}

		if( ! ($alb->{artist} =~ /^VARIOUS$/i) ){
			$self->bother( "album_artist for sampler is ", 
				"not VARIOUS" );
			$err++;
		}

	} elsif( $type eq "album" ){
		if( $alb->{artist} =~ /^VARIOUS$/i ){
			$self->bother( "album_artist invalid");
			$err++;
		}

	} else {
		$self->bother( "unknown album type" );
		$err++;
	}


	return !$err;
}

# return boolean, wether all entries for this title are valid
# used by Dudl::Job::Rename::check_title
sub title_valid {
	my $self = shift;
	my $alb = shift;
	my $tit = shift;

	my $type = $alb->{type};
	if( $type eq "album" ){
		if( ! $tit->{artist} ){
			$tit->{artist} = $alb->{artist};
		}
	}

	return 1;
}



1;
