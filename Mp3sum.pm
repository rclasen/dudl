#!/usr/bin/perl -w

package Mp3sum;

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
		FILEDIGEST	=> Digest::MD5->new,
		DATADIGEST	=> Digest::MD5->new,
		RIFF		=> 0,
		ID3V1		=> 0,
		ID3V2		=> 0,
		};

	bless $self, $class;
	return $self;
}

sub filedigest {
	my $self	= shift;
	return $self->{FILEDIGEST}->hexdigest;
}

sub datadigest {
	my $self	= shift;
	return $self->{DATADIGEST}->hexdigest;
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





sub head_id3v2 {
	my $len		= shift;
	my $skip	= shift;
	my $rbuf	= shift;

	$len -= $skip;
	# start header is 10 byte long ...
	if( $len < 10 ){
		# not enough to detect
		return -1;
	}

	# is this an ID3v2 Tag?
	if (substr ($$rbuf,$skip,3) eq "ID3") {
		# get the tag size
		my $size=0;
		foreach ( unpack("x6C4", substr($$rbuf, $skip)) ) {
			$size = ($size << 7) + $_;
		}
		return $size + 10;
	}

	return 0;
}

sub head_riff {
	my $len		= shift;
	my $skip	= shift;
	my $rbuf	= shift;

	$len -= $skip;
	if( $len < 12 ){
		return -1;
	}

	my $headlen = 12;
	my $buf;
	
	$buf = substr( $$rbuf, $skip, 12 );
	my( $head, $hlen, $subhead ) = unpack( "A4lA4", $buf );
	if( $head ne "RIFF" ){
		return 0;
	}

	$hlen = 0;
	while( $head ne "data" ){
		$headlen += $hlen;

		if( $len < ($skip + $headlen) ){
			return -1;
		}

		$buf = substr( $$rbuf, $skip + $headlen, 8 );
		$headlen += 8;

		($head, $hlen ) = unpack( "A4l", $buf );
	}

	return $headlen;
}

sub tail_id3v1 {
	my $len		= shift;
	my $skip	= shift;
	my $rbuf	= shift;

	if( $len - $skip  < 128 ){
		return -1;

	} 
	
	if( substr( $$rbuf, -$skip -128, 3 ) eq "TAG" ){
		return 128

	}

	return 0;
}


sub scan {
	my $self	= shift;
	my $file	= shift;

	$self->{ID3V1}	= 0;
	$self->{ID3V2}	= 0;
	$self->{RIFF}	= 0;

	my $fsum = $self->{FILEDIGEST};
	my $dsum = $self->{DATADIGEST};
	$fsum->reset;
	$dsum->reset;

	my $chunk	= 4096;	# try to read that much
	my $bufhist	= 3;	# how many buffers to keep

	my $buf;		# buffer to read into
	my @old;		# 2 last buffers
	my $got;		# read got that many bytes

	my $skip	= 0;	# still need to skip that many

	my $total	= 0;	# totaly processed that much data




	unless( open( F, $file ) ){
		cluck "cannot open $file: $!";
		return 0;
	}

	# skip junk at beginning ...
	do {
		$got = read( F, $buf, $chunk );
		$total += $got;

		$fsum->add( $buf );

		push @old, $buf;
		if( $#old >= $bufhist ){
			shift @old;
		}

		
		if( $got == 0 ){
			# EOF
			$skip = 0;

		} elsif( $skip > $got ){
			# there is more to skip
			$skip -= $got;

		} else {
			if( $skip > 0 ){
				# enough data for skipping
				$buf = substr($buf, $skip);
				$got -= $skip;
				$skip = 0;

			} elsif( $skip < 0 ){
				# prepend kept data from previos buffer
				$buf = substr( $old[$#old], 
					length($old[$#old]) + $skip ) . $buf;
				$got = length($buf);
				$skip = 0;
			}

			my $r;
			my $keep	= 0;

			# skip ID3v2
			if( 0 > ( $r = &head_id3v2( $got, $skip, \$buf ))){
				$keep++;
			} else {
				$skip += $r;
				$self->{ID3V2}	+= $r;
			}
			
			# skip RIFF
			if( 0 > ( $r = &head_riff( $got, $skip, \$buf ))){
				$keep++;
			} else {
				$skip += $r;
				$self->{RIFF}	+= $r;
			}


			# no header found and too few data to find one
			if( ! $skip && $keep ){
				$skip = - $got;
			}
		}

	} while( $skip != 0 );

	@old = ();
	$dsum->add( $buf );




	# read main data ...
	while( $got && ($got = read( F, $buf, $chunk )) ){
		$total += $got;

		$fsum->add( $buf );

		push @old, $buf;
		if( $#old >= $bufhist  ){
			$dsum->add( shift @old );
		}
	}
	close F;



	# skip junk at end
	$buf = join('', @old );
	$got = length($buf);
	$skip = 0;

	my $r;

	# skip ID3v1
	if( 0 > ( $r = &tail_id3v1( $got, $skip, \$buf ))){
		cluck "not enough data - increase \$bufhist"
	} else {
		$skip += $r;
		$self->{ID3V1}	+= $r;
	}

	if( $skip ){
		$buf = substr( $buf, 0, - $skip );
	}
	$dsum->add( $buf );

	return 1;
}



1;

