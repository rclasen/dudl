BEGIN;

-- TODO: rename mserv->juke

-- DROP VIEW mserv_dupes;
CREATE VIEW mserv_dupes AS
SELECT t.*, h.added
FROM 
	( SELECT file_id 
		FROM mserv_hist
		WHERE user_id = 0
		GROUP BY file_id
		HAVING count(*) > 1) d 
	INNER JOIN mserv_track t
		ON t.id = d.file_id
	INNER JOIN (SELECT * 
		FROM mserv_hist
		WHERE user_id = 0 ) h
		ON h.file_id = d.file_id
ORDER BY t.id, h.added
;


GRANT SELECT ON mserv_dupes TO PUBLIC;
GRANT all ON mserv_dupes TO GROUP dudl;

COMMIT;
