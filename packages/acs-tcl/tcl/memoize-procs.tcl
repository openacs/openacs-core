ad_library {

    Defines a convenient cache mechanism, util_memoize.

    @author Various [acs@arsdigita.com]
    @author Rob Mayoff <mayoff@arsdigita.com>
    @author Victor Guerra
    @author Gustaf Neumann

    @creation-date 2000-10-19
    @cvs-id $Id$
}


if {[ns_info name] eq "NaviServer"} {
    #
    # Implementation of util_memoize for NaviServer.  The built-in
    # ns_cache_* implementation of NaviServer allows to specify for
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
        ns_cache_eval {*}$max_age  -- util_memoize $script {*}$script
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
	    ns_log Warning "util_memoize_cached_p: ignore max_age $max_age for $script"
	}
        return [expr {[ns_cache_keys util_memoize $script] ne ""}]
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
            ns_log Debug "util_memoize_flush_pattern: flushed $nf_flushed entries using the pattern: $pattern"
        }
    }

} else {
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

}

ad_proc -public util_memoize_initialized_p {} {
    Return 1 if the util_memoize cache has been initialized
    and is ready to be used and 0 otherwise.
    
} -

if { [catch {ns_cache set util_memoize __util_memoize_installed_p 1} error] } {
    # This definition of util_memoize_initialized_p is for loading during bootstrap.
    
    proc  util_memoize_initialized_p {} {
	#
	# If the cache is not yet created (or some other error is
	# raised) the util_memoize cache is not available.
	#
	if {[catch {ns_cache set util_memoize __util_memoize_installed_p 1} error]} {
	    return 0
	}
	#
	# When he call above has succes, the cache is initialized, we
	# can rewrite the function in an always succeeding one and
	# return success as well.
	#
	proc ::util_memoize_initialized_p {} {
	    return 1
	}
	return 1
    }
} else {
    proc util_memoize_initialized_p {} {
	#
	# This definition of util_memoize_initialized_p is just for
	# reloading, since at that time the cache is always
	# initialized.
	#
	return 1
    }
}


ad_proc -private util_memoize_flush_local {script} {
    Forget any cached value for <i>script</i>.  You probably want to use
    <code>util_memoize_flush</code> to flush the caches on all servers
    in the cluster, in case clustering is enabled.
    
    @param script The Tcl script whose cached value should be flushed.
} {
    ns_cache flush util_memoize $script
}

ad_proc -public util_memoize_flush_regexp {
    -log:boolean
    expr
} {
    Loop through all cached scripts, flushing all that match the
    regular expression that was passed in.

    It is recommended to use util_memoize_flush_pattern whenever
    possible, since glob-match is in most cases sufficient and much
    better performancewise. the glob match can be better supported by
    the built-in set of the server.
    
    @see util_memoize_flush_pattern
    
    @param expr The regular expression to match.
    @param log Whether to log keys checked and flushed (useful for debugging).
} {
    foreach name [ns_cache names util_memoize] {
	if {$log_p} {
	    ns_log Debug "util_memoize_flush_regexp: checking $name for $expr"
	}
	if { [regexp $expr $name] } {
	    if {$log_p} {
		ns_log Debug "util_memoize_flush_regexp: flushing $name"
	    }
	    util_memoize_flush $name
	}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
