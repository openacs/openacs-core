# packages/acs-core-ui/www/admin/site-nodes/delete.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-09-09
  @cvs-id $Id$
} {
  expand:integer,multiple
  node_id:integer,notnull
  {root_id:integer {}}
}

db_transaction {

  if {$root_id == $node_id} {
    set root_id [db_string parent_select {
      select parent_id
      from site_nodes
      where node_id = :node_id
    }]
  }

  db_exec_plsql node_delete {
    begin
      site_node.delete(:node_id);
    end;
  }
}

ad_returnredirect .?[export_url_vars expand:multiple root_id]
