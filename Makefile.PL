use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'dudl-db',
    'VERSION'		=> '0.0.7',
    'PREREQ_PM'		=> {
	'EzDBI'			=> 0,
	'EzDBo'			=> 0,
	'Dudl::Config'		=> 0,
    	'Net::FreeDB2'		=> 0,
	'MP3::Digest'		=> 0,
	'MP3::Tag'		=> 0,
	'MP3::Info'		=> 0,
	'DBD::Pg'		=> 0,
	}, # e.g., Module::Name => 1.1
    'PMLIBDIRS'		=> [qw( Dudl )],
    'EXE_FILES'		=> [qw( 
	dudl-dbavcheck
	dudl-dbmaintenance
	dudl-dbstatus
	dudl-dbupdate
	dudl-doarchive
	dudl-docdimg
	dudl-doedit
	dudl-doout
	dudl-doren
	dudl-dosort
	dudl-dotest
	dudl-mus2id
	dudl-mus2job
	dudl-musbatch
	dudl-musdirs
	dudl-musgen
	dudl-mushave
	dudl-musimport
	dudl-muslinks
	dudl-musyearadd
	dudl-storhave
	dudl-storscan 
    )],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'dudl database maintenance scripts',
       AUTHOR     => 'Rainer Clasen <bj@zuto.de>') : ()),
);
