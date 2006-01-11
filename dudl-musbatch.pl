#!/usr/bin/perl -w

# $Id: dudl-musbatch.pl,v 1.3 2006-01-11 11:28:47 bj Exp $

# alle auf einer CD gefundenen alben/directories aus der file-Datenbank in
# Musik Datenbank überführen.

use strict;
use Getopt::Long;
use Dudl::DB;
use Dudl::StorUnit;
use File::Temp qw( tempfile );

$ENV{EDITOR} ||= "vi";
$ENV{TMPDIR} ||= "/tmp";

my $dudl = Dudl::DB->new;
my $cdpath = $dudl->conf("cdpath");
my $afile = $dudl->conf("write_jname");

my $unit;
my $opt_pickdirs;
my $opt_manual;

my $needhelp;
my $wanthelp;

if( ! GetOptions(
	"help|h!"	=> \$wanthelp,
	"pickdirs|p!"	=> \$opt_pickdirs,
	"manual|m!"	=> \$opt_manual,
)){
	$needhelp++;
}

if( $#ARGV == 0 ){
	$unit = shift;
	if( $unit !~ /^(\w+)(\d+)$/ ){
		print STDERR "invalid unit specifier\n";
		$needhelp++;
	}
} else {
	print STDERR "invalid number of arguments\n";
	$needhelp++;
}

if( $wanthelp ){
	print <<EOF;
usage: $0 <unit>
EOF
	exit 0;
}

if( $needhelp ){
	print STDERR "use --help for usage info\n";
	exit 1;
}

# step1: 
# build list with directories and let user decide which to process

# TODO: make dudl_musdirs a module and use it directly
my($tit, $fil, $unitid, $dir);
my( $tfh, $tfn ) = tempfile;
open( DFH, "dudl_musdirs.pl $unit|" ) or die "open(dudl_musdirs): $!";
# header:
$_ = <DFH>; 
print $tfh $_;
# rest:
while(<DFH>){
	chomp;
	s/^\s+//;
	($tit, $fil, $unitid, $dir) = split /\s+/,$_,4;
	if( $tit ){
		print STDERR "skipping non-virgin '$dir'\n";
		next;
	}
	printf $tfh "%4s %4d %7d %s\n", $tit, $fil, $unitid, $dir;
}
close(DFH);
close($tfh);

if( $opt_pickdirs ){
	system( "$ENV{EDITOR} \"$tfn\"" ) and die "open(editor): $!";
}

# step2:
# read directory list and process each directory

open( FH, "$tfn" ) or die "open: $!";
$_ = <FH>; # skip header
while(<FH>){
	chomp;
	s/^\s+//;
	($tit, $fil, $unitid, $dir) = split /\s+/,$_,4;
	&dodir( $unitid, $dir ) && last;
}
close(FH);

unlink($tfn);




sub dodir {
	my( $unitid, $dir ) = @_;

	# TODO: make dudl_musgen a module and use it directly
	# TODO: make dudl_musimport a module and use it directly

	print "\n\nprocessing $dir...\n";

	my $unit = Dudl::StorUnit->load( dudl => $dudl,
		where => { id => $unitid } );
	my $jobpath = $cdpath ."/". $unit->dir ."/$dir/$afile";

	my $needuser;
	-r $jobpath || $needuser++;
	$opt_manual && $needuser++;



	my( $doexit, $donext );
	my $tfn;
	do {

		# create/rebuild jobfile
		if( ! $tfn ){
			my $tfh;
			( $tfh, $tfn ) = tempfile;
			open( GFH, "dudl_musgen.pl \"$unitid\" \"$dir\"|" ) 
				or die "open(dudl_musgen): $!";
			while( <GFH> ){
				print $tfh $_;
			}
			close(GFH);
			close($tfh);
		}

		# edit jobfile / decide what to do
		my $reply;
		if( ! $needuser ){
			$reply = "i";
			$needuser++;

		} else {
			system( "$ENV{EDITOR} \"$tfn\"" ) and die "open(editor): $!";
			do {
				print <<EOP;
what shall I do?
 r - re-generate list loosing your changes
 e - re-edit list
 i - add list to database
 n - skip to next
 x - exit
EOP

				$reply = <>;
				chomp $reply;
			} until $reply =~ /^[reinx]$/;
		}


		# ACTION!
		if( $reply eq "r" ){
			unlink( $tfn );
			$tfn = undef;

		} elsif( $reply eq "e" ){
			# next round

		} elsif( $reply eq "i" ){
			print "importing $dir...\n";
			if( 0 == system( "dudl_musimport.pl", $tfn ) ){
				$donext++;
			} else {
				print "press ENTER to continue\n";
				<>;
			}

		} elsif( $reply eq "n" ){
			$donext++;

		} elsif( $reply eq "x" ){
			$doexit++;
		}

	} until( $doexit or $donext );

	unlink $tfn if $tfn;

	return( $doexit ? 1 : 0 );
}

