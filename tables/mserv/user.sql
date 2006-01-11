BEGIN;

-- TODO: rename mserv->juke

CREATE SEQUENCE mserv_user_id_seq;
GRANT SELECT ON mserv_user_id_seq TO PUBLIC;
GRANT all ON mserv_user_id_seq TO GROUP dudl;

-- DROP TABLE mserv_user;
CREATE TABLE mserv_user (
	id		INTEGER NOT NULL
			DEFAULT nextval('mserv_user_id_seq'),
	name		VARCHAR(16),
	pass		VARCHAR NOT NULL,
	lev		INTEGER NOT NULL	-- see below
);

GRANT SELECT ON mserv_user TO PUBLIC;
GRANT all ON mserv_user TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mserv_user__id
	ON mserv_user(id);
CREATE UNIQUE INDEX mserv_user__name
	ON mserv_user( lower(name) );

COMMIT;
