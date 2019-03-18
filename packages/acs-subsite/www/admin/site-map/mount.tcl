# packages/acs-core-ui/www/admin/site-nodes/mount.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-09-12
  @cvs-id $Id$
} {
  node_id:naturalnum,notnull
  {expand:integer,multiple {}}
  root_id:naturalnum,optional
}

set user_id [ad_conn user_id]

set page_title "Mount A Package Instance"

set context [list [list . "Site Map"] $page_title]

set site_node_url [site_node::get_url -node_id $node_id]

set the_public [acs_magic_object the_public]

db_multirow -extend { url } unmounted packages_unmounted_select {} {
    set url [export_vars -base mount-2 { expand:multiple root_id node_id package_id }]
}

db_multirow -extend { url } mounted packages_mounted_select {
   select p.package_id,
          p.instance_name as name,
          pt.pretty_name as package_pretty_name
   from   apm_packages p,
          apm_package_types pt
   where  pt.package_key = p.package_key
   and    (
              acs_permission.permission_p(p.package_id, :user_id, 'read')
           or acs_permission.permission_p(p.package_id, :the_public, 'read')
          )
   and    exists (select 1
                  from site_nodes
                  where object_id = p.package_id)
   order  by name
} {
    set url [export_vars -base mount-2 { expand:multiple root_id node_id package_id}]
}

db_multirow -extend { url } singleton packages_singleton_select {} {
    set url [export_vars -base mount-2 { expand:multiple root_id node_id package_id}]
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
