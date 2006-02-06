# Create the cache used by util_memoize.

# Note: we must pass the package_id to ad_parameter, because
# otherwise ad_parameter will end up calling util_memoize to figure
# out the package_id.

ns_cache create util_memoize -size \
    [ad_parameter -package_id [ad_acs_kernel_id] MaxSize memoize 200000]


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

ad_proc -public util_memoize_flush {script} {
    Forget any cached value for <i>script</i>.  If clustering is
    enabled, flush the caches on all servers in the cluster.

    @param script The Tcl script whose cached value should be flushed.
} $flush_body

unset flush_body
