BEGIN;

-- view stor_xfile

CREATE VIEW stor_xfile AS
SELECT
	f.id,
	f.unitid,
	u.collection		as col,
	u.colnum,
	f.dir,
	f.fname,
	f.broken,
	f.cmnt,
	f.titleid,
	f.freq
FROM
	stor_unit u,
	stor_file f
WHERE
	u.id = f.unitid;

GRANT SELECT ON stor_xfile TO PUBLIC;
GRANT all ON stor_xfile TO GROUP dudl;


COMMIT;
