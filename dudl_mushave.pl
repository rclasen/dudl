#!/usr/bin/perl -w

# $Id: dudl_mushave.pl,v 1.3 2001-12-18 12:27:39 bj Exp $

# search database

use strict;
use Getopt::Long;
use Dudl;

my $opt_help = 0;
my $opt_artist = "";
my $opt_album = "";
my $opt_title = "";
my $needhelp = 0;

my $want_artist = 0;
my $want_album = 0;
my $want_title = 0;
my $want_genre = 0;

sub usage {
	my $fh = shift;
	print $fh "usage: $0 [opts] <what>
search musik database
 --artist <regexp>    
 --album <regexp>    
 --title <regexp>    
 --help
<what>:
 artist
 album
 title
 genre
";
}


if( ! GetOptions(
	"help|h!"		=> \$opt_help,
	"artist|a=s"		=> \$opt_artist,
	"album|l=s"		=> \$opt_album,
	"title|t=s"		=> \$opt_title,
) ){
	$needhelp ++;
}

my $want = 0;
if( ! @ARGV ){
	push @ARGV, "most";
}

foreach my $a ( @ARGV ){
	if( $a =~ /^artist$/i ){
		$want_artist++;
		$want++;

	} elsif( $a =~ /^album$/i ){
		$want_album++;
		$want++;

	} elsif( $a =~ /^title$/i ){
		$want_title++;
		$want++;

	} elsif( $a =~ /^genre$/i ){
		$want_genre++;
		$want++;

	} elsif( $a =~ /^most$/i ){
		$want_artist++;
		$want_album++;
		$want_genre++;
		$want++;

	} elsif( $a =~ /^all$/i ){
		$want_artist++;
		$want_album++;
		$want_title++;
		$want_genre++;
		$want++;

	} else {
		$needhelp ++;
		print STDERR "invalid argument to what\n";
	}
}

if( ! $want ){
	print STDERR "nothing wanted!\n";
	$needhelp++;
}

if( $opt_help ){
	&usage( \*STDOUT );
	exit 0;
}

if( $needhelp ){
	&usage( \*STDERR );
	exit 1;
}

my $dudl = Dudl->new;
my $db = $dudl->db;


my $query = "";

if( $want_artist ){

	$query = "SELECT DISTINCT
		a.id, 
		a.nname
	FROM
		mus_artist a 
	";

	$query .= ", mus_album al " if $opt_album;
	$query .= ", mus_title t " if $opt_title;

	my @w;
	push @w, "a.id = t.artist_id", 
		"t.title ~* '$opt_title'" if $opt_title;
	push @w, "a.id = al.artist_id",
		"al.album ~* '$opt_album'" if $opt_album;
	push @w, "al.id = t.album_id" if $opt_title && $opt_album;
	push @w, "a.nname ~* '$opt_artist'" if $opt_artist;

	$query .= "WHERE ". join " AND ", @w if @w;

	print "\nartists:\n";
	&query( $db, $query );
}

if( $want_genre ){
	my @s =( "t.genres" );
	push @s, "a.nname", "a.id" if $opt_artist;

	$query = "SELECT
		count(*), ". join( ", ", @s ) ."
	FROM
		mus_title t 
	";

	$query .= ", mus_artist a " if $opt_artist;

	my @w;
	push @w, "a.id = t.artist_id", 
		"a.nname ~* '$opt_artist'" if $opt_artist;
	push @w, "t.title ~* '$opt_title'" if $opt_title;

	$query .= "WHERE ". join " AND ", @w if @w;
	$query .= "GROUP BY ". join( ", ", @s );

	print "\ngenres:\n";
	&query( $db, $query );
}

if( $want_album ){

	$query = "SELECT DISTINCT
		al.id,
		al.album,
		a.nname
	FROM
		mus_album al,
		mus_artist a
	";

	$query .= ", mus_title t " if $opt_title;

	my @w;
	push @w, "al.artist_id = a.id";
	push @w, "a.nname ~* '$opt_artist'" if $opt_artist;
	push @w, "al.album ~* '$opt_album'" if $opt_album;
	push @w, "t.album_id = al.id", 
		"t.title ~* '$opt_title'" if $opt_title;

	$query .= "WHERE ". join " AND ", @w if @w;

	print "\nalbums:\n";
	&query( $db, $query );
}

if( $want_title ){

	$query = "SELECT DISTINCT
		t.id,
		t.title,
		a.nname
	FROM
		mus_title t,
		mus_artist a
	";

	$query .= ", mus_album al " if $opt_album;

	my @w;
	push @w, "t.artist_id = a.id";
	push @w, "a.nname ~* '$opt_artist'" if $opt_artist;
	push @w, "t.title ~* '$opt_title'" if $opt_title;
	push @w, "t.album_id = al.id", 
		"al.album ~* '$opt_album'" if $opt_album;

	$query .= "WHERE ". join " AND ", @w if @w;

	print "\ntitles:\n";
	&query( $db, $query );
}


$dudl->done();

sub query {
	my $db = shift;
	my $query = shift;

	#print $query, "\n";

	my $sth = $db->prepare( $query );
	if( ! $sth ){
		die $db->errstr ."\nquery: $query\n";
	}

	my $res = $sth->execute;
	if( ! $res ){
		die $sth->errstr ."\nquery: $query\n";
	}

	my $r;
	while( defined( $r = $sth->fetchrow_arrayref ) ){
		foreach my $c ( @$r ){
			print "$c	";
		}
		print "\n";
	}	
	$sth->finish;
} 


