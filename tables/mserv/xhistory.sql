BEGIN;

-- TODO: rename mserv->juke

-- DROP VIEW mserv_xhist;
CREATE VIEW mserv_xhist AS
SELECT 
	t.*,
	time2unix(h.added) AS played, 
	h.user_id,
	h.completed
FROM 
	mserv_track t
		INNER JOIN mserv_hist h
		ON h.file_id = t.id;

GRANT SELECT ON mserv_xhist TO PUBLIC;
GRANT all ON mserv_xhist TO GROUP dudl;

COMMIT;
