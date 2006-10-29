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
    segment_id rel_segments.segment_id%TYPE;
    schema_user   varchar2(100);
    jobnum        integer;
begin 

  main_site_id := apm_service.new(
		    package_key => 'acs-subsite',
		    instance_name => '#acs-kernel.Main_Site#',
                    context_id => acs.magic_object_id('default_context')
	       );

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
  set object_type = 'application_group',
      context_id = main_site_id
  where object_id = -2;

  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select acs_object_id_seq.nextval, -2, 'admin_rel'
    from dual;

  segment_id := rel_segment.new(
    segment_name => '#acs-kernel.Main_Site_Members#',
    group_id => -2,
    rel_type => 'membership_rel'
  );

  segment_id := rel_segment.new(
    segment_name => '#acs-kernel.lt_Main_Site_Administrat#',
    group_id => -2,
    rel_type => 'admin_rel'
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
