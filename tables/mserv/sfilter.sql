BEGIN;

-- saved filters

CREATE SEQUENCE juke_sfilter_id_seq;
GRANT SELECT ON juke_sfilter_id_seq TO PUBLIC;
GRANT all ON juke_sfilter_id_seq TO GROUP dudl;

-- DROP TABLE juke_sfilter;
CREATE TABLE juke_sfilter (
	id		INTEGER NOT NULL
			DEFAULT nextval('juke_sfilter_id_seq'),
	name		VARCHAR(32),
	filter		TEXT
);

GRANT SELECT ON juke_sfilter TO PUBLIC;
GRANT all ON juke_sfilter TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX juke_sfilter__id 
	ON juke_sfilter(id);
CREATE UNIQUE INDEX juke_sfilter__name 
	ON juke_sfilter( lower(name) );

COMMIT;
