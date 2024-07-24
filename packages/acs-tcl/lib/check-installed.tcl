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

set version_dir [::util::resources::version_dir \
                     -resource_info $resource_info \
                     -version $version]

set newest_version [::util::resources::cdnjs_get_newest_version -resource_info $resource_info]

foreach url {versionCheckURL vulnerabilityCheckURL} {
    if {[dict exists $resource_info $url]} {
        set $url [dict get $resource_info $url]
    }
}

#
# Check, if the resources are already installed.
#
set is_installed [::util::resources::is_installed_locally \
                      -resource_info $resource_info \
                      -version_dir $version_dir ]
if {$is_installed} {
    #
    # Tell the users, where the resources are installed.
    #
    set resources $resource_dir/$version_dir
    
} else {
    #
    # Check, if we can install the resources locally.
    #
    set writable [util::resources::can_install_locally \
                      -resource_info $resource_info \
                      -version_dir $version_dir]
    
    if {!$writable} {
        #
        # If we cannot install locally, tell the user were we want to
        # install.
        #
        set path $resource_dir/$version
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
