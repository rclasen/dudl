#!/usr/bin/perl -w

# check if files marked as unavailable somehow became abailable

use strict;
use Dudl::DB;


my $dudl = Dudl::DB->new;
my $db = $dudl->db;
my $topdir = $dudl->conf("cdpath");

my( $res, $id, $fname );

print "\nstep 1: find files that reapeared...\n";
$res = $db->select( "f.id, stor_filename(collection,colnum,dir,fname) AS file ".
	"FROM stor_file f INNER JOIN stor_unit u ON f.unit_id = u.id ".
	"WHERE not available" );

$res->bind_columns( \$id, \$fname );

while( $res->fetch ){
	if( -e "$topdir/$fname" ){
		print "reapeared: $fname\n";
		$db->update( "stor_file", { available => "true" }, 
			"id = $id" );
	}
}

print "\nstep 2: find files that vanished...\n";
$res = $db->select( "f.id, stor_filename(collection,colnum,dir,fname) AS file ".
	"FROM stor_file f INNER JOIN stor_unit u ON f.unit_id = u.id ".
	"WHERE available OR available ISNULL" );

$res->bind_columns( \$id, \$fname );

while( $res->fetch ){
	if( ! -e "$topdir/$fname" ){
		print "vanished: $fname\n";
		$db->update( "stor_file", { available => "false" }, 
			"id = $id" );
	}
}


$db->commit;
$db->rollback;
