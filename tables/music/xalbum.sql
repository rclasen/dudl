BEGIN;

-- view mus_xalbum

-- DROP VIEW mus_xalbum;
CREATE VIEW mus_xalbum AS
SELECT
	a.id,
	a.album,
	aa.nname,
	a.publish_date
FROM
	mus_album a 
		INNER JOIN mus_artist aa
		ON a.artist_id = aa.id

;

GRANT SELECT ON mus_xalbum TO PUBLIC;
GRANT all ON mus_xalbum TO GROUP dudl;

COMMIT;
