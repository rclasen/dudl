BEGIN;

-- TODO: move regexps to Dudl::StorExport module
-- TODO: kill this table

------------------------------------------------------------
--
-- stor_export
--
------------------------------------------------------------

CREATE TABLE stor_export (
	id		SERIAL,
	modified	TIMESTAMP,

	regexp		varchar(250),	-- see below
	fields		TEXT,		-- see below
	description	TEXT,		-- what does this do?
	priority	INTEGER,	-- to determine match order

	UNIQUE( regexp ),
	PRIMARY KEY( id )
);


-- regexp:	case insensitive extended regular expresion to be 
--		matched against "dir/fname". 
--		Do not include any extension in regexp!
-- fields:	comma seperated list of items found by the regexp. These
--		Items must be marked with a pair of parens. Known items:
--		artist, title, album, titlenum
--		Each element in the list corrosponds an opening paren in 
--		the regexp. Elements may be left blank.

GRANT SELECT ON stor_export TO PUBLIC;
GRANT SELECT ON stor_export_id_seq TO PUBLIC;

GRANT all ON stor_export TO GROUP dudl;
GRANT all ON stor_export_id_seq TO GROUP dudl;



------------------------------------------------------------
--
-- trigger_stor_export_modified
--
------------------------------------------------------------

CREATE TRIGGER trigger_stor_export_modified
BEFORE INSERT OR UPDATE 
ON stor_export
FOR EACH ROW
EXECUTE PROCEDURE trigger_update_modified();


------------------------------------------------------------
--
-- DATA
--
------------------------------------------------------------

INSERT INTO stor_export ( id, description ) 
	VALUES( 0, 'Dont - For duplicate Files' );
INSERT INTO stor_export ( id, description ) 
	VALUES( 1, 'manual (dont) - If regexp + ID3 Tag fail' );
INSERT INTO stor_export ( id, description ) 
	VALUES( 2, 'ID3 Tag - use Information from ID3 Tag' );

SELECT setval( 'stor_export_id_seq', 2 );

-- rating: <data items> <special items> <special chars> <uniquenes>

-- sleepless - non-sampler 
-- 5 3 11 +2
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: .--.album/tartist.--.01_title',
        '\\.--\\.([^/]+)/([^/]+)\\.--\\.([0-9]+)_([^/]+)',
        'album,artist,titlenum,title');

-- 5 4 11 +2
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: (aartist) album/01 - [tartist] title',
	'\\([^/]+\\) ([^/]+)/([0-9]+)[-_ .]*\\[([^/]+)\\][-_ .]*([^/]+)',
        'album,titlenum,artist,title');
-- 5 3 11 +2
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: \\(aartist - \\)album/01_(tartist) title',
	'[_ .]-+[_ .]+([^/]+)/([0-9]+)[-_ .]*\\(([^/]+)\\)[-_ .]*([^/]+)',
        'album,titlenum,artist,title');


-- fehlt noch:
INSERT INTO stor_export ( description, regexp, fields) VALUES (
	'Regexp: ^|/)artist (album #01) title',
	'(^|/)([^/]+) \\(([^/]+) #([0-9]+)\\) - ([^/]+)',
	',artist,album,titlenum,title');








-- sleepless - sampler A
-- 4 2 8 +1
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: \\(artist - \\)album/01_artist.--.title',
        '([_ .]-+[_ .]+)?([^/]+)/([0-9]+)_([^/]+)\\.--\\.([^/]+)',
        ',album,titlenum,artist,title');
-- sleepless - sampler B
-- 4 2 7 +1
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: \\(artist - \\)album/artist.--.01_title',
        '([_ .]-+[_ .]+)?([^/]+)/([^/]+)\\.--\\.([0-9]+)_([^/]+)',
        ',album,artist,titlenum,title');

-- 4 3 7 -1
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: \\(artist - \\)album/01_artist.-.title',
        '([_ .]-+[_ .]+)?([^/]+)/([0-9]+)[-_ .]+([^/]+)[-_ .]+-[-_ .]+([^/])',
        ',album,titlenum,artist,title');






-- 6 4 10 -1
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: \\(artist - \\)album/artist - album-01-title',
        '([_ .]-+[_ .]+)?[^/]+/([^/]+)[-_ .]+-[-_ .]+([^/]+)-([0-9]+)-([^/]+)',
        ',artist,album,titlenum,title');
-- 5 3 11 +1
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: artist.-.album/artist.-.01.-.title',
        '([_ .]-+[_ .]+)?([^/]+)/([^/]+)[-_ .]+-[-_ .]+([0-9]+)[-_ .]+-[-_ .]+([^/]+)',
        ',album,artist,titlenum,title');







-- 4 4 7
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: (artist) album/01 - title',
        '\\(([^/]+)\\) ([^/]+)/([0-9]+)[-_ .]+([^/]+)',
        'artist,album,titlenum,title');

-- 4 3 8
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: artist - album/01 - title',
        '([^/]+)[_ .]-+[_ .]+([^/]+)/([0-9]+)[-_ .]+([^/]+)',
        'artist,album,titlenum,title');

-- 3 1 3 -1
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: album/01_title',
        '([^/]+)/([0-9]+)[-_ .]+([^/]+)',
        'album,titlenum,title');

-- 3 3 4
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: (artist) album/title',
	'\\(([^/]+)\\) ([^/]+)/([^/]+)',
        'artist,album,title');

-- 3 3 7 -1
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: artist - album/artist - title',
	'-[-_ .]+([^/]+)/([^/]+)[-_ .]+-[-_ .]+([^/]+)',
        'album,artist,title');
-- 3 2 4 -2
INSERT INTO stor_export ( description, regexp, fields) VALUES (
        'Regexp: album/artist - title',
        '([^/]+)/([^/]+)[-_ .]+-[-_ .]+([^/]+)',
        'album,artist,title');





COMMIT;

