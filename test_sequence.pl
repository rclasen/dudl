#!/usr/bin/perl -w

# $Id: test_sequence.pl,v 1.2 2001-12-13 11:41:48 bj Exp $

use strict;
use Dudl;

my $dudl = Dudl->new;
my $db = $dudl->db;

#my( $id )= $db->selectrow_array( "SELECT nextval('stor_file_id_seq')" );
#print $id, "\n";

print $db->quote( 3, "BOOLEAN" ), "\n";

$dudl->done;
