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
    node_id    site_nodes.node_id%TYPE;
    main_site_id site_nodes.node_id%TYPE;
    admin_id	apm_packages.package_id%TYPE;
    docs_id    apm_packages.package_id%TYPE;
    api_doc_id apm_packages.package_id%TYPE;
    cr_id apm_packages.package_id%TYPE;
    segment_id rel_segments.segment_id%TYPE;
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

  insert into application_groups
    (group_id, package_id)
  values
    (-2, main_site_id);

  update acs_objects
  set object_type = 'application_group'
  where object_id = -2;

  segment_id := rel_segment.new(
    segment_name => 'Main Site Members',
    group_id => -2,
    rel_type => 'membership_rel'
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
