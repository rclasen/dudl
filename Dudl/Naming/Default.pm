#!/usr/bin/perl -w

# $Id: Default.pm,v 1.2 2008-12-27 23:14:27 bj Exp $

package Dudl::Naming::Default;

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

our $truncno = 0;

# non-exported package globals go here

# initialize package globals, first exported ones


=pod

=head1 NAME

Dudl::Naming::Default - Naming policy for mp3 files

=head1 SYNOPSIS

 use Dudl::Naming::Default;

 %album = (
 	type	=> "album",
	name	=> "the Wall",
	artist	=> "Ping Floyd",
	);
 %title = (
	num	= 1,
	artist	= "Pink Floyd",
	name	= "another brick in the wall",
 	);

 $nam = new Dudl::Naming::Default;
 $dirname = $nam->dir( \%album );
 $fname = $nam->fname( \%album, \%title );

=head1 DESCRIPTION

Use this module to generate filenames for MP3s.

By chance the hashes taken by dir() and fname() are compatible with those
returned by I<Dudl::Job::Rename>.

=head1 CONSTRUCTOR

=over 4

=item new()

returns a new object instance. You'll probably prefer to call
I<Dudl::Config::naming> to get the naming object, the user wants.

=cut
sub new {
	my $proto	= shift;
	if( !defined $proto ){
		croak "must be called as method";
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

=pod

=head1 METHODS

=item dir( $albumhash )

return directory name to place titles in.

=cut
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
		croak "unknown album type";
	}

	return $self->fnormalize( $name );
}

=pod

=item fname( $albumhash, $titlehash )

return basename of file.

=cut
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
		croak "unknown album type";
	}

	return $self->fnormalize( $name .".mp3" );
}

=pod

=item album_types()

return list of all allowed values for $albumref->{type}. Used by
I<Dudl::Job::Rename> for input verification.

=cut
sub album_types {
	my $self = shift;

	return qw( album sampler );
}


=pod

=item album_type_valid( $type )

returns true when the passed type is valid for $albumref->{type}. Used by
I<Dudl::Job::Rename> for input verification.

=cut
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

=pod

=item album_valid( $albumref )

check all supplied data of an Album. Returns true on success. Used by
I<Dudl::Job::Rename::chec_album> for input verification.

=cut
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

=pod

=item album_valid( $albumref )

check all supplied data of a title. Returns true on success. Used by
I<Dudl::Job::Rename::check_title>

=cut
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


=pod

=item fnormalize( $fname ) 

Builds a cleaned up filename from the input. All disallowed chars are
replaced by a single dot '.'. Multiple dots are merged together.  Call it
for each path component as it strips slashes, too.

=cut
sub fnormalize {
	my $self = shift;
	my $fname = shift;

	$fname =~ s/ä/ae/g;
	$fname =~ s/ö/oe/g;
	$fname =~ s/ü/ue/g;
	$fname =~ s/Ä/Ae/g;
	$fname =~ s/Ö/Oe/g;
	$fname =~ s/Ü/Ue/g;
	$fname =~ s/ß/ss/g;
	$fname =~ s/[^a-zA-Z0-9_\$()=+-]+/./g;
	$fname =~ s/^\.+//; # leading/trailing dots
	$fname =~ s/\.+$//; # leading/trailing dots

	if( length( $fname ) > 64 ){
		my $nfn;
		# TODO: avoid hardcoded file extension
		if( $fname =~ /\.(mp3|wav)$/ ){
			$nfn = sprintf( "%.57s_%02x.$1", $fname, ++$truncno );
		} else {
			$nfn = sprintf( "%.61s_%02x", $fname, ++$truncno );
		}
		#print "WARINING: \"$fname\" exceeds 64 chars, truncated to \"$nfn\"\n";
		$fname = $nfn;
	}

	return $fname;
}


1;
__END__

=head1 AUTHOR

Rainer Clasen

=head1 SEE ALSO

L<Dudl::Job::Rename>, L<Dudl::Config>, L<dudl_rename(1)>.

=cut
