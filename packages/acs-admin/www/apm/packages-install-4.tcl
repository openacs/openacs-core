ad_page_contract {

    Installs the packages.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct  9 00:22:31 2000
    @cvs-id $Id$
} {
    {sql_file:multiple ""}
    {mount_p:multiple ""} 
    {mount_path:array ""}
}

set pkg_install_list [ad_get_client_property apm pkg_install_list]
set pkg_enable_list [ad_get_client_property apm pkg_enable_list]
set sql_file_paths [ad_get_client_property apm sql_file_paths]
set install_path [ad_get_client_property apm install_path]
set copy_files_p [ad_get_client_property apm copy_files_p]

ReturnHeaders
ns_write "[apm_header  "Package Installation"]
<h2>Installing packages...</h2>
<p>
<ul>
"

# We have a set of SQL files that need to be sourced at the appropriate time.
set sql_files [list]
foreach index $sql_file {
    ns_log Debug "File index: $index: [lindex $sql_file_paths $index]"
    lappend sql_files [lindex $sql_file_paths $index]
}

set installed_count 0
foreach pkg_info $pkg_install_list {
    set spec_file [pkg_info_spec $pkg_info]
    if { [catch {
	array set version [apm_read_package_info_file $spec_file]
    } errmsg] } {
	ns_write "<li> Unable to install the [pkg_info_key $pkg_info] package because its specification
	file is invalid: <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
	continue
    }

    if {[apm_package_version_installed_p $version(package.key) $version(name)] } {
	# Already installed.
	continue
    }

    set package_key $version(package.key)
    set version_files $version(files)

    set data_model_files [list]
    # Find the correct data model files for this package.
    foreach file $sql_files {
	if {![string compare [lindex $file 2] $package_key]} {
	    # Pass on the file path and its type.
	    lappend data_model_files $file
	}
    }

    # Mount path of package
    if { [lsearch $mount_p $package_key] != -1 && [info exists mount_path($package_key)] && ![empty_string_p $mount_path($package_key)] } {
        set selected_mount_path $mount_path($package_key)
    } else {
        set selected_mount_path ""
    }

    # Install the packages.
    ns_log Debug "APM: Installing packages from $install_path."
    if {$copy_files_p} {
	set version_id [apm_package_install -install_path $install_path \
		-callback apm_ns_write_callback -copy_files -load_data_model \
		-data_model_files $data_model_files \
                -mount_path $selected_mount_path \
                $spec_file]
	if {$version_id != 0} {
	    file delete -force $install_path/$package_key
	}
    } else {
        set enable_p [expr [lsearch -exact $pkg_enable_list $package_key] != -1]

	set version_id [apm_package_install \
                -enable=$enable_p \
                -install_path $install_path \
		-callback apm_ns_write_callback \
                -load_data_model \
		-data_model_files $data_model_files \
                -mount_path $selected_mount_path \
                $spec_file]
    }

    incr installed_count
}

if {$installed_count < 1} {
    ns_write "</ul>
    All packages in this directory have already been installed.
    Please return to the <a href=\"index\">index</a>.<p>
    [ad_footer]"
    return
} else {

ns_write "</ul><p>
Done installing packages.
<p>You should restart the server now to make installed and upgraded packages available.</p>
[ad_footer]
"
}
