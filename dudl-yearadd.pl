#!/usr/bin/perl -w

# find albums without a publish_date and prompt user to complete this
# info.

use strict;
use Dudl::DB;

$|=1;

my $dudl = new Dudl::DB;
my $db = $dudl->db;

my $query = "SELECT
	a.id,
	ar.nname AS artist,
	a.album
FROM
	mus_album a INNER JOIN 
		mus_artist ar ON a.artist_id = ar.id
WHERE
	a.publish_date ISNULL
	AND ar.nname != 'VARIOUS'
ORDER BY
	artist,
	album
";
my $lst = $db->prepare( $query ) or die $db->errstr."\nquery: $query";


my( $id, $artist, $album );
my $res = $lst->execute or die $db->errstr."\nquery: $query";
$lst->bind_columns( \( $id, $artist, $album ));

LST: while( defined $lst->fetch ){
	print "$id $artist: $album\n";

	my $date;
	IN: while(1){
		print "date: ";
		$date = <>;
		chomp $date;

		next LST if $date =~ /^n$/i;

		$date .= "-1" if $date =~ /^\d+-\d+$/;
		$date .= "-1-1" if $date =~ /^\d+$/;
		last if $date =~ /^\d\d\d\d-\d+-\d+$/;

		print STDERR "invalid date\n";
	}

	$query = "UPDATE mus_album SET publish_date = '$date' where id=$id";
	$db->do( $query ) or warn $db->errstr."\nquery: $query";
	$dudl->commit;
}

