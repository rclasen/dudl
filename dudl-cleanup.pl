#!/usr/bin/perl -w

# $Id: dudl-cleanup.pl,v 1.3 2005-10-08 16:52:46 bj Exp $

# do periodic maintenance

use strict;
use Dudl::DB;

my $dudl = new Dudl::DB;
my $db = $dudl->db;
my $sth;

# clear history
$sth = $db->prepare( 
"DELETE FROM mserv_hist 
WHERE age(added) > interval '6 month'" )
	or die $db->errstr;
$sth->execute 
	or die $db->errstr;
$db->commit;

# vacuum analyze
#$db->{AutoCommit} = 1;
#$sth = $db->prepare( "VACUUM ANALYZE" )
#	or die $db->errstr;
#$sth->execute 
#	or die $db->errstr;

