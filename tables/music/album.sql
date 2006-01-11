BEGIN;

------------------------------------------------------------
--
-- mus_album
--
------------------------------------------------------------

CREATE SEQUENCE mus_album_id_seq;
GRANT SELECT ON mus_album_id_seq TO PUBLIC;
GRANT all ON mus_album_id_seq TO GROUP dudl;

CREATE TABLE mus_album (
	id		INTEGER NOT NULL
			DEFAULT nextval('mus_album_id_seq'),

	album		VARCHAR(255)
			NOT NULL
			CONSTRAINT mus_album__album
				CHECK( album <> '' ),
	artist_id	INTEGER
			DEFAULT NULL,
-- 	publish_id	INTEGER
-- 			DEFAULT NULL,
	publish_date	DATE
-- TODO: publish_date -> publish_year INTEGER;
);

GRANT SELECT ON mus_album TO PUBLIC;
GRANT all ON mus_album TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mus_album__id 
	ON mus_album(id);
CREATE UNIQUE INDEX mus_album__artist_album 
	ON mus_album(artist_id, album);

-- referential integrity

ALTER TABLE mus_album
	ADD CONSTRAINT ri__mus_album__mus_artist
		FOREIGN KEY ( artist_id )
		REFERENCES mus_artist(id)
			DEFERRABLE;

--ALTER TABLE mus_album
--	ADD CONSTRAINT ri__mus_album__mus_publisher
--		FOREIGN KEY ( artist_id )
-- 		REFERENCES mus_publisher(id),
--		DEFERRABLE;

COMMIT;

