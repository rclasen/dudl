BEGIN;

-- DROP VIEW mserv_artist;
CREATE VIEW mserv_artist AS
SELECT 
	id AS artist_id,
	nname AS artist_name
FROM 
	mus_artist a;

GRANT SELECT ON mserv_artist TO PUBLIC;
GRANT all ON mserv_artist TO GROUP dudl;

COMMIT;
