#!/usr/bin/perl -w

use strict;
use Dudl;
use Getopt::Long;

sub usage {
	print 
"$0 [opt] [<where>]
 export   really export
 show     show what will get exported (default)
 all      show what each way of export would result in
";
}

my $opt_export;
my $opt_show;
my $opt_all;

if( ! GetOptions( 
	"export!"	=> \$opt_export,
	"show!"		=> \$opt_show,
	"all!"		=> \$opt_all,
	)){
	&usage();
	exit 1;
}

my $where = shift;
if( ! $opt_all ){
	if( defined $where && $where ){
		$where .= " AND";
	}
	$where .= " ( export > 1 )";
}

my @regexps;

my $dudl = Dudl->new;
my $db = $dudl->db;


my( 
	$id, 
	$export,
	$dir,
	$fname,
	$id_title,
	$id_artist,
	$id_album,
	$id_tracknum,
	);

&get_dbre;
&do_dbfiles;


$dudl->commit or die $db->errstr;

$dudl->done;


exit 0;







sub get_dbre {
	my $query = 
		"SELECT ".
			"id, ".
			"regexp, ".
			"fields ".
		"FROM stor_export ";
	my $dbre = $db->prepare( $query );
	if( ! $dbre ){
		die "query failed: ". $query ."\n". $db->errstr;
	}
	if( ! $dbre->execute ){
		die "query failed: ". $query ."\n". $dbre->errstr;
	}

	my(
		$id,
		$regexp,
		$fields
		);
	
	$dbre->bind_columns( \(
		$id,
		$regexp,
		$fields
		));

	while( $dbre->fetch ){
		$regexp = "" unless defined $regexp;
		$fields = "" unless defined $fields;

		$regexps[$id] = {
			re	=> $regexp,
			fields	=> {},
			};

		my @f = split /\s*,\s*/, $fields;
		foreach( 0..$#f ){
			if( defined $f[$_] && $f[$_] ){
				$regexps[$id]{fields}{$f[$_]} = $_;
			}
		}
	}

	$dbre->finish;
}



sub do_dbfiles {
	my $query = 
		"SELECT ".
			"id, ".
			"export, ".
			"dir, ".
			"fname, ".
			"id_title, ".
			"id_artist, ".
			"id_album, ".
			"id_tracknum ".
		"FROM stor_file ";
	if( defined $where && $where ){
		$query .= "WHERE $where";
	}

	my $dbfiles = $db->prepare( $query );
	if( ! $dbfiles ){
		die "query failed: ". $query ."\n". $db->errstr;
	}
	if( ! $dbfiles->execute ){
		die "query failed: ". $query ."\n". $dbfiles->errstr;
	}

	$dbfiles->bind_columns( \( 
		$id, 
		$export,
		$dir,
		$fname,
		$id_title,
		$id_artist,
		$id_album,
		$id_tracknum,
		));

	if( $opt_show || $opt_all ){
		&head;
	}

	while( $dbfiles->fetch ){
		if( $opt_all ){
			foreach( 0..$#regexps ){
				&show( &get_one( $_ ));
			}
		} else {
			my $exp = &get_one( $export );

			if( $opt_show ){
				&show(  $exp );
			}

			if( $opt_export ){
				&export( $exp );
			}
		}
	}

	$dbfiles->finish;
}




sub get_one {
	my $export = shift;

	if( $export == 2 ){
		return &get_idtag;
	}

	return &get_regexp( $export );
}

sub get_idtag {
	return( {
		artist		=> (defined $id_artist) ? $id_artist :"", 
		album		=> (defined $id_album) ? $id_album :"", 
		tracknum	=> (defined $id_tracknum) ? $id_tracknum :"", 
		title		=> (defined $id_title) ? $id_title :"",
		});
}

sub get_regexp {
	my $reid = shift;

	my $path = $dir ."/". $fname;
	my $re = $regexps[$reid]{re} ."\\.mp3\$";
	my $fields = $regexps[$reid]{fields};

	my @match = $path =~ m:$re:i;

	return( {
		artist		=> 
			( exists $fields->{artist} && 
			defined $match[$fields->{artist}] ) ?
			"$match[$fields->{artist}]" : "",
		album		=> 
			( exists $fields->{album} && 
			defined $match[$fields->{album}] ) ?
			"$match[$fields->{album}]" : "",
		titlenum	=> 
			( exists $fields->{titlenum} && 
			defined $match[$fields->{titlenum}] ) ?
			"$match[$fields->{titlenum}]" : "",
		title		=> 
			( exists $fields->{title} && 
			defined $match[$fields->{title}] ) ?
			"$match[$fields->{title}]" : "",
		});
}


sub head {
	printf "%5s|%2s|%32s|%32s|%32s|%s\n", 
		"id", "tn", 
		"artist", "album", "title", 
		"path";
};

sub show {
	my $hr	= shift;

	return unless ref($hr);
	if( exists $hr->{artist} && defined $hr->{artist} && $hr->{artist} && 
		exists $hr->{title} && defined $hr->{title} && $hr->{title} ){
	printf "%5s|%2s|%32s|%32s|%32s|%s\n", 
		$id, $hr->{titlenum},
		$hr->{artist}, $hr->{album}, $hr->{title},
		$dir ."/". $fname;
	}
};

