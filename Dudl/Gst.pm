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

package Dudl::Gst;
use Carp;
use Glib;
use GStreamer qw/ -init GST_SECOND /; # TODO: no init, breaks ARGV
use File::Temp qw( tempdir );

# TODO: use an own mainloop instance and don't fiddle with the global one.

our @ISA = qw( Exporter );

sub new {
	my $proto = shift;
	my $a = shift || {};

	my %g;
	my $me = {
		debug	=> 0,
		%$a,
		error	=> 0,
		loop	=> new Glib::MainLoop,
		gst	=> \%g,
		rsegs	=> [], # raw cutter segments
		tdat	=> [], # per title data
		adat	=> {
			gain	=> 0,
			gainp	=> 0,
		},
		dir	=> undef, # tmpdir
	};
	bless $me, ref $proto || $proto;

	$me->{dir} = tempdir( CLEANUP => 1 )
		or croak "cannot create temp dir: $!";
	$me->log_debug( "tmpdir: ", $me->{dir} );

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

sub log_debug {
	my( $me ) = shift;
	$me->{debug} && print STDERR @_, "\n";
}

sub album {
	my( $me ) = @_;
	$me->{adat};
}

sub track {
	my( $me, $id ) = @_;
	$me->{tdat}[$id];
}

sub tracks {
	my( $me ) = @_;
	$me->{tdat};
}

sub scan {
	my( $me, $files ) = @_;

	$me->{adat} = {};
	$me->{tdat} = [];

	$me->{gst}{gain}->set( "num-tracks", scalar @$files );
	foreach my $file ( @$files ){
		$me->_scanfile( $file ) || return;
	}

	1;
}

sub _scanfile {
	my( $me, $file ) = @_;

	$me->log_debug( "scanning $file ..." );
	$me->{error} = 0;

	my @rsegs;
	$me->{rsegs} = \@rsegs;

	my $tdat = {
		fname	=> $file,
		# final pipe duration/position:
		dur	=> 0,
		# processed segs from cutter:
		segs	=> [],
		# replaygain:
		gain	=> 0,
		gainp	=> 0,
	};
	push @{$me->{tdat}}, $tdat;

	# TODO: evil hack to workaround utf8 problems
	my $lnk = $me->{dir} .'/lnk';
	unlink( $lnk );
	if( ! symlink( $file, $lnk ) ){
		carp "failed to create temp symlink";
		return;
	}

	$me->{gst}{src}->set( "location", $lnk );

	my $to = Glib::Timeout->add( 500, \&cb_getpos, $me );
	$me->{gst}{pipe}->set_state( "playing" );
	$me->{loop}->run;
	Glib::Source->remove( $to );

	# TODO: hack to retrieve duration
	my $p = new GStreamer::Query::Position( "time" );
	$me->{gst}{pipe}->query( $p );

	my $d = new GStreamer::Query::Duration( "time" );
	$me->{gst}{pipe}->query( $d );


	#print STDERR "pos=", ($p->position)[1],
		#", dur=", ($d->duration)[1], "\n";

	# TODO: hackish $p and $d access
	if( $tdat->{dur} < ($p->position)[1] ){
		$tdat->{dur} = ($p->position)[1];
	}
	if( $tdat->{dur} < ($d->duration)[1] ){
		$tdat->{dur} = ($d->duration)[1];
	}

	$me->{gst}{pipe}->set_state( "ready" );

	# cutter found no segments. synthesize one segment that spans the
	# whole file:
	if( $#rsegs < 0 ){
		push @rsegs, {
			above		=> 1,
			timestamp	=> 0,
		}, {
			above		=> 0,
			timestamp	=> $tdat->{dur},
		};

	# synthesize (missing) leading + trailing segments:
	} else {
		my $first = $rsegs[0];

		if( ! $first->{above} ){
			unshift @rsegs, {
				above		=> 1,
				timestamp	=> 0,
			};
		}

		my $last = $rsegs[-1];
		if( $last->{above} ){
			push @rsegs, {
				above		=> 0,
				timestamp	=> $tdat->{dur},
			}
		}
	}

	# get start/end timestamps from cutter segments
	foreach my $i ( 0..$#rsegs ){
		my $seg = $rsegs[$i];
		if( $seg->{timestamp} > $tdat->{dur} ){
			$seg->{timestamp} = $tdat->{dur};
		}

		next unless $i > 0;
		my $pseg = $rsegs[$i -1];

		if( $pseg->{above} && $pseg->{timestamp} < $seg->{timestamp} ){
			push @{$tdat->{segs}}, {
				from	=> $pseg->{timestamp},
				to	=> $seg->{timestamp},
			};
		};

	}

	if( $me->{debug} ){
		my $from = $tdat->{segs}[0]{from};
		my $to = $tdat->{segs}[-1]{to};
		$me->log_debug( sprintf( 'seg: %3d (%3d) %3d (%3d) %3d',
			$from / GST_SECOND,
			($to - $from) / GST_SECOND,
			$to / GST_SECOND,
			($tdat->{dur} - $to) / GST_SECOND,
			$tdat->{dur} / GST_SECOND,
		));
	}

	return if $me->{error};
	1;
}

sub cb_getpos {
	my( $me ) = @_;

	my $p = new GStreamer::Query::Position( "time" );
	$me->{gst}{pipe}->query( $p );
	if( ($p->position)[1] > $me->{tdat}[-1]{dur} ){
		$me->{tdat}[-1]{dur} = ($p->position)[1];
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
			$me->{tdat}[-1]{$n} = $t->{$n}[0] if exists $t->{$n};
		}

		$me->{tdat}[-1]{gain} = $t->{'replaygain-track-gain'}[0]
			if exists $t->{'replaygain-track-gain'};
		$me->{tdat}[-1]{gainp} = $t->{'replaygain-track-peak'}[0]
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

			push @{$me->{rsegs}}, {
				above		=> $dat{above},
				timestamp	=> $dat{timestamp},
			};
		}
	}

	return 1;
}


sub DESTROY {
	my $me = shift;
	$me->{gst}{pipe}->set_state("null") if $me->{gst}{pipe};
}




1;
