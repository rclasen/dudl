#! /usr/bin/perl -w


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
	print "  --unit    do not scan files\n";
	print "  --mp3     scan mp3 information\n";
	print "  --sum     calculate md5 sum\n";
	print " if none is specified, --mp3 --sum is assumed.\n";
}


my $opt_mp3;
my $opt_sum;
my $opt_unit;

my $result = GetOptions(
	"mp3!"		=> \$opt_mp3,
	"sum!"		=> \$opt_sum,
	"unit!"		=> \$opt_unit,
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
my $dlen = length($dir);

print "going to scan ". ($#ARGV +1) ." CDs in \"". $dir ."\"\n";




foreach $disc ( @ARGV ){
	my $collection;
	my $discid;

	if( 2 != ( ( $collection, $discid ) = ($disc =~ m/(\D+)(\d+)/ ))){
		print STDERR "invalid collection or id: $disc\n";
		next;
	}




	my $unit = $dudl->newunit;
	$unit->get_collection( $collection, $discid );

	if( $dev ){
		system( "/bin/umount", $dev );

		do {
			print "please insert disc \"$disc\" in $dev: ";
			my $foo = <STDIN>;
		} while( system( "/bin/mount", $dev ));

		$unit->acquire( $dev );
	}

	my $id;
	if( $unit->id  ){
		$id = $unit->update;
	} else {
		$id = $unit->insert;
	}

	if( ! $id ){
		die;
	}
	print "unit id: ". $id ."\n";
	
	next if $opt_unit;




	print "searching for mp3s in \"$dir\"\n";
	#@files = ();
	#&finddepth(\&want_file, $dir );
	@files = `find $dir -type f -iname \*.mp3`;

	print "analyzing mp3s\n";
	my $file = $unit->newfile;
	$file->want( \@want );

	my $errs = 0;


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
			print " adding";
			$id = $file->insert;
		}

		if( ! $id ){
			die;
		}
		print " $id\n";

		$file->clean;
	}
	$dudl->commit || die;

}

$dudl->done;



sub want_file {
	print $_ . 	$File::Find::name ."\n";
	if( /\.mp3$/i ){
		push @files, $File::Find::name;
	}
	
	return 0;
	return 1;
}



