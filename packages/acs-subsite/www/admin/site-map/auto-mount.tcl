# /packages/acs-subsite/www/admin/site-map/auto-mount.tcl

ad_page_contract {

    Automatically mounts a package beneath the specified node

    @author mbryzek@arsdigita.com
    @creation-date Fri Feb  9 20:27:26 2001
    @cvs-id $Id$

} {
    package_key:notnull
    node_id:integer,notnull
    {return_url ""}
}

subsite::auto_mount_application -node_id $node_id $package_key

if {$return_url eq ""} {
    set return_url [site_node::get_url -node_id]
}

ad_returnredirect $return_url
