BEGIN;

------------------------------------------------------------
--
-- mus_album
--
------------------------------------------------------------

CREATE TABLE mus_album (
	id		SERIAL,

	album		VARCHAR(255)
			NOT NULL
			CHECK( album <> '' ),
	artist_id	int
			DEFAULT NULL
			REFERENCES mus_artist(id),
-- 	publish_id	int
-- 			DEFAULT 0
-- 			NOT NULL
-- 			REFERENCES mus_publisher(id),
	publish_date	DATE,

	UNIQUE( artist_id, album ),
	PRIMARY KEY( id )
);


GRANT SELECT ON mus_album TO PUBLIC;
GRANT SELECT ON mus_album_id_seq TO PUBLIC;

GRANT all ON mus_album TO GROUP dudl;
GRANT all ON mus_album_id_seq TO GROUP dudl;


COMMIT;

