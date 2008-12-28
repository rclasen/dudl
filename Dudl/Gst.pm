#/usr/bin/perl -w

#
# Copyright (c) 2008 Rainer Clasen
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

use strict;
use bignum;

package Dudl::Gst::Scan;
use Carp;
use Glib;
use GStreamer -init; # TODO: no init, breaks ARGV
use File::Temp qw( tempdir );
use Data::Dumper;

# TODO: use an own mainloop instance and don't fiddle with the global one.

our @ISA = qw( Exporter );

sub new {
	my $proto = shift;
	my %g;
	my $me = {
		error	=> 0,
		loop	=> new Glib::MainLoop,
		gst	=> \%g,
		adat	=> {
			gain	=> 0,
			gainp	=> 0,
		},
		tdat	=> {},
	};
	bless $me, ref $proto || $proto;
	$me->_newfile;

	$me->{dir} = tempdir( CLEANUP => 1 )
		or croak "cannot create temp dir: $!";

	( @g{qw(src dec conv gain cut sink)} ) =
	GStreamer::ElementFactory->make(
		"filesrc"	=> "src",
		"mad"		=> "dec",
		"audioconvert"	=> "conv",
		"rganalysis"	=> "gain",
		"cutter"	=> "cut",
		"fakesink"	=> "sink" );

	while( my($n,$e) = each %g ){
		croak "cannot load gst $n plugin" unless defined $e;
	}

	# TODO: verify cutter thresholds
	$g{cut}->set( "run-length", "2000000000" );
	$g{cut}->set( "threshold-dB", -60 );

	$g{pipe} = new GStreamer::Pipeline( "pipe" );
	$g{pipe}->get_bus->add_watch( \&cb_bus_message, $me )
		or croak "gst bus watch failed";

	$g{pipe}->add( @g{qw(src dec conv gain cut sink )});
	$g{src}->link( @g{qw(dec conv gain cut sink )})
		or croak "gst pipe link failed";

	return $me;
}

sub _newfile {
	my $me = shift;
	$me->{tdat} = {
		dur	=> 0,
		# cutter:
		segs	=> [],
		# replaygain:
		gain	=> 0,
		gainp	=> 0,
	}; 
	$me->{segs} = [];
}


sub scanfile {
	my( $me, $file, $last ) = @_;
	
	#print STDERR "scanning $file ...\n";
	$me->{error} = 0;
	$me->_newfile;

	# TODO: evil hack to workaround utf8 problems
	my $lnk = "$me->{dir}/lnk";
	unlink( $lnk );
	if( ! symlink( $file, $lnk ) ){
		carp "failed to create temp symlink";
		return;
	}

	$me->{gst}{src}->set( "location", $lnk );
	$me->{gst}{gain}->set( "num-tracks", $last ? 1 : 10 );

	my $to = Glib::Timeout->add( 500, \&cb_getpos, $me );
	$me->{gst}{pipe}->set_state( "playing" );
	$me->{gst}{gain}->set_locked_state( $last ? 1 : 0 );
	$me->{loop}->run;
	Glib::Source->remove( $to );

	# TODO: hack to retrieve duration
	my $p = new GStreamer::Query::Position( "time" );
	$me->{gst}{pipe}->query( $p );

	my $d = new GStreamer::Query::Duration( "time" );
	$me->{gst}{pipe}->query( $d );

	$me->{gst}{pipe}->set_state( $last ? "null" : "ready");

	#print STDERR "pos=", ($p->position)[1],
		#", dur=", ($d->duration)[1], "\n";

	# TODO: hackish $p and $d access
	if( $me->{tdat}{dur} < ($p->position)[1] ){
		$me->{tdat}{dur} = ($p->position)[1];
	}
	if( $me->{tdat}{dur} < ($d->duration)[1] ){
		$me->{tdat}{dur} = ($d->duration)[1];
	}

	my $segs = $me->{segs};
	if( $#$segs < 0 ){
		push @$segs, {
			above		=> 1,
			timestamp	=> 0,
		}, {
			above		=> 0,
			timestamp	=> $me->{tdat}{dur},
		};

	} else {
		my $first = $segs->[0];

		if( ! $first->{above} ){
			unshift @$segs, {
				above		=> 1,
				timestamp	=> 0,
			};
		}

		my $last = $segs->[$#$segs];
		if( $last->{above} ){
			push @$segs, {
				above		=> 0,
				timestamp	=> $me->{tdat}{dur},
			}
		}
	}
	foreach my $i ( 0..$#$segs ){
		my $seg = $segs->[$i];
		if( $seg->{timestamp} > $me->{tdat}{dur} ){
			$seg->{timestamp} = $me->{tdat}{dur};
		}

		next unless $i > 0;
		my $pseg = $segs->[$i -1];

		if( $pseg->{above} && $pseg->{timestamp} < $seg->{timestamp} ){
			push @{$me->{tdat}{segs}}, {
				from	=> $pseg->{timestamp},
				to	=> $seg->{timestamp},
			};
		};

	}


	return if $me->{error};

	return $me->{tdat}, $me->{adat} if $last;
	return $me->{tdat};
}

sub scanalbum {
	my( $me ) = shift;
	my $f = ref $_[0] eq "ARRAY" ? $_[0] : \@_;

	my @ret;
	foreach my $i ( 0.. $#$f ){
		$me->scanfile( $f->[$i], $i == $#$f )
			or return;
		push @ret, $me->{tdat};
	}

	return \@ret, $me->{adat};
}

sub cb_getpos {
	my( $me ) = @_;

	my $p = new GStreamer::Query::Position( "time" );
	$me->{gst}{pipe}->query( $p );
	if( ($p->position)[1] > $me->{tdat}{dur} ){
		$me->{tdat}{dur} = ($p->position)[1];
	}

	return 1;
}

sub cb_bus_message {
	my( $bus, $message, $me )= @_;

	if( $message->type & "error" ){
		$me->{error}++;
		carp $message->error . $message->debug;
		$me->{loop}->quit;

	} elsif( $message->type & "eos" ){
		$me->{loop}->quit;

	} elsif( $message->type & "tag" ){ 
		my $t = $message->tag_list;

		foreach my $n ( qw( album artist date track-number title )){
			$me->{tdat}{$n} = $t->{$n}[0] if exists $t->{$n};
		}

		$me->{tdat}{gain} = $t->{'replaygain-track-gain'}[0]
			if exists $t->{'replaygain-track-gain'};
		$me->{tdat}{gainp} = $t->{'replaygain-track-peak'}[0]
			if exists $t->{'replaygain-track-peak'};

		$me->{adat}{gain} = $t->{'replaygain-album-gain'}[0]
			if exists $t->{'replaygain-album-gain'};
		$me->{adat}{gainp} = $t->{'replaygain-album-peak'}[0]
			if exists $t->{'replaygain-album-peak'};


	} elsif( $message->type & "element" ){ 
		my $st = $message->get_structure;
		if( $st->{name} eq "cutter" ){
			my %dat;
			foreach my $f ( @{$st->{fields}} ){
				$dat{$$f[0]} = $$f[2];
			}
			push @{$me->{segs}}, {
				above		=> $dat{above},
				timestamp	=> $dat{timestamp},
			};
		}
	}

	return 1;
}


sub DESTROY {
	my $me = shift;
	$me->{gst}{gain}->set_locked_state(0) if $me->{gst}{gain};
	$me->{gst}{pipe}->set_state("null") if $me->{gst}{pipe};
	$me->{gst}{gain}->set_state("null") if $me->{gst}{gain};
}




1;
