#!/usr/bin/perl -w

# set stor_file.export to the matching stor_export.id

print STDERR "this program is obsolete\n";
exit 0;

use strict;
use Dudl;

sub update_matching {
	my $db		= shift;
	my $id		= shift;
	my $regexp	= shift;

	$regexp = $db->quote($regexp ."\\.mp3\$", DBI::SQL_CHAR);
	$regexp =~ s/\\/\\\\/g;
	my $query =
		"UPDATE stor_file ".
		"SET ".
			"export=$id ".
		"WHERE ".
			"( export ISNULL ) AND ".
			"( (dir || '/' || fname) ~* $regexp) ";
	print "$query\n";
	my $r = $db->do( $query );
	if( ! $r ){
		die "query failed: ". $query ."\n". $db->errstr;
	}
	print "updated: ". $r ."\n";
}


my $dudl = Dudl->new;
my $db = $dudl->db;


my $query = 
	"SELECT id, regexp ".
	"FROM stor_export ".
	"WHERE regexp NOTNULL ".
	"ORDER BY priority,id";
my $sth = $db->prepare( $query );
if( ! $sth ){
	die "query failed: ". $query ."\n". $db->errstr;
}
if( ! $sth->execute ){
	die "query failed: ". $query ."\n". $sth->errstr;
}

my( $id, $regexp );
$sth->bind_columns( \( $id, $regexp ));

while( $sth->fetch ){
	&update_matching( $db, $id, $regexp );
}
$sth->finish;

print "Interrupt to skip commit - hit Enter to continue";
my $answ = <STDIN>;

print "comitting ...\n";
$dudl->commit or die $db->errstr;

$dudl->done;



