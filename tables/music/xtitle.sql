BEGIN;

-- view mus_xtitle

-- TODO: use INNER JOIN + NOTNULL optimizations for mus_xtitle

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
	t.random,
	t.cmnt,
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

GRANT SELECT ON mus_xtitle TO PUBLIC;
GRANT all ON mus_xtitle TO GROUP dudl;

COMMIT;
