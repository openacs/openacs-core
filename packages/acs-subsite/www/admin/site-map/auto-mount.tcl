# /packages/acs-subsite/www/admin/site-map/auto-mount.tcl

ad_page_contract {

    Automatically mounts a package beneath the specified node

    @author mbryzek@arsdigita.com
    @creation-date Fri Feb  9 20:27:26 2001
    @cvs-id $Id$

} {
    package_key:notnull
    node_id:integer,notnull
    { return_url "" }
}

subsite::auto_mount_application -node_id $node_id $package_key

if { [empty_string_p $return_url] } {
    # Go back to the node
    db_1row select_node_url {
	select site_node.url(s.node_id) as return_url
	  from site_nodes s, apm_packages p
	 where s.object_id = p.package_id
	   and s.node_id = :node_id
    }
}

ad_returnredirect $return_url
