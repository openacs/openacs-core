--
-- /packages/acs-kernel/sql/acs-install.sql
--
-- Complete the install of the system by setting up some default URL mappings.
--
-- @author Bryan Quinn (bquinn@arsdigita.com
-- @creation-date 2000/10/01
-- @cvs-id $Id$
--

declare
    kernel_id  apm_packages.package_id%TYPE;
    node_id    site_nodes.node_id%TYPE;
    main_site_id site_nodes.node_id%TYPE;
    admin_id	apm_packages.package_id%TYPE;
    lang_id     apm_packages.package_id%TYPE;
    docs_id    apm_packages.package_id%TYPE;
    api_doc_id apm_packages.package_id%TYPE;
    cr_id apm_packages.package_id%TYPE;
    schema_user   varchar2(100);
    jobnum        integer;
begin 
  kernel_id := apm_service.new(
		    package_key => 'acs-kernel',
		    instance_name => 'ACS Kernel',
                    context_id => acs.magic_object_id('default_context')
	       );
  commit;

  apm_package.enable(kernel_id);

  main_site_id := apm_service.new(
		    package_key => 'acs-subsite',
		    instance_name => 'Main Site',
                    context_id => acs.magic_object_id('default_context')
	       );
  apm_package.enable(main_site_id); 

  node_id := site_node.new (
    name => '',
    directory_p => 't',
    pattern_p => 't',
    object_id => main_site_id
  );

  acs_permission.grant_permission (
    object_id => main_site_id,
    grantee_id => acs.magic_object_id('the_public'),
    privilege => 'read'
  );

  select user into schema_user from dual;

  dbms_job.submit (
    jobnum,
    'dbms_stats.gather_schema_stats (''' || schema_user || ''', 10, cascade => true);',
    trunc(sysdate+1) + 4/24,
    'trunc(sysdate+1) + 4/24'
  );

  commit;
end;
/
show errors
