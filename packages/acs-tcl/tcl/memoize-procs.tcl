ad_library {

    Defines a convenient cache mechanism, util_memoize.

    @author Various [acs@arsdigita.com]
    @author Rob Mayoff <mayoff@arsdigita.com>
    @creation-date 2000-10-19
    @cvs-id memoize-procs.tcl,v 1.4.2.1 2003/03/05 14:40:42 lars Exp
}

# Use shiny new ns_cache-based util_memoize.

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

    if {![string equal $max_age ""] && $max_age < 0} {
        error "max_age must not be negative"
    }

    set current_time [ns_time]

    set cached_p [ns_cache get util_memoize $script pair]

    if {$cached_p && [string compare $max_age ""] != 0} {
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

ad_proc -private util_memoize_flush_local {script} {
    Forget any cached value for <i>script</i>.  You probably want to use
    <code>util_memoize_flush</code> to flush the caches on all servers
    in the cluster, in case clustering is enabled.

    @param script The Tcl script whose cached value should be flushed.
} {
    ns_cache flush util_memoize $script
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

    if {[string equal $max_age ""]} {
        return 1
    } else {
        set cache_time [lindex $pair 0]
        return [expr {[ns_time] - $cache_time <= $max_age}]
    }
}

ad_proc -public util_memoize_initialized_p {} {
    Return 1 if the util_memoize cache has been initialized
    and is ready to be used and 0 otherwise.
    
    @author Peter Marklund
} {
    return [ad_decode [catch {ns_cache set util_memoize __util_memoize_installed_p 1} error] 0 1 0]
}

ad_proc -public util_memoize_flush_regexp {
    -log:boolean
    expr
} {

    Loop through all cached scripts, flushing all that match the
    regular expression that was passed in.

    @param expr The regular expression to match.
    @param log Whether to log keys checked and flushed (useful for debugging).

} {
    foreach name [ns_cache names util_memoize] {
       if $log_p {
           ns_log Debug "util_memoize_flush_regexp: checking $name for $expr"
       }
       if { [regexp $expr $name] } {
           if $log_p {
               ns_log Debug "util_memoize_flush_regexp: flushing $name"
           }
           util_memoize_flush $name
       }
    }
}
