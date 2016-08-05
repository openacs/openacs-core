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
    foreach spec_file [apm_scan_packages "$::acs::rootdir/packages"] {
        if { ! [catch {array set version [apm_read_package_info_file $spec_file]} errMsg] } { 
            if { ! [apm_package_registered_p $version(package.key)] } {
                if {$version(package-name) eq ""} { 
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

ad_proc -public core_docs_html_redirector {args} { 

    Performs an internal redirect requests for .html-pages to .adp
    pages if these exist.
    
    @author Gustaf Neumann
} {
    #
    # There is no [ad_conn file] processed yet. Therefore, we have to
    # compute the path (consider just the path after the package_url
    # for file name construction).
    #
    set path    [string range [ad_conn url] [string length [ad_conn package_url]] end]
    set html_fn [acs_package_root_dir [ad_conn package_key]]/www/$path
    set adp_fn  [file root $html_fn].adp
    
    if {[file readable $adp_fn]} {
        #
        # Perform an internal redirect to the .adp file and stop the filter chain
        #
        #ns_log notice "===== core_docs_html_redirector <$args> url <[ad_conn url]> <[ad_conn file]> ADP exists"
        
        rp_internal_redirect -absolute_path $adp_fn 
        return filter_break
        
    } else {
        #
        # Continue with business as usual
        #
        return filter_ok
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
