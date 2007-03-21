#!/usr/bin/perl -w

# $Id: Config.pm,v 1.2 2007-03-21 10:19:17 bj Exp $

=pod

=head1 NAME

Dudl::Config - reads system and user settings for dudl applications

=head1 SYNOPSIS

 use Dudl::Config;
 my $c = new Dudl::Config;
 print $c->conf("key"), "\n";

=head1 DESCRIPTION

Read system and user settings for dudl applications. 

=cut

package Dudl::Config;

use strict;
use Carp qw{ :DEFAULT cluck };


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

=pod

=head1 CONSTRUCTOR

=over 4

=item new()

Creates a new object and reads the configs.

=cut
sub new {
	my $proto	= shift;
	if( !defined $proto ){
		croak "must be called as method";
	}

	my $class	= ref($proto) || $proto;
	my $self	= {
		# files
		RCFILES		=> [ 
			"/etc/dudl.rc", 
			&gethome ."/.dudlrc",
			],

		# default values
		CONF		=> {
			# other inherited defaults
			@_,

			# misc
			cdpath		=> "/pub/fun/mp3/CD",
			cddev		=> "/dev/cdrom",
			workpath	=> "/pub/fun/mp3",

			# TODO: cddb

			# suggestor
			sug_id3		=> 1,
			sug_int		=> 1,
			sug_max		=> 1,
			sug_score	=> 6,

			# encoder
			enc_procs	=> 1,
			enc_jname	=> "TRACKS.dudl_encode",
			enc_outdir	=> ".",

			# rename
			ren_jname	=> "TRACKS.dudl_rename",

			# mp3 generation/renaming
			naming		=> 'Default',
			write_job	=> 1,
			write_jname	=> "TRACKS.dudl_archive",
			write_v1	=> 1,
			write_v2	=> 0,
			write_dir	=> ".",
		},

		};

	bless $self, $class;

	$self->initialize;

	return $self;
}

sub gethome {
	return (getpwuid($>))[7]
}

sub initialize {
	my $self = shift;

	# read config files
	my $rc;
	foreach $rc (@{$self->{RCFILES}}){
		$self->read_conf( $rc );
	}
}

# read one config file
sub read_conf {
	my $self	= shift;
	my $rc		= shift;

	return unless  -r $rc ;

	open( RC, $rc ) or croak "cannot open $rc: $!";

	while( <RC> ){
		s/#.*//;
		s/\s*$//;
		next if /^$/;

		s/^\s*//;

		if( my ($k,$v) = /^(\w+)\s*=\s*(.*)$/ ){
			#print "found: $k=$v\n";

			$self->{CONF}{lc $k}=$v if exists $self->{CONF}{lc $k};
		} else {
			print STDERR $rc, ", line $.: Syntax error\n";
		}
	}
	close RC;

}

=pod

=head1 METHODS

=item conf( $key )

=item conf( $key, $newval )

returns or sets a config variable. Returns undef when variable is unknown.

=cut
sub conf {
	my $self = shift;
	my $var = shift;
	my $val = shift;

	return undef unless exists $self->{CONF}->{$var};
	$self->{CONF}->{$var} = $val if defined $val;
	return $self->{CONF}->{$var};
}

=pod

=item naming()

create a new Dudl::Naming object according to the "naming" config variable.

=cut
sub naming {
	my $self = shift;

	my $mod = $self->conf( "naming" );
	return undef unless eval "require Dudl::Naming::$mod";
	return "Dudl::Naming::$mod"->new( @_ );
}

1;
__END__

=head1 FILES

=item F</etc/dudl.rc>, F<$HOME/.dudlrc>.

extensible config files read by this module. See I<dudlrc(5)> for details.
This module uses the following keys:

=over 4

=item naming (string)

Dudl::Naming::$naming module to use for constructing file- and directory names.

=back 

=head1 SEE ALSO

L<dudlrc(5)>, L<Dudl::Naming::Default>.

=head1 AUTHOR

Rainer Clasen

=cut

