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
	t.tgname		AS trigger_name,
	t.tgenabled		AS enabled,
	f.proname		AS trigger_function
FROM   
	pg_class	r1, 
	pg_trigger	t, 
	pg_proc		f
WHERE  
	r1.oid = t.tgrelid AND
	t.tgfoid = f.oid AND
	NOT t.tgisconstraint;


------------------------------------------------------------
--
-- pgx_constraint_triggers
--
-- lists all stored constraint triggers
--
------------------------------------------------------------

-- hrm, when loading a pg_dump, tgconstrrelid isn't set
-- therefore this join doesn't work
--
-- CREATE VIEW pgx_constraint_trigger AS
-- SELECT
-- 	r1.relname		AS table_name,
-- 	t.tgtype		AS trigger_type,
-- 	t.tgname		AS trigger_name,
-- 	t.tgenabled		AS enabled,
-- 	f.proname		AS trigger_function,
-- 	t.tgconstrname		AS constrain_name,
-- 	r2.relname		AS foreign_table
-- FROM   
-- 	pg_class	r1, 
-- 	pg_class	r2, 
-- 	pg_trigger	t, 
-- 	pg_proc		f
-- WHERE  
-- 	r1.oid = t.tgrelid AND
-- 	t.tgfoid = f.oid AND
-- 	r2.oid = t.tgconstrrelid;

CREATE VIEW pgx_constraint_trigger AS
SELECT
	r1.relname		AS table_name,
	t.tgtype		AS trigger_type,
	t.tgname		AS trigger_name,
	t.tgenabled		AS enabled,
	f.proname		AS trigger_function,
	t.tgconstrname		AS constrain_name
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
