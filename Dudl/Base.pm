#!/usr/bin/perl -w

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
		DBHOST		=> "",
		DBUSER		=> "reader",
		DBPASS		=> "reader",
		DBNAME		=> "dudl",
		CDPATH		=> "/vol/cd/MP3",
		RCFILES		=> [ 
			"/etc/dudl.rc", 
			$ENV{'HOME'} ."/.dudlrc",
			],
		DB		=> undef,
		};

	bless $self, $class;

	$self->initialize;

	return $self;
}

sub done {
	my $self	= shift;

	$self->db->disconnect;
}

sub cdpath {
	my $self	= shift;

	return $self->{CDPATH};
}

sub db {
	my $self	= shift;

	return $self->{DB};
}


sub initialize {
	my $self = shift;

	# read config files
	my $rc;
	foreach $rc (@{$self->{RCFILES}}){
		$self->read_conf( $rc );
	}

	# open database
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


1;
