#!/usr/bin/perl -w

# $Id: dudl_rename.pl,v 1.9 2001-12-20 16:38:28 bj Exp $

use strict;
use Getopt::Long;
use MP3::Tag;
use MP3::Offset;
use Dudl;
use Dudl::Naming;
use Dudl::Job::Rename;
use Dudl::Job::Archive;

# TODO: write v2 tags

sub usage {
	my $fh = shift;

	print $fh "$0 - [options] [input files]
renames MP3 files and sets their ID3 tag
options:
 --[no]copy    copy file to new name (default: on)
 --[no]delete  delete orgiginal file after copy (default: off)
 --[no]v1      set v1 tag on new copy (default on)
".# --[no]v2      set v2 tag on new copy (default off)
"
 --[no]info    generate info file  (default: on)
 --ifile <n>   override base name of info file

 --help        this help

Notes:
 - RIFF headers are stripped
 - v1/v2 tags are stripped when disabled
 - info files may get used for dudl database imports
";
}

my $dudl = new Dudl;
my $nam = new Dudl::Naming;

my $opt_copy = 1;
my $opt_v1 = $dudl->write_v1;
my $opt_v2 = $dudl->write_v2;
my $opt_delete = 0;

my $opt_info = $dudl->write_job;
my $opt_ifile = $dudl->write_jname;

my $opt_help = 0;
my $needhelp = 0;

if( ! GetOptions(
	"copy|c!"		=> \$opt_copy,
	"delete!"		=> \$opt_delete,
	"v1!"			=> \$opt_v1,
#	"v2!"			=> \$opt_v2,
	"info!"			=> \$opt_info,
	"name|n=s"		=> \$opt_ifile,
	"help!"			=> \$opt_help,
) ){
	$needhelp++;
}

if( ! $opt_v1 && ! $opt_v2 ){
	warn "you have no IDtag version selected";
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




my $job = new Dudl::Job::Rename( naming	 => $nam );
foreach my $f ( @ARGV ){
	$job->read( $f ) || die "error: $!";
}
$job->order;


if( $opt_info && ! &gen_info( $job ) ){
	die "info generation failed";
}

if( $opt_copy && ! &copy( $job ) ){
	die "rename failed";
}

$dudl->done;

exit 0;



sub tag_valid {
	my $tag = shift;
	my $val = shift;

	if( ! $val ){
		return 1;
	}

	if( length( $tag ) > 30 ){
		warn "tag '$tag' too long";
	}
	# TODO: invalid chars

	return 1;
}


sub write_info {
	my $out = shift;

	if( $out->album ){
		my $dir = $nam->dir( $out->album );
		print STDERR "generate archive jobfile in $dir ...\n";

		&make_dir( $dir ) || die "cannot mkdir: $!";
		local *OUT;
		open( OUT, ">$dir/$opt_ifile" ) ||
			die "open failed: $!";
		$out->write( \*OUT );
		close( OUT );
	}

	return 1;
}

sub gen_info {
	my $in = shift;

	$in->rewind;

	my $out = new Dudl::Job::Archive( naming => $nam );
	while( my($alb,$fil,$tit) = $in->next ){
		if( ! exists $alb->{gen_info} ){
			$alb->{gen_info} = 1;

			&write_info( $out ) || return;

			$out = new Dudl::Job::Archive( naming => $nam );
			$out->add_album( %$alb );
		}

		if( ! exists $fil->{gen_info} ){
			$fil->{gen_info} = 1;

			$out->add_file( %$fil );

			my $fname = $nam->fname( $alb, $tit );
			$out->file->{mp3} = $fname
		}

		$out->add_title( %$tit );
	}
	&write_info( $out ) || return;

	return 1;
}

sub copy {
	my $in = shift;


	$in->rewind;
	my $oalb;
	my $onum;
	my $err = 0;
	while( my($alb,$fil,$tit) = $in->next ){
		if( !defined($oalb) || $oalb != $alb ){
			print STDERR "copying ", $alb->{type}," '", $alb->{name}, "' ...\n";
			$oalb = $alb;
			$onum = 0;
		}
		if( ++$onum != $tit->{num} ){
			warn "unexpected title number: ", $tit->{num};
			$err++;
		}
		$onum = $tit->{num};

		&copy_file( $fil->{mp3}, $alb, $tit ) || return;
	}

	return 1 unless $opt_delete;

	if( $err ){
		warn "warnings found, not deleting input files";
		return 1;
	}

	$in->rewind;
	while( my($alb,$fil,$tit) = $in->next ){
		unlink( $fil->{mp3} ) || warn "unlink failed: $!";
	}

	return 1;
}

sub copy_file {
	my $ifile = shift;
	my $album = shift;
	my $title = shift;

	printf STDERR " %2d ". $ifile, $title->{num};

	my $dir = $nam->dir( $album );
	&make_dir( $dir ) || die "mkdir failed: $!";

	my $fname = $nam->fname( $album, $title );
	my $mp = new MP3::Offset( $ifile );
	
	# file anlegen
	local *OUT;
	open( OUT, ">$dir/$fname" ) || die "cannot open output: $!";
	close( OUT );

	if( $opt_v2 ){
		&write_v2( "$dir/$fname", $album, $title ) || 
			die "cannot write id3v2 tag";
	}

	local *IN;
	open( IN, $ifile ) || die "cannot open input: $!";
	seek( IN, $mp->offset, 0 );

	# copy data
	open( OUT, "+>$dir/$fname" ) || die "cannot open output: $!";
	{
		my $buf;
		read( IN, $buf, $mp->dsize ) || die "cannot read: $!";
		print OUT $buf;
	}
	close( IN );
	close( OUT );

	if( $opt_v1 ){
		&write_v1( "$dir/$fname", $album, $title ) || 
			die "cannot write id3v2 tag";
	}

	print "\n";
	return 1;
}

sub make_dir {
	my $dir = shift;

	if( ! -d $dir ) { 
		mkdir( $dir, 0777 ) || return 0;
	}

	return 1;
}

sub write_v1 {
	my $fname = shift;
	my $album = shift;
	my $title = shift;
	
	my $t = new MP3::Tag( $fname ) || return;
	my $v1 = $t->new_tag( 'ID3v1' ) || return;

	# TODO: check with tag_valid?

	$v1->song( $title->{name} );
	$v1->artist( $title->{artist} );
	$v1->album( $album->{name} );
	$v1->comment( $title->{cmt} );
	$v1->year( $title->{year} );
	$v1->genre( $title->{genres} );
	$v1->track( $title->{num} );

	$v1->writeTag() || return;
	$t->close();

	return 1;
}

sub write_v2 {
	my $fname = shift;
	my $album = shift;
	my $title = shift;
	
	my $t = new MP3::Tag( $fname ) || return; 
	my $v2 = $t->new_tag( 'ID3v2' ) || return;

	#$v2->add_frame( qw( TIT2 TPE1 TALB COMM TYER TCON TRCK ) );
	$v2->add_frame( "TIT2", $title->{name} );
	$v2->add_frame( "TPE1", $title->{artist} );
	$v2->add_frame( "TALB", $album->{name} );
	$v2->add_frame( "COMM", $title->{cmt} );
	$v2->add_frame( "TYER", $album->{year} );
	$v2->add_frame( "TCON", $album->{genres} );
	$v2->add_frame( "TRCK", $album->{num} );

	$v2->write_tag() || return;
	$t->close();
	return 1;
}


