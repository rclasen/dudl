#!/usr/bin/perl -w


# add music entries from template file
# TODO: modify

use strict;
use Dudl;
use Dudl::Job::Music;

my $dudl = new Dudl;
my $job = new Dudl::Job::Music;

foreach my $f ( @ARGV ){
	$job->read( $f ) || die "$!";
}

while( my( $alb, $fil, $tit ) = $job->next ){
	if( ! $alb->{id} ){
		$alb->{id} = &save_album( $dudl, $alb );
	}

	&save_title( $dudl, $alb->{id}, $fil->{id}, $tit );
}
#$dudl->rollback();
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

	# TODO: search for artist with prepended "the ", or "die "
	# TODO: search for artist with stripped "the "...
	my $query =
		"SELECT ".
			"id ".
		"FROM mus_artist ".
		"WHERE ".
			"LOWER(nname) = LOWER($artist) ".
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

	print STDERR "adding album $aid\n";

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

	my $nr = $db->quote( $hr->{num}, DBI::SQL_INTEGER );
	my $title = $db->quote( $hr->{name}, DBI::SQL_CHAR );
	my $genres = $db->quote( $hr->{genres}, DBI::SQL_CHAR );
	# TODO: move default for random to SQL server
	my $random;
	if( defined $hr->{random} ){
		$random = $hr->{random} ? "true" : "false";
	}else {
		$random = "true";
	}

	# first get a new id
	my $query = "SELECT nextval('mus_title_id_seq')";
	my ( $tid ) = $db->selectrow_array($query );
	if( ! $tid ){
		die $db->errstr ."\nquery: $query\n";
	}

	print STDERR "adding title $tid: $albid,$nr\n";

	# add new title with this id
	$query =
		"INSERT INTO mus_title ( ".
			"id, ".
			"album_id, ".
			"nr, ".
			"title, ".
			"artist_id, ".
			"genres, ".
			"random ".
		") VALUES ( ".
			"$tid, ".
			"$albid, ".
			"$nr, ".
			"$title, ".
			"$aid, ".
			"$genres, ".
			"$random ".
		") ";
	#print STDERR "save_title: ", $query, "\n";
	my $res = $db->do( $query );
	if( $res != 1 ){
		die $db->errstr ."\nquery: $query\n";
	}


	# update file
	$query =
		"UPDATE stor_file ".
		"SET titleid = $tid ".
		"WHERE ".
			"titleid ISNULL AND ".
			"id = $filid ";
	$res = $db->do( $query );
	if( $res != 1 ){
		die $db->errstr ."\nquery: $query\n";
	}
}
