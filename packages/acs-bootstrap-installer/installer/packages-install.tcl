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
    ns_write "  <p><li>Mounting the main site and other core packages.<p>
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

    # Now process the application bundle if an install.xml file was found.

    if { [nsv_exists acs_application node] } {

        ns_write "<p>Loading packages for the [nsv_get acs_application pretty_name] application.</p>"

        set actions [xml_node_get_children_by_name [nsv_get acs_application node] actions]
        if { [llength $actions] > 1 } {
            ns_log Error "Error in \"install.xml\": only one action node is allowed"
            ns_write "<p>Error in \"install.xml\": only one action node is allowed<p>"
            return
        }
        set actions [xml_node_get_children [lindex $actions 0]]

        foreach action $actions {

            switch -exact [xml_node_get_name $action] {

                text {}

                install {

                    set install_spec_files [list]
                    foreach install_spec_file \
                        [glob -nocomplain "[acs_root_dir]/packages/[apm_required_attribute_value $action package]/*.info"] {
                        if { [catch { array set package [apm_read_package_info_file $install_spec_file] } errmsg] } {
                            # Unable to parse specification file.
                            ns_log Error "$install_spec_file could not be parsed correctly.  The error: $errmsg"	
                            ns_write "<br>install: $install_spec_file could not be parsed correctly.  The error: $errmsg"	
                            return
                        }
                        if { [apm_package_supports_rdbms_p -package_key $package(package.key)] &&
                             ![apm_package_installed_p $package(package.key)] } {
                            lappend install_spec_files $install_spec_file
                        }
                    }

                    set pkg_info_list [list]
                    foreach spec_file [glob -nocomplain "[acs_root_dir]/packages/*/*.info"] {
                        # Get package info, and find out if this is a package we should install
                        if { [catch { array set package [apm_read_package_info_file $spec_file] } errmsg] } {
                            # Unable to parse specification file.
                            ns_log Error "$spec_file could not be parsed correctly.  The error: $errmsg"	
                            ns_write "<br>install: $spec_file could not be parsed correctly.  The error: $errmsg"	
                            return
                        }

                        if { [apm_package_supports_rdbms_p -package_key $package(package.key)] &&
                             ![apm_package_installed_p $package(package.key)] } {
                            # Save the package info, we may need it for dependency satisfaction later
                            lappend pkg_info_list [pkg_info_new $package(package.key) $spec_file \
                                $package(provides) $package(requires) ""]
                        }
                    }

                    if { [llength $install_spec_files] > 0 } {
                        set dependency_results [apm_dependency_check -pkg_info_all $pkg_info_list $install_spec_files]
                        if { [lindex $dependency_results 0] == 1 } {
                            apm_packages_full_install -callback apm_ns_write_callback [lindex $dependency_results 1]
                        } else {
                            foreach package_spec [lindex $dependency_results 1] {
                                if { [string is false [pkg_info_dependency_p $package_spec]] } {
                                    ns_log Error "install: package \"[pkg_info_key $package_spec]\"[join [pkg_info_comment $package_spec] ","]"
                                    append html "<p>Package \"[pkg_info_key $package_spec]\"\n<ul><li>[join [pkg_info_comment $package_spec] "<li>"]\n</ul>\n"
                                }
                            }
                            ns_write "$html\n"
                            return
                        }
                    }
                }

                mount {

                    set package_key [apm_required_attribute_value $action package]
                    set instance_name [apm_required_attribute_value $action instance-name]
                    set mount_point [apm_required_attribute_value $action mount-point]

                    set parent_id [site_node::get_node_id -url "/"]

                    if { [catch {
                        db_transaction {            
                            set node_id [site_node::new -name $mount_point -parent_id $parent_id]
                        }
                    } error] } {
                        # There is already a node with that path, check if there is a package mounted there
                        array set node [site_node::get -url "/$mount_point"]
                        if { [empty_string_p $node(object_id)] } {
                            # There is no package mounted there so go ahead and mount the new package
                            set node_id $node(node_id)
                        } else {
                            ns_log Error "A package is already mounted at \"$mount_point\""
                            ns_write "<br>mount: A package is already mounted at \"$mount_point\", ignoring mount command."
                            set node_id ""
                        }
                    }

                    if { ![empty_string_p $node_id] } {

                        ns_write "<p>Mounting new instance of package $package_key at /$mount_point<p>"
                        site_node::instantiate_and_mount \
                            -node_id $node_id \
                            -node_name $mount_point \
                            -package_name $instance_name \
                            -package_key $package_key

                    }

                }

                set-parameter {
                    set name [apm_required_attribute_value $action name]
                    set value [apm_required_attribute_value $action value]
                    set package_key [apm_attribute_value -default "" $action package]
                    set url [apm_attribute_value -default "" $action url]

                    if { ![string equal $package_key ""] && ![string equal $url ""] } {
                        ns_log Error "set-parameter: Can't specify both package and url"
                        ns_write "<br>set-parameter: Can't specify both package and url"
                        return
                    } elseif { ![string equal $package_key ""] } {
                        parameter::set_from_package_key -package_key $package_key -parameter $name -value $value
                    } else {
                        parameter::set_value \
                            -package_id [site_node::get_object_id -node_id [site_node::get_node_id -url $url]] \
                            -parameter $name \
                            -value $value
                    }
                }

                default {
                    ns_log Error "Error in \"install.xml\": got bad node \"[xml_node_get_name $action]\""
                }

            }

        }
    }
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
