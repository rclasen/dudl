BEGIN;

------------------------------------------------------------
--
-- stor_file
--
------------------------------------------------------------

CREATE TABLE stor_file (
	id		SERIAL,
	modified	TIMESTAMP,

	------------------------------
	-- information related to each file

	unitid		INTEGER
			NOT NULL
			REFERENCES stor_unit(id),

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

	broken		BOOLEAN		-- is this file damaged?
			NOT NULL 
			DEFAULT 'false',
	cmnt		TEXT,		-- Comment

	------------------------------
	-- linkage to music part of DB

	-- export	INTEGER,	-- TODO: delete column
	titleid		INTEGER
			REFERENCES mus_title(id)
			ON DELETE SET NULL,

	UNIQUE( unitid, dir, fname ),
	PRIMARY KEY( id )
);

GRANT SELECT ON stor_file TO PUBLIC;
GRANT SELECT ON stor_file_id_seq TO PUBLIC;

GRANT all ON stor_file TO GROUP dudl;
GRANT all ON stor_file_id_seq TO GROUP dudl;



------------------------------------------------------------
--
-- stor_file
--
------------------------------------------------------------

CREATE TRIGGER trigger_stor_file_modified
BEFORE INSERT OR UPDATE 
ON stor_file
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_modified();


CREATE VIEW stor_xfile AS
SELECT
	f.id,
	f.unitid,
	u.collection		as col,
	u.colnum,
	f.dir,
	f.fname,
	f.broken,
	f.cmnt,
	f.titleid,
	f.freq
FROM
	stor_unit u,
	stor_file f
WHERE
	u.id = f.unitid;


COMMIT;

