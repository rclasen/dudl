#! /usr/bin/perl -w

# $Id: test_unit.pl,v 1.3 2002-07-26 17:49:25 bj Exp $


use strict;
use Dudl::DB;
use Dudl::Unit;

sub show {
	my $unit	= shift;

	print "id:         ", $unit->id, "\n";
	print "collection: ", $unit->collection, "\n";
	print "colnum:     ", $unit->colnum, "\n";
	print "volname:    ", $unit->volname, "\n";
	print "size:       ", $unit->size, "\n";
}

my $dudl = Dudl::DB->new;
my $unit = Dudl::Unit->new( $dudl );


$unit->get( 629504 );
&show( $unit );

$unit->find( "sl", 27 );
&show( $unit );

#$unit->acquire( "/dev/hdc" );
#&show( $unit );

$unit->update;

$unit->clear;
$unit->collection("test");
$unit->colnum(0);
$unit->insert;


