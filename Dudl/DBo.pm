package Dudl::DBo;

use strict;
use warnings;

use EzDBo;
use Carp;

our @ISA = qw(EzDBo);

sub new {
	my $proto = shift;
	my $a = ref $_[0] eq "HASH" ? shift : { @_ };

	croak "missing dudl argument" unless exists $a->{dudl};
	$a->{db} = $a->{dudl}->db;

	my $self = $proto->SUPER::new( $a );
	$self->{DUDL} = $a->{dudl};
	$self;
}

