#!/usr/bin/perl -w

# generate directory trees for mserv
# - symlinks
# - .trk info files

use strict;
use Getopt::Long;
use Dudl;
use Dudl::Unit;

my $opt_help = 0;
my $opt_msdir = ".";
my $opt_what = "all";
my $needhelp = 0;

my $want_sym = 0;
my $want_nfo = 0;

sub usage {
	my $fh = shift;
	print $fh "usage: $0 [opts]
generate mserv directory trees
 --mserv-dir|--dir <dir>   default: '.'
 --what <what>             all|symlinks|info, default: all
 --help
";
}


if( ! GetOptions(
	"help|h!"		=> \$opt_help,
	"mserv-dir|dir|d=s"	=> \$opt_msdir,
	"what|w=s"		=> \$opt_what,
) ){
	$needhelp ++;
}

if( ! -d $opt_msdir ){
	$needhelp ++;
	print STDERR "mserv-dir doesn't exist\n";
}
my $dir_sym = $opt_msdir ."/tracks";
my $dir_nfo = $opt_msdir ."/trackinfo";

if( $opt_what =~ /^a(l(l)?)?$/i ){
	$want_sym = 1;
	$want_nfo = 1;
} elsif( $opt_what =~ /^(s(y(m(l(i(n(k(s)?)?)?)?)?)?)?|tracks)$/i ){
	$want_sym = 1;
} elsif( $opt_what =~ /^(i(n(f(o)?)?)?|tracki(n(f(o)?)?)?)$/i ){
	$want_nfo = 1;
} else {
	$needhelp ++;
	print STDERR "invalid argument to --what\n";
}

if( $opt_help ){
	&usage( \*STDOUT );
	exit 0;
}

if( $needhelp ){
	&usage( \*STDERR );
	exit 1;
}

my $dudl = Dudl->new;
my $db = $dudl->db;

if( ! -d $dir_sym ){
	mkdir $dir_sym, 0777 || die "mkdir('$dir_sym'): $!";
}

if( ! -d $dir_nfo ){
	mkdir $dir_nfo, 0777 || die "mkdir('$dir_nfo'): $!";
}

my $query = "
SELECT 
	ala.nname, 
	al.album, 
	ti.id, 
	ti.nr, 
	ti.title, 
	tia.nname, 
	ti.genres,
	ti.random, 
	su.collection, 
	su.colnum, 
	fi.dir, 
	fi.fname,
	date_part('epoch',fi.duration) AS dur
FROM 
	mus_album al,
	mus_artist ala, 
	mus_title ti, 
	mus_artist tia, 
	stor_file fi, 
	stor_unit su
WHERE 
	al.artist_id = ala.id AND 
	al.id = ti.album_id AND 
	ti.artist_id = tia.id AND 
	ti.id = fi.titleid AND 
	fi.unitid = su.id AND 
	NOT fi.broken
ORDER by 
	ala.nname, 
	al.album,
	ti.nr;
";

my $sth = $db->prepare( $query );
if( ! $sth ){
	die $db->errstr ."\nquery: $query\n";
}

my $res = $sth->execute;
if( ! $res ){
	die $sth->errstr ."\nquery: $query\n";
}

my (
	$al_artist, 
	$al_album, 
	$ti_id, 
	$ti_nr, 
	$ti_title, 
	$ti_artist, 
	$ti_genres,
	$ti_random, 
	$su_col, 
	$su_colnum, 
	$fi_dir, 
	$fi_fname,
	$fi_dur,
);
$sth->bind_columns( \( 
	$al_artist, 
	$al_album, 
	$ti_id, 
	$ti_nr, 
	$ti_title, 
	$ti_artist, 
	$ti_genres,
	$ti_random, 
	$su_col, 
	$su_colnum, 
	$fi_dir, 
	$fi_fname,
	$fi_dur,
) );

my $old_apath = "";
my $old_basepath = ""; 

while( defined $sth->fetch ){
	my $apath = $al_artist;
	$apath =~ s/\W+/./g;

	if( $old_apath ne $apath ){
		if( $want_sym ){
			mkdir "$dir_sym/$apath", 0777 ||
				die "mkdir('$dir_sym/$apath'): $!";
		}
		if( $want_nfo ){
			mkdir "$dir_nfo/$apath", 0777 ||
				die "mkdir('$dir_nfo/$apath'): $!";
		}
		$old_apath = $apath;
	}

	my $basepath = $al_album;
	$basepath =~ s/\W+/./g;
	$basepath = $apath ."/". $basepath;

	if( $old_basepath ne $basepath ){
		if( $want_sym ){
			mkdir "$dir_sym/$basepath", 0777 ||
				die "mkdir('$dir_sym/$basepath'): $!";
		}
		if( $want_sym ){
			mkdir "$dir_nfo/$basepath", 0777 ||
				die "mkdir('$dir_nfo/$basepath'): $!";
			open( A, ">$dir_nfo/$basepath/album" ) ||
				die "open('$dir_nfo/$basepath/album'): $!";
			print A "_author=$al_artist\n";
			print A "_name=$al_album\n";
			close A;
		}
		$old_basepath = $basepath;

	} elsif( $old_id == $ti_id ){
		# skip duplicate files for titles
		next;

	}
	$old_id = $ti_id;

	$su_col =~ s/\s+$//;
	$ti_nr = sprintf "%02d", $ti_nr;

	my $relpath = "$ti_nr.$ti_artist.$ti_title.mp3";
	$relpath =~ s/\W+/./g;
	$relpath = $basepath ."/". $relpath;

	if( $want_sym ){
		my $file = &Dudl::Unit::mkpath( $dudl->cdpath, 
			$su_col, $su_colnum);
		$file .= "/$fi_dir" if $fi_dir;
		$file .= "/$fi_fname";

		symlink $file, "$dir_sym/$relpath";
	}

	if( $want_nfo ){
		if( $ti_random ){
			$ti_genres .= "," if $ti_genres;
			$ti_genres .= "random";
		}

		# TODO: update, not overwrite
		open( T, ">$dir_nfo/$relpath.trk" )||
			die "open('$dir_nfo/$relpath.trk'): $!";
		print T "_author=$ti_artist\n";
		print T "_name=$ti_title\n";
		print T "_year=0\n";
		print T "_genres=$ti_genres\n";
		print T "_lastplay=0\n";
		print T "_duration=0\n";
		print T "_miscinfo=128kbps\n";
		close T;
	}

}	

$sth->finish;

# TODO: delete obsolete files

$dudl->done();

