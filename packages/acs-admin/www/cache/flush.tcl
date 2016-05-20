ad_page_contract {
    Flush one or more values from util_memoize's cache
} {
    type
    pattern
    raw_date
    key:allhtml
    {return_url:localurl "show-util-memoize?pattern=$pattern"}
}

if {[catch {set pair [ns_cache get util_memoize $key]} errmsg]} {
    # backup plan, find it again because the key doesn't always 
    # pass through cleanly
    set cached_names [ns_cache names util_memoize]
    foreach name $cached_names {
	if {[regexp -nocase -- $pattern $name match]} {
	    set pair [ns_cache get util_memoize $name]
	    set raw_time [lindex $pair 0]
	    if {$raw_time == $raw_date} {
		set value [ns_quotehtml [lindex $pair 1]]
		set time [clock format $raw_time]
		set key $name
		break
	    }
	}
    }

    if {![info exists value] || "" eq $value} {
	ad_return_complaint 1 "Could not retrieve"
    }
}


ns_cache flush util_memoize $key

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
