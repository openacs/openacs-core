# packages/acs-core-ui/www/admin/site-nodes/unmount.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-09-12
  @cvs-id $Id$
} {
  node_id:integer,notnull
  {expand:integer,multiple {}}
  root_id:integer,optional
}

db_transaction {
  db_dml unmount {
    update site_nodes
    set object_id = null
    where node_id = :node_id
  }

  site_nodes_sync
}

ad_returnredirect .?[export_url_vars expand:multiple root_id]
