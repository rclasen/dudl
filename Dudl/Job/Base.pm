#!/usr/bin/perl -w

# job:		base	encode	rename	archive	music
#
# album
#  name		+	+	+	+	+
#  artist	+	+	+	+	+
#  id		-	-	-	-	*
#
# file
#  wav		-	+	-	-	-
#  mp3		-	-	+	+	-
#  id		-	-	-	-	+
#  encoder	?	?	?	?	?
#  broken	?	?	?	?	?
#  cmt		?	?	?	?	?
#
# title
#  num		+	+	+	+	+
#  name		+	+	+	+	+
#  artist	+	+	+	+	+
#  genres	?	?	?	?	?
#  random	?	?	?	?	?
#  cmt		?	?	?	?	?
#  year		?	?	?	?	?
#  id		-	-	-	-	*

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
		calb	=> 0,	# current album index to return
		cfil	=> 0,	# current file index to return
		ctit	=> -1,	# current title index to return
		};

	bless $self, $class;
	
	my $fname = shift;
	if( $fname ){
		return $self->read( $fname );
	}
	return $self;
}


sub rewind {
	my $self = shift;

	$self->{calb} = 0;
	$self->{cfil} = 0;
	$self->{ctit} = -1;
}

sub next {
	my $self = shift;

	$self->{ctit}++;
	my( $alb, $fil, $tit );

	my $albs = $#{$self->{all}};
	while( ! $tit ) {
		if( $self->{calb} > $albs ){
			return;
		}
		$alb = $self->{all}[$self->{calb}];

		my $fils = $#{$alb->{files}};
		if( $self->{cfil} > $fils ){
			$self->{calb}++;
			$self->{cfil}=0;
			next;
		}
		$fil = $alb->{files}[$self->{cfil}];

		my $tits = $#{$fil->{titles}};
		if( $self->{ctit} > $tits ){
			$self->{cfil}++;
			$self->{ctit}=0;
			next;
		}

		$tit = $fil->{titles}[$self->{ctit}];
	};

	return( $alb, $fil, $tit );
}

sub album {
	my $self = shift;

	my $albs = $#{$self->{all}};
	if( $self->{calb} > $albs ){
		return;
	}
	return $self->{all}[$self->{calb}];
}

sub file {
	my $self = shift;

	my $alb = $self->album;
	return unless $alb;
		
	my $fils = $#{$alb->{files}};
	if( $self->{cfil} > $fils ){
		return;
	}

	return $alb->{files}[$self->{cfil}];
}

sub title {
	my $self = shift;

	my $fil = $self->file;
	return unless $fil;
		
	my $tits = $#{$fil->{titles}};
	if( $self->{ctit} > $tits ){
		return;
	}

	return $fil->{titles}[$self->{ctit}];
}







############################################################
# add to config
#

sub add_album {
	my $self = shift;
	my $ent;
	if( ref($_[0]) ){
		$ent = shift;
	} else {
		$ent = { @_ };
	}

	delete $ent->{files};

	push @{$self->{all}}, { %$ent };
	$self->{calb} = $#{$self->{all}};
}

sub add_file {
	my $self = shift;
	my $ent;
	if( ref($_[0]) ){
		$ent = shift;
	} else {
		$ent = { @_ };
	}

	delete $ent->{titles};

	my $alb = $self->album;
	push @{$alb->{files}}, { %$ent };
	$self->{cfil} = $#{$alb->{files}};
}

sub add_title {
	my $self = shift;
	my $ent;
	if( ref($_[0]) ){
		$ent = shift;
	} else {
		$ent = { @_ };
	}

	my $fil = $self->file;
	push @{$fil->{titles}}, { %$ent };
	$self->{ctit} = $#{$fil->{titles}};
}


############################################################
# reading config
#
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

	$self->add_album( $cur );
	$self->{album} = {};

	return !$err;
}

sub file_group {
	my $self = shift;
	
	my $cur = $self->{file};
	if( ! keys %$cur ){
		return 1;
	}

	my $errs = 0;
	$self->file_check || $errs ++;

	$self->add_file( $cur );
	$self->{file} = {};

	return 1;
}

sub title_group {
	my $self = shift;
	
	my $cur = $self->{title};
	if( ! keys %$cur ){
		return 1;
	}

	my $err = 0;
	$self->title_check || $err ++;

	$self->add_title( $cur );
	$self->{title} = {};

	return ! $err;
}

# overloadable:

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


sub file_check {
	return 1;
}

sub file_key {
	my $self = shift;
	my $key = shift;
	my $val = shift;

	my $cur = $self->{file};

	if( $key eq "encoder" ){
		$cur->{$key} = $val;
		return 1;
	
	} elsif( $key eq "broken" ){
		$cur->{$key} = $val;
		return 1;
	
	} elsif( $key eq "cmt" ){
		$cur->{$key} = $val;
		return 1;
	
	}

	$self->bother( "invalid entry for file");
	return;
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


############################################################
# writing config
#
sub write {
	my $self = shift;
	my $fh = shift;

	foreach my $alb ( @{$self->{all}} ){
		$self->write_album( $fh, $alb );
		print $fh "\n";

		foreach my $fil ( @{$alb->{files}} ){
			$self->write_file( $fh, $fil );
			print $fh "\n";

			foreach my $tit ( @{$fil->{titles}} ){
				$self->write_title( $fh, $tit );
				print $fh "\n";
			}
		}
	}

	print $fh "# vi:syntax=dudlmus\n";
}

# overloadable:

sub write_album {
	my $self = shift;
	my $fh = shift;
	my $alb = shift;

	print $fh "album_name	". ($alb->{name} || "") ."\n";
	print $fh "album_artist	". ($alb->{artist} || "") ."\n";
}

sub write_file {
	my $self = shift;
	my $fh = shift;
	my $fil = shift;

	print $fh "file_encoder	". ($fil->{encoder} || "") ."\n";
	print $fh "file_broken	". ($fil->{broken} || 0) ."\n";
	print $fh "file_cmt	". ($fil->{cmt} || "") ."\n";
}

sub write_title {
	my $self = shift;
	my $fh = shift;
	my $tit = shift;

	my $random = exists( $tit->{random} ) ? $tit->{random} : 1;

	print $fh "title_num	". ($tit->{num} || 0) ."\n";
	print $fh "title_name	". ($tit->{name} || "") ."\n";
	print $fh "title_artist	". ($tit->{artist} || "") ."\n";
	print $fh "title_genres	". ($tit->{genre} || "") ."\n";
	print $fh "title_random	". $random ."\n";
	print $fh "title_cmt	". ($tit->{cmt} || "") ."\n";
}




1;
