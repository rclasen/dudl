------------------------------------------------------------
--
-- bool
--
------------------------------------------------------------

CREATE FUNCTION bool( NUMERIC )
RETURNS boolean
AS 'SELECT $1 != 0;' 
LANGUAGE 'sql';



------------------------------------------------------------
--
-- trigger_update_modified
--
------------------------------------------------------------

CREATE FUNCTION trigger_update_modified()
RETURNS opaque
AS	'BEGIN
	new.modified := now();
	RETURN new;
	END;'
LANGUAGE 'plpgsql';


-- DROP FUNCTION unix2time(integer);
CREATE FUNCTION unix2time(INTEGER)
RETURNS TIMESTAMP
AS '
BEGIN
	return timestamp ''epoch'' + ($1 || '' seconds'');
END;
' LANGUAGE 'plpgsql';


-- DROP FUNCTION time2unix(timestamp);
CREATE FUNCTION time2unix(TIMESTAMP)
RETURNS INTEGER
AS '
BEGIN
	return date_part(''epoch'', $1);
END;
' LANGUAGE 'plpgsql';
