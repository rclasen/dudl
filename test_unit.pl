#! /usr/bin/perl -w

# $Id: test_unit.pl,v 1.4 2002-07-30 16:04:34 bj Exp $


use strict;
use Dudl::DB;
use Dudl::StorUnit;

sub show {
	my $unit	= shift;

	print "id:         ", $unit->val("id"), "\n";
	print "collection: ", $unit->val("collection"), "\n";
	print "colnum:     ", $unit->val("colnum"), "\n";
	print "volname:    ", $unit->val("volname"), "\n";
	print "size:       ", $unit->val("size"), "\n";
}

my $dudl = Dudl::DB->new;

my $unit;

# empty unit
$unit = Dudl::StorUnit->new( dudl => $dudl );

# load existing id
eval { $unit = Dudl::StorUnit->load(
		dudl => $dudl,
		where => { id => 64553 } ); };
if( $@ ){
	print "unit not found: $@\n";
} else {
	&show( $unit );
}

# load existing collection
eval { $unit = Dudl::StorUnit->load_path(
		dudl => $dudl,
		path => "sl27" ); };
if( $@ ){
	print "unit not found\n";
} else {
	&show( $unit );
}
print "saved: ", $unit->save(), "\n";


# empty unit
$unit = Dudl::StorUnit->new( dudl => $dudl );
$unit->val( "collection", "test");
$unit->val( "colnum", 0);
$unit->acquire( "/dev/hdc" );
&show( $unit );
print "saved: ", $unit->save(), "\n";



