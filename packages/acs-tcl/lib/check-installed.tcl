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
if {$version eq ""} {
    set version [dict get $resource_info configuredVersion]
}
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

set return_url [ad_conn url]

dict with parameterInfo {
    set parameter_id [::acs::dc list get {
        select parameter_id from apm_parameters
        where package_key = :package_key
        and parameter_name = :parameter_name
    }]
    if {$parameter_id ne ""} {
        set configured_via "package parameter $parameter_name"
        #
        # Presence of modifyPackageParameterURL controls action item
        #
        set modifyPackageParameterURL [export_vars -base "/shared/parameters" {
            package_key
            {scope global}
            return_url
            {scroll_to $parameter_name}
        }]
        set version_id [apm_version_id_from_package_key $package_key]
        set return_label "Back to Site-wide Admin Page"
        set deletePackageParameterURL [export_vars -base "/acs-admin/apm/version-parameters" {
            version_id
            {section_name all}
            {scope global}
            return_url
            return_label
            {scroll_to $parameter_name}
        }]
        # missing for deletePackageParameterURL: filtering, scroll_to
    } else {
        set parameter_value [ns_config ns_section ns/server/[ns_info server]/acs/$package_key $parameter_name]
        if {$parameter_value eq ""} {
            set configured_via "configuration file"
        } else {
            #
            # Presence of addPackageParameterURL controls action item
            #
            set configured_via "default value of the package"
            set version_id [apm_version_id_from_package_key $package_key]
            set description "Version number of [dict get $resource_info resourceName]"
            set addPackageParameterURL [export_vars -base "/acs-admin/apm/parameter-add" {
                version_id
                {section_name all}
                {scope global}
                parameter_name
                default_value
                description
                return_url
                return_label
                {update_info_file false}
            }]
        }
    }
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

if {[dict exists $resource_info vulnerabilityCheck]} {
    set vulnerabilityCheck [dict get $resource_info vulnerabilityCheck]
    dict with vulnerabilityCheck {
        set result [::util::resources::check_vulnerability \
                        -service $service \
                        -library $library \
                        -version $version]
        if {[dict get $result hasVulnerability] ne "?"} {
            set vulnerabilityCheckURL [dict get $result libraryURL]
            set vulnerabilityCheckVersionURL [dict get $result versionURL]
            set vulnerabilityAdvisorURL [dict get $result advisorURL]
            set vulnerabilityCheckResult [dict get $result hasVulnerability]
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
