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


