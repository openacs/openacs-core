ad_page_contract {
    Install from local file system
} {
    {package_type "apm_application"}
    {upgrade_p 0}
}

set page_title "Install From Local File System"

set context [list [list "." "Install Software"] $page_title]

array set installed_version [list]
db_foreach installed_packages { 
    select package_key, version_name
    from   apm_package_versions
    where  enabled_p = 't'
} {
    set installed_version($package_key) $version_name
}

multirow create packages package_key package_name version_name package_type upgrade

set upgrades_p 0

array set package [list]

foreach spec_file [apm_scan_packages "[acs_root_dir]/packages"] {
    with_catch errmsg {
        array set version [apm_read_package_info_file $spec_file]
        if {  [string equal $package_type "all"] || [string equal $version(package.type) $package_type] } {
            set package_key $version(package.key)
            if {  [apm_package_supports_rdbms_p -package_key $version(package.key)] } {
                
                set installed_p 0
                if { ![info exists installed_version($version(package.key))] } {
                    set upgrade_text {}
                } elseif { [string equal $version(name) $installed_version($version(package.key))] } {
                    set installed_p 1
                } elseif { [apm_higher_version_installed_p $version(package.key) $version(name)] != 1 } {
                    set installed_p 1
                } else {
                    set upgrade_text Upgrade
                    set upgrades_p 1
                }
                

                # If in upgrade mode, only add to list if it's an upgrade
                if { !$installed_p && (!$upgrade_p || ![empty_string_p $upgrade_text]) } {
                    
                    set package([string toupper $version(package-name)]) [list \
                                                                              $version(package.key) \
                                                                              $version(package-name) \
                                                                              $version(name) \
                                                                              $version(package.type) \
                                                                              $upgrade_text]
                }
            }
        }
    } {
        global errorInfo
        ns_log Error "Error while checking package info file $spec_file: $errmsg\n$errorInfo"
    }
}

# Sort the list alphabetically (in case package_name and package_key doesn't sort the same)
foreach name [lsort -ascii [array names package]] {
    set row $package($name)
    multirow append packages \
        [lindex $row 0] \
        [lindex $row 1] \
        [lindex $row 2] \
        [lindex $row 3] \
        [lindex $row 4]
}


template::list::create \
    -name packages \
    -multirow packages \
    -key package_key \
    -bulk_actions {
        "Install checked applications" "local-install-2" "Install checked applications"
    } \
    -elements {
        package_name {
            label "Application"
        }
        version_name {
            label "Version"
        }
        upgrade {
            label "Upgrade"
            hide_p {[ad_decode $upgrades_p 1 0 1]}
        }
        install {
            label "Install"
            link_url_eval {[export_vars -base local-install-2 { package_key }]}
            link_html { title "Install single application" }
            display_template {Install}
        }
    }
