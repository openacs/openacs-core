ad_library {

    Defines a convenient cache mechanism, util_memoize.

    @author Various [acs@arsdigita.com]
    @author Rob Mayoff <mayoff@arsdigita.com>
    @date 2000-10-19
    @cvs-id $Id$
}

if {[llength [info commands ns_cache]] > 0} {

    # Use shiny new ns_cache-based util_memoize.

    ad_proc util_memoize {script {max_age ""}} {
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

    ad_proc util_memoize_seed {script value {max_age ""}} {
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

    ad_proc util_memoize_flush_local {script} {
	Forget any cached value for <i>script</i>.  You probably want to use
	<code>util_memoize_flush</code> to flush the caches on all servers
	in the cluster, in case clustering is enabled.

	@param script The Tcl script whose cached value should be flushed.
    } {
	ns_cache flush util_memoize $script
    }

    # We construct the body of util_memoize_flush differently depending
    # on whether clustering is enabled and what command is available for
    # cluster-wide flushing.

    if {[llength [info commands ncf.send]] > 0} {
	set flush_body {
	    ncf.send util_memoize $script
	}
    } elseif {[llength [info commands server_cluster_httpget_from_peers]] > 0} {
	set flush_body {
	    server_cluster_httpget_from_peers "/SYSTEM/flush-memoized-statement.tcl?statement=[ns_urlencode $script]"
	}
    } else {
	set flush_body {}
    }

    append flush_body {
	ns_cache flush util_memoize $script
    }

    ad_proc util_memoize_flush {script} {
	Forget any cached value for <i>script</i>.  If clustering is
	enabled, flush the caches on all servers in the cluster.

	@param script The Tcl script whose cached value should be flushed.
    } $flush_body

    unset flush_body

    ad_proc util_memoize_cached_p {script {max_age ""}} {
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

} else {

    # Use crusty old NSV-based util_memoize.

    ad_proc util_memoize {
	tcl_statement
	{oldest_acceptable_value_in_seconds ""}
    } {

	Returns the result of evaluating the Tcl statement argument and
	then remembers that value in a cache. The memory persists for
	the specified number of seconds or until the server is restarted
	if the second argument is not supplied or until someone calls
	util_memoize_flush with the same Tcl statement. Note that this
	procedure should be used with care because it calls the eval
	built-in procedure.

	@param tcl_statement  The tcl statement to be memoized.  Usually
	    best to put this in a list, e.g. [list proc $arg1 $arg2]

	@param oldest_acceptable_value_in_seconds Specifies how long the
	    memoization should persist.

	@return The cached value of the tcl_statement.
    } { 

	# we look up the statement in the cache to see if it has already
	# been eval'd.  The statement itself is the key

	if {
	    ![nsv_exists util_memoize_cache_value $tcl_statement]
	    || (
		![empty_string_p $oldest_acceptable_value_in_seconds]
		&& (
		    [nsv_get util_memoize_cache_timestamp $tcl_statement]
		    + $oldest_acceptable_value_in_seconds
		    < [ns_time]
		)
	    )
	} {

	    # not in the cache already OR the caller spec'd an expiration
	    # time and our cached value is too old

	    set statement_value [eval $tcl_statement]
	    nsv_set util_memoize_cache_value $tcl_statement $statement_value
	    # store the time in seconds since 1970
	    nsv_set util_memoize_cache_timestamp $tcl_statement [ns_time]
	}

	return [nsv_get util_memoize_cache_value $tcl_statement]
    }

    proc_doc util_memoize_seed {
	tcl_statement
	value
	{oldest_acceptable_value_in_seconds ""}
    } {
	Seeds the memoize catch with a particular value.
	If clustering is enabled, flushes cached values
	from peers in the cluster.
    } {
	if {[llength [info procs server_cluster_httpget_from_peers]] == 1} {
	    server_cluster_httpget_from_peers "/SYSTEM/flush-memoized-statement.tcl?statement=[ns_urlencode $tcl_statement]"
	}

	nsv_set util_memoize_cache_value $tcl_statement $value
	# store the time in seconds since 1970
	nsv_set util_memoize_cache_timestamp $tcl_statement [ns_time]
    }

    proc_doc util_memoize_flush_local {tcl_statement} {
	Flush the cached value only on the local server.
	In general you will want to use util_memoize_flush instead of this!
    } {
	if [nsv_exists util_memoize_cache_value $tcl_statement] {
	    nsv_unset util_memoize_cache_value $tcl_statement
	}
	if [nsv_exists util_memoize_cache_timestamp $tcl_statement] {
	    nsv_unset util_memoize_cache_timestamp $tcl_statement
	}
    }

    proc_doc util_memoize_flush {tcl_statement} {
	Flush the cached value (established with util_memoize
	associated with the argument). If clustering is enabled,
	flushes cached values from peers in the cluster.
    } {
	if {[llength [info procs server_cluster_httpget_from_peers]] == 1} {
	    server_cluster_httpget_from_peers "/SYSTEM/flush-memoized-statement.tcl?statement=[ns_urlencode $tcl_statement]"
	}
	util_memoize_flush_local $tcl_statement
    }

    proc_doc util_memoize_value_cached_p {
	tcl_statement
	{oldest_acceptable_value_in_seconds ""}
    } {
	Returns 1 if there is a cached value for this Tcl expression.  If a second argument is supplied, only returns 1 if the cached value isn't too old.
    } {

	# we look up the statement in the cache to see if it has already
	# been eval'd.  The statement itself is the key

	if {
	    ![nsv_exists util_memoize_cache_value $tcl_statement]
	    || (
		![empty_string_p $oldest_acceptable_value_in_seconds]
		&& (
		    [nsv_get util_memoize_cache_timestamp $tcl_statement]
		    + $oldest_acceptable_value_in_seconds
		    < [ns_time]
		)
	    )
	} {
	    return 0
	} else {
	    return 1
	}    
    }

}
