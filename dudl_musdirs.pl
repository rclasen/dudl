#!/usr/bin/perl -w

# $Id: dudl_musdirs.pl,v 1.6 2002-07-26 17:49:25 bj Exp $

# list directories of a unit

# show number of files
# show if all/some files in directory have links in mus_

use strict;
use Dudl::DB;

my $dudl = new Dudl::DB;
my $db = $dudl->db;

my $unitname = shift || die "need a unit name";

my $unit = $dudl->findunitpath($unitname);
if( ! $unit ){
	print STDERR "no such unit found: $unitname\n";
	exit 1;
}

# TODO: move database access to module
my $query = 
	"SELECT ".
		"dir, ".
		"COUNT(title) as titles, ".
		"COUNT(dir) as files ".
	"FROM stor_file ".
	"WHERE ".
		"unit_id = ". $unit->id() ." ".
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

my( $dir, $titles, $files );
$sth->bind_columns( \( $dir, $titles, $files ) );

printf "%4s %4s %7s %s\n", "tit", "fil", "unit", "dir";
while( defined $sth->fetch ){
	printf "%4s %4d %7d %s\n", $titles, $files, $unit->id(), $dir;
}	
$sth->finish;


