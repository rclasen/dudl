#!/usr/bin/perl -w

# $Id: dudl_dupes.pl,v 1.7 2002-07-26 17:49:25 bj Exp $

# find duplicate files using their stored md5sums

# TODO: move database access to module

use strict;
use Dudl::DB;

my $dudl = new Dudl::DB;

sub run {
	my $db		= shift;
	my $field	= shift;

	my $query;
	my $sth;
	my $res;

	$query =
		"SELECT $field ".
		"INTO TEMP tmp_$field ".
		"FROM stor_file ".
		"GROUP BY $field ".
		"HAVING count(*) > 1";
	$res = $db->do( $query );
	if( ! $res ){
		die $db->errstr ."\nquery: $query\n";
	}

	$query =
		"SELECT ".
			"tmp_$field.$field, ".
			"trim(collection), ".
			"colnum, ".
			"dir, ".
			"fname ".

		"FROM ".
			"tmp_$field, ".
			"stor_file, ".
			"stor_unit ".
		"WHERE ".
			"(tmp_$field.$field = stor_file.$field) AND ".
			"(stor_file.unit_id = stor_unit.id ) ".
		"ORDER BY ".
			"tmp_$field.$field";
	$sth = $db->prepare( $query );
	if( ! $sth ){
		die $db->errstr ."\nquery: $query\n";
	}

	$res = $sth->execute;
	if( ! $res ){
		die $sth->errstr ."\nquery: $query\n";
	}

	my( $sum, $collection, $colnum, $dir, $fname );
	$sth->bind_columns( \( $sum, $collection, $colnum, $dir, $fname ) );

	my $osum;
	while( defined $sth->fetch ){
		if( $osum ne $sum ){
			print "\n";
			$osum = $sum;
		}
		print join("/", $collection.$colnum, $dir, $fname), "\n";
	}
}

print "\nduplicates by file:\n";
&run( $dudl->db, "fsum" );

print "\nduplicates by data:\n";
&run( $dudl->db, "dsum" );

