BEGIN;

-- DROP FUNCTION stor_filename(char,integer,char,char);
CREATE FUNCTION stor_filename(char,integer,char,char)
RETURNS char AS '
DECLARE
	col ALIAS FOR $1;
	colnum ALIAS FOR $2;
	dir ALIAS FOR $3;
	fname ALIAS FOR $4;

	pdir VARCHAR;
BEGIN
	IF dir IS NULL OR dir = '''' THEN
		pdir := '''';
	ELSE
		pdir := dir || ''/'';
	END IF;

	return col || ''/'' || col ||
		to_char(cast( colnum AS numeric),''FM0000'') || ''/'' ||
		pdir || fname;
END;
' LANGUAGE 'plpgsql';

COMMIT;
