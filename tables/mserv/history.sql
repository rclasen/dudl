BEGIN;

CREATE SEQUENCE mserv_hist_id_seq;
GRANT SELECT ON mserv_hist_id_seq TO PUBLIC;
GRANT all ON mserv_hist_id_seq TO GROUP dudl;

-- DROP TABLE mserv_hist;
CREATE TABLE mserv_hist (
	id		INTEGER NOT NULL
			DEFAULT nextval('mserv_hist_id_seq'),
	file_id		INTEGER NOT NULL,
	added		TIMESTAMP NOT NULL
			DEFAULT CURRENT_TIMESTAMP,
	user_id		INTEGER		-- who queued this track?
);

GRANT SELECT ON mserv_hist TO PUBLIC;
GRANT all ON mserv_hist TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mserv_hist__id
	ON mserv_hist(id);

-- referential integrity

ALTER TABLE mserv_hist
	ADD CONSTRAINT ri__mserv_hist__stor_file
		FOREIGN KEY ( file_id )
		REFERENCES stor_file( id )
			ON DELETE CASCADE
			ON UPDATE CASCADE
			DEFERRABLE;

ALTER TABLE mserv_hist
	ADD CONSTRAINT ri__mserv_hist__mserv_user
		FOREIGN KEY ( user_id )
		REFERENCES mserv_user( id )
			ON DELETE SET NULL
			ON UPDATE CASCADE
			DEFERRABLE;


-- trigger to update stor_file.lastplay on insert

-- DROP FUNCTION mserv_hist__up_lastplay();
CREATE FUNCTION mserv_hist__up_lastplay()
RETURNS opaque AS  '
DECLARE
	file	RECORD;
BEGIN
	SELECT INTO file lastplay 
		FROM stor_file 
		WHERE id = new.file_id AND title NOTNULL;

	IF NOT FOUND THEN
		RAISE EXCEPTION ''found no music file with id %'', new.file_id;
	END IF;

	IF file.lastplay > new.added THEN
		RAISE NOTICE ''lastplay for file % is newer - no update'', 
			new.file_id;
		RETURN new;
	END IF;

	UPDATE stor_file SET lastplay = new.added WHERE id = new.file_id;

	RETURN new;
END;
' LANGUAGE 'plpgsql';


-- DROP TRIGGER mserv_hist__up ON mserv_hist;
CREATE TRIGGER mserv_hist__up
AFTER INSERT OR UPDATE
ON mserv_hist FOR EACH ROW
EXECUTE PROCEDURE mserv_hist__up_lastplay();
 

COMMIT;
