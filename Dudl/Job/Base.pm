#!/usr/bin/perl -w

# job:		encode	rename	archive	music
#
# album
#  name		+	+	+	+
#  artist	+	+	+	+
#  id		-	-	-	*
#
# file
#  wav		+	-	-	-
#  mp3		-	+	+	-
#  id		-	-	-	+
#  encoder	-	?	?	?
#  cmt		?	?	?	?
#
# title
#  num		+	+	+	+
#  name		+	+	+	+
#  artist	+	+	+	+
#  genres	?	?	?	?
#  random	?	?	?	?
#  cmt		?	?	?	?
#  year		?	?	?	?
#  id		-	-	-	*

# legend:
# - must not exist
# + must exist
# ? may exist
# * special meaning

package Dudl::Job::Base;
# base class for jobfile parser

use strict;
use Carp qw( :DEFAULT cluck);

BEGIN {
	use Exporter ();
	use vars	qw($VERSION @ISA @EXPORT @EXPORT_VAR @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION	= 1.00;
	@ISA		= qw(Exporter);

	# exported by default:
	@EXPORT_VAR	= qw();
	@EXPORT		= ( qw(), 
			@EXPORT_VAR );
	
	# shortcuts for in demand exports
	%EXPORT_TAGS	= ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK	= ( qw(),
			@EXPORT );
}
use vars	@EXPORT_VAR;

# non-exported package globals go here

# initialize package globals, first exported ones

sub new {
	my $proto	= shift;
	if( !defined $proto ){
		carp "must be called as method";
	}
	my $class	= ref($proto) || $proto;
	my $self	= {
		fname	=> undef,
		debug	=> 0,
		album	=> {},	# currently parsed album
		file	=> {},	# currently parsed file
		title	=> {},	# currently parsed title
		all	=> [],
		};

	bless $self, $class;
	
	my $fname = shift;
	if( $fname ){
		return $self->read( $fname );
	}
	return $self;
}

sub read {
	my $self	= shift;
	my $fname	= shift;

	local *FH;
	if( ! open( FH, $fname ) ){
		print STDERR "cannot open file: $fname: $!";
		return;
	}
	$self->{fname} = $fname;

	my $last_group = "";
	my $errors = 0;

	while(<FH>){
		chomp;
		s/^\s+//;
		s/^#.*//;
		s/\s+$//;
		next if /^\s*$/;

		my( $group, $key, $val ) = /^(\S+)_(\S+)\s*(.*)/;
		$group = lc $group;
		$key = lc $key;

		if( $group ne $last_group ){
			if( $last_group ){
				$self->group_add( $last_group ) || 
					$errors++;
			}
			$last_group = $group;
		}

		#print STDERR "DEBUG: got: group=$group key=$key val=$val\n";
		$self->group_key( $group, $key, $val ) ||
			$errors++;
	}
	close( FH );

	$self->album_group || $errors++;
	$self->file_group || $errors++;
	$self->title_group || $errors++;

	return $errors ? undef : $self;
}

sub bother {
	my $self = shift;
	
	print STDERR $self->{fname},":$.: ", @_, "\n";
}

sub group_add {
	my $self = shift;
	my $group = shift;

	if( $group eq "album" ){
		return $self->album_group;
	} elsif( $group eq "file" ){
		return $self->file_group;
	} elsif( $group eq "title" ){
		return $self->title_group;
	}

	$self->bother( "invalid group");
	return;
}

sub group_key {
	my $self = shift;
	my $group = shift;
	my $key = shift;
	my $val = shift;

	if( $group eq "album" ){
		return if $self->duplicate( $group, $key );
		return $self->album_key( $key, $val );

	} elsif( $group eq "file" ){
		return if $self->duplicate( $group, $key );
		return $self->file_key( $key, $val );

	} elsif( $group eq "title" ){
		if( $key ne "num" && $self->duplicate( $group, $key )) {
			return;
		}
		return $self->title_key( $key, $val );

	} 

	$self->bother( "invalid group");
	return;
}

sub duplicate {
	my $self = shift;
	my $group = shift;
	my $key = shift;

	if( exists $self->{$group}->{$key} ){
		$self->bother( "dupliate entry for ". $group ."_". $key);
		return 1;
	}

	return;
}

sub album_group {
	my $self = shift;
	
	my $cur = $self->{album};
	if( ! keys %$cur ){
		return 1;
	}

	my $err = 0;
	$self->album_check || $err++;

	push @{$self->{all}}, { %$cur };
	$self->{album} = {};

	return !$err;
}

sub album_check {
	my $self = shift;

	my $cur = $self->{album};
	my $err = 0;
	if( ! $cur->{name} ){
		$self->bother( "missing album name");
		$err++;
	
	} elsif( ! $cur->{artist} ){
		$self->bother( "missing album artist");
		$err++;

	}

	return !$err;
}

sub album_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{album};

	if( $key eq "name" ){
		$cur->{$key} = $val;
		return 1;

	} elsif( $key eq "artist" ){
		$cur->{$key} = $val;
		return 1;

	}

	$self->bother( "invalid entry for album");
	return;
}


sub file_group {
	my $self = shift;
	
	my $cur = $self->{file};
	if( ! keys %$cur ){
		return 1;
	}

	my $errs = 0;
	$self->file_check || $errs ++;

	my $albs = $#{$self->{all}};
	push @{$self->{all}[$albs]->{files}}, { %$cur };
	$self->{file} = {};

	return 1;
}

sub file_check {
	return 1;
}

sub file_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{file};

	if( $key eq "cmt" ){
		$cur->{$key} = $val;
		return 1;
	
	}

	$self->bother( "invalid entry for file");
	return;
}

sub title_group {
	my $self = shift;
	
	my $cur = $self->{title};
	if( ! keys %$cur ){
		return 1;
	}

	my $err = 0;
	$self->title_check || $err ++;

	my $albs = $#{$self->{all}};
	my $fils = $#{$self->{all}[$albs]{files}};
	push @{$self->{all}[$albs]->{files}[$fils]->{titles}}, { %$cur };
	$self->{title} = {};

	return ! $err;
}

sub title_check {
	my $self = shift;

	my $cur = $self->{title};
	my $err = 0;
	if( ! $cur->{num} ){
		$self->bother( "missing title number");
		$err++;
	
	} elsif( ! $cur->{name} ){
		$self->bother( "missing title name");
		$err++;

	} elsif( ! $cur->{artist} ){
		$self->bother( "missing title artist");
		$err++;

	}

	return ! $err;
}

sub title_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{title};

	if( $key eq "num" ){
		my $err = 0;
		$self->title_group || $err++;

		$cur->{$key} = $val;
		return !$err;

	} elsif( $key eq "name" ){
		$cur->{$key} = $val;
		return 1;

	} elsif( $key eq "artist" ){
		$cur->{$key} = $val;
		return 1;

	} elsif( $key eq "genres" ){
		$cur->{$key} = $val;
		return 1;

	} elsif( $key eq "random" ){
		$cur->{$key} = $val;
		return 1;

	} elsif( $key eq "cmt" ){
		$cur->{$key} = $val;
		return 1;

	} elsif( $key eq "year" ){
		$cur->{$key} = $val;
		return 1;

	}

	$self->bother( "invalid entry for title");
	return;
}



	
#sub write {
#	my $self	= shift;
#	my $fh		= shift;
#
#	foreach my $alb ( $self->{alben} ){
#		&write_album( $fh, $alb );
#	}
#}
#
#sub write_album {
#	my $fh = shift;
#	my $alb = shift;
#
#	print $fh, "album_artist	\n";
#	print $fh, "album_name	\n";
#
#	foreach my $fil ( $alb->{files} ){
#		&write_file( $fh, $fil );
#	}
#}
#
#sub write_file {
#	my $fh = shift;
#	my $fil = shift;
#
#	print $fh "# $path\n";
#	print $fh "file_id		$storid\n";
#	print $fh "\n";
#}
#
#sub write_title {
#	my $fh = shift;
#	my $title = shift;
#
#	print $fh "# sug: $source\n";
#	print $fh "title_num	$tnum\n";
#	print $fh "title_name	$title\n";
#	print $fh "title_artist	$artist\n";
#	print $fh "title_genres	$genre\n";
#	print $fh "title_random	$random\n";
#	print $fh "title_cmt	$cmt\n";
#	print $fh "\n";
#
#
#}
#
#
#

1;
