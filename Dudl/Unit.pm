#!/usr/bin/perl -w

# $Id: Unit.pm,v 1.5 2001-12-13 11:41:48 bj Exp $

package Dudl::Unit;

use strict;
use Carp qw{ :DEFAULT cluck };
use DBI;
use Dudl::Base;
use Dudl::File;


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
		id		=> undef,
		collection	=> "",
		colnum		=> 0,
		volname		=> undef,
		size		=> undef,
		};

	bless $self, $class;
	return $self;
}

sub db {
	my $self	=shift;

	return $self->{BASE}->db;
}

sub clear {
	my $self	= shift;

	$self->{id}		= undef; 
	$self->{collection}	= "";
	$self->{colnum}		= 0;
	$self->{volname}	= undef;
	$self->{size}		= undef;
};


sub collection {
	my $self	= shift;
	my $collection	= shift;

	if( $collection ){
		$self->{collection} = $collection;
	}
	return $self->{collection};
}

sub colnum {
	my $self	= shift;
	my $colnum	= shift;

	if( $colnum ){
		$self->{colnum} = $colnum;
	}
	return $self->{colnum};
}

sub volname {
	my $self	= shift;
	my $volname	= shift;

	if( $volname ){
		$self->{volname} = $volname;
	}
	return $self->{volname};
}

sub size {
	my $self	= shift;
	my $size	= shift;

	if( $size ){
		$self->{size} = $size;
	}
	return $self->{size};
}

sub id {
	my $self	= shift;

	return $self->{id};
}


sub path {
	my $self	= shift;
	my $path	= shift;

	if( $path ){
		my @sp = &splitpath( $path ) || return undef;

		$self->{collection} = $sp[1];
		$self->{colnum} = $sp[2];

		return 1;

	} else {
		return &mkpath( 
			$self->{BASE}->{CDPATH},
			$self->{collection}, 
			$self->{colnum} );
	}
}

# create a new file object attached to this unit
sub newfile {
	my $self	= shift;

	if( ! $self->id ){
		return undef;
	}

	return Dudl::File->new( $self->{BASE}, $self->id );
}


# get information from disc in specified device
# returns success status - ie true for success
sub acquire {
	my $self	= shift;
	my $device	= shift;

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

	my $query = qq{
		SELECT 
			trim(collection),
			colnum,
			volname,
			size
		FROM stor_unit
		WHERE
			id = $id
		};
	my $prep = $self->db->prepare( $query );
	if( ! $prep ) {
		cluck $self->db->errstr ."\nquery: $query\n";
		return undef;
	}
	
	my $ex = $prep->execute;
	if( ! $ex ){
		cluck $prep->errstr ."\nquery: $query\n";
		return undef;
	}

	if( $prep->rows > 1 ){
		$prep->finish;
		confess "more than one unit found ".
			"- this should never happen.\n".
			"Query: ". $query;
		return undef;

	} elsif( $prep->rows == 0 ){
		$prep->finish;
		return undef;

	}

	( $self->{collection}, 
		$self->{colnum}, 
		$self->{volname},
		$self->{size},
		) = $prep->fetchrow_array;
	$prep->finish;
	$self->{id} = $id;

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
	
	my $query = 
		"SELECT 
			id,
			volname,
			size
		FROM stor_unit
		WHERE ".
			"trim(collection) = ". 
				$self->db->quote($self->collection, 
					DBI::SQL_CHAR).
				" AND ".
			"colnum = ". 
				$self->db->quote($self->colnum, 
					DBI::SQL_SMALLINT)
		;
	my $prep = $self->db->prepare( $query );
	if( ! $prep ) {
		cluck $self->db->errstr ."\nquery: $query\n";
		return undef;
	}
	
	my $ex = $prep->execute;
	if( ! $ex ){
		cluck $prep->errstr ."\nquery: $query\n";
		return undef;
	}

	if( $prep->rows > 1 ){
		$prep->finish;
		confess "more than one unit found ".
			"- this should never happen.\n".
			"Query: ". $query;
		return undef;

	} elsif( $prep->rows == 0 ){
		$prep->finish;
		return undef;

	}

	( $self->{id}, $self->{volname}, $self->{size} ) = 
		$prep->fetchrow_array;
	$prep->finish;

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

	my $collection	= $self->db->quote($self->collection, DBI::SQL_CHAR);
	my $colnum	= $self->db->quote($self->colnum, DBI::SQL_SMALLINT);
	my $volname	= $self->db->quote($self->volname, DBI::SQL_CHAR);
	my $size	= $self->db->quote($self->size, DBI::SQL_INTEGER);

	my( $id ) = $self->db->selectrow_array( 
		"SELECT nextval('stor_unit_id_seq')" );
	if( ! $id ){
		cluck $self->db->errstr;
		return undef;
	}

	my $query = qq{
		INSERT INTO stor_unit (
			id,
			collection, 
			colnum, 
			volname,
			size
			) 
		VALUES (
			$id,
			$collection,
			$colnum,
			$volname )
		};
	my $res = $self->db->do( $query );
	if( $res != 1 ){
		cluck $self->db->errstr ."\nquery: $query\n";
		return undef;
	}

	$self->{id} = $id;
	return $id;
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

	my $collection	= $self->db->quote($self->collection, DBI::SQL_CHAR);
	my $colnum	= $self->db->quote($self->colnum, DBI::SQL_SMALLINT);
	my $volname	= $self->db->quote($self->volname, DBI::SQL_CHAR);
	my $size	= $self->db->quote($self->size, DBI::SQL_INTEGER);

	my $query = qq{
		UPDATE stor_unit SET
			collection = $collection,
			colnum = $colnum, 
			volname = $volname,
			size = $size
		WHERE id = $id
		};
	my $res = $self->db->do( $query );
	if( $res != 1 ){
		cluck $self->db->errstr ."\nquery: $query\n";
		return undef;
	}

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

