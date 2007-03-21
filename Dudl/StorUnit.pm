package Dudl::StorUnit;

use strict;
use warnings;

use Dudl::DBo;
use Carp;

our @ISA = qw(Dudl::DBo);

my %scheme = (
	name => 'stor_unit',
	cols => [qw( id collection colnum volname size step )],
	pkey => 'id',
	);

sub table_scheme {
	return \%scheme;
}

sub load_path {
	my $proto = shift;
	my $a = ref $_[0] eq "HASH" ? shift : { @_ };

	croak "missing path argument" unless exists $a->{path};
	$a->{path} =~ /([^\d\/]+)(\d+)\/*$/
		or croak "invalid path";
	$a->{where} = {
		collection => "'$1'", # TODO: quote properly 
		colnum => $2,
	};

	$proto->load( $a ), 
}

sub load_step {
	my $proto = shift;
	my $a = ref $_[0] eq "HASH" ? shift : { @_ };

	croak "missing step argument" unless exists $a->{step};
	$a->{where} = {
		step => "'$a->{step}'", # TODO: quote properly 
	};

	$proto->load( $a ), 
}

sub dir {
	my $self = shift;
	my $path = shift;

	return sprintf( "%s/%s%04d",
		$self->{data}{collection}, 
		$self->{data}{collection}, 
		$self->{data}{colnum} );
}

# get information from disc in specified device
# returns success status - ie true for success
sub acquire {
	my $self = shift;
	my $device = shift;

	# TODO: use something better than cdinfo
	my $cdinfo = $self->{DUDL}->conf("cdinfo");
	my @out	 = `$cdinfo $device`;

	my $found;
	foreach( @out ){
		if( /iso9660: (\d*) .* `(.*)\s*'/ ){
			$self->{data}{size} = $1 * 1024 * 1024;
			$self->{data}{volname} = $2;
			$found++;
		}
	}

	return $found;
}


