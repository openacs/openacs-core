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
    acs_sc_id		apm_packages.package_id%TYPE;
    cr_id		apm_packages.package_id%TYPE;
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
                    acs__magic_object_id(''default_context'')
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
    admin_id,
    ''t'',
    ''t'',
    null,
    null
  );
  

  acs_sc_id := apm_service__new (
      null,
      ''ACS Service Contract'',
      ''acs-service-contract'',
      ''apm_service'',
      now(),
      null,
      null,
      null
      );

  PERFORM apm_package__enable (acs_sc_id);

  node_id := site_node__new (
    null,
    site_node__node_id(''/'', null),
    ''acs-service-contract'',
    acs_sc_id,
    ''t'',
    ''t'',
    null,
    null
  );


  cr_id := apm_service__new (
      null,
      ''ACS Content Repository'',
      ''acs-content-repository'',
      ''apm_service'',
      now(),
      null,
      null,
      null
      );

  PERFORM apm_package__enable (cr_id);

  node_id := site_node__new (
    null,
    site_node__node_id(''/'', null),
    ''acs-content-repository'',
    cr_id,
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
    site_node__node_id(''/'',null),
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

  insert into inline_data (id,name) values (api_doc_id, ''api_doc_id'');

  return null;

end;' language 'plpgsql';

  
  -- Set default permissions for ACS API Browser so 
  -- that only users logged in can view it
create function inline_1 () returns integer as '
declare
        api_doc_id      integer;
begin

  select id into api_doc_id 
  from inline_data where name = ''api_doc_id'';

  PERFORM acs_permission__grant_permission (
    api_doc_id, 
    acs__magic_object_id (''registered_users''), 
    ''read''
  );

  api_doc_id := site_node__new (
    null,
    site_node__node_id(''/'',null),
    ''api-doc'',
    api_doc_id,
    ''t'',
    ''t'',
    null,
    null
    );

    return null;

end;' language 'plpgsql';

create table inline_data (
       id        integer,
       name      varchar
);

select inline_0 ();

select id from inline_data where name = 'api_doc_id';
update acs_objects
     set security_inherit_p = 'f'
   where object_id = (select id from inline_data where name = 'api_doc_id');

select inline_1 ();

drop function inline_0 ();
drop function inline_1 ();
drop table inline_data;

-- show errors
