ad_page_contract {
} {
}

set page_title "Cache Control"
set context [list [list "../developer" "Developer's Administration"] $page_title]

template::multirow create caches name entries size max flushed hit_rate

foreach cache [lsort -dictionary [ns_cache_names]] {
    if {[regexp {util_memoize_(.*)} $cache match suffix] \
	    || $cache eq "util_memoize"} {
	if {![info exists suffix] || "" eq $suffix} {
	    set name "util_memoize"
	    set match "util_memoize"
	} else {
	    set name $suffix
	}
	set pair [ns_cache_size $match]
	set size [format "%.2f MB" [expr {[lindex $pair 1] / 1048576.0}]]
	set max [format "%.2f MB" [expr {[lindex $pair 0] / 1048576.0}]]
	ns_cache_stats $match stats_array
	set entries $stats_array(entries)
	set flushed $stats_array(flushed)
	set hit_rate $stats_array(hitrate)
	template::multirow append caches $name $entries $size $max \
		$flushed $hit_rate
    }
    set match ""
    set suffix ""
}

