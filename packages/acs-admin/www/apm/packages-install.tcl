ad_page_contract {

    Select, dependency check, install and enable packages.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {
    {checked_by_default_p:boolean 1}
    {install_path [apm_workspace_install_dir]}
}

ad_return_top_of_page "[apm_header "Package Installation"]
<p>Please wait while the installer loads ........<p>

"

### Selection Phase
set all_spec_files [apm_scan_packages $install_path]
# Nothing in the install dir, maybe they just copied the files in under packages.
if { [empty_string_p $all_spec_files] } {
    set actual_install_path "[acs_root_dir]/packages"
    set all_spec_files [apm_scan_packages $actual_install_path]
    # We don't need to copy any files, because they are already there.
    ad_set_client_property apm copy_files_p 0 
} else {
    ad_set_client_property apm copy_files_p 1 
    set actual_install_path $install_path
}

# Determine which spec files are new installs; install all of the new items.
set spec_files [list]
set warnings [list]
foreach spec_file $all_spec_files {
    array set version [apm_read_package_info_file $spec_file]
    set version_name $version(name)
    set package_name $version(package-name)
    set package_key $version(package.key)
    if { [db_package_supports_rdbms_p $version(database_support)] } {
        if { [apm_package_registered_p $package_key] } {
            if { [apm_higher_version_installed_p $package_key $version_name] } {
                lappend spec_files $spec_file
            } else {
                lappend warnings "Package &quot;$package_name&quot; ($package_key) skipped because a later version is already installed."
            }
        } else {
            lappend spec_files $spec_file
        }
    } else {
        lappend warnings "Package &quot;$package_name&quot; ($package_key) skipped because it doesn't support [db_type]."
    }
}

ns_log Debug $spec_files

ns_write "Done.<p>
"

if { [llength $warnings] > 0 } {
    ns_write "<h3>Packages skipped</h3><ul><li>[join $warnings "<li>"]</ul>"
}


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
    install it but don't enable it.<p>

<script language=javascript>
function uncheckAll() {
    for (var i = 0; i < [expr [llength $spec_files] * 2]; ++i)
        document.forms\[0\].elements\[i\].checked = false;
    this.href='';
}
function checkAll() {
    for (var i = 0; i < [expr [llength $spec_files] * 2]; ++i)
        document.forms\[0\].elements\[i\].checked = true;
    this.href='';
}
</script>
<a href=\"packages-install?checked_by_default_p=0&[export_url_vars install_path]\" onclick=\"javascript:uncheckAll();return false\"><b>uncheck all boxes</b></a> |
<a href=\"packages-install?checked_by_default_p=1&[export_url_vars install_path]\"  onclick=\"javascript:checkAll(); return false\"><b>check all boxes</b></a>
"

    ns_write "<form action=packages-install-2 method=post>"

    # Client properties do not deplete the limited URL variable space.
    # But they are limited to the maximum length of a varchar ...

    ad_set_client_property -clob t apm spec_files $spec_files
    ad_set_client_property apm install_path $actual_install_path

    set errors [list]
    set pkg_info_list [list]
    set pkg_key_list [list]
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
            lappend pkg_key_list $package(package.key)
	}
    }
	
    if { $checked_by_default_p } {
        set widget [apm_package_selection_widget $pkg_info_list $pkg_key_list $pkg_key_list]
    } else {
        set widget [apm_package_selection_widget $pkg_info_list]
    }

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
