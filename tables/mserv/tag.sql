BEGIN;

-- list of available tags (formerly genres)

CREATE SEQUENCE mserv_tag_id_seq;
GRANT SELECT ON mserv_tag_id_seq TO PUBLIC;
GRANT all ON mserv_tag_id_seq TO GROUP dudl;

CREATE TABLE mserv_tag (
	id		INTEGER NOT NULL
			DEFAULT nextval('mserv_tag_id_seq'),
	name		VARCHAR(32)
);

GRANT SELECT ON mserv_tag TO PUBLIC;
GRANT all ON mserv_tag TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mserv_tag__id 
	ON mserv_tag(id);
CREATE UNIQUE INDEX mserv_tag__name 
	ON mserv_tag(name);

COMMIT;
