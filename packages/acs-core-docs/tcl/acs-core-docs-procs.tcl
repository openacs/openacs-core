ad_library {
    core documentation procs.

    @author Jeff Davis (davis@xarg.net)
    @creation-date 2002-09-10
    @cvs-id $Id$
}

ad_proc -private core_docs_uninstalled_packages_internal {} {
    Returns a list (in array set format) of package.key package-name
    (used for display on the index.adp page).

    @author Jeff Davis (davis@xarg.net)
} {
    set uninstalled [list]
    # Determine which spec files are not installed
    foreach spec_file [apm_scan_packages "[acs_root_dir]/packages"] {
        if { ! [catch {array set version [apm_read_package_info_file $spec_file]} errMsg] } { 
            if { ! [apm_package_registered_p $version(package.key)] } {
                if {[empty_string_p $version(package-name)]} { 
                    set version(package-name) $version(package.key)
                }
                lappend uninstalled [list $version(package.key) $version(package-name)]
            }
        }
    }

    # sort the list and return in array set form
    set out [list]
    foreach pkg [lsort -dictionary -index 1 $uninstalled] { 
        set out [concat $out $pkg]
    }
    return  $out

}

ad_proc -public core_docs_uninstalled_packages {} { 
    Returns a list (in array set format) of package.key package-name
    (used for display on the index.adp page).
    
    Cached version of core_docs_uninstalled_packages_internal
    
    @author Jeff Davis davis@xarg.net
} { 
    return [util_memoize core_docs_uninstalled_packages_internal]
}
