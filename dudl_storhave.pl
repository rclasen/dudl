#!/usr/bin/perl -w

# $Id: dudl_storhave.pl,v 1.2 2001-12-13 14:49:36 bj Exp $

use strict;
use Dudl;

my @attribs = qw( dir fname );
my $filesql = "TRIM( both ' ' FROM collection ) || ".
	"colnum || '/' || dir || '/' || fname";

my $what=lc shift || die "missing 'what' argument: any|file|sql|..";
my $pattern = join( " ", @ARGV ) || die "missing pattern";

my $dudl = Dudl->new;
my $db = $dudl->db;

$pattern = $db->quote( $pattern, DBI::SQL_CHAR );

my $where;
if( $what eq "all" || $what eq "any" ){
	foreach( @attribs ){
		$where .= " OR " if $where;
		$where .= "( $_ ~* $pattern )";
	}

} elsif( $what eq "file" ){
	$where .= "($filesql) ~* $pattern";

} elsif( $what eq "sql" || $what eq "select" ){
	$where = join " ", @ARGV;

} else {
	my $found = 0;
	foreach( @attribs ){
		if( $_ eq $what ){
			$where .= "$what ~* $pattern";
			$found++;
			last;
		}
	}
	if( $found ){
		die "invalid 'what' argument";
	}
}


print STDERR "SELECT ... WHERE $where\n";

my $query = 
"SELECT ".
	"$filesql as file ".
"FROM ".
	"stor_file f INNER JOIN ".
		"stor_unit u ".
		"ON u.id = f.unitid ".
"WHERE ".
	"NOT broken AND ".
	"( $where ) ".
"ORDER BY ".
	"u.collection, ".
	"u.colnum, ".
	"f.dir, ".
	"f.fname";

my $sth = $db->prepare( $query );
if( ! $sth ){
	die $db->errstr ."\nquery: $query\n";
}

my $res = $sth->execute;
if( ! $res ){
	die $sth->errstr ."\nquery: $query\n";
}

my $file;
$sth->bind_columns( \$file );

while( defined $sth->fetch ){
	print $file, "\n";
}	
$sth->finish;

$dudl->done();



