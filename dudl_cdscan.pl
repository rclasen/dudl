#! /usr/bin/perl -w

# $Id: dudl_cdscan.pl,v 1.5 2001-12-13 11:41:48 bj Exp $


use strict;
use File::Find;
use Getopt::Long;
use Dudl;

# Dudl::File elements to update
my @want;
#my @want = qw{ FSUM DSUM };

my $dir;
my $dev;
my $cd;

my $disc;
my @files;

sub usage {
	print "usage: ". $0 ." [opts] <cdpath> \"<collection><discid>\" ...\n";
	print " scan one CD mounted at <topdir> for mp3s\n";
 	print " get IDtag and add infos to database\n";
	print " options:\n";
	print "  --eject   open tray when done with CD\n";
	print "  --unit    do not scan files\n";
	print "  --mp3     scan mp3 information\n";
	print "  --sum     calculate md5 sum\n";
	print "  --add     add missing files although CD is already in DB\n";
	print " if none is specified, --mp3 --sum is assumed.\n";
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
	"add|a"		=> \$opt_add;
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


$cd = shift;
if( ! $cd ){
	print STDERR "missing device/cdpath\n";
	&usage();
	exit 1;
}

if( $#ARGV < 0 ){
	print STDERR "missing collection name(s)\n";
	&usage();
	exit 1;
}

	
my $dudl = Dudl->new;

( $dev, $dir ) = $dudl->get_fstab( $cd );
if( ! $dir ){
	$dir = $cd;
	if( $#ARGV > 0 ){
		print STDERR 
			"cannot scan multiple units when $cd is no CD-ROM\n";
		$dudl->done;
		exit 1;
	}
}

$dir .= "/";
$dir =~ s:/+:/:g;

print "going to scan ". ($#ARGV +1) ." CDs in \"". $dir ."\"\n";



&cd_umount( $dev, 0 );

foreach $disc ( @ARGV ){
	&cd_mount( $dev, $disc );

	&scan( $dev, $dir, $disc, ! $opt_unit );
	$dudl->commit || die;

	&cd_umount( $dev, $opt_eject );
}

$dudl->done;





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
	

	$add_file ++ if $opt_add;

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
					unless $add_file;

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



