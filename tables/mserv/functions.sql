BEGIN;


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



-- DROP FUNCTION gettag( varchar );
CREATE FUNCTION gettag( varchar )
RETURNS INTEGER AS '
DECLARE
	tag RECORD;
BEGIN
	SELECT INTO tag id 
	FROM mserv_tag
	WHERE name = lower($1);

	IF NOT FOUND THEN
		RAISE EXCEPTION ''tag not found: %'', $1;
	END IF;

	RETURN tag.id;
END;
' LANGUAGE 'plpgsql';


-- DROP FUNCTION mserv_tags(integer);
CREATE FUNCTION mserv_tags(integer)
RETURNS char AS '
DECLARE
	tag RECORD;
	tags VARCHAR := '''';
BEGIN
	FOR tag IN SELECT name 
		FROM 
			mserv_filetag tt 
				INNER JOIN mserv_tag ta
				ON tt.tag_id = ta.id
		WHERE
			tt.file_id = $1
		ORDER BY
			ta.id
	LOOP
		IF tags = '''' THEN
			tags := tag.name; 
		ELSE
			tags := tags || '','' || tag.name;
		END IF;
	END LOOP;

	RETURN tags;
END;
' LANGUAGE 'plpgsql';

-- DROP FUNCTION mserv_tagids(integer);
CREATE FUNCTION mserv_tagids(integer)
RETURNS char AS '
DECLARE
	tag RECORD;
	tags VARCHAR := '''';
BEGIN
	FOR tag IN SELECT tag_id AS id
		FROM 
			mserv_filetag tt 
		WHERE
			tt.file_id = $1
		ORDER BY
			tt.tag_id
	LOOP
		IF tags = '''' THEN
			tags := tag.id; 
		ELSE
			tags := tags || '','' || tag.id;
		END IF;
	END LOOP;

	RETURN tags;
END;
' LANGUAGE 'plpgsql';


-- DROP FUNCTION mserv_tagged(integer, integer );
CREATE FUNCTION mserv_tagged(integer, integer )
RETURNS boolean AS '
DECLARE
	id integer;
BEGIN
	SELECT INTO id tag_id
	FROM mserv_filetag 
	WHERE file_id = $1 AND tag_id = $2;

	IF NOT FOUND THEN
		RETURN 0;
	END IF;

	RETURN 1;
END;
' LANGUAGE 'plpgsql';


-- DROP FUNCTION mserv_tagged(integer, varchar );
CREATE FUNCTION mserv_tagged(integer, varchar )
RETURNS boolean AS '
BEGIN
	RETURN mserv_tagged($1, gettag($2));
END;
' LANGUAGE 'plpgsql';



-- DROP FUNCTION mserv_set_tag( integer, integer );
CREATE FUNCTION mserv_set_tag( integer, integer )
RETURNS boolean AS '
BEGIN
	IF mserv_tagged($1,$2) THEN
		RETURN 1;
	END IF;

	INSERT INTO mserv_filetag( file_id, tag_id )
	VALUES( $1, $2 );

	RETURN 1;
END;
' LANGUAGE 'plpgsql';


-- DROP FUNCTION mserv_set_tag( integer, varchar );
CREATE FUNCTION mserv_set_tag( integer, varchar )
RETURNS boolean AS '
BEGIN
	RETURN mserv_set_tag( $1, gettag($2) );
END;
'LANGUAGE 'plpgsql';


-- DROP FUNCTION mserv_del_tag( integer, integer );
CREATE FUNCTION mserv_del_tag( integer, integer )
RETURNS boolean AS '
BEGIN
	DELETE FROM mserv_filetag 
		WHERE file_id = $1 AND tag_id = $2;

	RETURN 1;
END;
' LANGUAGE 'plpgsql';


-- DROP FUNCTION mserv_del_tag( integer, varchar );
CREATE FUNCTION mserv_del_tag( integer, varchar )
RETURNS boolean AS '
BEGIN
	RETURN mserv_del_tag( $1, gettag($2) );
END;
'LANGUAGE 'plpgsql';

COMMIT;
