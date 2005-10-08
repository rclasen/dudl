#!/usr/bin/perl -w

# check if files marked as unavailable somehow became abailable

use strict;
use Dudl::DB;


my $dudl = Dudl::DB->new;
my $db = $dudl->db;

my ( $enc ) = $db->selectrow_array( "SHOW client_encoding" );
my $topdir = $dudl->conf("cdpath");
my $ukartist = &get_artist("UNKNOWN");


print "step 1: find files that reapeared...\n";
&check_reapear;

print "\nstep 2: find files that vanished...\n";
&check_vanish;

print "\nstep 3: find new files...\n";
&check_autoscan;
exit 0;

sub check_reapear {
	my $res = $db->select( 
			"f.id, ".
			"stor_filename(collection,colnum,dir,fname) AS file ".
		"FROM stor_file f ".
			"INNER JOIN stor_unit u ON f.unit_id = u.id ".
		"WHERE not available" );
	if( ! $res ){
		die $db->errstr;
	}

	my( $id, $fname );
	$res->bind_columns( \$id, \$fname );

	while( $res->fetch ){
		if( -e "$topdir/$fname" ){
			print "reapeared($id): $fname\n";
			if( ! $db->update( "stor_file", 
				{ available => "true" }, 
				"id = $id" )){

				die $db->errstr;
			}
		}
	}
	$db->commit || die $db->errstr;
}


sub check_vanish {
	my $res = $db->select( 
			"f.id, ".
			"stor_filename(collection,colnum,dir,fname) ".
				"AS file ".
		"FROM stor_file f ".
			"INNER JOIN stor_unit u ON f.unit_id = u.id ".
		"WHERE available OR available ISNULL" );
	if( ! $res ){
		die $db->errstr;
	}

	my( $id, $fname );
	$res->bind_columns( \$id, \$fname );

	while( $res->fetch ){
		if( ! -e "$topdir/$fname" ){
			print "vanished($id): $fname\n";
			if( ! $db->update( "stor_file", 
				{ available => "false" }, 
				"id = $id" )){

				die $db->errstr;
			}
		}
	}
	$db->commit || die $db->errstr;
}


sub check_autoscan {

	my $units = $db->select( 
			"id, ".
			"collection, ".
			"colnum, ".
			"stor_unitpath(collection, colnum) AS path ".
		"FROM stor_unit ".
		"WHERE autoscan" );
	if( ! $units ){
		die $db->errstr;
	}

	my( $id, $col, $colnum, $path );
	$units->bind_columns( \( $id, $col, $colnum, $path ));
	while( $units->fetch ){
		my $uname = sprintf "%s%04d", $col, $colnum;
		&clean_uvanished( $id );
		&check_unew( $id, $uname, "$topdir/$path" );
	}
	$units->finish;
	$db->commit || die $db->errstr;
}


# remove files that vanished - relies on dudl-checkavail
sub clean_uvanished {
	my $id = shift;

	if( ! $db->do( 
		"DELETE FROM stor_file ".
		"WHERE unit_id = $id AND NOT available" )){

		die $db->errstr;
	}
}

sub check_unew {
	my $uid		= shift;
	my $uname	= shift;
	my $udir	= shift;


	print "checking mp3s in \"$udir\"\n";
	my @files = `find '$udir' -type f -iname '*.mp3' -follow | sort`;

	my $dlen = length($udir);
	my $odir = "";
	my @afiles;

	foreach my $fnd( @files ){
		chomp $fnd;

		my $relpath = substr($fnd, $dlen );
		$relpath =~ s/\/+/\//g;

		my( $dir, $fname ) = $relpath =~ /^\/(?:(.*)\/)?([^\/]+)$/;

		if( $dir ne $odir ){
			&check_files( $uid, $uname, $udir, $odir, \@afiles );

			$odir = $dir;
			@afiles = ();
		}

		push @afiles, $fname;
	}

	&check_files( $uid, $uname, $udir, $odir, \@afiles );
}

sub get_artist {
	my $aname = $db->quote(shift, DBI::SQL_CHAR);

	# get one id:
	my ( $aid ) = $db->selectrow_array( 
		"SELECT id ".
		"FROM mus_artist ".
		"WHERE nname = $aname ".
		"ORDER BY id");

	return $aid;
}

sub get_diralbum {
	my $dir = shift;

	my $aname = $db->quote("DIR: $dir",DBI::SQL_CHAR);
	return &get_album( $aname ) || &add_album( $aname );
}

sub get_album {
	my $aname = shift;

	# get one id:
	my ( $aid ) = $db->selectrow_array( 
		"SELECT id ".
		"FROM mus_album ".
		"WHERE album = $aname ".
		"ORDER BY id");

	return $aid;
}

sub add_album {
	my $aname = shift;

	# get new album id ...
	my ( $aid ) = $db->selectrow_array( 
		"SELECT nextval('mus_album_id_seq')" );
	if( ! $aid ){
		die $db->errstr;
	}

	# ... and add new album with this id
	if( 1 != $db->do( 
		"INSERT INTO mus_album ( ".
			"id, ".
			"album, ".
			"artist_id, ".
			"publish_date ".
		") VALUES ( ".
			"$aid, ".
			"$aname, ".
			"$ukartist, ".
			"'1970-1-1' ".
		")" )){

		die $db->errstr;
	}

	return $aid;
}

sub get_maxpos {
	my $albid = shift;

	my( $max ) = $db->selectrow_array(
		"SELECT max(album_pos) ".
		"FROM stor_file ".
		"WHERE album_id = $albid" );
	return $max || 0;
}

sub check_files {
	my( $uid, $uname, $udir, $dir, $files ) = @_;

	my $file = new Dudl::File( $dudl, $uid );
	my $albid;
	my $maxpos;

	# TODO: use suggester - at least for guessing album_pos
	foreach my $fname( @$files ){
		$file->clean;

		$file->get_path( "$dir/$fname" );

		if( $file->id ){
			next;
		}

		if( ! $file->acquire( $udir, "$dir/$fname" ) ){
			die "cannot get file details";
		}
		
		my $fid = $file->insert;
		die unless $fid;

		if( ! $albid ){
			$albid = &get_diralbum( lc "$uname/$dir" );
			$maxpos = &get_maxpos( $albid );
		}

		$fname =~ /(.*)(\.mp3)?$/;
		my $title = $db->quote( lc $1, DBI::SQL_CHAR );
		$maxpos++;
		if( 1 != $db->do( 
			"UPDATE stor_file SET ".
				"album_id = $albid, ".
				"album_pos = $maxpos, ".
				"title = $title, ".
				"artist_id = $ukartist ".
			"WHERE id = $fid")){

			die $db->errstr;
		}

		print "new($fid): $uname/$dir/$fname\n";
	}
	$db->commit || die $db->errstr;
}

