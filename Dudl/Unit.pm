#!/usr/bin/perl -w

# $Id: Unit.pm,v 1.8 2002-07-30 15:57:44 bj Exp $

package Dudl::Unit;

use strict;
use Carp qw{ :DEFAULT cluck };
use DBI;


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
my $cdinfo	= "/usr/local/bin/cdinfo";


sub new {
	my $proto	= shift;
	if( !defined $proto ){
		carp "must be called as method";
	}

	my $class	= ref($proto) || $proto;
	my $self	= {
		BASE		=> shift,
		data		=> {
			id		=> undef,
			collection	=> "",
			colnum		=> 0,
			volname		=> undef,
			size		=> undef,
			},
		};

	bless $self, $class;
	return $self;
}

sub db {
	my $self	=shift;

	return $self->{BASE}->db;
}

sub qval {
	my $self = shift;
	my $col = shift;

	return $self->db->qval( "stor_unit", $col, $self->{data}{$col} );
}

sub qdata {
	my $self = shift;

	return $self->db->qvals( "stor_unit", $self->{data} );
}

sub clear {
	my $self	= shift;

	$self->{data}{id}		= undef; 
	$self->{data}{collection}	= "";
	$self->{data}{colnum}		= 0;
	$self->{data}{volname}		= undef;
	$self->{data}{size}		= undef;
}


sub collection {
	my $self	= shift;
	my $collection	= shift;

	if( $collection ){
		$self->{data}{collection} = $collection;
	}
	return $self->{data}{collection};
}

sub colnum {
	my $self	= shift;
	my $colnum	= shift;

	if( $colnum ){
		$self->{data}{colnum} = $colnum;
	}
	return $self->{data}{colnum};
}

sub volname {
	my $self	= shift;
	my $volname	= shift;

	if( $volname ){
		$self->{data}{volname} = $volname;
	}
	return $self->{data}{volname};
}

sub size {
	my $self	= shift;
	my $size	= shift;

	if( $size ){
		$self->{data}{size} = $size;
	}
	return $self->{data}{size};
}

sub id {
	my $self	= shift;

	return $self->{data}{id};
}


sub path {
	my $self	= shift;
	my $path	= shift;

	if( $path ){
		my @sp = &splitpath( $path ) || return undef;

		$self->{data}{collection} = $sp[1];
		$self->{data}{colnum} = $sp[2];

		return 1;

	} else {
		return &mkpath( 
			$self->{BASE}->{CDPATH},
			$self->{data}{collection}, 
			$self->{data}{colnum} );
	}
}

# create a new file object attached to this unit
sub newfile {
	my $self	= shift;
	my $fname = shift;

	if( ! $self->id ){
		return undef;
	}

	require "Dudl::File";
	# TODO: pass fname
	return Dudl::File->new( $self->{BASE}, $self->id );
}


# get information from disc in specified device
# returns success status - ie true for success
sub acquire {
	my $self	= shift;
	my $device	= shift;

	# TODO: use something better than cdinfo
	my @out		= `$cdinfo $device`;
	my $found;

	foreach( @out ){
		if( /iso9660: (\d*) .* `(.*)\s*'/ ){
			$self->size($1 * 1024 * 1024);
			$self->volname($2);
			$found++;
		}
	}

	return $found;
}

# get unit data from database by ID
# returns ID on success
# otherwise undef
sub get_id {
	my $self	= shift;
	my $id		= shift;

	my $sel = $self->db->select( qq{
			collection,
			colnum,
			volname,
			size
		FROM stor_unit
		WHERE
			id = $id
		}) or return;

	$sel->rows == 1 or return;

	( $self->{data}{collection}, 
		$self->{data}{colnum}, 
		$self->{data}{volname},
		$self->{data}{size},
		) = $sel->fetchrow_array;
	$self->{data}{id} = $id;

	return $id;
}


# get unit data from database by symbolic information
# returns ID on success
# otherwise undef
sub get_collection {
	my $self	= shift;
	my $collection	= shift;
	my $colnum	= shift;

	if( defined $collection ){
		$self->collection( $collection );
	}
	
	if( defined $colnum ){
		$self->colnum( $colnum );
	}
	
	my $sel = $self->db->select( "
			id,
			volname,
			size
		FROM stor_unit
		WHERE 
			collection = ". $self->qval("collection"). " AND 
			colnum = ". $self->qval("colnum") )
			or return;

	$sel->rows == 1 or return;

	( $self->{data}{id}, 
		$self->{data}{volname}, 
		$self->{data}{size},
		) = $sel->fetchrow_array;

	return $self->id;
}


# save data
# returns ID on success
# otherwise undef
sub insert {
	my $self	= shift;

	# already exists
	if( $self->id ){
		return undef;
	}

	my $q = $self->qdata;
	$q->{id} = $self->db->nextval( 'stor_unit_id_seq');

	$self->db->insert( "stor_unit", $q )
		or return;

	$self->{data}{id} = $q->{id};
	return $q->{id};
}


# save
# returns ID on success
# otherwise undef
sub update {
	my $self	= shift;

	my $id		= $self->id;
	if( ! $id ){
		return undef;
	}

	my $q = $self->qdata;
	delete $q->{id};

	$self->db->update( "stor_unit", $q, "id = $id" )
		or return;

	return $id;
}


sub splitpath {
	my $path = shift;

	return $path =~ /([^\d\/]+)(\d+)$/;
	#return $path =~ /(\w+[^\d\/])(\d+)$/;
}


# generic helper
sub mkpath {
	my $cdpath	= shift;
	my $collection	= shift;
	my $colnum	= shift;

	my $fname = $cdpath ."/". 
		$collection ."/".
		$collection;

	if( -d ( $fname . sprintf( "%d", $colnum)) ){
		$fname .= sprintf( "%d", $colnum );

	} elsif( -d ( $fname . sprintf( "%02d", $colnum)) ){
		$fname .= sprintf( "%02d", $colnum );

	} elsif( -d ( $fname . sprintf( "%03d", $colnum)) ){
		$fname .= sprintf( "%03d", $colnum );

	} else {
		$fname .= sprintf( "%04d", $colnum );
	} 
	
	return $fname;
} 

1;

