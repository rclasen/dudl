#!/usr/bin/perl -w

# TODO: use Job::Archive for reading Job file

# generate mus template for editing an adding

# edit
# - search for files in directory
# - fetch matching mus entries (use those from search if user requested)
# - generate template


use strict;
use Dudl;
use Dudl::Suggester;
use Dudl::Job::Music;

my $dudl = new Dudl;

my $unitid = shift || die "need a unit ID";
my $dir = shift || die "need a directory";
my $genre = shift || "";

# TODO: check arguments
# TODO: let user specify a mus_album
# TODO: merge with an existing mus_album
# TODO: edit an existing mus_album
# TODO: optionally only use idtag or certain regexp IDs
# TODO: use default genre


my $opt_max = 1;
my $opt_id = 1;

my %lastsug = (
	title	=> "",
	tnum	=> "",
	genres	=> "",
	artist	=> "",
	);


my $db = $dudl->db;
my $exp = new Dudl::Suggester( $dudl );
my $job = new Dudl::Job::Music;
$job->add_album();

# TODO: move database access to module
my $query =
	"SELECT ".
		"id, ".
		"fname, ".
		"id_title, ".
		"id_artist, ".
		"id_album, ".
		"id_tracknum, ".
		"titleid ".
	"FROM stor_file ".
	"WHERE ".
		"unitid = $unitid AND ".
		"dir = ". $db->quote( $dir, DBI::SQL_CHAR ) ." ".
	"ORDER BY ".
		"fname";

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
	$id_title, $id_artist, $id_album, $id_tracknum, 
	$titleid );
$sth->bind_columns( \( $id, $fname, 
	$id_title, $id_artist, $id_album, $id_tracknum,
	$titleid ) );

my $nr = 0;
while( defined $sth->fetch ){
	my $path = ($dir ? $dir ."/" : "") .$fname;

	$nr ++;
	$exp->clear();

	$job->add_file( 
		mp3	=> $path,
		id	=> $id, 
		);

	if( $titleid ){
		# TODO: fetch data from mus_title
		$exp->add( 
			titleid => $titleid,
		#	...
			);
	}

	# TODO: try to find a match in mus_title



	# suggest at least an empty one
	$exp->add( source => "empty" );

	# suggest idtag
	if( $opt_id ){
		$exp->add(
			artist		=> $id_artist,
			titlenum	=> $id_tracknum || $nr,
			title		=> $id_title,
			album		=> $id_album,
			source		=> "ID3",
			);
	}

	# suggest with stored regexps
	$exp->add_stor( $path );

	$exp->order;
	my $sug;
	my $sugnum = 0;
	while( ( ! $opt_max || $sugnum < $opt_max ) && 
	    defined ($sug = $exp->get) ){
	    	$job->add_title(
			id	=> $sug->{titleid} || undef,
			source	=> $sug->{source},
			name	=> $sug->{title},
			artist	=> $sug->{artist}, 
			num	=> $sug->{titlenum} || $nr, 
			genres	=> $genre);
		$sugnum ++;
	}
}	
$sth->finish;
$job->write( \*STDOUT );

# cleanup
$dudl->done();


