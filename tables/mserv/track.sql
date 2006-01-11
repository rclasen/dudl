BEGIN;

-- TODO: rename mserv->juke

-- DROP VIEW mserv_track;
CREATE VIEW mserv_track AS
SELECT 
	t.id,
	t.album_pos,
	date_part('epoch',t.duration) AS dur,
	time2unix(t.lastplay) AS lplay,
	t.title,
	stor_filename(u.collection,u.colnum,t.dir,t.fname) 
		AS filename,
	a.*,
	ar.*
FROM 
	stor_file t INNER JOIN stor_unit u  
		ON t.unit_id = u.id 
	INNER JOIN mserv_album a
		ON t.album_id = a.album_id
	INNER JOIN mserv_artist ar
		ON t.artist_id = ar.artist_id

WHERE 
	title NOTNULL AND
	NOT t.broken;

GRANT SELECT ON mserv_track TO PUBLIC;
GRANT all ON mserv_track TO GROUP dudl;


-- DROP FUNCTION mserv_check_file();
CREATE FUNCTION mserv_check_file()
RETURNS opaque AS  '
DECLARE
	file	RECORD;
BEGIN
	SELECT INTO file id 
		FROM stor_file 
		WHERE id = new.file_id AND title NOTNULL;

	IF NOT FOUND THEN
		RAISE EXCEPTION ''found no music file with id %'', new.file_id;
	END IF;

	RETURN new;
END;
' LANGUAGE 'plpgsql';



COMMIT;
