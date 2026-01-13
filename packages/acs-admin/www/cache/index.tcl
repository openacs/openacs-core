ad_page_contract {
} {
}

set page_title "Cache Control"
set context [list [list "../developer" "Developer's Administration"] $page_title]

#
# If we have xotcl-core installed, use its cache management
#
if {[dict get [::acs::site_node get -url /xotcl/cache] url] ne "/"} {
    set html [ad_parse_template \
                  [template::themed_template "/packages/xotcl-core/www/cache"]]
    ns_return 200 text/html [ns_adp_parse $html]
    ad_script_abort
}

template::multirow create caches name entries size max flushed hit_rate

foreach cache [lsort -dictionary [ns_cache_names]] {
    array set stats_array [ns_cache_stats $cache]
    set pair [ns_cache_size $cache]
    set size [format "%.2f MB" [expr {[lindex $pair 1] / 1048576.0}]]
    set max [format "%.2f MB" [expr {[lindex $pair 0] / 1048576.0}]]
    set entries $stats_array(entries)
    set flushed $stats_array(flushed)
    set hit_rate $stats_array(hitrate)
    template::multirow append caches $cache $entries $size $max \
        $flushed $hit_rate
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
