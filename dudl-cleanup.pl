#!/usr/bin/perl -w

# $Id: dudl-cleanup.pl,v 1.4 2005-10-08 22:29:53 bj Exp $

# do periodic maintenance

use strict;
use Dudl::DB;

my $dudl = new Dudl::DB;
my $db = $dudl->db;

# clear history
$db->do( 
"DELETE FROM mserv_hist ".
"WHERE age(added) > interval '6 month'" )
	or die $db->errstr;
$db->commit;

# delete albums without titles (except UNSORTED)
$db->do(
"DELETE FROM mus_album ".
"WHERE id IN ( ".
	"SELECT a.id ".
	"FROM mus_album a ".
		"LEFT JOIN stor_file f ON a.id = f.album_id ".
	"WHERE a.album != 'UNSORTED' ".
	"GROUP BY a.id ".
	"HAVING COUNT(f.id) = 0)")

	or die $db->errstr;
$db->commit;

# delete artists without titles/albums (except UNKNOWN, VARIOUS)
$db->do(
"DELETE FROM mus_artist ".
"WHERE id IN ( ".
	"SELECT ar.id ".
	"FROM mus_artist ar ".
		"LEFT JOIN (SELECT f.artist_id ".
			"FROM stor_file f ".
		"UNION ALL SELECT al.artist_id ".
			"FROM mus_album al) ids ON ar.id = ids.artist_id ".
	"WHERE NOT ar.nname IN( 'UNKNOWN', 'VARIOUS' ) ".
	"GROUP BY ar.id ".
	"HAVING COUNT(ids.artist_id) = 0)")

	or die $db->errstr;
$db->commit;

# vacuum analyze
#$db->{AutoCommit} = 1;
#$sth = $db->do( "VACUUM ANALYZE" )
#	or die $db->errstr;

