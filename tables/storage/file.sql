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

	dir		VARCHAR(255),	-- directory on this unit
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
	-- linkage to music part of DB

	export		INTEGER
			REFERENCES stor_export(id)
			ON DELETE SET NULL,
			-- what information to use to generate usable 
			-- track names
			--  NULL	to be determined
			--  0		don't (duplicate)
			--  1		don't (manual)
			--  2		ID3 Tag
			--  3..		with matching regexp from stor_regexp
	titleid		INTEGER
			REFERENCES music_title(id)
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


COMMIT;

