BEGIN;

CREATE SEQUENCE mserv_queue_id_seq;
GRANT SELECT ON mserv_queue_id_seq TO PUBLIC;
GRANT all ON mserv_queue_id_seq TO GROUP dudl;

-- DROP TABLE mserv_queue;
CREATE TABLE mserv_queue (
	id		INTEGER NOT NULL
			DEFAULT nextval('mserv_queue_id_seq'),
	title_id	INTEGER NOT NULL,
	added		TIMESTAMP NOT NULL
			DEFAULT CURRENT_TIMESTAMP,
	user_id		INTEGER		-- who queued this track?
);

GRANT SELECT ON mserv_queue TO PUBLIC;
GRANT all ON mserv_queue TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mserv_queue__id
	ON mserv_queue(id);

-- referential integrity

ALTER TABLE mserv_queue
	ADD CONSTRAINT ri__mserv_queue__mus_title
		FOREIGN KEY ( title_id )
		REFERENCES mus_title( id )
			ON DELETE CASCADE
			ON UPDATE CASCADE
			DEFERRABLE;

ALTER TABLE mserv_queue
	ADD CONSTRAINT ri__mserv_queue__mserv_user
		FOREIGN KEY ( user_id )
		REFERENCES mserv_user( id )
			ON DELETE SET NULL
			ON UPDATE CASCADE
			DEFERRABLE;

COMMIT;
