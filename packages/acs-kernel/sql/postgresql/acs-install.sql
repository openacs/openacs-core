--
-- /packages/acs-kernel/sql/acs-install.sql
--
-- Complete the install of the system by setting up some default URL mappings.
--
-- @author Bryan Quinn (bquinn@arsdigita.com
-- @creation-date 2000/10/01
-- @cvs-id acs-install.sql,v 1.9.2.1 2001/01/12 18:32:21 dennis Exp
--

create function inline_0 ()
returns integer as '
declare
    node_id             site_nodes.node_id%TYPE;
    main_site_id        site_nodes.node_id%TYPE;
    admin_id            apm_packages.package_id%TYPE;
    docs_id             apm_packages.package_id%TYPE;
    api_doc_id          apm_packages.package_id%TYPE;
    acs_sc_id		apm_packages.package_id%TYPE;
    cr_id		apm_packages.package_id%TYPE;
    schema_user         varchar(100);
    jobnum              integer;
begin   

  main_site_id := apm_service__new(
                    null,
		    ''Main Site'',
		    ''acs-subsite'',
                    ''apm_service'',
                    now(),
                    null,
                    null,
                    acs__magic_object_id(''default_context'')
	       );


  insert into application_groups
    (group_id, package_id)
  values
    (-2, main_site_id);

  update acs_objects
  set object_type = ''application_group''
  where object_id = -2;

  perform rel_segment__new(
                   null,
                   ''rel_segment'',
                   now(),
                   null,
                   null,
                   null,
                   null,
                   ''Main Site Members'',
                   -2,
                   ''membership_rel'',
                   null
                 );

  PERFORM apm_package__enable (main_site_id); 

  node_id := site_node__new (
          null,
          null,          
          '''',
          main_site_id,          
          ''t'',
          ''t'',
          null,
          null
  );

  PERFORM acs_permission__grant_permission (
        main_site_id,
        acs__magic_object_id(''the_public''),
        ''read''
        );


  return null;

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

