#!/usr/bin/perl -w

# TODO: set ID tags according to data from music database

use strict;
use Dudl::DB;
use MP3::Tag;

my $dudl = new Dudl::DB;
my $db = $dudl->db;

my $query = "SELECT
	stor_filename(u.collection, u.colnum, f.dir, f.fname) AS path,
	f.album_pos,
	f.title,
	ta.nname AS artist,
	a.album,
	EXTRACT(year FROM a.publish_date) AS year
FROM
	stor_file f 
		INNER JOIN stor_unit u ON f.unit_id = u.id
		INNER JOIN mus_album a ON f.album_id = a.id
		INNER JOIN mus_artist ta ON f.artist_id = ta.id
WHERE 
	album_id = 880
ORDER BY
	path
";
my $sth = $db->prepare( $query ) or die $db->errstr."\nquery: $query";


my( $path, $pos, $title, $artist, $album, $year );
my $res = $sth->execute or die $db->errstr."\nquery: $query";
$sth->bind_columns( \( $path, $pos, $title, $artist, $album, $year ));

while( defined $sth->fetch ){
	my $fname = $dudl->conf("cdpath") . "/$path";
	my $tt = new MP3::Tag( $fname ) || next;
	my $t = $tt->new_tag( 'ID3v1' ) || next;

	$t->track( $pos );
	$t->song( $title );
	$t->artist( $artist );
	$t->album( $album );
	$t->year( $year );

	$t->write_tag() || next;
}

