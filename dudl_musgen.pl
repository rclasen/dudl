#!/usr/bin/perl -w

# $Id: dudl_musgen.pl,v 1.14 2002-04-28 11:54:59 bj Exp $

# generate mus template for editing an adding

# edit
# - search for files in directory
# - fetch matching mus entries (use those from search if user requested)
# - generate template


use strict;
use Getopt::Long;
use Dudl;
use Dudl::Suggester;
use Dudl::Job::Music;
use Dudl::Job::Archive;


# TODO: let user specify a mus_album
# TODO: merge with an existing mus_album
# TODO: edit an existing mus_album

my $dudl = new Dudl;

my $opt_max = $dudl->sug_max;
my $opt_minscore = $dudl->sug_score;
my $opt_id = $dudl->sug_id3;
my $opt_stored = $dudl->sug_int;

my $opt_archive = 1;
my $opt_afile = $dudl->write_jname;

my $opt_help = 0;
my $needhelp = 0;

my( $unitid, $dir, $genre );

sub usage {
	print { $_[0] } "$0 [opts] <unitid> <dir> [<genres>]
generate job file for dudl_musimport.pl
optons:
 --max <n>       maximum number of suggestions per file
 --minscore <n>  minimum score suggestions must have
 --[no]id        get suggestions from IDtags in storage tables
 --[no]stored    use stored regexps for suggestions
 --[no]archive   try to get suggestions from an archive file
 --afile <f>     override archive jobfile

 --help          this help
";
}


if( !GetOptions(
	"max=i"		=> \$opt_max,
	"minscore=i"	=> \$opt_minscore,
	"id!"		=> \$opt_id,
	"stored!"	=> \$opt_stored,
	"archive!"	=> \$opt_archive,
	"afile=s"	=> \$opt_afile,
	"help|h!"	=> \$opt_help,
)){
	$needhelp++;
}

$unitid = shift;
if( ! $unitid || ! $unitid =~ /^\d+$/ ){
	print STDERR "need numeric unit ID\n";
	$needhelp ++;
}

$dir = shift;
if( ! $dir ){
	print "need a directory (at least '/')\n";
	$needhelp ++;
}

$genre = shift || "";
$genre = "" if $genre eq "-";

if( $opt_afile =~ /\// ){
	print STDERR "archive jobfile must be a basename\n";
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


my $db = $dudl->db;

my $arch;
if( $opt_archive ){
	my $unit = new Dudl::Unit( $dudl );
	$unit->get_id( $unitid );
	my $path = $unit->path ."/";
	$path .= $dir ."/" if $dir;
	$path .= $opt_afile;
	$arch = new Dudl::Job::Archive( file => $path );
}

my $exp = new Dudl::Suggester;
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
		"title ".
	"FROM stor_file ".
	"WHERE ".
		"unit_id = $unitid AND ".
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
	$title );
$sth->bind_columns( \( $id, $fname, 
	$id_title, $id_artist, $id_album, $id_tracknum,
	$title ) );

my %album;
my $nr = 0;
while( defined $sth->fetch ){
	my $path = ($dir ? $dir ."/" : "") .$fname;

	$nr ++;
	$exp->clear();

	$job->add_file( 
		mp3	=> $path,
		id	=> $id, 
		);

	if( defined $title ){
		# TODO: fetch music data from stor_file
		$exp->add_asis( 
			titleid => $id,
		#	...
			);
	}

	if( $arch ){
		$arch->rewind;
		while( my($alb,$fil,$tit) = $arch->next ){
			my $n = $fil->{mp3};
			if( $path =~ /(^|\/)\Q$n\E$/i ){
				$exp->add_asis(
				artist		=> $tit->{artist},
				titlenum	=> $tit->{num} || $nr,
				title		=> $tit->{name},
				genres		=> $tit->{genres},
				cmt		=> $tit->{cmt},
				album		=> $alb->{name},
				source		=> "archive",
				preference	=> 3,
				);

				$job->file->{encoder} = $tit->{encoder};
				$job->file->{broken} = $tit->{broken};
				$job->file->{cmt} = $tit->{cmt};
				last;
			}
		}
	}


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
	if( $opt_stored ){
		$exp->add_stor( $path );
	}


	$exp->order;
	my $sug;
	my $sugnum = 0;
	while( ( ! $opt_max || $sugnum < $opt_max ) && 
	    defined ($sug = $exp->get) ){

		next if $sugnum && $sug->{sug_quality} < $opt_minscore;

	    	$job->add_title(
			id	=> $sug->{titleid} || undef,
			source	=> $sug->{source} ." score: ".
				$sug->{sug_quality},
			name	=> $sug->{title},
			artist	=> $sug->{artist}, 
			num	=> $sug->{titlenum} || $nr, 
			genres	=> $genre || $sug->{genres} || "",
			cmt	=> $sug->{cmt} || "",
		);
		$album{name}{$sug->{album}}++ if $sug->{album};
		$album{artist}{$sug->{artist}}++ if $sug->{artist};

		$sugnum ++;
	}
}	
$sth->finish;

@_ = sort { $album{name}{$b} <=> $album{name}{$a} } keys %{$album{name}};
if( @_ && 3* $album{name}{$_[0]} >= scalar @_ ){
	$job->album->{name} = $_[0];
}

@_ = sort { $album{artist}{$b} <=> $album{artist}{$a} } keys %{$album{artist}};
if( @_ && 3* $album{artist}{$_[0]} >= scalar @_ ){
	$job->album->{artist} = $_[0];
	$job->album->{type} = 'album';
}


$job->write( \*STDOUT );

# cleanup
$dudl->done();


