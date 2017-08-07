--
-- Changes induced by the type discrepancy cleanup in 5.9.1d8-5.9.1d9:
-- Using consistently varchar(1000) for object types.
--

ALTER TABLE subsite_callbacks          ALTER COLUMN object_type     TYPE varchar(1000);
