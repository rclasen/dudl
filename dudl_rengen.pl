#!/usr/bin/perl -w

# $Id: dudl_rengen.pl,v 1.13 2001-12-20 16:38:28 bj Exp $

# TODO: suggest album, too
# TODO: get suggestions from freedb

use strict;
use Getopt::Long;
use Dudl;
use Dudl::Suggester;
use Dudl::Job::Rename;

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


my @files = $dudl->arg_files( \@ARGV );

my %album;
my $job = new Dudl::Job::Rename;


$job->add_album(
	name	=> "",
	artist	=> "VARIOUS",
	type	=> "sampler",
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
		$sug->add_id3( $f );
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

		$album{name}{$dat->{album}}++ if $dat->{album};
		$album{artist}{$dat->{artist}}++ if $dat->{artist};

		$sugnum++;
	}
}

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

