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
    kernel_id           apm_packages.package_id%TYPE;
    node_id             site_nodes.node_id%TYPE;
    main_site_id        site_nodes.node_id%TYPE;
    admin_id            apm_packages.package_id%TYPE;
    docs_id             apm_packages.package_id%TYPE;
    api_doc_id          apm_packages.package_id%TYPE;
    schema_user         varchar(100);
    jobnum              integer;
begin 
  kernel_id := apm_service__new (
                    null,
                    ''ACS Kernel'',
                    ''acs-kernel'',
                    ''apm_service'',
                    now(),
                    null,
                    null,
                    acs.magic_object_id(''default_context'')
                    );


  PERFORM apm_package__enable (kernel_id);

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

  admin_id := apm_service__new (
      null,
      ''ACS Administration'',
      ''acs-admin'',
      ''apm_service'',
      now(),
      null,
      null,
      null
      );

  PERFORM apm_package__enable (admin_id);

  node_id := site_node__new (
    null,
    site_node__node_id(''/'', null),
    ''acs-admin'',
    admin_id
    ''t'',
    ''t'',
    null,
    null
  );
  
  docs_id := apm_service__new (
      null,
      ''ACS Core Documents'',
      ''acs-core-docs'',
      ''apm_service'',
      now(),
      null,
      null,
      main_site_id
      );

  node_id := site_node__new (
    null,
    site_node.node_id(''/''),
    ''doc'',
    docs_id,
    ''t'',
    ''t'',
    null,
    null
    );

  api_doc_id := apm_service__new (
      null,
      ''ACS API Browser'',
      ''acs-api-browser'',
      ''apm_service'',
      now(),
      null,
      null,
      main_site_id
      );

  PERFORM apm_package__enable (api_doc_id);

  -- Set default permissions for ACS API Browser so 
  -- that only users logged in can view it

  update acs_objects
     set security_inherit_p = 'f'
   where object_id = api_doc_id;

  PERFORM acs_permission__grant_permission (
    api_doc_id, 
    acs__magic_object_id (''registered_users''), 
    ''read''
  );

  api_doc_id := site_node__new (
    null,
    site_node.node_id(''/''),
    ''api-doc'',
    api_doc_id,
    ''t'',
    ''t'',
    null,
    null
    );

  -- select user into schema_user from dual;

  -- dbms_job.submit (
  --   jobnum,
  --  'dbms_stats.gather_schema_stats (''' || schema_user || ''', 10, cascade => true);',
  --  trunc(sysdate+1) + 4/24,
  --  'trunc(sysdate+1) + 4/24'
  );


  return null;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors
