BEGIN;
------------------------------------------------------------
--
-- stor_unit
--
------------------------------------------------------------

CREATE TABLE stor_unit (
	id		SERIAL,

	collection	CHAR(8),	-- sl, kr, mm, ...
	colnum		SMALLINT	-- 1, 2, 3, ...
			NOT NULL
			DEFAULT 0,

	volname		CHAR(12),	-- Volume name
	size		INTEGER,	-- disk size - in bytes

	UNIQUE( collection, colnum ),
	PRIMARY KEY( id )
);

GRANT SELECT ON stor_unit TO PUBLIC;
GRANT SELECT ON stor_unit_id_seq TO PUBLIC;

GRANT all ON stor_unit TO GROUP dudl;
GRANT all ON stor_unit_id_seq TO GROUP dudl;

-- sample data:
INSERT INTO stor_unit (collection, colnum )
	VALUES( 'local', 0 );


COMMIT;
