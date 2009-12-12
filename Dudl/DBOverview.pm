#!/usr/bin/perl -w

#
# Copyright (c) 2008 Rainer Clasen
#
# This program is free software; you can redistribute it and/or modify
# it under the terms described in the file LICENSE included in this
# distribution.
#

=pod

=head1 NAME

Dudl::DBOverview - the Dudl Database Overview

=head1 DESCRIPTION

The Dudl Database currently covers the following parts:

=over 4

=item B<storage>

These tables keep track of available Files of your archive.

=over 4

=item B<file>

The file table contains information about all files. In addition to
filename, path, file size, cached ID3 Tags, cached MP3 info it is also
used to keep track, which files are currently available. This offers you
the chance to use removable media for your archive.

=item B<unit>

Each file belongs to a so called "unit". A unit is an entity that can take
files: A CD-ROM, a DVD, a directory on your disk, whatever you like.
Usually units are considered read-only: Once a unit is created, it's not
expected to change. Likewise Dudl will not expect to be able to modify
anything on a unit (although it might try to).

What are units good for?

=over 4

=item removable media:

Once you've found the file in the file table, you know the CD you have to
search for ;-).

=item backup:

If you open up a new "unit" (AKA Directory) every N Days/Bytes/whatever
for new files, you just have to backup the new directories since your last
run.

=back

=item B<collection>

Each unit belongs to a collection. Collections were introduced to
distinguish the origin of units. If you receive a set of CDs from a
friend, just assign them all to the same collection and you can easily
keep track of his CDs.

=back

The storage database is maintained by I<dudl-storscan>(1),
I<dudl-dbavcheck>(1) and your favorite PostgreSQL client.

You can query these tables with I<dudl-storhave>(1).

=item B<music>

These tables create a logical structure: You can assign title-, artist-
and albumnames completely independent of the file database. For example
tracks of a single album don't have to be in the same directoy, title
names are completely independent of file names. While this seperation was
initially introduced because of read-only units, it proved to be very
powerful.

=over 4

=item B<artist>

An artist is a person or group of persons that makes the music. Feel free
to take this as it fits best.

There are two special artists:

=over 4

=item UNKNOWN

where you (or the script you use) doesn't know the artist.

=item VARIOUS

for albums that contain tracks of several artist.

=back

=item B<album>

Usually artists release their music on CDs or LPs or ... . I consider an
album one of such thingies: If there is a pack with 2 CDs in it, I create
2 Albums with the same name suffixed by CD plus number.

Of course you can create your own "albums" of standalone Tracks.

=item B<track>

call it title, track, piece of music, composition - you know what I mean,
do you? Tracks are part of an album.

=item B<tag>

This grew from the Idea of genres. But as genres are a matter of taste
this is a bit more abstract. You can set several tags for a file. Of
course you can create Tags named "rock", "pop", "metal", ... and assign
them to your tracks to gain back your beloved genres. Well, and in case
you're undecided, you can even assign both "metal" and "rap" to a
crossover track ;-). Other uses: "good", "bad", "live", "junk",
"duplicate", ...

To sum up: This is where the power of your database comes from ;-)

FYI: By default the jukebox tries to set the tag "failed" on tracks it
couldn't play.

FYI2: it's likely that tags will be extended to carry a score. This score
will get used by the jukebox to play tracks more/less often.

FYI3: There are also Ideas to put tags in per-user namespace, but for now
that's just an Idea.

FYI42: There are a lot more Ideas ;-)

=back

You can add new stuff to the music database using I<dudl-musbatch>(1) or
if you're a tough guy I<dudl-musimport>(1).

Some basic editing is supported through the jukebox. Tag management is
best done through the jukebox.

More advanced changes have to be done using your favorite PostgreSQL
client.

You can search these tables with I<dudl-mushave>(1).

=item B<jukebox>

These tables had to be added for the jukebox.

=over 4

=item B<user>

usernames, passwords and access privileges.

=item B<queue>

The list of tracks that are supposed to be played next.

=item B<history>

list of tracks that were played.

=back

=back

All tables come with a numeric ID.

Unfortunatly the table namimg is quite inconsistent. Once upon a time the
jukebox was based on "mserv" - a different MP3 jukebox and the tag, user
queue and history tables were named according to this.

=head1 SEE ALSO

I<dudl-dbupdate>(1) source code for a commented DB schema.

=head1 AUTHOR

Rainer Clasen

=cut
