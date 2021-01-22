--
-- Since many years, new installations are created with "Registered
-- Users" (object_id -2) having object_type as "application_group" and
-- the context id of the main subsite (see
-- acs-kernel/sql/postgresql/acs-install.sql).
--
-- However, it seems as if some prior upgrade scripts have not cared
-- sufficiently to update all installation correctly (some have still
-- "group", some have no context_id set). This upgrade script tries to
-- bring everything in sync such that "newer" and "older"
-- installations behave the same.
--
DO $$
DECLARE
  v_main_subsite_id acs_objects.object_id%TYPE;
BEGIN
	select object_id from site_nodes
	into v_main_subsite_id
	where parent_id is NULL order by node_id limit 1;

	update acs_objects 
	       set context_id = v_main_subsite_id
  	       where object_id = -2
	       and context_id is NULL;

        update acs_objects
	       set object_type = 'application_group'
	       where object_id = -2
	       and object_type = 'group';

	update acs_objects
	       set title = '#acs-kernel.Registered_Users#'
	       where object_id = -2;
END$$;

