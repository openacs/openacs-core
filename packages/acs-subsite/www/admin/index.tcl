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
    acs_admin_url:onevalue
    instance_name:onevalue
    acs_automated_testing_url:onevalue
    acs_lang_admin_url:onevalue
}

array set this_node [site_node::get -url [ad_conn url]]
set subsite_name $this_node(instance_name)

set acs_admin_url [apm_package_url_from_key "acs-admin"]
array set acs_admin_node [site_node::get -url $acs_admin_url]
set acs_admin_name $acs_admin_node(instance_name)

set acs_automated_testing_url [apm_package_url_from_key "acs-automated-testing"]

set acs_lang_admin_url "[apm_package_url_from_key "acs-lang"]admin/"

# Dirk: temporary fix for noquote hacking
set acs_admin_available_p 1
set instance_name "foobar"

set context {}

ad_return_template
