BEGIN;

-- view mus_xtitle

-- DROP VIEW mus_xtitle;
CREATE VIEW mus_xtitle AS
SELECT
	aa.id			AS album_artist_id,
	aa.nname		AS album_artist,
	t.album_id,
	a.album,
	a.publish_date,
	t.id,
	t.album_pos		AS pos,
	t.title,
	ta.id			AS title_artist_id,
	ta.nname		AS title_artist,
	mserv_tags(t.id)	AS tags,
	mserv_tagids(t.id)	AS tid,
	t.cmnt,
	stor_filename( u.collection, u.colnum, t.dir, t.fname )
				AS filename
FROM
	mus_album a 
		INNER JOIN mus_artist aa
		ON a.artist_id = aa.id

		INNER JOIN stor_file t
		ON t.album_id = a.id

		INNER JOIN mus_artist ta
		ON t.artist_id = ta.id
		
		INNER JOIN stor_unit u
		ON t.unit_id = u.id

WHERE
	t.title NOTNULL
;

GRANT SELECT ON mus_xtitle TO PUBLIC;
GRANT all ON mus_xtitle TO GROUP dudl;

COMMIT;

-- select id, title_artist, substr(title,0,40), album, album_id from mus_xtitle where not exists (select file_id from mserv_filetag where tag_id = 29 and file_id = id) order by title_artist, title;
