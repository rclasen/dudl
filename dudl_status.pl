#!/usr/bin/perl -w

# $Id: dudl_status.pl,v 1.4 2002-04-28 11:54:59 bj Exp $

# list directories of a unit

# show number of files
# show if all/some files in directory have links in mus_

use strict;
use Dudl;

my $dudl = Dudl->new;
my $db = $dudl->db;

# TODO: move database access to module
my $query = 
	"SELECT ".
		"trim(collection), ".
		"colnum, ".
		"dir, ".
		"COUNT(title) as titles, ".
		"COUNT(dir) as files ".
	"FROM ".
		"stor_file f, ".
		"stor_unit u ".
	"WHERE ".
		"f.unit_id = u.id ".
	"GROUP BY ".
		"dir ".
	"ORDER BY ".
		"collection, ".
		"colnum, ".
		"dir ";
print $query ,"\n";
exit;

