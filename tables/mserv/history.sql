BEGIN;

CREATE SEQUENCE mserv_hist_id_seq;
GRANT SELECT ON mserv_hist_id_seq TO PUBLIC;
GRANT all ON mserv_hist_id_seq TO GROUP dudl;

-- DROP TABLE mserv_hist;
CREATE TABLE mserv_hist (
	id		INTEGER NOT NULL
			DEFAULT nextval('mserv_hist_id_seq'),
	title_id	INTEGER NOT NULL,
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
	ADD CONSTRAINT ri__mserv_hist__mus_title
		FOREIGN KEY ( title_id )
		REFERENCES mus_title( id )
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


-- trigger to update mus_title.lastplay on insert

-- DROP FUNCTION mserv_hist__up_lastplay();
CREATE FUNCTION mserv_hist__up_lastplay()
RETURNS opaque AS  '
DECLARE
	title	RECORD;
BEGIN
	SELECT INTO title lastplay FROM mus_title WHERE id = new.title_id;

	IF title.lastplay > new.added THEN
		RAISE NOTICE ''lastplay for title % is newer - no update'', 
			new.title_id;
		RETURN new;
	END IF;

	UPDATE mus_title SET lastplay = new.added WHERE id = new.title_id;

	RETURN new;
END;
' LANGUAGE 'plpgsql';


-- DROP TRIGGER mserv_hist__up ON mserv_hist;
CREATE TRIGGER mserv_hist__up
AFTER INSERT OR UPDATE
ON mserv_hist FOR EACH ROW
EXECUTE PROCEDURE mserv_hist__up_lastplay();
 

COMMIT;
