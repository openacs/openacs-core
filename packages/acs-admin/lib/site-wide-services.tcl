ad_include_contract {
    Include for listing site-wide services
} {
    {nr_subsites:integer 0}
}

set acs_admin_url      [apm_package_url_from_key "acs-admin"]
set acs_lang_admin_url [apm_package_url_from_key "acs-lang"]admin/
set acs_core_docs_url  [apm_package_url_from_key "acs-core-docs"]

set cluster_enabled_p  [parameter::get -parameter ClusterEnabledP -package_id $::acs::kernel_id]

if {[file exists [acs_package_root_dir acs-subsite]/www/admin/nsstats.tcl]} {
    set nsstats_url /admin/nsstats
}
set acs_api_browser_url       [site_node::get_package_url -package_key "acs-api-browser"]
set request_monitor_url       [site_node::get_package_url -package_key "xotcl-request-monitor"]
set acs_developer_support_url [site_node::get_package_url -package_key "acs-developer-support"]


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
