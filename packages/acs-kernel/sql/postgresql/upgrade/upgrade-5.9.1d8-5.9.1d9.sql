--
-- Type discrepancy cleanup for object_types in OpenACS:
--
-- Fixing an inconsistency introduced in 2002: In PostgreSQL the table
-- "acs_object_types" the type of column "object_type" is
-- varchar(1000), while the supertype has varchar(100);
--
--   https://github.com/openacs/openacs-core/blame/oacs-5-9/packages/acs-kernel/sql/postgresql/acs-metadata-create.sql#L26
--
-- Similarly, the type of column acs_objects.object_type has
-- varchar(100). These attributes have a length of 1000 in the Oracle
-- versions.  An additional consequence of this discrepancy is that
-- casts are required when resolving the object-type-tree with
-- recursive queries. So, aligning these column types is desirable.
-- Another option would be to use type "text" instead if
-- varchar(1000), but such a change would require a much larger
-- cleanup and the result would not be compatible with Oracle.
--
-- Unfortunately, there are several other tables affected to address
-- this type discrepancies, since these use the object_type as foreign
-- keys.
--

ALTER TABLE acs_object_types           ALTER COLUMN supertype       TYPE varchar(1000);
-- ALTER TABLE acs_objects             ALTER COLUMN object_type     TYPE varchar(1000);
ALTER TABLE acs_attribute_descriptions ALTER COLUMN object_type     TYPE varchar(1000);
-- ALTER TABLE acs_attributes          ALTER COLUMN object_type     TYPE varchar(1000); 
ALTER TABLE acs_object_type_tables     ALTER COLUMN object_type     TYPE varchar(1000);
-- ALTER TABLE acs_rel_types           ALTER COLUMN object_type_one TYPE varchar(1000);
-- ALTER TABLE acs_rel_types           ALTER COLUMN object_type_two TYPE varchar(1000);
-- ALTER TABLE acs_rel_types           ALTER COLUMN rel_type        TYPE varchar(1000);
ALTER TABLE acs_static_attr_values     ALTER COLUMN object_type     TYPE varchar(1000);
ALTER TABLE group_type_rels            ALTER COLUMN group_type      TYPE varchar(1000);
ALTER TABLE group_types                ALTER COLUMN group_type      TYPE varchar(1000);
ALTER TABLE group_rels                 ALTER COLUMN rel_type        TYPE varchar(1000);
ALTER TABLE group_type_rels            ALTER COLUMN rel_type        TYPE varchar(1000);
-- ALTER TABLE group_element_index     ALTER COLUMN rel_type        TYPE varchar(1000);

--
-- Unfortunately, we can't do simply
--
--    ALTER TABLE acs_objects      ALTER COLUMN object_type TYPE varchar(1000);
--
-- since many views include the attribute "object_type", including
-- many application packages. The genererally recommended way is to
-- drop and recreate the views, but this is for a kernel upgrade not
-- feasible. Since the length change is not a real type change, we can
-- simply update the length information in the pg_attribute table.

WITH RECURSIVE dependent_views AS (
    SELECT c.oid::REGCLASS AS view_name
      FROM pg_class c
     WHERE c.relname = 'acs_objects'
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
AND   pg_attribute.attname = 'object_type';

--
-- ALTER TABLE acs_attributes             ALTER COLUMN object_type     TYPE varchar(1000); --deps
--
WITH RECURSIVE dependent_views AS (
    SELECT c.oid::REGCLASS AS view_name
      FROM pg_class c
     WHERE c.relname = 'acs_attributes'
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
AND   pg_attribute.attname = 'object_type';


--
-- ALTER TABLE acs_rel_types           ALTER COLUMN object_type_one TYPE varchar(1000);
-- ALTER TABLE acs_rel_types           ALTER COLUMN object_type_two TYPE varchar(1000);
-- ALTER TABLE acs_rel_types           ALTER COLUMN rel_type        TYPE varchar(1000);
--
WITH RECURSIVE dependent_views AS (
    SELECT c.oid::REGCLASS AS view_name
      FROM pg_class c
     WHERE c.relname = 'acs_rel_types'
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
AND   pg_attribute.attname in ('object_type_one', 'object_type_two', 'rel_type');

--- 
-- ALTER TABLE group_element_index        ALTER COLUMN rel_type        TYPE varchar(1000);
-- 
WITH RECURSIVE dependent_views AS (
    SELECT c.oid::REGCLASS AS view_name
      FROM pg_class c
     WHERE c.relname = 'group_element_index'
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
AND   pg_attribute.attname = 'rel_type';




