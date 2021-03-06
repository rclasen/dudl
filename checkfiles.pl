#!/usr/bin/perl -w

# $Id: checkfiles.pl,v 1.3 2008-12-28 11:39:22 bj Exp $

#
# Copyright (c) 2008 Rainer Clasen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

# delete bogus entries from database

use strict;
use Dudl::DB;

print STDERR "this file is too dangerous!!";
exit 0;

my $dudl = new Dudl::DB;

my $query =
"SELECT ".
	"f.id, ".
	"collection, ".
	"colnum, ".
	"dir, ".
	"fname ".
"FROM ".
	"stor_unit u INNER JOIN ".
		"stor_file f ".
		"ON u.id = f.unit_id ".
"WHERE ".
	"NOT broken ".
	"AND NOT collection IN( ".
		"'ab', ".
		"'mm', ".
		"'lead',".
		"'misc' ) ".
"ORDER BY ".
	"collection,".
	"colnum,".
	"dir,".
	"fname";

my $db = $dudl->db;

my $sth = $db->prepare( $query );
if( ! $sth ){
	die $db->errstr ."\nquery: $query\n";
}

my $res = $sth->execute;
if( ! $res ){
	die $sth->errstr ."\nquery: $query\n";
}

my(
	$id,
	$col,
	$colnum,
	$dir,
	$fname
);

$sth->bind_columns( \(
	$id,
	$col,
	$colnum,
	$dir,
	$fname
) );

my @old;
my $base = "/vol/cd/MP3";
while( defined $sth->fetch ){
	$col =~ s/\s+$//;
	my $path = $base ."/".
		$col ."/".
		sprintf( "%s%04d", $col, $colnum ) ."/".
		$dir ."/".
		$fname;

	if( ! -e $path ){
		print $id, " ", $path, "\n";
		push @old, $id;
	}
}

$sth->finish;

$query = "delete from stor_file where id in (".
	join( ",",@old ).
	")";

print "query: ", $query, "\n";
$_ = <STDIN>;

$res = $db->do( $query );
if( ! $res ){
	die $sth->errstr ."\nquery: $query\n";
}

$db->commit;



