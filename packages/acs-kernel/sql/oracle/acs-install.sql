--
-- /packages/acs-kernel/sql/acs-install.sql
--
-- Mount the main site. Start schema stats job.
--
-- @author Peter Marklund
-- @creation-date 2000/10/01
-- @cvs-id $Id$
--

declare
    node_id    site_nodes.node_id%TYPE;
    main_site_id site_nodes.node_id%TYPE;
    schema_user   varchar2(100);
    jobnum        integer;
begin 

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
