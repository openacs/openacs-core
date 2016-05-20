ad_page_contract {
    Flush one or more values from util_memoize's cache
} {
    suffix
    {return_url:localurl "."}
}

if {$suffix eq "util_memoize"} {   
    foreach name [ns_cache names util_memoize] {
	ns_cache flush util_memoize $name
    } 
} else {
    #ns_return 200 text/html $suffix
    if {[catch { util_memoize_flush_cache $suffix } errmsg]} {
	ns_return 200 text/html "Cannot flush the cache for $suffix suffix."
    } 
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
