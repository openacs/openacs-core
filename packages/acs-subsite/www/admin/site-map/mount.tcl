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

set page_title "Mount A Package Instance"

set context [list [list . "Site Map"] $page_title]

set site_node_url [site_node::get_url -node_id $node_id]

db_multirow -extend { url } unmounted packages_unmounted_select {} {
    set url "mount-2?[export_vars { expand:multiple root_id node_id package_id }]"
}

db_multirow -extend { url } mounted packages_mounted_select {} {
    set url "mount-2?[export_vars { expand:multiple root_id node_id package_id}]"
}

db_multirow -extend { url } singleton packages_singleton_select {} {
    set url "mount-2?[export_vars { expand:multiple root_id node_id package_id}]"
}


