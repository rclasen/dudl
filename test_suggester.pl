
# rengen
my $nam = $dudl->naming;
my $sug = new Dudl::Suggester;

$sug->src( new Dudl::Suggester::Regexp( "title=(.*)" ));
$sug->src( new Dudl::Suggester::Stored());
$sug->src( new Dudl::Suggester::ID3());

foreach my $fname ( @ARGV ){
	$sug->file(
		path	=> $fname,
	);
}

my $job = new Dudl::Job::Rename(
	naming => $nam,
);

$sug->job( $job,
	minscore => 1,
	maxsug => 1,
	samesrc => 1, # use same suggestion source album members
);

$job->write( \*STDOUT );


# musgen
my $nam = $dudl->naming;
my $archive = new Dudl::Job::Archive( naming => $nam, file => "foo" );

my $sug = new Dudl::Suggester;

$sug->src( new Dudl::Suggester::Regexp( "title=(.*)" ));
$sug->src( new Dudl::Suggester::Stored());
$sug->src( new Dudl::Suggester::DBID3());
$sug->src( new Dudl::Suggester::Job( $archive ));

my $sth = $db->prepare( "SELECT ..." );
$sth->bind_columns( \( $id, $path, $id_artist, $id_title, ...));
while( defined $sth->fetch ){
	$sug->file(
		id	=> $id,
		path	=> $path,
		id_artist	=> $id_artist,
		...
	);
}

my $job = new Dudl::Job::Rename(
	naming => $dudl->naming,
);

$sug->job( $job,
	minscore => 1,
	maxsug => 1,
	samesrc => 1, # use same suggestion source album members
);

$job->write( \*STDOUT );


