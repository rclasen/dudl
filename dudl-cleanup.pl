#!/usr/bin/perl -w

# $Id: dudl-cleanup.pl,v 1.1 2004-08-28 13:24:01 bj Exp $

# do periodic maintenance

use strict;
use Dudl::DB;

my $dudl = new Dudl::DB;
my $db = $dudl->db;
my $sth;

# clear history
$sth = $db->prepare( 
"DELETE FROM mserv_hist 
WHERE age(added) > interval '2 month'" )
	or die $db->errstr;
$sth->execute 
	or die $db->errstr;
$db->commit;

# vacuum analyze
$db->{AutoCommit} = 1;
$sth = $db->prepare( "VACUUM ANALYZE" )
	or die $db->errstr;
$sth->execute 
	or die $db->errstr;

