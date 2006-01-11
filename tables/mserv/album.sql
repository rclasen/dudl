BEGIN;

-- TODO: rename mserv->juke

-- DROP VIEW mserv_album;
CREATE VIEW mserv_album AS
SELECT 
	a.id AS album_id,
	a.publish_date AS album_publish_date,
	a.album AS album_name,
	a.artist_id AS album_artist_id,
	ar.nname AS album_artist_name
FROM 
	mus_album a INNER JOIN mus_artist ar
		ON a.artist_id = ar.id;

GRANT SELECT ON mserv_album TO PUBLIC;
GRANT all ON mserv_album TO GROUP dudl;

COMMIT;
