BEGIN;

CREATE SEQUENCE mserv_queue_id_seq;
GRANT SELECT ON mserv_queue_id_seq TO PUBLIC;
GRANT all ON mserv_queue_id_seq TO GROUP dudl;

-- DROP TABLE mserv_queue;
CREATE TABLE mserv_queue (
	id		INTEGER NOT NULL
			DEFAULT nextval('mserv_queue_id_seq'),
	file_id		INTEGER NOT NULL,
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
	ADD CONSTRAINT ri__mserv_queue__stor_file
		FOREIGN KEY ( file_id )
		REFERENCES stor_file( id )
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


-- trigger to check file validity

-- DROP TRIGGER mserv_queue__up ON mserv_queue;
CREATE TRIGGER mserv_queue__up
AFTER INSERT OR UPDATE
ON mserv_queue FOR EACH ROW
EXECUTE PROCEDURE mserv_check_file();
 
COMMIT;
