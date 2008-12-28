package Dudl::DBo;

#
# Copyright (c) 2008 Rainer Clasen
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

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

