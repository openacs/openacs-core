# packages/acs-core-ui/www/admin/site-nodes/mount-2.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-09-12
  @cvs-id $Id$
} {
  node_id:integer,notnull
  package_id:integer,notnull
  {expand:integer,multiple {}}
  root_id:integer,optional
}

ad_require_permission $package_id read

db_transaction {
  db_dml mount {
    update site_nodes
    set object_id = :package_id
    where node_id = :node_id
    and object_id is null
  }

  site_nodes_sync
}

ad_returnredirect .?[export_url_vars expand:multiple root_id]
