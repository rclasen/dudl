BEGIN;

------------------------------------------------------------
--
-- mus_title
--
------------------------------------------------------------

CREATE SEQUENCE mus_title_id_seq;
GRANT SELECT ON mus_title_id_seq TO PUBLIC;
GRANT all ON mus_title_id_seq TO GROUP dudl;

CREATE TABLE mus_title (
	id		INTEGER NOT NULL
			DEFAULT nextval('mus_title_id_seq'),

	album_id	INTEGER			-- -> ref
			NOT NULL,
	nr		INTEGER
			NOT NULL
			CHECK( nr > 0 ),
	title		VARCHAR(255)
			NOT NULL
			CHECK( title <> '' ),
	artist_id	INTEGER			-- -> ref
			DEFAULT 0
			NOT NULL,

	duration	TIME,			-- really needed?
	cmnt		TEXT,			-- Comment
	lyrics		TEXT,

	-- lastplay is updated automatically on update/insert in
	-- mserv_hist. There is no need to update this column manually.
	lastplay	TIMESTAMP NOT NULL	-- mserv: last time of play
			DEFAULT '1970-1-1 0:0:0+0'
);

GRANT SELECT ON mus_title TO PUBLIC;
GRANT all ON mus_title TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mus_title__id
	ON mus_title(id);
CREATE UNIQUE INDEX mus_titls__album_nr
	ON mus_title( album_id, nr );


-- referetnial integrity

ALTER TABLE mus_title
	ADD CONSTRAINT ri__mus_title__mus_album
		FOREIGN KEY( album_id )
		REFERENCES mus_album(id)
			DEFERRABLE;

ALTER TABLE mus_title
	ADD CONSTRAINT ri__mus_title__mus_artist
		FOREIGN KEY( artist_id )
		REFERENCES mus_artist(id)
			DEFERRABLE;

COMMIT;



