BEGIN;

------------------------------------------------------------
--
-- stor_track
--
-- temporary storage for exporting to music_* tables
--
------------------------------------------------------------

CREATE TABLE stor_track (
	id		INTEGER
			NOT NULL
			REFERENCES stor_file(id),

	title		VARCHAR(250),	-- title of track
	artist		VARCHAR(250),	-- artist of track
	album		VARCHAR(250),	-- album this track belongs to
	tracknum	SMALLINT	-- index on the above album 
			NOT NULL
			DEFAULT 0,
	
	PRIMARY KEY( id )
);

GRANT SELECT ON stor_track TO PUBLIC;

GRANT all ON stor_track TO GROUP dudl;



COMMIT;

