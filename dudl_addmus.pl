#!/usr/bin/perl -w

# add/modify music entries from template file

# template (similar to mp3ren)
#
# album_artist		artist for this album (optional)
# album_name		Album
#
#
# file_id		database ID of file
# track_id		database ID (only when found)
#
# track_num		Track number
# track_name		Track name
# track_artist		Artist
# track_genres		genres (temporary till rating works)
# 

use strict;
use Dudl;

my $dudl = new Dudl;

my %nonempty = (
	album_name	=> 1,
	file_id		=> 1,
	title_num	=> 1,
	title_artist	=> 1,
	title_name	=> 1,
	);

my %album = (
	artist	=> undef,
	name	=> undef,
	);
my %title = (
	id	=> undef,
	num	=> undef,
	artist	=> undef,
	name	=> undef,
	genres	=> undef,
	);
my $file_id;
my $album_id;

my $state = "album";
LINE: while(<>){
	chomp;
	s/^\s+//;
	s/^#.*//;
	s/\s+$//;
	next if /^\s*$/;

	my( $key, $group, $gkey, $val ) = /^((\S+)_(\S+))\s*(.*)/;

	#print STDERR "$ARGV($.): $key=$val\n";
	if( $nonempty{$key} && ! $val ){
		die "$ARGV($.): empty value for key $key";
	}

	# continue title entry
	if( ($group eq "title") && exists($title{$gkey}) ){

		if( ! $file_id ){
			die "$ARGV($.): title entry without file_id";
		}


		if( $title{$gkey} ){
			die "$ARGV($.): duplicate entry for $key";
		}

		$title{$gkey} = $val;
		next LINE;
	}

	# start a new file/title
	if( $key eq "file_id" ){
		if( ! $album_id ){
			# either there was nothing or an album entry - try to
			# save album
			$album_id = &save_album( $dudl, \%album );
		}

		if( $file_id  ){
			# previos entry was a file - save it
			&save_title( $dudl, $album_id, $file_id, \%title );
		}

		$file_id = $val;
		next LINE;
	}

	# continue album entry
	if( ($group eq "album") && exists($album{$gkey}) ){

		if( $file_id ){
			# previos entry was for a file - save it
			&save_title( $dudl, $album_id, $file_id, \%title );

			$file_id = undef;
			$album_id = undef;
	
		} elsif( $album_id ){
			die "$ARGV($.): another album? the last one was empty!";
		}

		if( $album{$gkey} ){
			die "$ARGV($.): duplicate entry for $key";
		}

		$album{$gkey} = $val;
		next LINE;
	}

	die "$ARGV($.): invalid key";
}

if( $file_id  ){
	# previos entry was a file - save it
	&save_title( $dudl, $album_id, $file_id, \%title );
}

$dudl->commit();

# cleanup
$dudl->done();

# search for artist
# if found, return id
# otherwise create new and return id
sub get_artist {
	my $dudl	= shift;
	my $db		= $dudl->db;
	my $artist	= $db->quote(shift || 'UNKNOWN', DBI::SQL_CHAR);

	my $query =
		"SELECT ".
			"id ".
		"FROM mus_artist ".
		"WHERE ".
			"nname = $artist ".
		"ORDER BY ".
			"id DESC";
	my $sth = $db->prepare( $query );
	if( ! $sth ){
		die $db->errstr ."\nquery: $query\n";
	}

	my $res = $sth->execute;
	if( ! $res ){
		die $sth->errstr ."\nquery: $query\n";
	}

	my $aid;
	$sth->bind_columns( \$aid );
	while( $sth->fetch ){
	}
	$sth->finish;

	if( defined $aid ){
		#print "found artist: $aid\n";
		return $aid;
	}


	# first get a new id
	$query = "SELECT nextval('mus_artist_id_seq')";
	( $aid ) = $db->selectrow_array( $query );
	if( ! $aid ){
		die $sth->errstr ."\nquery: $query\n";
	}

	# add new artist with this id
	$query =
		"INSERT INTO mus_artist ( ".
			"id, ".
			"nname ".
		") VALUES ( ".
			"$aid, ".
			"$artist ".
		") ";
	$res = $db->do( $query );
	if( $res != 1 ){
		die $db->errstr ."\nquery: $query\n";
	}

	print STDERR "added new artist entry: $aid\n";
	return $aid;
}


# save album and return ID
sub save_album {
	my $dudl	= shift;
	my $hr		= shift;

	my $artist = &get_artist( $dudl, $hr->{artist} );
	my $db = $dudl->db;

	# first get a new id
	my $query = "SELECT nextval('mus_album_id_seq')";
	my ( $aid ) = $db->selectrow_array( $query );
	if( ! $aid ){
		die $db->errstr ."\nquery: $query\n";
	}

	# add new artist with this id
	my $album = $db->quote( $hr->{name}, DBI::SQL_CHAR );
	$query =
		"INSERT INTO mus_album ( ".
			"id, ".
			"album, ".
			"artist_id ".
		") VALUES ( ".
			"$aid, ".
			"$album, ".
			"$artist ".
		") ";
	my $res = $db->do( $query );
	if( $res != 1 ){
		die $db->errstr ."\nquery: $query\n";
	}

	foreach( keys %$hr ){
		$hr->{$_} = undef;
	}

	return $aid;
}

# save title
# update stor_file
sub save_title {
	my $dudl	= shift;
	my $albid	= shift;
	my $filid	= shift;
	my $hr		= shift;

	my $aid = &get_artist( $dudl, $hr->{artist} );
	my $db = $dudl->db;

	# first get a new id
	my $query = "SELECT nextval('mus_title_id_seq')";
	my ( $tid ) = $db->selectrow_array($query );
	if( ! $tid ){
		die $db->errstr ."\nquery: $query\n";
	}

	# add new title with this id
	my $nr = $db->quote( $hr->{num}, DBI::SQL_INTEGER );
	my $title = $db->quote( $hr->{name}, DBI::SQL_CHAR );
	my $genres = $db->quote( $hr->{genres}, DBI::SQL_CHAR );
	$query =
		"INSERT INTO mus_title ( ".
			"id, ".
			"album_id, ".
			"nr, ".
			"title, ".
			"artist_id, ".
			"genres ".
		") VALUES ( ".
			"$tid, ".
			"$albid, ".
			"$nr, ".
			"$title, ".
			"$aid, ".
			"$genres ".
		") ";
	my $res = $db->do( $query );
	if( $res != 1 ){
		die $db->errstr ."\nquery: $query\n";
	}


	# update file
	$query =
		"UPDATE stor_file ".
		"SET titleid = $tid ".
		"WHERE id = $filid ";
	$res = $db->do( $query );
	if( $res != 1 ){
		die $db->errstr ."\nquery: $query\n";
	}

	foreach( keys %$hr ){
		$hr->{$_} = undef;
	}
}
