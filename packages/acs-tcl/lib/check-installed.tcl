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
    {download_url "download"}
}

set resource_dir  [dict get $resource_info resourceDir]
set cdn           [dict get $resource_info cdn]
set resource_name  [dict get $resource_info resourceName]

#
# Check, if the resources are already installed.
#
set is_installed [::util::resources::is_installed_locally \
              -resource_info $resource_info \
              -version_dir $version ]
if {$is_installed} {
    #
    # Tell the users, where the resources are installed.
    #
    set resources $resource_dir/$version

} else {
    #
    # Check, if we can install the resources locally.
    #
    set writable [util::resources::can_install_locally \
              -resource_info $resource_info \
              -version_dir $version]
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
