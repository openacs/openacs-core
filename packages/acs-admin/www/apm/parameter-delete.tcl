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

apm_parameter_unregister $parameter_id

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

ad_returnredirect [export_vars -base "version-parameters" { version_id section_name }]
