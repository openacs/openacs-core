ad_include_contract {
    Include for listing site wide services
} {
    {nr_subsites:integer 0}
}

set acs_admin_url      [apm_package_url_from_key "acs-admin"]
set acs_lang_admin_url [apm_package_url_from_key "acs-lang"]admin/
set acs_core_docs_url  [apm_package_url_from_key "acs-core-docs"]

set request_moonitor_package_id [apm_package_id_from_key "xotcl-request-monitor"]
if {$request_moonitor_package_id > 0} {
    set request_monitor_url [apm_package_url_from_id $request_moonitor_package_id]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
