#!/usr/bin/perl -w

# $Id: Base.pm,v 1.5 2001-12-18 18:13:23 bj Exp $

package Dudl::Base;

use strict;
use Carp qw{ :DEFAULT cluck };
use DBI;


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
		# Database
		DBHOST		=> "",
		DBUSER		=> "reader",
		DBPASS		=> "reader",
		DBNAME		=> "dudl",

		# files
		CDPATH		=> "/vol/cd/MP3",
		RCFILES		=> [ 
			"/etc/dudl.rc", 
			$ENV{'HOME'} ."/.dudlrc",
			],

		# preferences for suggestor
		SUG_ID3		=> 1,
		SUG_INT		=> 1,
		SUG_MAX		=> 1,
		SUG_SCORE	=> 6,

		# mp3 generation/renaming
		WRITE_JOB	=> 1,
		WRITE_JNAME	=> "TRACKS.dudl_archive",
		WRITE_V1	=> 1,
		WRITE_V2	=> 0,

		# runtime
		DB		=> undef,
		};

	bless $self, $class;

	$self->initialize;

	return $self;
}

sub done {
	my $self	= shift;

	$self->db->disconnect if defined $self->{DB};
}

sub cdpath {
	my $self = shift;
	return $self->{CDPATH};
}

sub sug_id3 {
	my $self = shift;
	return $self->{SUG_ID3};
}

sub sug_int {
	my $self = shift;
	return $self->{SUG_INT};
}

sub sug_max {
	my $self = shift;
	return $self->{SUG_MAX};
}

sub sug_score {
	my $self = shift;
	return $self->{SUG_SCORE};
}

sub write_job {
	my $self = shift;
	return $self->{WRITE_JOB};
}

sub write_jname {
	my $self = shift;
	return $self->{WRITE_JNAME};
}

sub write_v1 {
	my $self = shift;
	return $self->{WRITE_V1};
}

sub write_v2 {
	my $self = shift;
	return $self->{WRITE_V2};
}

sub db {
	my $self	= shift;

	if( ! defined $self->{DB} ){
		my $cmd = "dbi:Pg:".
			"dbname=". $self->{DBNAME};
		if( $self->{DBHOST} ){
			$cmd .= ";host=". $self->{DBHOST};
		}

		$self->{DB} = DBI->connect( $cmd,
			$self->{DBUSER}, 
			$self->{DBPASS},
			{ 'AutoCommit' => 0 }) ||
			croak $DBI::errstr;
	}

	return $self->{DB};
}


sub initialize {
	my $self = shift;

	# read config files
	my $rc;
	foreach $rc (@{$self->{RCFILES}}){
		$self->read_conf( $rc );
	}
}


# transaction stuff ...
sub commit {
	my $self	= shift;
	return $self->db->commit;
}
sub rollback {
	my $self	= shift;
	return $self->db->rollback;
}


# read one config file
sub read_conf {
	my $self	= shift;
	my $rc		= shift;

	return unless  -r $rc ;

	open( RC, $rc ) or croak "cannot open $rc: $!";
	my ( $k, $v );
	while( <RC> ){
		s/#.*//;
		s/\s*$//;
		next if /^$/;

		s/^\s*//;

		if( ($k,$v) = /(.*)\s*=\s*(.*)/ ){
			#print "found: $k=$v\n";
			if( $k eq "db_host" ){
				$self->{DBHOST} = $v;

			} elsif( $k eq "db_name" ){
				$self->{DBNAME} = $v;

			} elsif( $k eq "db_user" ){
				$self->{DBUSER} = $v;

			} elsif( $k eq "db_pass" ){
				$self->{DBPASS} = $v;

			} elsif( $k eq "cdpath" ){
				$self->{CDPATH} = $v;

			} elsif( $k eq "sug_id3" ){
				$self->{SUG_ID3} = $v;

			} elsif( $k eq "sug_int" ){
				$self->{SUG_INT} = $v;

			} elsif( $k eq "sug_max" ){
				$self->{SUG_MAX} = $v;

			} elsif( $k eq "sug_minscore" ){
				$self->{SUG_SCORE} = $v;

			} elsif( $k eq "write_jobfile" ){
				$self->{WRITE_JOB} = $v;

			} elsif( $k eq "write_jobname" ){
				$self->{WRITE_JNAME} = $v;

			} elsif( $k eq "write_id3v1" ){
				$self->{WRITE_V1} = $v;

			} elsif( $k eq "write_id3v2" ){
				$self->{WRITE_V2} = $v;

			} else {
				print STDERR "$rc, line $.: Unknown keyword\n";
			}

		} else {
			print STDERR "$rc, line $.: Syntax error\n";
		}
	}
	close RC;
}

# return matching (device, mountpoint) tuple from fstab
sub get_fstab
{
	my $self	= shift;
	my $ent		= shift;

	if( ! open FS, "/etc/fstab" ){
		cluck "cannot open fstab";
		return undef;
	}

	while( <FS> ){
		s/#.*//;
		s/^\s*//;

		next if( /^$/ );

		my( $fs, $mp, $type, $opt) = split;
		if( ($fs eq $ent) || ($mp eq $ent) ){
			close FS;
			return( $fs, $mp );
		}
	}

	close FS;

	return undef;
}

sub arg_files {
	my $self = shift;
	my $arg = shift;

	my @f;
	my $stdin =0;
	foreach( @$arg ){
		if( $_ eq "-" ){
			push @f, &arg_stdin if ! $stdin++;

		} elsif( -d $_ ){
			push @f, &arg_dir( $_ );

		} else {
			push @f, $_;
		}
	}

	return @f;
}

sub arg_stdin {
	my @files;

	while( <STDIN> ){
		chomp;
		push @files, $_;
	}
	return @files;
}

sub arg_dir {
	my $dir = shift;

	local *DIR;
	my @files;

	opendir( DIR, $dir ) || die "cannot opendir \"$dir\": $! ";
	while( defined( $_ = readdir( DIR )) ){
		next if /^\.\.?$/;
		next unless /\.(mp3|wav)$/i;
		push @files, "$dir/$_";
	}
	closedir( DIR );

	return sort { $a cmp $b } @files;
}


1;
