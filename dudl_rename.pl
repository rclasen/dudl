#!/usr/bin/perl -w

# v0.0.1.1 - 2001-11-27
#	* major rewrite
#	* read everything before doing something
#	* info file generation
#	* riff header stripping / copying of files
#	* id3v2 tags - klappt nich :-((
#	* commandline options
# v0.0.0.4 - 2001-11-12
#	* strip v2 tags
#	* fix permissions
# v0.0.0.3 - 2001-06-18
#	* pass -- to mv
# v0.0.0.2 - 2000-12-26
#	* use MP3::Info
# v0.0.0.1 - 2000-08-27 20:18
#	* release

# rename mp3s an edit their ID-Tag.

#syntax of input file(s):

# A <albumtitle>	#
# S			# album is a sampler  (reset for A)
# G <groupname>		#
# F <oldname>		#
# N <index>		# position on a CD
# T <tile>		# and finally rename the file
# C <comment>
# Y <year>
# E <genre>
#
# comment *lines* are introduced with a # sign
# you can not use # to comment out the remaining part of a line

# NOTES: 
#  - you need to strip the leading "#" from the example *g*
#  - whitespaces at line begin/end and after the command letter are ignored
#  - each setting remains unaffected until it is reset (except S)
#  - a new album/title is started with either A or F
#  - add other tags to complete necessary information

# example:
# A kill em all
# G metallica
#
# F blahblubgfsdghj.mp3
# N1
# T hit the lights
#
# #### stuff snipped ###
#
# A reload
#
# F fsafd f sdf.mp3
# N1
# T	fuel
#
# F fdasf.mp3
# N2
# C ein kommentar
# Y 2000
# T titel
# E Metal
#
# F fdsa.mp3
# N3
# T blah

use strict;
use lib "/home/bj/src/work/nccdev/dudl";
use Getopt::Long;
use MP3::Tag;
use Mp3sum;


sub usage {
	my $fh = shift;

	print $fh "$0 - [options] [input files]
renames MP3 files and sets their ID3 tag
options:
 --copy        copy file to new name (default: on)
 --delete      delete orgiginal file after copy (default: off)
 --v1          set v1 tag on new copy (default on)
 --v2          set v2 tag on new copy (default off)

 --info        generate info file  (default: on)

 --help        this help

Notes:
 - RIFF headers are stripped
 - v1/v2 tags are stripped when disabled
 - info files may get used for dudl database imports
";
}

my $opt_copy = 1;
my $opt_v1 = 1;
my $opt_v2 = 0;
my $opt_delete = 0;

my $opt_info = 1;

my $opt_help = 0;
my $needhelp = 0;

if( ! GetOptions(
	"copy|c!"		=> \$opt_copy,
	"delete!"		=> \$opt_delete,
	"v1!"			=> \$opt_v1,
#	"v2!"			=> \$opt_v2,
	"info!"			=> \$opt_info,
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




my @data;

if( &collect( \@data ) ){
	die "too many errors";
}

if( $opt_info && &gen_info( \@data ) ){
	die "info generation failed";
}

if( $opt_copy && &copy( \@data ) ){
	die "rename failed";
}

exit 0;



sub collect {
	my $data = shift;

	my $do_album = 1;
	my $errors = 0;

	# current album
	my %album = (
		album	=> '',
		artist	=> '',
		sampler	=> '',
		titles	=> [],
		);

	# current title
	my %title = (
		file	=> '',
		title	=> '',
		artist	=> '',
		tnum	=> 0,

		year	=> 0,
		genre	=> '',
		comment	=> '',
		random	=> 1,
		);

	while( <> ){
		# strip trailing cr
		chomp;
		# strip comments
		s/^\s*#.*//;
		# strip leading whitespace
		s/^\s*//;
		# skip empty lines
		next if /^$/;


		/^(.)\s*(.*)\s*/;

		if( $1 eq "A" ){
			if( $album{album} ){
				if( &album_error( \%album ) ){
					$errors++;
				} else {
					push @$data, { %album };
				}
			}

			$album{album} = $2;
			$album{titles} = [];
			$album{sampler} = 0;
			
			$do_album = 1;
			next;

		} elsif( $1 eq "F" ) {
			if( $title{file} ){
				if( &title_error( \%title )){
					$errors++;
				} else {
					push @{$album{titles}}, { %title };
				}
			}
			
			$title{file} = $2;
			$title{tnum} = 0;

			$do_album = 0;
			next;

		} elsif( $1 eq "S" ){
			if( $do_album ){
				$album{sampler} = 1;
				$album{artist} = 'VARIOUS';
				$title{artist} = '';
			} else {
				warn "ignoring S tag in line $.";
				$errors++;
			}
			next;

		} elsif( $1 eq "G" ){
			if( $do_album ){
				$album{artist} = $2;
			}
			$title{artist} = $2;
			next;

		} elsif( $1 eq "N" ){
			$title{tnum} = $2;
			next;

		} elsif( $1 eq "C" ){
			$title{comment} = $2;
			next;

		} elsif( $1 eq "Y" ){
			$title{year} = $2;
			next;

		} elsif( $1 eq "E" ){
			$title{genre} = $2;
			next;

		} elsif( $1 eq "T" ){
			$title{title} = $2;
			next;

		} elsif( $1 eq "R" ){
			$title{random} = $2;
			next;

		} else {
			warn "invalid tag in line $.";
			next;
		}
	}

	if( $title{file} ){
		if( &title_error( \%title )){
			$errors++;
		} else {
			push @{$album{titles}}, { %title };
		}
	}

	if( $album{album} ){
		if( &album_error( \%album ) ){
			$errors++;
		} else {
			push @$data, { %album };
		}
	}

	return $errors;
}

sub album_error {
	my $alb = shift;

	my $errors = 0;
	foreach my $f ( qw( album artist ) ){
		if( ! $alb->{$f} ){
			warn "missing tag '$f' in line $.";
			$errors ++;

		} elsif( ! &tag_valid( $alb->{$f} ) ){
			warn "bad tag '$f' in line $.";
			$errors ++;
		}
	}

	return $errors;
}

sub title_error {
	my $tit = shift;

	my $errors = 0;
	foreach my $f ( qw( title artist tnum file ) ){
		if( ! $tit->{$f} ){
			warn "missing tag '$f' in line $.";
			$errors ++;
		}
	}

	foreach my $f ( keys %$tit ){
		if( ! &tag_valid( $tit->{$f} ) ){
			warn "bad tag '$f' in line $.";
			$errors ++;
		}
	}

	return $errors;
}

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


sub gen_info {
	my $data = shift;

	foreach my $album ( @$data ){
		my $dir = &gen_dirname( $album );
		
		&make_dir( $dir ) || die "cannot mkdir: $!";
		
		local *INF;
		open( INF, ">$dir/info.dudl" ) || 
			die "cannot open info file \"$dir/info.dudl\": $!";

		print INF "album_artist	", $album->{artist}, "\n";
		print INF "album_name	", $album->{album}, "\n";
		print INF "\n";

		foreach my $title ( @{$album->{titles}} ){
			my $fname = &gen_fname( $album, $title );

			print INF "file_name $fname\n";
			print INF "title_num	", $title->{tnum}, "\n";
			print INF "title_name	", $title->{title}, "\n";
			print INF "title_artist	", $title->{artist}, "\n";
			print INF "title_genres	", $title->{genre}, "\n";
			print INF "title_random	", $title->{random}, "\n";
			print INF "\n";
		}
		close( INF );
	}
}

sub copy {
	my $data = shift;

	foreach my $album ( @$data ){

		foreach my $title ( @{$album->{titles}} ){
			&copy_file( $album, $title );
		}
	}
}

sub copy_file {
	my $album = shift;
	my $title = shift;

	my $dir = &gen_dirname( $album );
	&make_dir( $dir ) || die "mkdir failed: $!";

	my $fname = &gen_fname( $album, $title );
	
	# file anlegen
	local *OUT;
	open( OUT, ">$dir/$fname" ) || die "cannot open output: $!";
	close( OUT );

	if( $opt_v2 ){
		&write_v2( "$dir/$fname", $album, $title ) || 
			die "cannot write id3v2 tag";
	}

	local *IN;
	open( IN, $title->{file} ) || die "cannot open input: $!";
	my $mp = new Mp3sum;
	$mp->analyze( \*IN );
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

	if( $opt_delete ){
		unlink( $title->{file} ) || warn "unlink failed: $!";
	}
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

	$v1->song( $title->{title} );
	$v1->artist( $title->{artist} );
	$v1->album( $album->{album} );
	$v1->comment( $title->{comment} );
	$v1->year( $title->{year} );
	$v1->genre( $title->{genre} );
	$v1->track( $title->{tnum} );

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

	$v2->add_frame( qw( TIT2 TPE1 TALB COMM TYER TCON TRCK ) );
	$v2->change_frame( "TIT2", $title->{title} );
	$v2->change_frame( "TPE1", $title->{artist} );
	$v2->change_frame( "TALB", $album->{album} );
	$v2->change_frame( "COMM", $title->{comment} );
	$v2->change_frame( "TYER", $album->{year} );
	$v2->change_frame( "TCON", $album->{genre} );
	$v2->change_frame( "TRCK", $album->{tnum} );

	$v2->write_tag() || return;
	$t->close();
	return 1;
}


sub gen_dirname {
	my $album = shift;

	my $name;
	if( $album->{sampler} ){
		$name = $album->{album};
	} else {
		$name = sprintf( "%s.--.%s", 
			$album->{artist}, 
			$album->{album});
	}

	return &fn_normalize( $name );
}

sub gen_fname {
	my $album = shift;
	my $title = shift;

	my $name;
	if( $album->{sampler} ) {
		# - a sampler, name it 
		# <album>/<nr>_<group>.--.<title> or 
		# <album>/<nr>_<title>
		if( $title->{artist}){
			$name = sprintf( "%02d_%s.--.%s.mp3", 
				$title->{tnum}, 
				$title->{artist}, 
				$title->{title} );
		} else {
			$name = sprintf( "%02d_%s.mp3", 
				$title->{tnum}, 
				$title->{title} );
		}

	} else {
		# - no sampler, name it 
		# <group>.--.<album>/<group>.--.<nr>_<title>
		$name = sprintf( "%s.--.%02d_%s.mp3", 
				$title->{artist}, 
				$title->{tnum}, 
				$title->{title} );
	}

	return &fn_normalize( $name );
}


sub fn_normalize {
	my $foo = shift;

        $foo =~ s/[^a-zäöüßA-ZÖÄÜ0-9_\$()=+-]+/./g;
	$foo =~ s/^\.*(.*)\.*$/$1/;

	if( length( $foo ) > 64 ){
		print "WARINING: \"$foo\" exceeds 64 chars\n";
	}

	return $foo;
}

