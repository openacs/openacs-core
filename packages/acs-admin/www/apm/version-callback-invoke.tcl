ad_page_contract {
    Invoke a callback.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 11 September 2003
    @cvs-id $Id$
} {
    version_id:integer,notnull    
    type:notnull
}

db_1row package_version_info "select pretty_name, version_name from apm_package_version_info where version_id = :version_id"

set return_url "version-callbacks?[export_vars { version_id }]"

# Set default values for type and proc name
set proc_value [apm_get_callback_proc -type $type -version_id $version_id]
set page_title "Invoke Tcl Callback"


set context [list \
                 [list "." "Package Manager"] \
                 [list [export_vars -base "version-view" { version_id }] "$pretty_name $version_name"] \
                 [list $return_url "Tcl Callbacks"] $page_title]

if { [catch $proc_value result] } {
    global errorInfo
    ns_log Error "Error invoking callback $proc_value: $result\n$errorInfo"
}


