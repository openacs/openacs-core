# /packages/mbryzek-subsite/www/admin/index.tcl

ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)
    @author Michael Bryzek (mbryzek@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
} {
} -properties {
    context:onevalue
    subsite_name:onevalue
    acs_admin_available_p:onevalue
    acs_admin_url:onevalue
    instance_name:onevalue
}

set package_id [ad_conn object_id]
set subsite_name [db_string subsite_name {
    select p.instance_name 
      from apm_packages p
     where p.package_id = :package_id
} -default "Subsite"]

# Return the first available link to the Site-Wide Admin page.
if {[db_0or1row acs_admin_url_get {
    select site_node.url(node_id) acs_admin_url, instance_name
    from site_nodes s, apm_packages p
    where s.object_id = p.package_id
    and p.package_key = 'acs-admin'
    and rownum = 1
}]} {
    set acs_admin_available_p "t"
} else {
    set acs_admin_available_p "f"
}

set context {}

ad_return_template
