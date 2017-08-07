--
-- Changes induced by the type discrepancy cleanup in 5.9.1d8-5.9.1d9:
-- Using consistently varchar(1000) for object types.
--

ALTER TABLE cr_content_mime_type_map   ALTER COLUMN content_type    TYPE varchar(1000);
ALTER TABLE cr_folder_type_map         ALTER COLUMN content_type    TYPE varchar(1000);
-- ALTER TABLE cr_items                ALTER COLUMN content_type    TYPE varchar(1000);
ALTER TABLE cr_type_children           ALTER COLUMN child_type      TYPE varchar(1000);
ALTER TABLE cr_type_children           ALTER COLUMN parent_type     TYPE varchar(1000);
ALTER TABLE cr_type_relations          ALTER COLUMN target_type     TYPE varchar(1000);
ALTER TABLE cr_type_relations          ALTER COLUMN content_type    TYPE varchar(1000);
ALTER TABLE cr_type_template_map       ALTER COLUMN content_type    TYPE varchar(1000);

--
-- ALTER TABLE cr_items                   ALTER COLUMN content_type    TYPE varchar(1000); --deps
--
WITH RECURSIVE dependent_views AS (
    SELECT c.oid::REGCLASS AS view_name
      FROM pg_class c
     WHERE c.relname = 'cr_items'
     UNION ALL
    SELECT DISTINCT r.ev_class::REGCLASS AS view_name
      FROM pg_depend d
      JOIN pg_rewrite r ON (r.oid = d.objid)
      JOIN dependent_views ON (dependent_views.view_name = d.refobjid)
     WHERE d.refobjsubid != 0
)
UPDATE pg_attribute 
   SET atttypmod = 1000 + 4
  FROM dependent_views   
WHERE pg_attribute.attrelid = dependent_views.view_name
AND   pg_attribute.attname = 'content_type';
