BEGIN;

------------------------------------------------------------
--
-- mus_artist
--
------------------------------------------------------------

CREATE TABLE mus_artist (
	id		SERIAL,

	vname		VARCHAR(255),
	nname		VARCHAR(255)
			NOT NULL
			CHECK( nname <> '' ),

	UNIQUE( vname, nname ),
	PRIMARY KEY( id )
);

GRANT SELECT ON mus_artist TO PUBLIC;
GRANT SELECT ON mus_artist_id_seq TO PUBLIC;

GRANT all ON mus_artist TO GROUP dudl;
GRANT all ON mus_artist_id_seq TO GROUP dudl;



------------------------------------------------------------
--
-- DATA
--
------------------------------------------------------------

INSERT INTO mus_artist (id, nname) 
	VALUES( 0, 'UNKNOWN');

COMMIT;
