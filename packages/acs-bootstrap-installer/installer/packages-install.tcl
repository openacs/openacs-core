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

# Load the acs-tcl init files that might be needed when installing, instantiating and mounting packages
# We shouldn't source request-processor-init.tcl as it might interfere with the installer request handler
foreach { init_file } { utilities-init.tcl site-nodes-init.tcl } {
    ns_log Notice "Loading acs-tcl init file $init_file"
    apm_source "[acs_package_root_dir acs-tcl]/tcl/$init_file"
}
apm_bootstrap_load_libraries -procs acs-subsite
apm_bootstrap_load_queries acs-subsite
install_redefine_ad_conn

# Attempt to install all packages.
set dependency_results [apm_dependency_check -initial_install [apm_scan_packages -new [file join [acs_root_dir] packages]]]
set dependencies_satisfied_p [lindex $dependency_results 0]
set pkg_list [lindex $dependency_results 1]
apm_packages_full_install -callback apm_ns_write_callback $pkg_list

# Complete the initial install.

if { ![ad_acs_admin_node] } {
    ns_write "  <p><li> Completing Install sequence by mounting the main site and other core packages.<p>
    <blockquote><pre>"

    # Mount the main site
    cd [file join [acs_root_dir] packages acs-kernel sql [db_type]]
    db_source_sql_file -callback apm_ns_write_callback acs-install.sql

    # Make sure the site-node cache is updated with the main site
    site_node::init_cache

    # We need to redefine ad_conn again since apm_package_install resourced the real ad_conn
    install_redefine_ad_conn

    # Mount and set permissions for core packages
    apm_mount_core_packages

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
