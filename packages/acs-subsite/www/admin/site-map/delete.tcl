# packages/acs-core-ui/www/admin/site-nodes/delete.tcl

ad_page_contract {

    @author rhs@mit.edu
    @creation-date 2000-09-09
    @cvs-id $Id$

} {
    expand:integer,multiple
    node_id:integer,notnull
    {root_id:integer ""}
}

if {$root_id == $node_id} {
    set root_id [site_node::get_parent_id -node_id $node_id]
}

site_node::delete -node_id $node_id

ad_returnredirect ".?[export_url_vars expand:multiple root_id]"
