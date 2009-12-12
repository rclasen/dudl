#!usr/bin/perl -w

use strict;

use Dudl::DB;
use Dudl::StorUnit;

my $dudl = new Dudl::DB;
my $o;

$o = Dudl::StorUnit->new( dudl => $dudl );
$o->val( volname => "test" );
$o->val( colnum => 1 );
my $id = $o->save;

$o = Dudl::StorUnit->load(
	dudl => $dudl,
	where => { id => $id } );

$dudl->rollback;
