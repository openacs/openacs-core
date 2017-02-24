ad_page_contract {

    Installs the packages.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Mon Oct  9 00:22:31 2000
    @cvs-id $Id$
} {
    {sql_file:multiple ""}
    {mount_packages:multiple ""} 
    {mount_path:array ""}
}

set pkg_install_list [ad_get_client_property apm pkg_install_list]
set pkg_enable_list [ad_get_client_property apm pkg_enable_list]
set sql_file_paths [ad_get_client_property apm sql_file_paths]

set title "Package Installation"
set context [list [list "/acs-admin/apm/" "Package Manager"] $title]

ad_return_top_of_page [ad_parse_template \
                           -params [list context title] \
                           [template::streaming_template]]

ns_write [subst {
    <h2>Installing packages...</h2>
    <script nonce='$::__csp_nonce'>var myInterval = setInterval(function(){window.scrollTo(0,document.body.scrollHeight)}, 300);
    </script>
    <p>
    <ul>
}]


# We have a set of SQL files that need to be sourced at the appropriate time.
set sql_files [list]
foreach index $sql_file {
    ns_log Debug "File index: $index: [lindex $sql_file_paths $index]"
    lappend sql_files [lindex $sql_file_paths $index]
}

set installed_count 0
foreach pkg_info $pkg_install_list {
    set spec_file [pkg_info_spec $pkg_info]
    set package_path [pkg_info_path $pkg_info]

    if { [catch {
	array set version [apm_read_package_info_file $spec_file]
    } errmsg] } {
	ns_write "<li> Unable to install the [pkg_info_key $pkg_info] package because its specification
	file is invalid: <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>"
	continue
    }

    set package_key $version(package.key)

    if {[apm_package_version_installed_p $package_key $version(name)] } {
	#ns_log notice "===== ALREADY installed $package_key"
	# Already installed.
	continue
    }

    set version_files $version(files)

    set data_model_files [list]
    # Find the correct data model files for this package.
    foreach file $sql_files {
	if {[lindex $file 2] eq $package_key } {
	    # Pass on the file path and its type.
	    lappend data_model_files $file
	}
    }

    # Mount path of package
    if { $package_key in $mount_packages
	 && [info exists mount_path($package_key)] 
	 && $mount_path($package_key) ne "" 
     } {
        set selected_mount_path $mount_path($package_key)
    } else {
        set selected_mount_path ""
    }

    # Install the packages.
    ns_log Debug "APM: Installing package at $package_path."

    #set enable_p [expr {$package_key in $pkg_enable_list}]
    set enable_p 1

    if {[catch {
	ns_log notice "===== INSTALL $package_key"
	set version_id [apm_package_install \
			    -enable=$enable_p \
			    -package_path $package_path \
			    -callback apm_ns_write_callback \
			    -load_data_model \
			    -data_model_files $data_model_files \
			    -mount_path $selected_mount_path \
			    $spec_file]
	ns_log notice "===== INSTALL $package_key DONE"

    } errorMsg]} {
	ns_write "Error: $errorMsg\n"
	ns_write [ns_quotehtml $::errorInfo]
	set version_id 0
    }

    if { $version_id == 0 } {
        # Installation of the package failed and we shouldn't continue with installation
        # as there might be packages depending on the failed package. Ideally we should
        # probably check for such dependencies and continue if there are none.
        ns_write [subst {
	    </ul>
	    <script nonce='$::__csp_nonce'>window.scrollTo(0,document.body.scrollHeight);clearInterval(myInterval);
            </script>
	}]
        ad_script_abort
    }

    incr installed_count
}

if {$installed_count < 1} {
    ns_write {
	</ul>
	All packages in this directory have already been installed.
	Please return to the <a href="index">index</a>.<p>
    }
} else {
    ns_write {</ul><p>
	Done installing packages.
	<p>You should restart the server now to make installed and upgraded packages available.</p>
        <p><a href="../server-restart" class="button">Click here</a> to restart the server now.</p>
    }
}
ns_write [subst {
    <script nonce='$::__csp_nonce'>window.scrollTo(0,document.body.scrollHeight);clearInterval(myInterval);</script>
}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
