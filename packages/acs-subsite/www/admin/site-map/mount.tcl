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

Please select one of the following packages to mount on [site_node::get_url -node_id $node_id].
<p>
The package instances are not mounted anywhere else:

<ul>
"

db_foreach packages_unmounted_select {} {
  doc_body_append "<li><a href=mount-2?[export_url_vars expand:multiple root_id node_id package_id]>$name</a>"
}

doc_body_append "</ul> These instances are already mounted
elsewhere. Selecting one of them will create an additional location
for the same application: <ul>"

db_foreach packages_mounted_select {} {
  doc_body_append "<li><a href=mount-2?[export_url_vars expand:multiple root_id node_id package_id]>$name</a>"
}

doc_body_append "</ul>

The packages are centralized services and are
probably not meant to be mounted anywhere:

<ul>"

db_foreach packages_singleton_select {} {
  doc_body_append "<li><a href=mount-2?[export_url_vars expand:multiple root_id node_id package_id]>$name</a>"
}

doc_body_append "
</ul>

[ad_footer]
"
