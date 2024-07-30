ad_include_contract {

    ADP include for checking if some resources are installed locally,
    and if not to provide the option to download these resources.

    @param resource_info    dict containing at least resourceDir and cdn
    @param version          version of the package
    @param download_url     url for downloading the resource

    @author Gustaf Neumann
} {
    {resource_info}
    {version ""}
    {download_url ""}
}

set resource_dir  [dict get $resource_info resourceDir]
set cdn           [dict get $resource_info cdn]
set resource_name [dict get $resource_info resourceName]
if {$download_url eq ""} {
    set download_url [ad_conn url]/download
}

if {[dict exists $resource_info parameterInfo]} {
    set parameterInfo [dict get $resource_info parameterInfo]

} else {
    dict set parameterInfo parameter_name Version
    regexp {/packages/([^/]+)/} $resource_dir . package_key
    dict set parameterInfo package_key $package_key
    dict set parameterInfo default_value ?
}

dict with parameterInfo {
    set parameter_id [::acs::dc list get {
        select parameter_id from apm_parameters
        where package_key = :package_key
        and parameter_name = :parameter_name
    }]
    if {$parameter_id ne ""} {
        set configured_via "package parameter $parameter_name"
        set actions modify_or_delete_package_parameter
        set modifyURL [string cat /shared/parameters?package_key=$package_key \
                           &scope=global \
                           &return_url=[ad_conn url]\
                           &scroll_to=$parameter_name]
    } else {
        set parameter_value [ns_config ns_section ns/server/[ns_info server]/acs/$package_key $parameter_name]
        if {$parameter_value eq ""} {
            set configured_via "configuration file"
        } else {
            set configured_via "default value"
        }
        set actions create_package_parameter
    }
    #set default_version $default_value
}


set version_segment [::util::resources::version_segment -resource_info $resource_info]
set newest_version [::util::resources::cdnjs_get_newest_version -resource_info $resource_info]

#
# In case, we have an explicit versionCheckURL, use this.
# Otherwise, try to derive it from the versionCheckAPI
#
if {[dict exists $resource_info versionCheckURL]} {
    set versionCheckURL [dict get $resource_info versionCheckURL]
} elseif {[dict exists $resource_info versionCheckAPI]} {
    set versionCheckAPI [dict get $resource_info versionCheckAPI]
    dict with versionCheckAPI {
        if {$cdn eq "cdnjs"} {
            set versionCheckURL https://cdnjs.com/libraries/$library
        }
    }
}

#ns_log notice "vulnerabilityCheck configured: [dict exists $resource_info vulnerabilityCheck]"
if {[dict exists $resource_info vulnerabilityCheck]} {
    set vulnerabilityCheck [dict get $resource_info vulnerabilityCheck]
    dict with vulnerabilityCheck {
        switch $service {
            snyk {
                set vulnerabilityCheckURL https://snyk.io/advisor/npm-package/$library
                set vulnerabilityCheckVersionURL https://security.snyk.io/package/npm/$library/$version
                set page [::util::resources::http_get_with_default \
                              -url $vulnerabilityCheckVersionURL \
                              -key snyk-$library/$version]
                if {$page eq ""} {
                    unset vulnerabilityCheckVersionURL
                    ns_log notice "vulnerabilityCheck: request failed $vulnerabilityCheckVersionURL"
                } else {
                    ns_log notice "vulnerabilityCheck: keep vulnerabilityCheckVersionURL $vulnerabilityCheckVersionURL"
                }
            }
            default "vulnerabilityCheck: unknown service '$service'"
        }
    }
}

foreach url {versionCheckURL vulnerabilityCheck} {
    if {[dict exists $resource_info $url]} {
        set $url [dict get $resource_info $url]
    }
}

#
# Check, if the resources are already installed.
#
set is_installed [::util::resources::is_installed_locally \
                      -resource_info $resource_info \
                      -version_segment $version_segment ]
if {$is_installed} {
    #
    # Tell the users, where the resources are installed.
    #
    set resources $resource_dir/$version_segment

} else {
    #
    # Check, if we can install the resources locally.
    #
    set writable [util::resources::can_install_locally \
                      -resource_info $resource_info \
                      -version_segment $version_segment]

    if {!$writable} {
        #
        # If we cannot install locally, tell the user were we want to
        # install.
        #
        set path $resource_dir/$version_segment
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
