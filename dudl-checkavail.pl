#!/usr/bin/perl -w

# check if files marked as unavailable somehow became abailable

use strict;
use Dudl::DB;


my $dudl = Dudl::DB->new;
my $db = $dudl->db;
my $topdir = $dudl->conf("cdpath");

my $res = $db->select( "f.id, stor_filename(collection,colnum,dir,fname) AS file ".
	"FROM stor_file f INNER JOIN stor_unit u ON f.unit_id = u.id ".
	"WHERE not available" );

my( $id, $fname );
$res->bind_columns( \$id, \$fname );

while( $res->fetch ){
	if( -e "$topdir/$fname" ){
		print "reapeared: $fname\n";
		$db->update( "stor_file", { available => "true" }, 
			"id = $id" );
	}
}

$db->commit;
$db->rollback;
