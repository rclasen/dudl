#!/usr/bin/perl -w

# $Id: import_from_musicdb.pl,v 1.4 2002-07-26 17:49:25 bj Exp $

use strict;
use Dudl::DB;

print STDERR "this script shouldn't be needed anymore\n";
exit 0;

my @want = ( qw{ UNITID DIR FNAME } );
my $dudl = Dudl::DB->new;

my %units;

my $coll;
my $colnum;
my $dir;
my $fname;

my $unit;
my $file;

while(<>){
	chomp;
	( $coll, $colnum, $dir, $fname ) = split /\t/;
	if( ! exists $units{$coll.$colnum} ){
		$dudl->commit || die;
		print STDERR "new unit: $coll$colnum\n";
		$unit = $dudl->newunit;
		$units{$coll.$colnum} = $unit;
		$unit->collection( $coll );
		$unit->colnum( $colnum );
		$unit->get_collection;
		if( ! $unit->id ){
			$unit->insert || die;
			#$dudl->commit;
		}
	} else {
		$unit = $units{$coll.$colnum};
	}

	$file = $unit->newfile;
	$file->want( \@want );
	$file->{DIR} = $dir;
	$file->{FNAME} = $fname;
	$file->get_path;

	if( ! $file->id ){
		$file->insert || die;
	}
}

