#!/usr/bin/perl -w

use strict;
use Dudl;

my $dudl = Dudl->new;
my $db = $dudl->db;

#my( $id )= $db->selectrow_array( "SELECT nextval('stor_file_id_seq')" );
#print $id, "\n";

print $db->quote( 3, "BOOLEAN" ), "\n";

$dudl->done;
