#!/usr/bin/perl -w

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
#  - you need to strip the "#"
#  - whitespaces at line begin/end and after the command letter are ignored
#  - each setting remains unaffected until it is reset (except S)
#  - a rename is tried on each T 

# example:
# A kill em all
# G metallica
#
# N1
# F blahblubgfsdghj.mp3
# T hit the lights
#
# #### stuff snipped ###
#
# A reload
#
# N1
# F fsafd f sdf.mp3
# T	fuel
#
# N2
# F fdasf.mp3
# C ein kommentar
# Y 2000
# E Metal
# T titel
#
# N3
# F fdsa.mp3
# T blah

use strict;
use MP3::Info;


$| = 1;


INPUT: foreach my $file ( @ARGV ) {
        open( FILE, $file ) || next INPUT;


        my( 
		$oldname, 
		$sampler,

		$alb_title, 
		$group, 
		$track, 
		$title, 

		$genre,
		$year,
		$comment,
		);
	
	
        LINE: while( <FILE> ){
                # strip trailing cr
                chomp;

                # strip comments
                s/^\s*#.*//;
                
                # strip leading whitespace
                s/^\s*//;

                # skip empty lines
                next LINE if /^$/;


		/^([FASGTNCYE])\s*(.*)\s*/;
		if( $1 eq "F" ) {
			$oldname = $2;
			next LINE;
		} elsif( $1 eq "A" ){
			$alb_title = $2;
			$sampler = 0;
			next LINE;
		} elsif( $1 eq "S" ){
			$group = '';
			$sampler = 1;
			next LINE;
		} elsif( $1 eq "G" ){
			$group = $2;
			next LINE;
		} elsif( $1 eq "T" ){
			$title = $2;
		} elsif( $1 eq "N" ){
			$track = $2;
			next LINE;
		} elsif( $1 eq "C" ){
			$comment = $2;
			next LINE;
		} elsif( $1 eq "Y" ){
			$year = $2;
			next LINE;
		} elsif( $1 eq "E" ){
			$genre = $2;
			next LINE;
		} else {
			print "whoops ...\n";
			next LINE;
		}



		TAG: foreach my $f( $title, $group, $alb_title ){
			if( ! defined( $f ) ){
				print STDERR "ERROR: required tag not set\n";
				next LINE;
			}

			# MP3::Info does this:
			#&tag_check( $f );
		}

		next LINE unless -r $oldname;
		print $oldname, " ...";

		my %tag = (
			TITLE		=> "$title",
			ARTIST		=> "$group",
			ALBUM		=> "$alb_title",
			TRACKNUM	=> "$track",
			YEAR		=> "",
			COMMENT		=> "",
			GENRE		=> "",
			);
		if( defined $year ){
			$tag{YEAR}	= $year;
		}
		if( defined $comment ){
			$tag{COMMENT}	= $comment;
		}
		if( defined $genre ){
			$tag{GENRE}	= $genre;
		}

		set_mp3tag( $oldname, \%tag );
		print " tagged";

                my $newname = undef;
                my $newdir = undef;
                if( $sampler ) {
                        # - a sampler, name it 
                        # <album>/<nr>_<group>.--.<title> or 
                        # <album>/<nr>_<title>
                        $newdir = $alb_title;
                        if( $group ){
                                $newname = sprintf( "%02d_%s.--.%s.mp3", 
					$track, $group, $title );
                        } else {
                                $newname = sprintf( "%02d_%s.mp3", 
					$track, $title );
                        }
                } else {
                        # - no sampler, name it 
                        # <group>.--.<album>/<group>.--.<nr>_<title>
                        $newname = sprintf( "%s.--.%02d_%s.mp3", 
				$group, $track, $title );
                        $newdir = sprintf( "%s.--.%s",
				$group, $alb_title);
                }
                $newname = &fn_normalize( $newname );
                $newdir = &fn_normalize( $newdir );

		if( ! -d $newdir ) { 
			if( !mkdir( $newdir, 0777 ) ) { 
                                warn "mkdir \"$newdir\": $? " ; 
                                next LINE; 
                        }
                }

		chmod( 0644, $oldname );

                rename( $oldname, $newdir ."/". $newname ) || 
			warn "rename '$oldname': $!";
		print " renamed";

		&run( "v2strip '$newdir/$newname' > /dev/null 2>&1" );
		print " stripped.\n";
        }
        close( FILE );
}


sub tag_check 
{
	my $f = shift;

	if( length( $f ) > 30 ){
		print STDERR "WARNING: ".
			"idtag exceeds 30 ".
			"chars, truncating: $f\n";
		return 1;
	}
	return 0;
}

sub fn_normalize 
{
	my $foo = shift;

        $foo =~ s/[^a-zäöüßA-ZÖÄÜ0-9_\$()=+-]+/./g;
	if( length( $foo ) > 64 ){
		print "WARINING: \"$foo\" exceeds 64 chars\n";
	}

	return $foo;
}


sub run 
{
        $, = " ";
        #print( @_, "\n" );
        system @_;
	if( $? ){
		print STDERR "ERROR: command returned ". ($? >> 8) ."\n";
	}
}
