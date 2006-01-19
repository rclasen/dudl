BEGIN;

-- TODO: sequence doesn't work: you tend to get "value is not initialized
-- for this session" when checking currval();

-- DROP SEQUENCE dbver;
CREATE SEQUENCE dbver;
SELECT setval('dbver',1);

GRANT SELECT ON dbver TO PUBLIC;
GRANT all ON dbver TO GROUP dudl;

COMMIT;
