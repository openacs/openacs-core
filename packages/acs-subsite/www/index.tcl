# packages/mbryzek-subsite/www/index.tcl

ad_page_contract {

  @author rhs@mit.edu
  @author mbryzek@mit.edu

  @creation-date 2000-09-18
  @cvs-id $Id$
} {
} -properties {
    context:onevalue
    subsite_name:onevalue
    nodes:multirow
    admin_p:onevalue
}

set context [list]
set package_id [ad_conn package_id]
set admin_p [ad_permission_p $package_id admin]

set subsite_name [db_string name {
    select acs_object.name(:package_id) from dual
}]

set node_id [ad_conn node_id]

db_multirow nodes site_nodes {
  select site_node.url(n.node_id) as url, acs_object.name(n.object_id) as name
    from site_nodes n
   where n.parent_id = :node_id
    and n.object_id is not null
}

ad_return_template
