ad_page_contract {

    Select, dependency check, install and enable packages.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {

}

proc ad_acs_kernel_id {} {
    if {[db_table_exists apm_packages]} {
	return [db_string acs_kernel_id_get {
	    select package_id from apm_packages
	    where package_key = 'acs-kernel'
	} -default 0]
    } else {
	    return 0
    }
}

ns_write "[install_header 200 "Installing OpenACS Core Services"]
"

# Attempt to install all packages.
set dependency_results [apm_dependency_check -initial_install [apm_scan_packages -new [file join [acs_root_dir] packages]]]
set dependencies_satisfied_p [lindex $dependency_results 0]
set pkg_list [lindex $dependency_results 1]
apm_packages_full_install -callback apm_ns_write_callback $pkg_list

# Complete the initial install.

if { ![ad_acs_admin_node] } {
    ns_write "  <p><li> Completing Install sequence.<p>
    <blockquote><pre>"
    cd [file join [acs_root_dir] packages acs-kernel sql [db_type]]
    db_source_sql_file -callback apm_ns_write_callback acs-install.sql
    ns_write "</pre></blockquote>"
} 

ns_write "All Packages Installed."

ns_write "<p>Generating secret tokens..."

populate_secret_tokens_db
ns_write "  <p>Done.<p>"

ns_write "
    <form action=create-administrator method=post>
    <center><input type=submit value=\"Next ->\"></center>
    </form>
    [install_footer]
"
