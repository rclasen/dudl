BEGIN;

------------------------------------------------------------
--
-- stor_file
--
------------------------------------------------------------

CREATE SEQUENCE stor_file_id_seq;
GRANT SELECT ON stor_file_id_seq TO PUBLIC;
GRANT all ON stor_file_id_seq TO GROUP dudl;

CREATE TABLE stor_file (
	id		INTEGER NOT NULL
			DEFAULT nextval('stor_file_id_seq'),

	------------------------------
	-- information related to each file

	unit_id		INTEGER		-- -> ref
			NOT NULL,

	dir		VARCHAR(255)	-- directory on this unit
			NOT NULL
			DEFAULT '',
	fname		VARCHAR(255),	-- filename (without directory)

	--ftype		INTEGER		-- file type
	--		NOT NULL,
	--		-- 0	unknown
	--		-- 1	mp3
			 

	fsize		INTEGER,	-- File size in byte


	fsum		CHAR(32),	-- md5 hex checksum for whole file
	dsum		CHAR(32),	-- md5 hex Checksum for data
	id3v1		BOOLEAN,	-- id3 tag version1 present
	id3v2		BOOLEAN,	-- id3 tag version2 present
	riff		BOOLEAN,	-- riff header present


	duration	TIME,
	channels	SMALLINT
			NOT NULL
			DEFAULT 2,

	------------------------------
	-- ID Tag information

	id_title	VARCHAR(30),	-- title of track
	id_artist	VARCHAR(30),	-- artist of track
	id_album	VARCHAR(30),	-- album this track belongs to
	id_tracknum	SMALLINT		-- index on the above album 
			NOT NULL
			DEFAULT 0,
	id_comment	VARCHAR(30),	-- additional info
	
	id_year		SMALLINT,	-- year of release
	id_genre	VARCHAR(10),	-- genre of this track
	
	------------------------------
	-- MP3 specific data

	freq		INTEGER		-- sampling frequency in HZ
			DEFAULT 44100,		-- usually 44100
	bits		SMALLINT
			DEFAULT 16,
	mpeg_ver	SMALLINT	-- mpeg version
			DEFAULT 2,		-- 1, 2
	mpeg_lay	SMALLINT	-- mpeg layer within mpeg_ver
			DEFAULT 3,		-- 1, 2, 3
	mpeg_brate	INTEGER,	-- encoded with this bitrate
	mpeg_mode	SMALLINT,	-- mpeg mode ?
	vbr		BOOLEAN,	-- variable bitrate? 


	------------------------------
	-- status

	available	BOOLEAN		-- file is readable
			NOT NULL
			DEFAULT 'true',
	broken		BOOLEAN		-- is this file damaged?
			NOT NULL 
			DEFAULT 'false',
	cmnt		TEXT,		-- Comment

	------------------------------
	-- music part of DB

	album_id	INTEGER,	-- -> ref
	album_pos	INTEGER
			CHECK( album_pos > 0 ),
	title		VARCHAR(255),
	artist_id	INTEGER		-- -> ref
			DEFAULT 0
			NOT NULL,

	------------------------------
	-- mserv data:

	-- lastplay is updated automatically on update/insert in
	-- mserv_hist. There is no need to update this column manually.
	-- TODO: find way to get lastplay from mserv_hist quickly. Maybe
	-- using a "last" flag per record, that's automatically updated.
	lastplay	TIMESTAMP NOT NULL	-- mserv: last time of play
			DEFAULT '1970-1-1 0:0:0+0'

);

GRANT SELECT ON stor_file TO PUBLIC;
GRANT all ON stor_file TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX stor_file__id
	ON stor_file(id);
CREATE UNIQUE INDEX stor_file__unit_file
	ON stor_file( unit_id, dir, fname );
CREATE UNIQUE INDEX stor_file__album_pos
	ON stor_file( album_id, album_pos );


-- checking

ALTER TABLE stor_file
	ADD CONSTRAINT stor_file__mus
		CHECK( (
			album_id ISNULL AND 
			album_pos ISNULL AND 
			title ISNULL AND
			artist_id = 0
		) OR (
			album_id NOTNULL AND 
			album_pos NOTNULL AND 
			title NOTNULL
		));
			
			
-- referential integrity

ALTER TABLE stor_file
	ADD CONSTRAINT ri__stor_file__stor_unit
		FOREIGN KEY ( unit_id )
		REFERENCES stor_unit(id)
			DEFERRABLE;

ALTER TABLE stor_file
	ADD CONSTRAINT ri__stor_file__mus_album
		FOREIGN KEY( album_id )
		REFERENCES mus_album(id)
			DEFERRABLE;

ALTER TABLE stor_file
	ADD CONSTRAINT ri__stor_file__mus_artist
		FOREIGN KEY( artist_id )
		REFERENCES mus_artist(id)
			DEFERRABLE;



-- sequence for unsorted files:
CREATE SEQUENCE stor_file_unknown_pos_seq;
-- UPDATE stor_file SET album_id = 0, title = fname, album_pos = NEXTVAL('stor_file_unknown_pos_seq') WHERE unit_id =351 AND dir = 'diverses';

COMMIT;

