BEGIN;

-- n->m mapping of which tags are set for a title

CREATE TABLE mserv_filetag (
	tag_id		INTEGER NOT NULL ,
	file_id		INTEGER NOT NULL
);

GRANT SELECT ON mserv_filetag TO PUBLIC;
GRANT all ON mserv_filetag TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mserv_filetag__tag_file 
	ON mserv_filetag(tag_id, file_id);
CREATE INDEX mserv_filetag__mserv_tag
	ON mserv_filetag(tag_id);
CREATE INDEX mserv_filetag__stor_file
	ON mserv_filetag(file_id);

-- refererential integrity

ALTER TABLE mserv_filetag
	ADD CONSTRAINT ri__mserv_filetag__mserv_tag
		FOREIGN KEY ( tag_id )
		REFERENCES mserv_tag( id )
			ON UPDATE CASCADE
			DEFERRABLE;

ALTER TABLE mserv_filetag
	ADD CONSTRAINT ri__mserv_filetag__stor_file
		FOREIGN KEY ( file_id )
		REFERENCES stor_file( id )
			ON DELETE CASCADE
			ON UPDATE CASCADE
			DEFERRABLE;


-- check that it's a real file
CREATE TRIGGER mserv_filetag__up
AFTER INSERT OR UPDATE
ON mserv_filetag FOR EACH ROW
EXECUTE PROCEDURE mserv_check_file();


COMMIT;
