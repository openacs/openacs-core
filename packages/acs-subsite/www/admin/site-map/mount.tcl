# packages/acs-core-ui/www/admin/site-nodes/mount.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-09-12
  @cvs-id $Id$
} {
  node_id:integer,notnull
  {expand:integer,multiple {}}
  root_id:integer,optional
}

set user_id [ad_conn user_id]

doc_body_append "[ad_header "Mount A Package Instance"]

Please select one of the following packages to mount on [db_string url {
  select site_node.url(:node_id) from dual
}].
<p />
The package instances are not mounted anywhere else:

<ul>
"

db_foreach packages_unmounted_select {
  select package_id, acs_object.name(package_id) as name
  from
  apm_packages
  where (acs_permission.permission_p(package_id, :user_id, 'read') = 't' or
         acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't')
        and apm_package.singleton_p(package_key) = 0
        and not exists (select 1
                           from site_nodes
                           where object_id = package_id)  

  order by name
} {
  doc_body_append "<li><a href=mount-2?[export_url_vars expand:multiple root_id node_id package_id]>$name</a>"
}

doc_body_append "</ul> These instances are already mounted
elsewhere. Selecting one of them will create an additional location
for the same application: <ul>"

db_foreach packages_mounted_select {
  select package_id, acs_object.name(package_id) as name
  from
  apm_packages
  where (acs_permission.permission_p(package_id, :user_id, 'read') = 't' or
         acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't')
        and exists (select 1
                       from site_nodes
                       where object_id = package_id)  
  order by name
} {
  doc_body_append "<li><a href=mount-2?[export_url_vars expand:multiple root_id node_id package_id]>$name</a>"
}

doc_body_append "</ul> 

The packages are centralized services and are
probably not meant to be mounted anywhere: 

<ul>"

db_foreach packages_singleton_select {
  select package_id, acs_object.name(package_id) as name
  from
  apm_packages
  where (acs_permission.permission_p(package_id, :user_id, 'read') = 't' or
         acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't')
        and apm_package.singleton_p(package_key) = 1
        and not exists (select 1
                           from site_nodes
                           where object_id = package_id)  
  order by name
} {
  doc_body_append "<li><a href=mount-2?[export_url_vars expand:multiple root_id node_id package_id]>$name</a>"
}

doc_body_append "
</ul>

[ad_footer]
"
