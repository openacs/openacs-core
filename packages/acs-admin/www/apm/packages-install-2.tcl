ad_page_contract {

    Do a dependency check of the install.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct  9 00:13:43 2000
    @cvs-id $Id$
} {
    {install:multiple ""}
    {enable:multiple ""}
    {force_p "f"}
}

# Install and enable are sets of keys; need to turn them back into spec files.
set spec_files [ad_get_client_property apm spec_files]

# Clear out previous client properties.
ad_set_client_property -clob t apm pkg_install_list ""
ad_set_client_property -clob t apm pkg_enable_list ""

foreach install_key $install {
    foreach spec_file $spec_files {
	# Find the spec_file that has the install_key
	if { [catch {
	    array set package [apm_read_package_info_file $spec_file]
	} errmsg] } {
	    # Unable to parse specification file.
	    # If we get here, its because someone hacked the archive the loading process
	    # which checks the info file and displays an error.
	    # process
	    ns_log Error "$spec_file could not be parsed correctly.  It is not being installed. 
	    The error: $errmsg"	
	}
	if {![string compare $package(package.key) $install_key]} {
	    lappend install_spec_files $spec_file
	}
    }
}

if {![info exists install_spec_files]} {
    doc_body_append "[apm_header "Package Installation"]<p>
No packages selected.<p>[ad_footer]"
    return
}

### Dependency Check
set dependency_results [apm_dependency_check $install_spec_files]

if { ([lindex $dependency_results 0] == 1) || ![string compare $force_p "t"]} {
    ### Check passed!  Initiate install.

    # We use client properties to pass along this information as it is fairly large.
    ad_set_client_property -clob t apm pkg_install_list [lindex $dependency_results 1]
    ad_set_client_property -clob t apm pkg_enable_list $enable

    ad_returnredirect packages-install-3
    return
} else {
    ### Check failed.  Offer user an explanation and an ability to select unselect packages.
    doc_body_append "[apm_header "Package Installation"]
    <h2>Select Packages to Install</h2><p>
    
    Some of the packages you are trying to install have unsatisfied dependencies.  The packages
    with unsatisfied dependencies have been deselected.  If you wish to install packages that do
    not pass dependencies, please click the \"force\" option below.
    <form action=packages-install-2 method=post>
    
    <ul>
    <li>To <b>install</b> a package is to load its data model.
    <li>To <b>enable</b> a package is to make it available to users.
    </ul>
    
    If you think you might want to use a package later (but not right away),
    install it but don't enable it.
    
    [export_form_vars spec_files]<p>
    
    <blockquote>
    <table>
    "
    
    set checkbox_count 0
    set counter 0
    set pkg_info_list [list]
    set band_colors { white "\#ececec" }
    doc_body_append [apm_package_selection_widget [lindex $dependency_results 1] $install $enable]

    
    doc_body_append "
    </table></blockquote>
    <input type=checkbox name=force_p value=\"t\"> <strong>Force the install<p></strong>
    <input type=submit value=\"Select Data Model Scripts\">
    </form>
    [ad_footer]
    "
}
