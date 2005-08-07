BEGIN;

------------------------------------------------------------
--
-- mus_artist
--
------------------------------------------------------------

CREATE SEQUENCE mus_artist_id_seq;
GRANT SELECT ON mus_artist_id_seq TO PUBLIC;
GRANT all ON mus_artist_id_seq TO GROUP dudl;

CREATE TABLE mus_artist (
	id		INTEGER NOT NULL
			DEFAULT nextval( 'mus_artist_id_seq' ),

	nname		VARCHAR(255)
			NOT NULL
			CHECK( nname <> '' )

);

GRANT SELECT ON mus_artist TO PUBLIC;
GRANT all ON mus_artist TO GROUP dudl;

-- indices

CREATE UNIQUE INDEX mus_artist__id 
	ON mus_artist(id);
CREATE UNIQUE INDEX mus_artist__names
	ON mus_artist(lower(nname));

-- DATA

INSERT INTO mus_artist (id, nname) 
	VALUES( 0, 'UNKNOWN');

COMMIT;

-- select id, nname, case when nname ~* '^(die|the) ' then substr(lower(nname),5) else lower(nname) end  from mus_artist order by case when nname ~* '^(die|the) ' then substr(lower(nname),5) else lower(nname) end;
