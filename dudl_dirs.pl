#!/usr/bin/perl -w

# list directories of a unit

# show number of files
# OPT: show if all/some files in directory have links in mus_

use strict;
use Dudl;

my $dudl = Dudl->new;
my $db = $dudl->db;

my $unitname = shift;

my $unit = $dudl->findunitpath($unitname);
if( ! $unit ){
	print STDERR "no such unit found: $unitname\n";
	exit 1;
}

my $query = 
	"SELECT ".
		"dir, ".
		"COUNT(dir) as num ".
	"FROM stor_file ".
	"WHERE ".
		"unitid = ". $unit->id() ." ".
	"GROUP BY ".
		"dir ".
	"ORDER BY ".
		"dir ";

my $sth = $db->prepare( $query );
if( ! $sth ){
	die $db->errstr ."\nquery: $query\n";
}

my $res = $sth->execute;
if( ! $res ){
	die $sth->errstr ."\nquery: $query\n";
}

my( $dir, $num );
$sth->bind_columns( \( $dir, $num ) );

printf "%4s %7s %s\n", "cnt", "unit", "dir";
while( defined $sth->fetch ){
	printf "%4d %7d '%s'\n", $num, $unit->id(), $dir;
}	
$sth->finish;

$dudl->done();

