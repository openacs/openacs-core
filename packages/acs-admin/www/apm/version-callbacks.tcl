ad_page_contract {

    @author Peter Marklund
    @creation-date 28 January 2003
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
}

db_1row package_version_info "select pretty_name, version_name from apm_package_version_info where version_id = :version_id"

set page_title "Tcl Callbacks"
set context_bar [ad_context_bar [list "." "ACS Package Manager Administration"] [list "version-view?[export_vars { version_id }]" "$pretty_name $version_name"] $page_title]

db_multirow callbacks get_all_callbacks {
    select type,
           proc
    from apm_package_callbacks
    where version_id = :version_id
    order by type
}

set unused_callback_types [apm_unused_callback_types -version_id $version_id]

set unused_types_p [ad_decode [llength $unused_callback_types] 0 0 1]

ad_return_template
