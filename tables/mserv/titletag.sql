BEGIN;

-- n->m mapping of which tags are set for a title

CREATE TABLE mserv_titletag (
	tag_id		INTEGER NOT NULL ,
	title_id	INTEGER NOT NULL
);

GRANT SELECT ON mserv_titletag TO PUBLIC;
GRANT all ON mserv_titletag TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mserv_titletag__tag_title 
	ON mserv_titletag(tag_id, title_id);

-- refererential integrity

ALTER TABLE mserv_titletag
	ADD CONSTRAINT ri__mserv_titletag__mserv_tag
		FOREIGN KEY ( tag_id )
		REFERENCES mserv_tag( id )
			ON DELETE CASCADE
			ON UPDATE CASCADE
			DEFERRABLE;

ALTER TABLE mserv_titletag
	ADD CONSTRAINT ri__mserv_titletag__mus_title
		FOREIGN KEY ( title_id )
		REFERENCES mus_title( id )
			ON DELETE CASCADE
			ON UPDATE CASCADE
			DEFERRABLE;


COMMIT;
