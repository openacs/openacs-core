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

set acs_admin_url "/acs-admin/"
array set acs_admin_node [site_node::get -url $acs_admin_url]
set acs_admin_name $acs_admin_node(instance_name)

# JA: temporary: should replace this with a real function
set acs_automated_testing_url "/automated-test/" 

# JA: temporary: should replace this with a real function
set acs_lang_admin_url "/acs-lang/admin/"

# Dirk: temporary fix for noquote hacking
set acs_admin_available_p 1
set instance_name "foobar"

set context {}

ad_return_template
