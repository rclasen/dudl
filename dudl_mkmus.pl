#!/usr/bin/perl -w

# generate mus template for editing an adding

# edit
# - search for files in directory
# - fetch matching mus entries (use those from search if user requested)
# - generate template


# template (similar to mp3ren)
#
# album_artist		artist for this album (optional)
# album_name		Album
#
#
# file_id		database ID of file
# title_id		database ID (only when found)
#
# title_num		Track number
# title_name		Track name
# title_artist		Artist
# title_genres		genres (temporary till rating works)
# 

use strict;
use Dudl;
use Dudl::StorExport;

my $dudl = new Dudl;

my $unitid = shift;
my $dir = shift;
# TODO: check arguments
# TODO: let user specify a mus_album
# TODO: merge with an existing mus_album
# TODO: edit an existing mus_album
# TODO: optionally only use idtag or certain regexp IDs
# TODO: use default genre



my $db = $dudl->db;
my $exp = new Dudl::StorExport( $dudl );
my $tpf = &tpl_open() || die "cannot open tempfile: $!";

# TODO: move database access to module
my $query =
	"SELECT ".
		"id, ".
		"fname, ".
		"id_title, ".
		"id_artist, ".
		"id_album, ".
		"id_tracknum, ".
		"id_genre, ".
		"titleid ".
	"FROM stor_file ".
	"WHERE ".
		"unitid = $unitid AND ".
		"dir ='$dir'";

my $sth = $db->prepare( $query );
if( ! $sth ){
	die $db->errstr ."\nquery: $query\n";
}

my $res = $sth->execute;
if( ! $res ){
	die $sth->errstr ."\nquery: $query\n";
}
print STDERR "found $res files\n";

my( $id, $fname, 
	$id_title, $id_artist, $id_album, $id_tracknum, $id_genre,
	$titleid );
$sth->bind_columns( \( $id, $fname, 
	$id_title, $id_artist, $id_album, $id_tracknum, $id_genre,
	$titleid ) );

while( defined $sth->fetch ){
	my $path = ($dir ? $dir ."/" : "") .$fname;

	if( $titleid ){
		&tpl_ignore( $tpf, $path, $id, $titleid );
		next;
	}

	&tpl_file( $tpf, $path, $id, $titleid );

	# TODO: current settings from mus_title

	# suggest idtag
	&tpl_cmt( $tpf, "IDtag" );
	&tpl_sug( $tpf, $id_artist, $id_tracknum, $id_title, $id_genre );

	# suggest each regexp
	$exp->rewind();
	my $sug;
	while( defined ($sug = $exp->suggest( $dir, $fname )) ){
		&tpl_cmt( $tpf, "export id=", $exp->id );
		&tpl_sug( $tpf,
			$sug->{artist}, 
			$sug->{titlenum}, 
			$sug->{title},
			"");
	}
}	
$sth->finish;

# cleanup
&tpl_close( $tpf );
$tpf = undef;
$dudl->done();






# album_artist		artist for this album (optional)
# album_name		Album
sub tpl_open {
	print "album_artist	\n";
	print "album_name	\n";

	return( \*STDOUT );
}

sub tpl_close {
	my $fh = shift;
	close( $fh );
}

sub tpl_cmt {
	my $fh = shift;

	print $fh "# ", @_, "\n";
}

sub tpl_ignore {
	my $fh = shift;
	my $path = shift;
	my $storid = shift;
	my $titleid = shift;

	print $fh "\n";
	print $fh "# already in mus_title: $path\n";
	print $fh "# file_id		$storid\n";
	print $fh "# title_id		$titleid\n";
	print $fh "\n";
}

sub tpl_file {
	my $fh = shift;
	my $path = shift;
	my $storid = shift;
	my $titleid = shift;

	print $fh "\n";
	print $fh "# $path\n";
	print $fh "file_id		$storid\n";
	print $fh "\n";
}


# title_num		Track number
# title_name		Track name
# title_artist		Artist
# title_genres		genres (temporary till rating works)
sub tpl_sug {
	my $fh = shift;
	my $artist = shift || "";
	my $tnum = shift || "";
	my $title = shift || "";
	my $genre = shift || "";

	print $fh "title_num	$tnum\n";
	print $fh "title_name	$title\n";
	print $fh "title_artist	$artist\n";
	print $fh "title_genres	$genre\n";
	print $fh "\n";
}


