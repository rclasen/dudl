#!/usr/bin/perl -w

# v0.0.1 - 2000-12-26
#	* release


# FIXME
# decide where to look for filenames and fill an array
if( defined $ARGV[0] ){
	if( -d $ARGV[0] ){
		# - readdir $ARGV[0]
		opendir( DIR, $ARGV[0] ) || die "cannot opendir \"$ARGV[0]\": $! ";
		while( defined( $_ = readdir( DIR )) ){
			&print_line( $_ );
		}
		closedir( DIR );
	} else {
		# - process all of @ARGV
		foreach $_ ( @ARGV ){
			&print_line( $_ );
		}
	}
} else {
	# - read stdin
	while( <STDIN> ){
		&print_line( $_ );
	}
}


# FIXME
# keep compatibility with filenames != /<basename>_<NO>.(wav|mp3)/i

# FIXME
# sort the array
# for each filename 
# 	skip non(mp3|wav) filenames
# 	skip if duplicate  mp3/wav filenames
# 	if last basename != current basename print Album-fileds
# 	print track fileds
sub print_line {
	if( /^(.*_(\d\d)).(wav|mp3)$/i ){
		print "\n\n\nG \nA \n#S\n\n" if( $2 == 1 ); 
		print "N$2\nF $1.mp3\nT \n\n";
	} else {
		print( STDERR "unknown file: $_" );
	}
}
