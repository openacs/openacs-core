ad_page_contract {

    Select, dependency check, install and enable packages.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {
    {install_path [apm_workspace_install_dir]}
}


ns_write "[apm_header "Package Installation"]
<p>Please wait while the installer loads ........<p>

"

### Selection Phase
set spec_files [apm_scan_packages $install_path]
# Nothing in the install dir, maybe they just copied the files in under packages.
if { [empty_string_p $spec_files] } {
    set install_path "[acs_root_dir]/packages"
    set all_spec_files [apm_scan_packages $install_path]
    # We don't need to copy any files, because they are already there.
    ad_set_client_property apm copy_files_p 0 
    # Determine which spec files are new installs; install all of the new items.
    foreach spec_file $all_spec_files {
	array set version [apm_read_package_info_file $spec_file]
	set version_name $version(name)
	set package_name $version(package-name)
	set package_key $version(package.key)
        if { [db_package_supports_rdbms_p $version(database_support)] } {
            if { [apm_package_registered_p $package_key] } {
                if { [apm_higher_version_installed_p $package_key $version_name] } {
                    lappend spec_files $spec_file
                }
            } else {
                lappend spec_files $spec_file
            }
        }
    }
} else {
    ad_set_client_property apm copy_files_p 1 
}

ns_log Debug $spec_files

ns_write "Done.<p>
"

if { [empty_string_p $spec_files] } {
    # No spec files to work with.
    ns_write "
    <h2>No New Packages to Install</h2><p>

    There are no new packages to install.  Please load some
    using the <a href=\"package-load\">Package Loader</a>.<p>
    Return to the <a href=\"index\">APM</a>.<p>
    [ad_footer]
    "
} else {   
    
    ns_write "
    <h2>Select Packages to Install</h2><p>
    Please select the set of packages you'd like to install
    and enable.

    <ul>
    <li>To <b>install</b> a package is to load its data model.
    <li>To <b>enable</b> a package is to make it available to users.
    </ul>
    
    If you think you might want to use a package later (but not right away),
    install it but don't enable it.
    
    <form action=packages-install-2 method=post>
    "
    # Client properties do not deplete the limited URL variable space.
    ad_set_client_property apm spec_files $spec_files
    ad_set_client_property apm install_path $install_path

    set errors [list]
    set pkg_info_list [list]
    ns_log Debug "APM: Specification files available: $spec_files"
    foreach spec_file $spec_files {
	### Parse the package.
	if { [catch {
	    array set package [apm_read_package_info_file $spec_file]
	} errmsg] } {
	    lappend errors "<li>Unable to parse $spec_file.  The following error was generated:
	    <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote><p>"
	} else {
	    ns_log Debug "APM: Adding $package(package.key) to list for installation." 
	    lappend pkg_info_list [pkg_info_new $package(package.key) $spec_file \
		    $package(provides) $package(requires) ""]
	}
    }
	
    set widget [apm_package_selection_widget $pkg_info_list]
    if {[empty_string_p $widget]} {
	ns_write "There are no new packages available.<p>
	[ad_footer]"
	ad_script_abort
    }
    
    ns_write $widget
    ns_write "
    <input type=submit value=\"Next -->\">
    </form>
    "
    
    if {![empty_string_p $errors]} {
	ns_write "The following errors were generated
	<ul>
	    $errors
	</ul>
	"
    }
    
    ns_write "
    [ad_footer]
    "
}
