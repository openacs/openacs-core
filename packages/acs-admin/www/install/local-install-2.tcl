ad_page_contract {
    Install from local file system
} {
    package_key:multiple
}

# We save this under a different name
foreach key $package_key {
    set install_p($key) 1
}

array set installed_version [list]
db_foreach installed_packages { 
    select package_key, version_name
    from   apm_package_versions
    where  enabled_p = 't'
} {
    set installed_version($package_key) $version_name
}

set install_spec_files [list]
set pkg_info_list [list]

array set package_name [list]

foreach spec_file [apm_scan_packages "[acs_root_dir]/packages"] {
    #catch {
        array set version [apm_read_package_info_file $spec_file]
        set package_name($version(package.key)) $version(package-name)

        if { [apm_package_supports_rdbms_p -package_key $version(package.key)] } {

            if { ![info exists installed_version($version(package.key))] } {
                # ok
            } elseif { [string equal $version(name) $installed_version($version(package.key))] } {
                continue
            } elseif { [apm_higher_version_installed_p $version(package.key) $version(name)] != 1 } {
                continue
            }

            # For dependency check
            lappend pkg_info_list [pkg_info_new \
                                       $version(package.key) \
                                       $spec_file \
                                       $version(provides) \
                                       $version(requires) \
                                       ""]
        
            if { [info exists install_p($version(package.key))] } {
                # This is a package which we should install
                lappend install_spec_files $spec_file
            }
        }
    #}
}

if { [llength $install_spec_files] } {
#    ad_returnredirect nothing-to-install
 #   ad_script_abort
}

set result [apm_dependency_check -pkg_info_all $pkg_info_list $install_spec_files]

set ok_p [lindex $result 0]
set install_pkg_info_list [lindex $result 1]
set extra_package_keys [lindex $result 2]

if { $ok_p } {
    ad_set_client_property -clob t apm pkg_install_list $install_pkg_info_list
    set continue_url local-install-3
    set page_title "Confirm"
} else {
    set page_title "Missing Required Packages"
}

set context [list [list "." "Install Applications"] [list "local-install" "Install From Local File System"] $page_title]

# Add the extras to the list
set package_key [concat $package_key $extra_package_keys]

multirow create install package_key package_name problem_p comment extra_p

set problems_p 0
set extras_p 0

foreach pkg_info $install_pkg_info_list {
    set key [pkg_info_key $pkg_info]
    set problem_p [expr ![template::util::is_true [pkg_info_dependency_p $pkg_info]]]
    set extra_p [expr [lsearch $extra_package_keys $key] != -1]
    if { $problem_p } {
        set problems_p 1
        set comment [pkg_info_comment $pkg_info]
    } else {
        set comment {}
    }
    if { $extra_p } {
        set extras_p 1
    }

    # We don't have package_name
    multirow append install \
        $key \
        $package_name($key) \
        $problem_p \
        [join $comment "<br>"] \
        $extra_p
}

template::list::create \
    -name install \
    -multirow install \
    -elements {
        package_name {
            label "Package"
        }
        comment {
            label "Error Message"
            hide_p {[ad_decode $problems_p 1 0 1]}
        }
        extra_p {
            label "Added"
            display_eval {[ad_decode $extra_p 1 "*" ""]}
            hide_p {[ad_decode $extras_p 1 0 1]}
            html { align center }
        }
    }

