#!/usr/bin/perl -w

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
		"COUNT(titleid) as titles, ".
		"COUNT(dir) as files ".
	"FROM ".
		"stor_file f, ".
		"stor_unit u ".
	"WHERE ".
		"f.unitid = u.id ".
	"GROUP BY ".
		"dir ".
	"ORDER BY ".
		"collection, ".
		"colnum, ".
		"dir ";
print $query ,"\n";
exit;

