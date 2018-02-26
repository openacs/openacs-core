ad_library {

    Defines a convenient cache mechanism, util_memoize.

    @author Various [acs@arsdigita.com]
    @author Rob Mayoff <mayoff@arsdigita.com>
    @author Victor Guerra
    @author Gustaf Neumann

    @creation-date 2000-10-19
    @cvs-id $Id$
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
    better performance-wise. the glob match can be better supported by
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
