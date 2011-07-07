--
-- /packages/acs-kernel/sql/acs-install.sql
--
-- Mount the main site.
--
-- @author Peter Marklund
-- @creation-date 2000/10/01
-- @cvs-id $Id$
--



--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE
    node_id             site_nodes.node_id%TYPE;
    main_site_id        site_nodes.node_id%TYPE;
BEGIN   

  main_site_id := apm_service__new(
                    null,
		    '#acs-kernel.Main_Site#',
		    'acs-subsite',
                    'apm_service',
                    now(),
                    null,
                    null,
                    acs__magic_object_id('default_context')
	       );


  -- Make the -2 registered users group an application_group

  insert into application_groups
    (group_id, package_id)
  values
    (-2, main_site_id);

  update acs_objects
  set object_type = 'application_group',
      context_id = main_site_id
  where object_id = -2;

  insert into group_rels
    (group_rel_id, group_id, rel_type)
  select nextval('t_acs_object_id_seq'), -2, 'admin_rel';


  -- Create the members and admins rel segments

  perform rel_segment__new(
                   null,
                   'rel_segment',
                   now(),
                   null,
                   null,
                   null,
                   null,
                   '#acs-kernel.Main_Site_Members#',
                   -2,
                   'membership_rel',
                   null
                 );

  perform rel_segment__new(
                   null,
                   'rel_segment',
                   now(),
                   null,
                   null,
                   null,
                   null,
                   '#acs-kernel.lt_Main_Site_Administrat#',
                   -2,
                   'admin_rel',
                   null
                 );

  node_id := site_node__new (
          null,
          null,          
          '',
          main_site_id,          
          't',
          't',
          null,
          null
  );

  perform acs_permission__grant_permission (
        main_site_id,
        acs__magic_object_id('the_public'),
        'read'
        );

  return null;

END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();
