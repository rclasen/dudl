#!/usr/bin/perl -w

# TODO: optionally suggest based on manually specified regexp

use strict;
use Getopt::Long;
use Dudl;
use Dudl::Suggester;
use Dudl::Job::Rename;
use MP3::Tag;

my $opt_max = 2;
my $opt_minscore = 6;
my $opt_genres = "";

my $opt_help = 0;
my $needhelp = 0;

sub usage {
	print { $_[0] } "$0 [opts] <filenames> ...
generate job file for dudl_rename.pl
optons:
 --max <n>       maximum number of suggestions per file
 --minscore <n>  minimum score suggestions must have
 --genres <g>    list default genres to use

 --help          this help

reads filenames from stdin when there are none on the cmdline
";
}


if( !GetOptions(
	"max=i"		=> \$opt_max,
	"minscore=i"	=> \$opt_minscore,
	"genres=s"	=> \$opt_genres,
	"help|h!"	=> \$opt_help,
)){
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


my @files;

# decide where to look for filenames and fill an array
if( defined $ARGV[0] ){
	if( -d $ARGV[0] ){
		my $dir = $ARGV[0];
		# - readdir $ARGV[0]
		opendir( DIR, $dir ) || die "cannot opendir \"$dir\": $! ";
		while( defined( $_ = readdir( DIR )) ){
			push @files, "$dir/$_";
		}
		closedir( DIR );
	} else {
		# - process all of @ARGV
		push @files, @ARGV;
	}
} else {
	# - read stdin
	while( <STDIN> ){
		chomp;
		push @files, $_;
	}
}

my $dudl = new Dudl;
my $job = new Dudl::Job::Rename;

$job->add_album(
	name	=> "",
	artist	=> "VARIOUS",
	);

foreach my $f ( @files ){
	$job->add_file( mp3 => $f );

	my $sug = new Dudl::Suggester( $dudl, $f );

	$sug->add( source => "empty" );
	$sug->add_stor( $f );

	my $id3 = new MP3::Tag( $f );
	if( $id3 ){
		foreach my $tag ( $id3->get_tags ){
			$sug->add( 
				source		=> $tag,
				artist		=> $id3->{$tag}->artist,
				album		=> $id3->{$tag}->album,
				title		=> $id3->{$tag}->song,
				titlenum	=> $id3->{$tag}->track,
				);
		}
	}

	$sug->order;

	my $dat;
	my $sugnum = 0;
	while( (!$opt_max || $sugnum < $opt_max ) &&
	    defined( $dat = $sug->get ) ){
		
		next if $sugnum && $dat->{sug_quality} < $opt_minscore;

		$job->add_title( 
			source	=> $dat->{source}.
				" score: ". $dat->{sug_quality},
			num	=> $dat->{titlenum},
			name	=> $dat->{title},
			artist	=> $dat->{artist},
			genres	=> $opt_genres,
			);

		$sugnum++;
	}
}

$job->write( \*STDOUT );

$dudl->done;
