BEGIN;

------------------------------------------------------------
--
-- mus_publisher
--
------------------------------------------------------------

-- CREATE TABLE mus_publisher (
-- 	id		SERIAL,

-- 	publisher	varchar(255)
-- 			NOT NULL
-- 			CHECK( publisher <> '' )
-- 			UNIQUE,

-- 	PRIMARY KEY( id )
-- );

-- GRANT SELECT ON mus_publisher TO PUBLIC;
-- GRANT SELECT ON mus_publisher_id_seq TO PUBLIC;

-- GRANT all ON mus_publisher TO GROUP dudl;
-- GRANT all ON mus_publisher_id_seq TO GROUP dudl;


------------------------------------------------------------
--
-- DATA
--
------------------------------------------------------------

-- insert INTO mus_publisher (id, publisher) 
--	VALUES( 0, 'UNKNOWN' );

COMMIT;
