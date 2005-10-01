BEGIN;

-- saved filters

CREATE SEQUENCE juke_filter_id_seq;
GRANT SELECT ON juke_filter_id_seq TO PUBLIC;
GRANT all ON juke_filter_id_seq TO GROUP dudl;

CREATE TABLE juke_filter (
	id		INTEGER NOT NULL
			DEFAULT nextval('juke_filter_id_seq'),
	name		VARCHAR(32),
	filter		TEXT
);

GRANT SELECT ON juke_filter TO PUBLIC;
GRANT all ON juke_filter TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX juke_filter__id 
	ON juke_filter(id);
CREATE UNIQUE INDEX juke_filter__name 
	ON juke_filter( lower(name) );

COMMIT;
