#!/usr/bin/perl -w

# $Id: test_sequence.pl,v 1.3 2002-07-26 17:49:25 bj Exp $

use strict;
use Dudl::DB;

my $dudl = Dudl::DB->new;
my $db = $dudl->db;

#my( $id )= $db->selectrow_array( "SELECT nextval('stor_file_id_seq')" );
#print $id, "\n";

print $db->quote( 3, "BOOLEAN" ), "\n";

