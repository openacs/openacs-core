-- Dropping obsolete tables (see http://openacs.org/forums/message-view?message_id=5330206)
-----------------------------------------------------------------------------
--
-- 1) Make sure to upgrade to at least acs-kernel 5.9.1d13
-- 2) Make a database dump as a backup; dropping is faster than recreating!
--

--
-- Drop the unused (potentially huge) materialized view
-- "acs_object_context_index" and its maintenance infrastructure.
--
DROP TABLE IF EXISTS acs_object_context_index CASCADE;
DROP TRIGGER IF EXISTS acs_objects_context_id_in_tr ON acs_objects CASCADE;
DROP TRIGGER IF EXISTS acs_objects_context_id_up_tr ON acs_objects CASCADE;
DROP FUNCTION IF EXISTS acs_objects_context_id_in_tr();
DROP FUNCTION IF EXISTS acs_objects_context_id_up_tr();


--
-- Drop the two (!) materialized views for the privilege hierarchy.
--
DROP TABLE IF EXISTS acs_privilege_descendant_map;
DROP TABLE IF EXISTS acs_privilege_hierarchy_index CASCADE;

DROP TRIGGER  IF EXISTS acs_priv_hier_ins_del_tr ON acs_privilege_hierarchy;
DROP FUNCTION IF EXISTS acs_priv_hier_ins_del_tr();

DROP TRIGGER  IF EXISTS acs_priv_del_tr ON acs_privileges;
DROP FUNCTION IF EXISTS acs_priv_del_tr();

DROP FUNCTION IF EXISTS priv_recurse_subtree(varbit, varchar);

--
-- Create "acs_privilege_descendant_map" as view (similar to the
-- Oracle implementation)
--
-- The clause after the first UNION ALL is just here to return the
-- identity column on the highest hierarchy ("admin, admin").
--
CREATE OR REPLACE VIEW acs_privilege_descendant_map AS
WITH RECURSIVE privilege_desc(parent, child) AS (
   SELECT child_privilege as parent, child_privilege as child FROM acs_privilege_hierarchy
UNION ALL
   SELECT privilege as parent, privilege as child FROM
   (SELECT privilege FROM acs_privilege_hierarchy
    EXCEPT
    SELECT child_privilege FROM acs_privilege_hierarchy) identity
UNION ALL
   SELECT h.privilege as parent, pd.child
   FROM acs_privilege_hierarchy h, privilege_desc pd
   WHERE pd.parent = h.child_privilege
) SELECT * FROM privilege_desc;

-----------------------------------------------------------------------------
