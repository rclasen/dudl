BEGIN;

------------------------------------------------------------
--
-- mus_title
--
------------------------------------------------------------

CREATE TABLE mus_title (
	id		SERIAL,

	album_id	int
			NOT NULL
			REFERENCES mus_album(id),
	nr		int
			NOT NULL
			CHECK( nr > 0 ),
	title		VARCHAR(255)
			NOT NULL
			CHECK( title <> '' ),
	artist_id	int
			DEFAULT 0
			NOT NULL
			REFERENCES mus_artist(id),

	duration	TIME,
	cmnt		TEXT,			-- Comment
	lyrics		TEXT,

	random		BOOLEAN			-- include in random play
			DEFAULT 'true',

	genres		VARCHAR(255),		-- temporary, for mserv

	UNIQUE( album_id, nr ),
	PRIMARY KEY( id )
);

GRANT SELECT ON mus_title TO PUBLIC;
GRANT SELECT ON mus_title_id_seq TO PUBLIC;

GRANT all ON mus_title TO GROUP dudl;
GRANT all ON mus_title_id_seq TO GROUP dudl;

COMMIT;



