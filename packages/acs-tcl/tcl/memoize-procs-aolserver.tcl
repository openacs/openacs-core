if {[ns_info name] eq "NaviServer"} {
    return
}

#
# "Classical" implementation of util_memoize for AOLServer
# with script-level expire handling
#
ad_proc -public util_memoize {script {max_age ""}} {
    If <i>script</i> has been executed before, return the value it
    returned last time, unless it was more than <i>max_age</i> seconds ago.

    <p> Otherwise, evaluate <i>script</i> and cache and return the
    result.

    <p> Note: <i>script</i> is not evaluated with <code>uplevel</code>.

    @param script A Tcl script whose value should be memoized.  May be
    best to pass this as a list, e.g. <code>[list someproc $arg1 $arg2]</code>.

    @param max_age The maximum age in seconds for the cached value of
    <i>script</i>.  If the cached value is older than <i>max_age</i>
    seconds, <i>script</i> will be re-executed.

    @return The possibly-cached value returned by <i>script</i>.
} {
    #
    # The ::util_memoize_flush proc is defined in the *-init script,
    # after the util_memoize cache was created. Therefore is save to
    # use the util_memoize when this proc is available.
    #
    if {[info commands ::util_memoize_flush] ne ""} {

        if {$max_age ne "" && $max_age < 0} {
            error "max_age must not be negative"
        }

        set current_time [ns_time]

        set cached_p [ns_cache get util_memoize $script pair]

        if {$cached_p && $max_age ne "" } {
            set cache_time [lindex $pair 0]
            if {$current_time - $cache_time > $max_age} {
                ns_cache flush util_memoize $script
                set cached_p 0
            }
        }

        if {!$cached_p} {
            set pair [ns_cache eval util_memoize $script {
                list $current_time [eval $script]
            }]
        }

        return [lindex $pair 1]
    } else {
        uplevel $script
    }
}

ad_proc -public util_memoize_seed {script value {max_age ""}} {
    Pretend <code>util_memoize</code> was called with <i>script</i> and
    it returned <i>value</i>.  Cache <i>value</i>, replacing any
    previous cache entry for <i>script</i>.

    <p> If clustering is enabled, this command flushes <i>script</i>'s
    value from the caches on all servers in the cluster before storing
    the new value.  The new value is only stored in the local cache.

    @param script A Tcl script that presumably would return
    <i>value</i>.

    @param value The value to cache for <i>script</i>.

    @param max_age Not used.
} {
    util_memoize_flush $script

    ns_cache set util_memoize $script [list [ns_time] $value]
}

ad_proc -public util_memoize_cached_p {script {max_age ""}} {
    Check whether <i>script</i>'s value has been cached, and whether it
    was cached no more than <i>max_age</i> seconds ago.

    @param script A Tcl script.

    @param max_age Maximum age of cached value in seconds.

    @return Boolean value.
} {
    if {![ns_cache get util_memoize $script pair]} {
	return 0
    }

    if {$max_age eq ""} {
	return 1
    } else {
	set cache_time [lindex $pair 0]
	return [expr {[ns_time] - $cache_time <= $max_age}]
    }
}

ad_proc -public util_memoize_flush_pattern {
    -log:boolean
    pattern
} {

    Loop through all cached scripts, flushing all that match the
    pattern that was passed in.

    @param pattern Match pattern (glob pattern like in 'string match $pattern').
    @param log Whether to log keys checked and flushed (useful for debugging).

} {
    foreach name [ns_cache names util_memoize $pattern] {
	if {$log_p} {
	    ns_log Debug "util_memoize_flush_pattern: flushing $name"
	}
	util_memoize_flush $name
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
