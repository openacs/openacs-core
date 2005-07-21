#packages/acs-core/admin-www/apm/parameter-delete-2.tcl
ad_page_contract {
    Adds a parameter to a version.
    @author Todd Nightingale [tnight@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    parameter_id:naturalnum,notnull
    section_name:notnull
    version_id:naturalnum,notnull
}

db_1row apm_package_by_version_id {
    select pretty_name, version_name, package_key
      from apm_package_version_info 
     where version_id = :version_id
}

# LARS hack
set sections [lindex [lindex [apm_parameter_section_slider $package_key] 0] 3]
foreach section $sections {
    if { [string equal $section_name [lindex $section 1]] } {
        set section_name [lindex $section 0]
        break
    }
}

set return_url [export_vars -base "version-parameters" { version_id section_name }]

ad_form -name del -form {
    parameter_id:key
    {confirm_p:text(hidden)}
    {version_id:text(hidden)}
    {section_name:text(hidden)}
    {pretty_name:text(inform) {label "Package"}}
    {parameter_name:text(inform) {label "Parameter"}}
} -edit_request {
    set confirm_p 1
    set parameter_name [db_string get_parameter_name {
        select parameter_name
        from apm_parameters
        where parameter_id = :parameter_id
    }]
} -edit_data {
    #here's where we actually do the delete.
    apm_parameter_unregister $parameter_id
} -after_submit {
    ad_returnredirect $return_url
    ad_script_abort
} -cancel_url $return_url

set page_title "Confirm Deletion"
set context [list [list "." "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] [list [export_vars -base version-parameters { version_id section_name }] "Parameters"] $page_title]

ad_return_template
