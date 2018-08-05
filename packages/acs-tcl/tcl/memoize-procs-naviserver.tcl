ad_library {

    Defines a convenient cache mechanism, util_memoize.

    @author Various [acs@arsdigita.com]
    @author Rob Mayoff <mayoff@arsdigita.com>
    @author Victor Guerra
    @author Gustaf Neumann

    @creation-date 2000-10-19
    @cvs-id $Id$
}

if {[ns_info name] ne "NaviServer"} {
    return
}

#
# Implementation of util_memoize for NaviServer.  The built-in
# ns_cache_* implementation of NaviServer allows one to specify for
# every entry an expire time (among others). This allows us to
# drop the "manual" expire handling as implemented in the OpenACS
# when NaviServer is available.
#
# @author Victor Guerra
# @author Gustaf Neumann

#
# Flush the existing util memoize cache to get rid of any previous
# caching conventions.  This is actually just needed for the
# upgrade from an AOLserver based util_memoize cache to the
# NaviServer based one, since the old version kept pairs of values
# and timestamps, which are not needed, but which might cause
# confusions, when retrieved later.
#
catch {ns_cache_flush util_memoize}

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
    if {$max_age ne ""} {
        set max_age "-expires $max_age"
    }
    ns_cache_eval {*}$max_age -- util_memoize $script {*}$script
}

# In case, the definition of the function has cached something,
# drop this as well.
catch {ns_cache_flush util_memoize}


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
    ns_cache_eval -force util_memoize $script [list set _ $value]
}


ad_proc -public util_memoize_cached_p {script {max_age ""}} {
    Check whether <i>script</i>'s value has been cached, and whether it
    was cached no more than <i>max_age</i> seconds ago.

    @param script A Tcl script.

    @param max_age Maximum age of cached value in seconds.

    @return Boolean value.
} {
    if {$max_age ne ""} {
        ns_log warning "util_memoize_cached_p: ignore max_age $max_age for $script"
    }
    return [ns_cache_get util_memoize $script .]
}

ad_proc -public util_memoize_flush_pattern {
    -log:boolean
    pattern
} {

    Loop through all cached scripts, flushing all that match the
    pattern that was passed in.

    @param pattern Match pattern (glob pattern like in 'string match $pattern ...').
    @param log Whether to log keys checked and flushed (useful for debugging).

} {
    set nr_flushed [ns_cache_flush -glob util_memoize $pattern]
    if {$log_p} {
        ad_log notice "util_memoize_flush_pattern: flushed $nr_flushed entries using the pattern: $pattern"
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
