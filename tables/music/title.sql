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
			NOT NULL
			DEFAULT 'true',

	genres		VARCHAR(255),		-- temporary, for mserv

	UNIQUE( album_id, nr ),
	PRIMARY KEY( id )
);

GRANT SELECT ON mus_title TO PUBLIC;
GRANT SELECT ON mus_title_id_seq TO PUBLIC;

GRANT all ON mus_title TO GROUP dudl;
GRANT all ON mus_title_id_seq TO GROUP dudl;

CREATE VIEW mus_xtitle AS
SELECT
	aa.id			AS album_artist_id,
	aa.nname		AS album_artist,
	t.album_id,
	a.album,
	t.id,
	t.nr,
	t.title,
	ta.id			AS title_artist_id,
	ta.nname		AS title_artist,
	t.genres,
	u.collection,
	u.colnum,
	f.dir,
	f.fname
FROM
	mus_title		t,
	mus_album		a,
	mus_artist		ta,
	mus_artist		aa,
	stor_file		f,
	stor_unit		u
WHERE
	t.artist_id = ta.id AND
	t.album_id = a.id AND
	a.artist_id = aa.id AND
	t.id = f.titleid AND
	f.unitid = u.id;

COMMIT;



