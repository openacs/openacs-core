ad_page_contract {
    Lists memoized data and gives options to view data or flush data
} {
    {pattern_type "contain"}
    pattern
    {full "f"}
}

set page_title "Search"
set context [list [list "../developer" "Developer's Administration"] [list "." "Cache Control"] $page_title]

#      ns_log notice "ep_flush_list_cache found [llength $cached_names] names cached"

template::multirow create matches key value value_size full_key date raw_date

set cached_names [ns_cache names util_memoize]

if {[ns_info name] eq "NaviServer"} {
    set stats [lindex [ns_cache_stats -contents util_memoize] 0]

    foreach name $cached_names {size time} $stats {
	if {[regexp -nocase -- $pattern $name match]} {
	    set key [ns_quotehtml $name]
	    set safe_key $key ;# why twice?
	    set raw_date [ns_time seconds $time]
	    if {$raw_date eq 0} {
		set expires "No expiration"
	    } else {
		set date [clock format $raw_date -format "%d %b %H:%M:%S"]  
		set expires "Expires $date"
	    }
	    if {[catch {set value [ns_cache get util_memoize $name]} errmsg]} {
		continue
	    }
	    set value_size [string length $value]
	    set value [ns_quotehtml $value]
	    if {$full} {
		template::multirow append matches $key $value $value_size \
		    $safe_key $expires $raw_date
	    } else {
		template::multirow append matches [string range $key 0 200] \
		    [string range $value 0 200] $value_size $safe_key \
		    $expires $raw_date
	    }
	}
    }
} else {

    foreach name $cached_names {
	if {[regexp -nocase -- $pattern $name match]} {
	    set key [ns_quotehtml $name]
	    set safe_key [ns_quotehtml $name]
	    if {[catch {set pair [ns_cache get util_memoize $name]} errmsg]} {
		continue
	    }
	    set raw_date [lindex $pair 0]
	    set date [clock format $raw_date -format "%d %b %H:%M:%S"]  
	    set value [ns_quotehtml [lindex $pair 1]]
	    set value_size [string length $value]
	    if {$full} {
		template::multirow append matches $key $value $value_size \
		    $safe_key $date $raw_date
	    } else {
		template::multirow append matches [string range $key 0 200] \
		    [string range $value 0 200] $value_size $safe_key \
		    $date $raw_date
	    }
	}
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
