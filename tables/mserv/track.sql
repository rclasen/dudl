BEGIN;

-- DROP VIEW mserv_track;
CREATE VIEW mserv_track AS
SELECT 
	t.id,
	t.album_id,
	t.album_pos,
	date_part('epoch',t.duration) AS dur,
	time2unix(t.lastplay) AS lplay,
	t.title,
	t.artist_id,
	stor_filename(u.collection,u.colnum,t.dir,t.fname) 
		AS filename 
FROM 
	stor_file t  
		INNER JOIN stor_unit u  
		ON t.unit_id = u.id 
WHERE 
	t.title NOTNULL 
	AND NOT t.broken;

GRANT SELECT ON mserv_track TO PUBLIC;
GRANT all ON mserv_track TO GROUP dudl;

COMMIT;
