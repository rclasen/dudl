BEGIN;
------------------------------------------------------------
--
-- stor_unit
--
------------------------------------------------------------

CREATE SEQUENCE stor_unit_id_seq;
GRANT SELECT ON stor_unit_id_seq TO PUBLIC;
GRANT all ON stor_unit_id_seq TO GROUP dudl;

CREATE TABLE stor_unit (
	id		INTEGER NOT NULL
			DEFAULT nextval('stor_unit_id_seq'),

	collection	VARCHAR(8),	-- sl, kr, mm, ...
	colnum		SMALLINT	-- 1, 2, 3, ...
			NOT NULL
			DEFAULT 0,

	volname		VARCHAR(12),	-- Volume name
	size		INTEGER,	-- disk size - in bytes

	autoscan	BOOLEAN NOT NULL -- automagically scan this unit 
			DEFAULT false	-- for new/deleted files

);

GRANT SELECT ON stor_unit TO PUBLIC;
GRANT all ON stor_unit TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX stor_unit__id
	ON stor_unit(id);
CREATE UNIQUE INDEX stor_unit__col_num
	ON stor_unit( collection, colnum );

-- data:

INSERT INTO stor_unit (collection, colnum )
	VALUES( 'local', 0 );


COMMIT;
