BEGIN;

-- DROP VIEW mserv_xhist;
CREATE VIEW mserv_xhist AS
SELECT 
	t.*,
	time2unix(h.added) AS played, 
	h.user_id
FROM 
	mserv_track t
		INNER JOIN mserv_hist h
		ON h.title_id = t.id;

GRANT SELECT ON mserv_xhist TO PUBLIC;
GRANT all ON mserv_xhist TO GROUP dudl;

COMMIT;
