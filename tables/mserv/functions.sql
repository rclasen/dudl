BEGIN;

-- DROP FUNCTION mserv_tags(integer);
CREATE FUNCTION mserv_tags(integer)
RETURNS char AS '
DECLARE
	tag RECORD;
	tags VARCHAR := '''';
BEGIN
	FOR tag IN SELECT name 
		FROM 
			mserv_titletag tt 
				INNER JOIN mserv_tag ta
				ON tt.tag_id = ta.id
		WHERE
			tt.title_id = $1
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
			mserv_titletag tt 
		WHERE
			tt.title_id = $1
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

COMMIT;
