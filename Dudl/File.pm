#!/usr/bin/perl -w

# $Id: File.pm,v 1.8 2002-04-28 11:55:02 bj Exp $

package Dudl::File;

use strict;
use Carp qw( :DEFAULT cluck );
use DBI;
use MP3::Info;
use MP3::Offset;
use MP3::Digest;
use Dudl::Base;

# TODO: move file analyzing to seperate file

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

my %table = (
	id		=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'base',
		},
	unit_id		=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'base',
		},
	dir		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'base',
		},
	fname		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'base',
		},
	fsize		=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'file',
		},
	fsum		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'sum',
		},
	dsum		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'sum',
		},
	id3v1		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'sum',
		},
	id3v2		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'sum',
		},
	riff		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'sum',
		},
	duration	=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'info',
		},
	channels	=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'info',
		},
	id_title	=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'tag',
		},
	id_artist	=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'tag',
		},
	id_album	=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'tag',
		},
	id_tracknum	=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'tag',
		},
	id_year		=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'tag',
		},
	id_comment	=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'tag',
		},
	id_genre	=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'tag',
		},
	freq		=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'info',
		},
	bits		=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'info',
		},
	mpeg_ver	=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'info',
		},
	mpeg_lay	=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'info',
		},
	mpeg_mode	=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'info',
		},
	mpeg_brate	=> {
		type	=> DBI::SQL_INTEGER,
		acq	=> 'info',
		},
	vbr		=> {
		type	=> DBI::SQL_CHAR,
		acq	=> 'info',
		},
	);

sub new {
	my $proto	= shift;
	if( !defined $proto ){
		carp "must be called as method";
	}

	my $class	= ref($proto) || $proto;
	my $self = {
		BASE		=> shift,
		unit_id		=> shift,	
		WANTUPD		=> [],	# arrayref
		WANTGET		=> {},	# hashref
		};
	&clean( $self );

	bless $self, $class;
	$self->want( shift );

	return $self;
}

sub acquires {
	my $self	= shift;
	my $acq		= shift;

	if( ! ref($self) ){
		$acq = $self;
	}

	my @cols;
	foreach(keys %table){
		if( $table{$_}{acq} eq $acq ){
			push @cols, $_;
		}
	}

	return @cols;
}

sub want {
	my $self	= shift;
	my $want 	= shift;

	my @realwant;

	if( ! defined($want) || ! (ref($want) eq "ARRAY") || ! @$want ){
		@realwant = keys %table;
	} 

	@{$self->{WANTUPD}} = ();
	%{$self->{WANTGET}} = ();
	foreach(keys %table){
		$self->{WANTGET}->{$table{$_}{acq}} = 0;
	}

	# duplicates don't matter because mksql puts them in a hash
	foreach( @$want ){
		next unless exists $table{$_};
		next if $_ eq "unit_id";
		next if $_ eq "id";

		push @{$self->{WANTUPD}}, $_;
		$self->{WANTGET}->{$table{$_}{acq}} = 1;
	}
}


sub db {
	my $self	= shift;

	return $self->{BASE}->db;
}

sub clean {
	my $self	= shift;

	foreach( keys %table ){
		if( $_ ne "unit_id" ){
			$self->{$_} = undef;
		}
	}
}

sub id {
	my $self	= shift;

	return $self->{id};
}


sub path {
	my $self	= shift;
	my $path	= shift;

	if( defined $path ){
		$path =~ /((.*)\/)?([^\/]+)$/;
		$self->{dir} = ( defined $2 && length $2 ) ? $2 : '';
		$self->{fname} = $3;
	}

	return (length($self->{dir}) ? 
		($self->{dir}."/") : 
		"" ). $self->{fname};
}

# fill in wanted information from specified file
# returns success status - ie true for success
sub acquire {
	my $self	= shift;
	my $top		= shift;
	my $path	= shift;


	$self->path( $path );

	if( scalar(keys %{$self->{WANTGET}}) <= 1 ){
		# nothing else wanted - abort
		return 1;
	}

	$path = $top ."/". $path;
	if( ! -f $path ){
		warn "does not exist";
		return 0;
	}

	if( $self->{WANTGET}->{file} ){
		$self->{fsize} = (stat(_))[7];
	}

	
	if( $self->{WANTGET}->{info} ){
		my $info = get_mp3info( $path );
		if( $info ){
			$self->{duration}	= (int($$info{"MM"} / 60) .":". 
					($$info{"MM"} % 60) .":".  
					$$info{"SS"});
			$self->{channels}	= ($$info{"STEREO"} ? 2 : 1);
			$self->{freq}		= 1000 * $$info{"FREQUENCY"};
			$self->{bits}		= 16;
			$self->{mpeg_ver}	= $$info{"VERSION"};
			$self->{mpeg_lay}	= $$info{"LAYER"};
			$self->{mpeg_mode}	= $$info{"MODE"};
			$self->{mpeg_brate}	= 1000 * $$info{"BITRATE"};
			$self->{vbr}		= $$info{"VBR"} ? 't' : 'f';
		} else {
			warn "no info";
		}
	}

	if( $self->{WANTGET}->{tag} ){
		my $tag = get_mp3tag( $path );
		if( ! $tag ){
			$tag = {};
		}

		$self->{id_title}	= $$tag{"TITLE"};
		$self->{id_artist}	= $$tag{"ARTIST"};
		$self->{id_album}	= $$tag{"ALBUM"};
		$self->{id_tracknum}	= $$tag{"TRACKNUM"};
		if( ! $self->{id_tracknum} ){
			$self->{id_tracknum} = 0;
		}
		if( $$tag{"YEAR"} && $$tag{"YEAR"} =~ /^\d+$/ ){
			$self->{id_year}	= $$tag{"YEAR"};
		}
		if( ! $self->{id_year} ){
			$self->{id_year} = 0;
		}
		$self->{id_comment}	= $$tag{"COMMENT"};
		$self->{id_genre}	= $$tag{"GENRE"};
	}

	if( $self->{WANTGET}->{sum} ){
		my $os = new MP3::Offset( $path );
		if( ! $os ){
			warn "no sum";
			return 0;
		}
		my $dg = new MP3::Digest( $os );

		$self->{fsum}	= $dg->filedigest;
		$self->{dsum}	= $dg->datadigest;
		$self->{id3v1}	= $os->id3v1 ? 't' : 'f';
		$self->{id3v2}	= $os->id3v2 ? 't' : 'f';
		$self->{riff}	= $os->riff ? 't' : 'f';
	}

	return 1;
}


# get data for one file from database
sub get {
	my $self	= shift;
	my $where	= shift;

	my @cols = keys %table;
	my $query = 
		"SELECT ".
			join(', ', @cols) ." ".
		"FROM stor_file ".
		"WHERE $where";

	my $prep = $self->db->prepare( $query );
	if( ! $prep ) {
		carp $self->db->errstr ."\nquery: $query\n";
		return undef;
	}
	
	my $ex = $prep->execute;
	if( ! $ex ){
		carp $prep->errstr ."\nquery: $query\n";
		return undef;
	}

	if( $prep->rows > 1 ){
		croak "found more than a single result";
	}

	if( $prep->rows != 1 ){
		return undef;
	}

	foreach(0..$#cols){
		$prep->bind_col( $_ +1, \$self->{$cols[$_]} );
	}

	$prep->fetch;
	$prep->finish;

	return $self->id;
}


sub get_id {
	my $self	= shift;
	my $id		= shift;

	return $self->get(
		"id = $id"
		);
}

# find one file by symbolic information
# returns ID on success
sub get_path {
	my $self	= shift;
	my $path	= shift;
	my $unitid	= shift;	# optional

	if( defined $path ){
		$self->path( $path );
	}

	if( defined $unitid ){
		$self->{unit_id} = $unitid;
	}

	my $sql = $self->mksql( [qw{ unit_id dir fname }] );

	my $q = "unit_id = ". $sql->{unitid} ." AND ".
		"fname = ".  $sql->{fname} ." AND ".
		"dir = ". $sql->{dir};

	return $self->get( $q );
}


# return a hashref with sql table names as key and apropriately quoted
# values
sub mksql {
	my $self	= shift;
	my $want	= shift;

	my $f;
	my %sql = ();
	foreach $f ( @$want ){
		next unless exists $table{$f};

		$sql{$f} = $self->db->quote($self->{$f}, 
			$table{$f}{type});
	}

	return \%sql;
}


# try to save data as new entitiy
# returns ID on success
sub insert {
	my $self	= shift;

	if( $self->id ){
		return undef;
	}


	( $self->{id} ) = $self->db->selectrow_array(
		"SELECT nextval('stor_file_id_seq')" );
	if( ! $self->id ){
		return undef;
	}

	my $sql = $self->mksql( [ "id", "unit_id", @{$self->{WANTUPD}} ] );
	my @cols = keys %$sql;
	my @vals;
	foreach(@cols){
		push @vals, $$sql{$_};
	}
	my $query =
		"INSERT INTO stor_file (".
			join(", ", @cols).
		")
		VALUES (".
			join(", ", @vals).
		")";

	my $res = $self->db->do( $query );
	if( $res != 1 ){
		$self->{id} = undef;
		croak $self->db->errstr ."\nquery: $query\n";
		return undef;
	}

	return $self->id;
}


# update stor_file with information from filename
# returns ID on success
sub update {
	my $self	= shift;

	if( ! $self->id ){
		return undef;
	}

	my $sql = $self->mksql( $self->{WANTUPD} );
	my $query;
	foreach( keys %$sql ){
		if( $query ){
			$query .= ", ";
		}
		$query .= $_ ."=". $$sql{$_};
	}
 	$query = "UPDATE stor_file SET ". $query ." ".
		"WHERE id = ". $self->id;

	my $res = $self->db->do( $query );
	if( $res != 1 ){
		croak $self->db->errstr ."\nquery: $query\n";
		return undef;
	}

	return $self->id;

}

1;

