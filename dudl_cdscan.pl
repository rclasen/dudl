#! /usr/bin/perl -w

# $Id: dudl_cdscan.pl,v 1.8 2002-07-26 17:49:25 bj Exp $


use strict;
use File::Find;
use Getopt::Long;
use Dudl::DB;
use Dudl::Misc;

# Dudl::File elements to update
my @want;
#my @want = qw{ FSUM DSUM };

my $dir;
my $dev;
my $cd;

my $disc;
my @files;

sub usage {
	print "usage: ", $0,
		" [opts] <cdpath> [\"<collection><discid>\"] ...\n",
		" scan one CD mounted at <topdir> for mp3s\n",
 		" get IDtag and add infos to database\n",
		"options:\n",
		"  --eject   open tray when done with CD\n",
		"  --unit    do not scan files\n",
		"  --mp3     scan mp3 information\n",
		"  --sum     calculate md5 sum\n",
		"  --add     add missing files although CD is already in DB\n",
		" if none is specified, --mp3 --sum is assumed.\n",
		"\n",
		"uses cdpath' basename when no discname is specified\n";
}


my $opt_eject;
my $opt_mp3;
my $opt_sum;
my $opt_unit;
my $opt_add;

my $result = GetOptions(
	"eject"		=> \$opt_eject,
	"mp3!"		=> \$opt_mp3,
	"sum!"		=> \$opt_sum,
	"unit!"		=> \$opt_unit,
	"add|a"		=> \$opt_add,
	);
if( ! $result ){
	&usage();
	exit 1;
}

if( !( $opt_mp3 || $opt_sum || $opt_unit )){
	$opt_mp3=1;
	$opt_sum=1;
}

if( $opt_mp3 ){
	push @want, Dudl::File::acquires( "base" );
	push @want, Dudl::File::acquires( "file" );
	push @want, Dudl::File::acquires( "info" );
	push @want, Dudl::File::acquires( "tag" );
}

if( $opt_sum ){
	push @want, Dudl::File::acquires( "sum" );
}


$cd = shift || '';
$cd =~ s:/+$::;
if( ! $cd ){
	print STDERR "missing device/cdpath\n";
	&usage();
	exit 1;
}

if( ! @ARGV && ($cd =~ /([^\/]+)$/) ){
	push @ARGV, $1;
}

if( ! @ARGV ){
	print STDERR "missing collection name(s)\n";
	&usage();
	exit 1;
}

	
my $dudl = new Dudl::DB;

( $dev, $dir ) = get_fstab( $cd );
if( ! $dir ){
	$dir = $cd;
	if( $#ARGV > 0 ){
		print STDERR 
			"cannot scan multiple units when $cd is no CD-ROM\n";
		exit 1;
	}
}

$dir .= "/";
$dir =~ s:/+:/:g;

print "going to scan ". ($#ARGV +1) ." CDs in \"". $dir ."\"\n";



&cd_umount( $dev, 0 );

foreach $disc ( @ARGV ){
	print "scaning unit: ", $disc,"\n";
	&cd_mount( $dev, $disc );

	&scan( $dev, $dir, $disc, ! $opt_unit );
	$dudl->commit || die;

	&cd_umount( $dev, $opt_eject );
}






sub scan {
	my $dev		= shift;
	my $dir		= shift;
	my $disc	= shift;
	my $dofiles	= shift;

	my $collection;
	my $discid;

	if( 2 != ( ( $collection, $discid ) = ($disc =~ m/(\D+)(\d+)/ ))){
		print STDERR "invalid collection or id: $disc\n";
		return;
	}




	my $unit = $dudl->newunit;
	$unit->get_collection( $collection, $discid );

	if( $dev ){
		$unit->acquire( $dev );
	}

	my $id;
	my $add_files = 0;
	if( $unit->id  ){
		$id = $unit->update;
	} else {
		$id = $unit->insert;
		$add_files ++;
	}

	if( ! $id ){
		die;
	}
	print "unit id: ". $id ."\n";
	

	$add_files ++ if $opt_add;

	if( $dofiles ){
		my $dlen = length($dir);
		my $file = $unit->newfile;
		$file->want( \@want );


		print "searching for mp3s in \"$dir\"\n";
		#@files = ();
		#&finddepth(\&want_file, $dir );
		@files = `find $dir -type f -iname "*.mp3"`;


		# TODO: scan for filenames not ending in .mp3

		print "analyzing mp3s\n";
		foreach (@files){
			chomp;

			my $relpath = substr($_, $dlen );
			print "$relpath ...";

			$file->get_path( $relpath );
			if( ! $file->acquire( $dir, $relpath ) ){
				die "cannot get file details";
			}

			if( $file->id ){
				print " updating";
				$id = $file->update;
			} else {
				die "not adding file to existing unit" 
					unless $add_files;

				print " adding";
				$id = $file->insert;
			}

			if( ! $id ){
				die;
			}
			print " $id\n";

			$file->clean;
		}
	}
}

sub cd_mount {
	my $dev		= shift;
	my $disc	= shift;

	if( $dev ){
		do {
			print "please insert disc \"$disc\" in $dev: ";
			my $foo = <STDIN>;
		} while( system( "/bin/mount", $dev ));
	}
}

sub cd_umount {
	my $dev		= shift;
	my $eject	= shift;

	if( $dev ){
		if( $eject ){
			system( "eject", $dev );
		} else {
			system( "/bin/umount", $dev );
		}
	}
}




sub want_file {
	print $_ . 	$File::Find::name ."\n";
	if( /\.mp3$/i ){
		push @files, $File::Find::name;
	}
	
	return 0;
	return 1;
}



