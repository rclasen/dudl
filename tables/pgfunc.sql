------------------------------------------------------------
--
-- pgx_triggers
--
-- lists all stored triggers
--
------------------------------------------------------------

CREATE VIEW pgx_trigger AS
SELECT
	r1.relname		AS table_name,
	t.tgtype		AS trigger_type,
	t.tgisconstraint	AS is_constr,
	CASE 
		WHEN t.tgisconstraint THEN t.tgconstrname
		ELSE t.tgname	
		END		AS func_or_constr,
	t.tgenabled		AS enabled,
	f.proname		AS trigger_function
FROM   
	pg_class	r1, 
	pg_trigger	t, 
	pg_proc		f
WHERE  
	r1.oid = t.tgrelid AND
	t.tgfoid = f.oid;


------------------------------------------------------------
--
-- pgx_refint
--
-- lists declared referential integrity
--
------------------------------------------------------------

CREATE VIEW pgx_refint AS
SELECT
	r1.relname		AS table_name,
	t.tgtype		AS trigger_type,
	t.tgenabled		AS enabled,
	f.proname		AS trigger_function,
	t.tgargs		AS trigger_args
FROM   
	pg_class	r1, 
	pg_trigger	t, 
	pg_proc		f
WHERE  
	r1.oid = t.tgrelid AND
	t.tgfoid = f.oid AND
	t.tgisconstraint;

------------------------------------------------------------
--
-- pgx_proc
--
-- list source of your own stored procedures
--
------------------------------------------------------------

CREATE VIEW pgx_proc AS
SELECT
	proname,
	prosrc
FROM
	pg_proc
WHERE
	oid > 9000; -- bis zu welcher OID macht sich postgresql breit?




