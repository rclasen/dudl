BEGIN;

-- DROP VIEW mserv_track;
CREATE VIEW mserv_track AS
SELECT 
	t.id,
	t.album_id,
	t.nr,
	date_part('epoch',f.duration) AS dur,
	time2unix(t.lastplay) AS lplay,
	t.title,
	t.artist_id,
	stor_filename(u.collection,u.colnum,f.dir,f.fname) 
		AS filename 
FROM 
	( 
		mus_title t  
			INNER JOIN stor_file f  
			ON t.id = f.titleid 
		)  
		INNER JOIN stor_unit u  
		ON f.unitid = u.id 
WHERE 
	f.titleid NOTNULL 
	AND NOT f.broken;

GRANT SELECT ON mserv_track TO PUBLIC;
GRANT all ON mserv_track TO GROUP dudl;

COMMIT;
