#!/usr/bin/perl -w

# $Id: dudl_rengen.pl,v 1.8 2001-12-13 16:38:21 bj Exp $

# TODO: suggest album, too
# TODO: get suggestions from freedb

use strict;
use Getopt::Long;
use Dudl;
use Dudl::Suggester;
use Dudl::Job::Rename;
use MP3::Tag;

my $dudl = new Dudl;

my $opt_max = $dudl->sug_max;
my $opt_minscore = $dudl->sug_score;
my $opt_id = $dudl->sug_id3;
my $opt_stored = $dudl->sug_int;
my $opt_regexp = "";
my $opt_genres = "";

my $opt_help = 0;
my $needhelp = 0;

my $regexp;

sub usage {
	print { $_[0] } "$0 [opts] <filenames> ...
generate job file for dudl_rename.pl
optons:
 --max <n>       maximum number of suggestions per file
 --minscore <n>  minimum score suggestions must have
 --genres <g>    list default genres to use
 --re|regexp <r> use this regexp for suggestions. 
 --[no]stored    use stored regexps for suggestions
 --[no]id        use ID tag for suggestions

 --help          this help

reads filenames from stdin when there are none on the cmdline

regexp example:
 titles: <artist>.--.<album>/<artist>.--._<num>_<title>.mp3
 regexp: album,artist,titlenum,title=\\.--\\.(.*)/(.*)\\.--\\.(..)_(.*)

use (?:<pattern>) to group without marking results or use ',,' in the 
field list to ignore a match.
";
}


if( !GetOptions(
	"max=i"		=> \$opt_max,
	"minscore=i"	=> \$opt_minscore,
	"genres=s"	=> \$opt_genres,
	"regexp|re=s"	=> \$opt_regexp,
	"stored!"	=> \$opt_stored,
	"id!"		=> \$opt_id,
	"help|h!"	=> \$opt_help,
)){
	$needhelp++;
}

if( $opt_regexp ){
	$regexp = &get_regexp( $opt_regexp );
	if( ! $regexp ){
		print STDERR "invalid regexp\n";
		$needhelp++;
	}
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

my $job = new Dudl::Job::Rename;

$job->add_album(
	name	=> "",
	artist	=> "VARIOUS",
	);

foreach my $f ( @files ){
	$job->add_file( mp3 => $f );

	my $sug = new Dudl::Suggester;

	$sug->add( source => "empty" );
	if( $opt_stored ){
		$sug->add_stor( $f );
	}
	if( $regexp ){
		$sug->add_regexp( $f, $regexp->{re}, 
			$regexp->{fields}, "cmdline" );
	}

	if( $opt_id ){
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


sub get_regexp {
	my $re = shift;

	my $regexp = {};

	my( $fields, $pattern ) = $re =~ /([^=]*)=(.*)/;

	my $dummy ="";
	eval { $dummy =~ /$pattern/ };
	if( $@ ){
		print $@;
		return;
	}

	$regexp->{re} = $pattern;

	my @f = split /\s*,\s*/, $fields;
	foreach( 0..$#f ){
		next unless( defined $f[$_] && $f[$_] );

		if( $f[$_] eq "title" ){
		} elsif( $f[$_] eq "titlenum" ){
		} elsif( $f[$_] eq "album" ){
		} elsif( $f[$_] eq "artist" ){
		} else {
			return;
		}

		$regexp->{fields}{$f[$_]} = $_;
	}

	return $regexp;
}

